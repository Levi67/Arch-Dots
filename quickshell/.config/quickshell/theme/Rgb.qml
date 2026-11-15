// Case RGB (rgbctl, ~/.config/rgb/rgbctl): off at every boot, on = a gradient in the theme colors.
// Settings: Config.rgb (brightness, direction, devices, zoneOrder, argbLeds, winter palette).
// On/off lives in $XDG_RUNTIME_DIR/rgbctl/state.json (written by rgbctl, so it is gone after a reboot).
// While on, repaints whenever the wallust colors, winter mode or the RGB settings change.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string ctl: Quickshell.env("HOME") + "/.config/rgb/rgbctl"
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    property bool on: false
    property bool available: false        // at least one server (OpenRGB / OpenLinkHub) answers
    property var servers: ({})
    property var devices: []               // rgbctl list: [{key, server, name, zones: [{name, leds}]}]
    readonly property int brightness: Config.rgb.get("brightness", 100)

    function toggle() {
        setOn(!on);
    }
    function setOn(v) {
        on = v;               // optimistic; the state file confirms it
        run([ctl, v ? "on" : "off"]);
    }
    function refresh() {
        statusProc.running = true;
        listProc.running = true;
    }

    // ---- repaint on changes (debounced; one rgbctl at a time) ----
    // settings changes repaint even while off: that is where the ARGB header sizes get applied
    readonly property string fingerprint: JSON.stringify(Config.rgb.data) + "|" + Config.winter.get("enabled", false)
    onFingerprintChanged: repaint.restart()

    FileView {
        path: Quickshell.env("HOME") + "/.config/kitty/wallust-colors.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: if (root.on)
            repaint.restart()
    }

    Timer {
        id: repaint
        interval: 150
        onTriggered: root.run([root.ctl, "apply"])
    }

    property var pending: null
    function run(cmd) {
        if (worker.running) {
            pending = cmd;
            return;
        }
        worker.command = cmd;
        worker.running = true;
    }
    Process {
        id: worker
        onExited: {
            listProc.running = true;      // zone sizes may have changed
            if (root.pending) {
                const next = root.pending;
                root.pending = null;
                root.run(next);
            }
        }
    }

    // ---- state ----
    FileView {
        id: stateFile
        path: root.runtimeDir + "/rgbctl/state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.on = JSON.parse(text()).on === true;
            } catch (e) {}
        }
        onLoadFailed: root.on = false
    }

    Process {
        id: statusProc
        command: [root.ctl, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.servers = s.servers;
                    root.available = Object.values(s.servers).some(v => v);
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    Process {
        id: listProc
        command: [root.ctl, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.devices = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    // servers can come up after the shell (boot): check now and again shortly
    Timer {
        interval: 10000
        running: !root.available
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
