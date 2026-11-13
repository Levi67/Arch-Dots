// Displays: drag the monitors into place, pick mode / scale / VRR, brightness over DDC/CI.
// "Apply" changes Hyprland live (hl.monitor via hyprctl eval) and asks for 15 s whether to keep it;
// no answer = revert. "Keep" saves ~/.config/desktop/displays.json and regenerates hypr/monitors.lua.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Displays"
    subtitle: "Drag the monitors to arrange them (edges snap together), then Apply."

    property var live: []        // what Hyprland runs right now: [{ name, description, mode, modes, x, y, w, h, scale, vrr }]
    property var draft: []       // what you are editing
    property var before: []      // the state to go back to while asking "keep?"
    property string selected: ""
    property int countdown: 0
    readonly property bool dirty: JSON.stringify(strip(draft)) !== JSON.stringify(strip(live))
    readonly property var sel: draft.find(m => m.name === selected) ?? null

    function strip(list) {
        return list.map(m => ({
                    name: m.name,
                    mode: m.mode,
                    x: m.x,
                    y: m.y,
                    scale: m.scale,
                    vrr: m.vrr
                }));
    }

    // ---- reading Hyprland ----
    Process {
        id: query
        running: true
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try {
                    list = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const mons = list.map(m => {
                    const modes = (m.availableModes ?? []).map(s => s.replace(/Hz$/, ""));
                    const cur = page.closestMode(modes, m.width, m.height, m.refreshRate);
                    return {
                        name: m.name,
                        description: m.description,
                        modes: modes,
                        mode: cur,
                        x: m.x,
                        y: m.y,
                        scale: +m.scale.toFixed(2),
                        vrr: m.vrr ? 1 : 0
                    };
                }).sort((a, b) => a.x - b.x);
                page.live = mons;
                if (page.countdown === 0)
                    page.draft = JSON.parse(JSON.stringify(mons));
                if (!page.selected && mons.length)
                    page.selected = mons[0].name;
            }
        }
    }

    function closestMode(modes, w, h, hz) {
        let best = w + "x" + h + "@" + hz.toFixed(2), err = 1e9;
        for (const s of modes) {
            const m = /^(\d+)x(\d+)@([\d.]+)$/.exec(s);
            if (!m || +m[1] !== w || +m[2] !== h)
                continue;
            const e = Math.abs(+m[3] - hz);
            if (e < err) {
                err = e;
                best = s;
            }
        }
        return best;
    }

    function size(m) {
        const r = /^(\d+)x(\d+)/.exec(m.mode);
        const w = r ? +r[1] : 1920, h = r ? +r[2] : 1080;
        return {
            w: Math.round(w / m.scale),
            h: Math.round(h / m.scale)
        };
    }

    function update(name, changes) {
        draft = draft.map(m => m.name === name ? Object.assign({}, m, changes) : m);
    }

    // ---- applying ----
    function luaFor(m) {
        return 'hl.monitor({ output = "' + m.name + '", mode = "' + m.mode + '", position = "' + m.x + "x" + m.y + '", scale = ' + m.scale + ", vrr = " + m.vrr + " })";
    }

    function push(list) {
        // one eval per monitor (the Lua has no single quotes, so it can be single-quoted)
        apply.command = ["sh", "-c", list.map(m => "hyprctl eval '" + luaFor(m) + "'").join("; ")];
        apply.running = true;
    }
    Process {
        id: apply
        onExited: refreshLater.restart()
    }
    Timer {
        id: refreshLater
        interval: 600
        onTriggered: query.running = true
    }

    function applyDraft() {
        before = JSON.parse(JSON.stringify(live));
        push(draft);
        countdown = 15;
    }

    function revert() {
        countdown = 0;
        push(before);
        draft = JSON.parse(JSON.stringify(before));
    }

    function keep() {
        countdown = 0;
        const out = {};
        for (const m of draft)
            out[m.name] = {
                mode: m.mode,
                x: m.x,
                y: m.y,
                scale: m.scale,
                vrr: m.vrr
            };
        Config.displays.set("monitors", out);
        writeLua.startDetached();
    }
    Process {
        id: writeLua
        command: ["sh", "-c", "sleep 0.5; exec \"$0\"", Quickshell.shellPath("scripts/write-monitors-lua")]
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.countdown > 0
        onTriggered: if (--page.countdown === 0)
            page.revert()
    }

    // closing the window while asking = revert
    Component.onDestruction: if (countdown > 0)
        revert()

    // ---- the map ----
    SCard {
        Item {
            id: map
            Layout.fillWidth: true
            implicitHeight: 260

            readonly property var bounds: {
                let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
                for (const m of page.draft) {
                    const s = page.size(m);
                    x0 = Math.min(x0, m.x);
                    y0 = Math.min(y0, m.y);
                    x1 = Math.max(x1, m.x + s.w);
                    y1 = Math.max(y1, m.y + s.h);
                }
                return page.draft.length ? {
                    x: x0,
                    y: y0,
                    w: x1 - x0,
                    h: y1 - y0
                } : {
                    x: 0,
                    y: 0,
                    w: 1,
                    h: 1
                };
            }
            // px on screen per logical px; a bit of room so you can drag outwards
            readonly property real k: Math.min(width / (bounds.w * 1.25), height / (bounds.h * 1.6))
            readonly property real ox: (width - bounds.w * k) / 2 - bounds.x * k
            readonly property real oy: (height - bounds.h * k) / 2 - bounds.y * k

            // snap a dropped monitor to the others' edges, then make the layout start at 0,0
            function drop(name, rx, ry) {
                const me = page.draft.find(m => m.name === name);
                const s = page.size(me);
                let x = Math.round((rx - ox) / k), y = Math.round((ry - oy) / k);
                const tol = 60 / k;      // 60 screen px
                let bx = tol + 1, by = tol + 1, sx = x, sy = y;
                for (const o of page.draft) {
                    if (o.name === name)
                        continue;
                    const os = page.size(o);
                    for (const c of [o.x - s.w, o.x + os.w, o.x, o.x + os.w - s.w])
                        if (Math.abs(c - x) < bx) {
                            bx = Math.abs(c - x);
                            sx = c;
                        }
                    for (const c of [o.y, o.y + os.h - s.h, o.y - s.h, o.y + os.h])
                        if (Math.abs(c - y) < by) {
                            by = Math.abs(c - y);
                            sy = c;
                        }
                }
                x = sx;
                y = sy;
                // no overlaps allowed
                const overlaps = page.draft.some(o => {
                    if (o.name === name)
                        return false;
                    const os = page.size(o);
                    return x < o.x + os.w && x + s.w > o.x && y < o.y + os.h && y + s.h > o.y;
                });
                if (!overlaps)
                    page.update(name, {
                        x: x,
                        y: y
                    });
                // normalize to start at 0,0
                const minX = Math.min(...page.draft.map(m => m.x)), minY = Math.min(...page.draft.map(m => m.y));
                if (minX !== 0 || minY !== 0)
                    page.draft = page.draft.map(m => Object.assign({}, m, {
                            x: m.x - minX,
                            y: m.y - minY
                        }));
                page.draftChanged();
            }

            Repeater {
                model: page.draft
                delegate: Rectangle {
                    id: mon
                    required property var modelData
                    readonly property var sz: page.size(modelData)
                    readonly property bool isSel: page.selected === modelData.name
                    x: map.ox + modelData.x * map.k
                    y: map.oy + modelData.y * map.k
                    width: sz.w * map.k
                    height: sz.h * map.k
                    radius: 8
                    z: drag.drag.active ? 2 : (isSel ? 1 : 0)
                    color: isSel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    border.width: isSel ? 2 : 1
                    border.color: isSel ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        SLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: mon.modelData.name
                            font.weight: Font.Bold
                        }
                        SLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: mon.modelData.mode.replace("@", " @ ") + "Hz"
                            dim: true
                            size: Theme.fontSize - 3
                        }
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        cursorShape: drag.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: page.countdown > 0 ? null : mon
                        onPressed: page.selected = mon.modelData.name
                        onReleased: {
                            const ex = map.ox + mon.modelData.x * map.k, ey = map.oy + mon.modelData.y * map.k;
                            if (Math.abs(mon.x - ex) > 0.5 || Math.abs(mon.y - ey) > 0.5)
                                map.drop(mon.modelData.name, mon.x, mon.y);
                        }
                    }
                }
            }
        }

        // keep / revert prompt
        Rectangle {
            visible: page.countdown > 0
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 12
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
            border.width: 1
            border.color: Theme.accent
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                SLabel {
                    Layout.fillWidth: true
                    text: "Keep these display settings? Reverting in " + page.countdown + " s"
                    font.weight: Font.Bold
                }
                SButton {
                    text: "Revert"
                    onClicked: page.revert()
                }
                SButton {
                    text: "Keep"
                    primary: true
                    onClicked: page.keep()
                }
            }
        }

        RowLayout {
            visible: page.countdown === 0
            Layout.fillWidth: true
            SLabel {
                Layout.fillWidth: true
                text: page.dirty ? "Unapplied changes" : "Matches what's running"
                dim: true
            }
            SButton {
                text: "Reset"
                flat: true
                enabled: page.dirty
                onClicked: page.draft = JSON.parse(JSON.stringify(page.live))
            }
            SButton {
                text: "Apply"
                primary: true
                enabled: page.dirty
                onClicked: page.applyDraft()
            }
        }
    }

    // ---- the selected monitor ----
    SCard {
        visible: page.sel !== null
        title: page.sel ? page.sel.name + "  ·  " + page.sel.description : ""
        icon: "monitor"
        enabled: page.countdown === 0

        SRow {
            label: "Resolution & refresh rate"
            SCombo {
                Layout.preferredWidth: 260
                options: page.sel ? page.sel.modes.map(s => ({
                            label: s.replace("@", " @ ") + " Hz",
                            value: s
                        })) : []
                current: page.sel?.mode
                onPicked: v => page.update(page.selected, {
                        mode: v
                    })
            }
        }
        SRow {
            label: "Scale"
            SCombo {
                Layout.preferredWidth: 160
                options: [1, 1.25, 1.333333, 1.5, 1.6, 1.75, 2].map(v => ({
                            label: Math.round(v * 100) + "%",
                            value: v
                        }))
                current: page.sel?.scale
                onPicked: v => page.update(page.selected, {
                        scale: v
                    })
            }
        }
        SRow {
            label: "Variable refresh rate (VRR)"
            SSwitch {
                checked: (page.sel?.vrr ?? 0) > 0
                onToggled: v => page.update(page.selected, {
                        vrr: v ? 1 : 0
                    })
            }
        }
        SRow {
            label: "Brightness"
            hint: !ddc.available ? "Needs ddcutil + the i2c-dev module (see install-packages.sh)" : ddc.displays[page.selected] === undefined ? "This monitor doesn't answer DDC/CI" : "Over DDC/CI - the monitor's own backlight"
            SSlider {
                Layout.preferredWidth: 300
                enabled: ddc.displays[page.selected] !== undefined
                from: 0
                to: 100
                stepSize: 5
                suffix: "%"
                value: ddc.brightness[page.selected] ?? 0
                onCommitted: v => ddc.set(page.selected, v)
            }
        }
    }

    // ---- DDC/CI brightness (slow: ~1 s per call, so only on demand) ----
    QtObject {
        id: ddc
        property bool available: false
        property var displays: ({})      // connector name -> ddcutil display number
        property var brightness: ({})    // connector name -> 0..100

        function set(name, v) {
            const b = Object.assign({}, brightness);
            b[name] = v;
            brightness = b;
            setter.command = ["ddcutil", "--noverify", "--display", String(displays[name]), "setvcp", "10", String(Math.round(v))];
            setter.running = true;
        }
    }
    Process {
        id: setter
    }
    Process {
        id: detect
        running: true
        command: ["sh", "-c", "command -v ddcutil >/dev/null || exit 3; ddcutil detect --terse 2>/dev/null | awk '/^Display/{d=$2} /DRM connector/{sub(/^card[0-9]+-/,\"\",$3); print d, $3}' | while read -r n c; do v=$(ddcutil --display $n getvcp 10 --brief 2>/dev/null | awk '{print $4}'); echo \"$n $c ${v:-0}\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const disp = {}, bri = {};
                for (const line of text.trim().split("\n")) {
                    const p = line.trim().split(/\s+/);
                    if (p.length < 3)
                        continue;
                    disp[p[1]] = +p[0];
                    bri[p[1]] = +p[2];
                }
                ddc.displays = disp;
                ddc.brightness = bri;
            }
        }
        onExited: code => ddc.available = code !== 3
    }
}
