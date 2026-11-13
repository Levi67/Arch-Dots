// components/Debate.qml
// Debate partner hub. The backend (~/Developement/Debate, systemd user unit debate-backend) runs the
// debate; this panel only shows ~/.local/state/debate/session.json and sends commands via debatectl.
// Hiding the panel keeps the debate running.
//   qs ipc --path ~/.config/quickshell/popups.qml call debate open|close|toggle
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"

Scope {
    id: root

    // ---- settings ----
    property int panelWidth: 1100
    property int panelHeight: 780
    property color warnColor: "#E5C07B"
    property color errorColor: "#E06C75"
    property color proColor: "#61AFEF"
    property color contraColor: "#C678DD"
    property real warnSeconds: 10
    property real scrollStep: 360        // pixels per mouse-wheel notch (bigger = faster)
    readonly property string home: Quickshell.env("HOME")
    readonly property string ctl: home + "/.local/bin/debatectl"
    // inner surfaces: a light tint over the translucent card (like the launcher's fields)
    readonly property color fill: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
    readonly property color fillHover: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
    readonly property color line: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

    // ---- state ----
    property bool shown: false
    property var targetScreen: null
    property var st: ({})
    property real now: Date.now() / 1000
    property bool backendUp: false

    // setup form (kept while the panel is hidden)
    property string motion: ""
    property string position: "random"
    property string difficulty: "normal"
    property int prepMinutes: 15
    property bool voice: true
    property bool annotations: false

    readonly property string phase: st.phase ?? "setup"
    readonly property bool running: ["prep", "info", "open", "closing"].includes(phase)
    readonly property string me: st.me ?? ""
    readonly property string status: st.speaker_status ?? ""
    readonly property bool myTurn: st.speaker === me && me !== ""
    readonly property bool paused: st.paused ?? false
    readonly property real clock: paused ? (st.paused_at ?? now) : now
    readonly property real turnElapsed: (st.turn_started_at ?? 0) > 0 ? Math.max(0, clock - st.turn_started_at) : 0
    readonly property real turnRemaining: (st.turn_seconds ?? 0) - turnElapsed
    readonly property bool turnRunning: (st.turn_started_at ?? 0) > 0
    readonly property real graceRemaining: Math.max(0, (st.grace_until ?? 0) - clock)
    readonly property real prepRemaining: Math.max(0, (st.prep_ends_at ?? 0) - clock)
    readonly property real openRemaining: Math.max(0, (st.open_debate_remaining ?? 0) - (phase === "open" && turnRunning ? Math.min(turnElapsed, st.turn_seconds ?? 0) : 0))
    readonly property var phaseLabel: ({ setup: "Einstellungen", prep: "Vorbereitung", info: "Eröffnungsrunde", open: "Offene Debatte", closing: "Schlussrunde", judging: "Feedback", done: "Feedback" })

    // fast wheel scrolling (the default Flickable wheel speed is very slow)
    function scroll(view, event) {
        const min = view.originY;
        const max = Math.max(min, view.originY + view.contentHeight - view.height);
        const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * scrollStep;
        view.contentY = Math.min(max, Math.max(min, view.contentY - delta));
    }

    // chess.com game-review classifications (colors and icons as on chess.com)
    readonly property var moves: ({
            brilliant: { label: "Brilliant", icon: "!!", color: "#26C2A3", glyph: false },
            great: { label: "Great", icon: "!", color: "#749BBF", glyph: false },
            best: { label: "Best", icon: "\uf005", color: "#81B64C", glyph: true },
            good: { label: "Good", icon: "\uf00c", color: "#95B776", glyph: true },
            book: { label: "Book", icon: "\uf02d", color: "#D5A47D", glyph: true },
            inaccuracy: { label: "Inaccuracy", icon: "?!", color: "#F7C631", glyph: false },
            mistake: { label: "Mistake", icon: "?", color: "#FFA459", glyph: false },
            miss: { label: "Miss", icon: "\uf00d", color: "#FF7769", glyph: true },
            blunder: { label: "Blunder", icon: "??", color: "#FA412D", glyph: false }
        })

    function send(obj) {
        Quickshell.execDetached([ctl, JSON.stringify(obj)]);
    }

    function fmt(sec) {
        const neg = sec < 0;
        const s = Math.floor(Math.abs(sec) + (neg ? 0 : 0.999));
        return (neg ? "-" : "") + Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function nameOf(pos) {
        const who = (st.positions ?? {})[pos];
        return who === "me" ? "Du" : (who ?? "");
    }

    function sideOf(pos) {
        return pos.startsWith("P") ? "pro" : "contra";
    }

    // ---- open / close ----
    function openPanel() {
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === mon.name) {
                    targetScreen = Quickshell.screens[i];
                    break;
                }
            }
        }
        triedStart = false;
        checkBackend.running = true;
        stateFile.reload();
        shown = true;
    }

    IpcHandler {
        target: "debate"
        function open(): void {
            root.openPanel();
        }
        function close(): void {
            root.shown = false;
        }
        function toggle(): void {
            root.shown ? root.shown = false : root.openPanel();
        }
    }

    // ---- backend ----
    // backend reachable = its socket answers; if not, start the unit once per opening
    property bool triedStart: false
    Process {
        id: checkBackend
        command: [root.ctl, "status"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            root.backendUp = exitCode === 0;
            if (!root.backendUp && !root.triedStart) {
                root.triedStart = true;
                Quickshell.execDetached(["systemctl", "--user", "start", "debate-backend.service"]);
            }
        }
    }

    FileView {
        id: stateFile
        path: root.home + "/.local/state/debate/session.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.st = s;
                transcriptModel.sync(s.transcript ?? []);
                if (s.suggested_motion && s.suggested_motion !== root.lastSuggestion) {
                    root.lastSuggestion = s.suggested_motion;
                    root.motion = s.suggested_motion;
                }
                if (s.annotation && s.annotation.at !== root.lastAnnotationAt) {
                    root.lastAnnotationAt = s.annotation.at;
                    toast.show(s.annotation);
                }
            } catch (e) {}
        }
    }
    property string lastSuggestion: ""
    property real lastAnnotationAt: 0

    // fallback in case a file watch is lost; also ticks the clocks
    Timer {
        interval: 250
        repeat: true
        running: root.shown
        onTriggered: {
            root.now = Date.now() / 1000;
            if (++ticks % 4 === 0) {
                stateFile.reload();
                checkBackend.running = true;
            }
        }
        property int ticks: 0
    }

    ListModel {
        id: transcriptModel
        // appends new entries and updates annotations, so the list doesn't jump on every update
        function sync(list) {
            if (list.length < count)
                clear();
            for (let i = 0; i < list.length; i++) {
                const e = list[i];
                const row = {
                    position: e.position,
                    phase: e.phase,
                    text: e.text,
                    seconds: e.seconds ?? 0,
                    overtime: e.overtime_seconds ?? 0,
                    symbol: e.annotation ? (e.annotation.move ?? "") : "",
                    comment: e.annotation ? e.annotation.comment : ""
                };
                if (i < count) {
                    if (get(i).symbol !== row.symbol)
                        set(i, row);
                } else {
                    append(row);
                }
            }
        }
    }

    // ---- small building blocks ----
    component Btn: Rectangle {
        id: btn
        property string label: ""
        property bool primary: false
        property bool active: false
        property color tint: Theme.accent
        property bool enabledBtn: true
        signal clicked
        implicitHeight: 36
        implicitWidth: btnText.implicitWidth + 28
        radius: height / 2
        opacity: enabledBtn ? 1 : 0.4
        color: primary || active ? tint : (mouse.containsMouse ? root.fillHover : root.fill)
        border.width: 1
        border.color: primary || active ? tint : root.line
        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: btn.primary || btn.active ? Theme.background : Theme.text
            font.pixelSize: Theme.fontSize + 1
            font.family: Theme.fontFamily
            font.bold: btn.primary
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabledBtn
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // two clicks needed (the panel can't show dialogs)
    component ConfirmBtn: Btn {
        id: cb
        property string confirmLabel: "Sicher?"
        property bool armed: false
        signal confirmed
        label: armed ? confirmLabel : labelIdle
        property string labelIdle: ""
        tint: root.errorColor
        active: armed
        onClicked: {
            if (armed) {
                armed = false;
                confirmed();
            } else {
                armed = true;
                disarm.restart();
            }
        }
        Timer {
            id: disarm
            interval: 3000
            onTriggered: cb.armed = false
        }
    }

    component Label: Text {
        color: Theme.inactiveWorkspace
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    component Field: Rectangle {
        id: field
        property alias text: input.text
        property string placeholder: ""
        property bool multiline: false
        signal submitted
        implicitHeight: multiline ? 110 : 42
        radius: multiline ? 12 : height / 2
        color: root.fill
        border.width: 1
        border.color: input.activeFocus ? Qt.darker(Theme.accent, 1.5) : root.line
        function focusInput() {
            input.forceActiveFocus();
        }
        Flickable {
            anchors.fill: parent
            anchors.margins: field.multiline ? 12 : 0
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            contentHeight: input.implicitHeight
            clip: true
            TextEdit {
                id: input
                width: parent.width
                height: field.multiline ? Math.max(implicitHeight, field.height - 24) : field.height
                verticalAlignment: field.multiline ? TextEdit.AlignTop : TextEdit.AlignVCenter
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Theme.accent
                font.pixelSize: Theme.fontSize + 2
                font.family: Theme.fontFamily
                Keys.onPressed: event => {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                        field.submitted();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        input.focus = false;
                        event.accepted = true;
                    }
                }
                Text {
                    visible: input.text.length === 0
                    anchors.fill: parent
                    verticalAlignment: parent.verticalAlignment
                    text: field.placeholder
                    color: Theme.inactiveWorkspace
                    font: input.font
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    component Choice: RowLayout {
        id: choice
        property var options: []        // [[value, label], ...]
        property string value: ""
        signal picked(string v)
        spacing: 6
        Repeater {
            model: choice.options
            Btn {
                required property var modelData
                label: modelData[1]
                active: choice.value === modelData[0]
                onClicked: choice.picked(modelData[0])
            }
        }
    }

    // ---- the panel ----
    PanelWindow {
        id: win
        visible: root.shown
        screen: root.targetScreen ?? Quickshell.screens[0]
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        // no anchors = centered on the screen
        implicitWidth: Math.min(root.panelWidth, (screen?.width ?? 1920) - 80)
        implicitHeight: Math.min(root.panelHeight, (screen?.height ?? 1080) - 120)

        WlrLayershell.namespace: "quickshell-debate"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // other apps stay usable

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 20
            color: Theme.barBackground
            border.width: 1
            border.color: Qt.darker(Theme.accent, 1.6)

            // ---- header ----
            Item {
                id: header
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                }
                height: headerCol.implicitHeight

                ColumnLayout {
                    id: headerCol
                    anchors {
                        left: parent.left
                        right: hideBtn.left
                        rightMargin: 12
                    }
                    spacing: 4
                    Text {
                        text: "Debatte · " + (root.phaseLabel[root.phase] ?? root.phase) + (root.paused ? "  ·  pausiert" : "")
                        color: root.paused ? root.warnColor : Theme.accent
                        font.pixelSize: Theme.fontSize + 1
                        font.family: Theme.fontFamily
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.phase !== "setup"
                        text: root.st.motion ?? ""
                        wrapMode: Text.Wrap
                        color: Theme.text
                        font.pixelSize: Theme.fontSize + 6
                        font.family: Theme.fontFamily
                        font.bold: true
                    }
                }
                Btn {
                    id: hideBtn
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                    label: "Ausblenden"
                    onClicked: root.shown = false
                }
            }

            Text {
                id: errorText
                anchors {
                    top: header.bottom
                    topMargin: 8
                    left: parent.left
                    right: parent.right
                    leftMargin: 20
                    rightMargin: 20
                }
                visible: text !== ""
                height: visible ? implicitHeight : 0
                text: !root.backendUp ? "Backend startet… (systemctl --user status debate-backend)" : (root.st.error ?? "")
                color: root.errorColor
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
            }

            Item {
                id: body
                anchors {
                    top: errorText.bottom
                    topMargin: 16
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 20
                    rightMargin: 20
                    bottomMargin: 20
                }

                // ================= setup =================
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.phase === "setup"
                    spacing: 10

                    Label {
                        text: "Streitfrage"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Field {
                            id: motionField
                            Layout.fillWidth: true
                            placeholder: "Eigene Streitfrage eingeben, z. B. „Sollen Hausaufgaben abgeschafft werden?“"
                            text: root.motion
                            onTextChanged: root.motion = text
                        }
                        Btn {
                            label: root.st.suggesting ? "…" : "Zufällig"
                            enabledBtn: root.backendUp && !root.st.suggesting
                            onClicked: root.send({ cmd: "suggest_motion" })
                        }
                    }

                    Label {
                        text: "Position"
                        Layout.topMargin: 6
                    }
                    Choice {
                        options: [["random", "Zufällig"], ["P1", "P1"], ["P2", "P2"], ["K1", "K1"], ["K2", "K2"]]
                        value: root.position
                        onPicked: v => root.position = v
                    }

                    Label {
                        text: "Niveau"
                        Layout.topMargin: 6
                    }
                    Choice {
                        options: [["beginner", "Anfänger"], ["easy", "Leicht"], ["normal", "Normal (gute 9. Klasse)"], ["hard", "Schwer"]]
                        value: root.difficulty
                        onPicked: v => root.difficulty = v
                    }

                    Label {
                        text: "Vorbereitungszeit"
                        Layout.topMargin: 6
                    }
                    RowLayout {
                        spacing: 8
                        Btn {
                            label: "−"
                            onClicked: root.prepMinutes = Math.max(0, root.prepMinutes - 1)
                        }
                        Text {
                            Layout.preferredWidth: 70
                            horizontalAlignment: Text.AlignHCenter
                            text: root.prepMinutes + " min"
                            color: Theme.text
                            font.pixelSize: Theme.fontSize + 3
                            font.family: Theme.fontFamily
                        }
                        Btn {
                            label: "+"
                            onClicked: root.prepMinutes = Math.min(60, root.prepMinutes + 1)
                        }
                    }

                    Label {
                        text: "Optionen"
                        Layout.topMargin: 6
                    }
                    RowLayout {
                        spacing: 8
                        Btn {
                            label: root.voice ? "Sprache: an" : "Sprache: aus (Text)"
                            active: root.voice
                            onClicked: root.voice = !root.voice
                        }
                        Btn {
                            label: root.annotations ? "Schach-Kommentare: an" : "Schach-Kommentare: aus"
                            active: root.annotations
                            onClicked: root.annotations = !root.annotations
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                    Btn {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredHeight: 46
                        primary: true
                        label: "Debatte starten"
                        enabledBtn: root.backendUp && root.motion.trim() !== ""
                        onClicked: root.send({
                            cmd: "start",
                            motion: root.motion.trim(),
                            position: root.position,
                            difficulty: root.difficulty,
                            prep_minutes: root.prepMinutes,
                            voice: root.voice,
                            annotations: root.annotations
                        })
                    }
                }

                // ================= seats (prep + debate) =================
                GridLayout {
                    id: seats
                    visible: root.running
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 10
                    Repeater {
                        model: ["P1", "K1", "P2", "K2"]
                        Rectangle {
                            id: seat
                            required property string modelData
                            readonly property bool mine: modelData === root.me
                            readonly property bool mate: modelData === root.st.teammate
                            readonly property bool speaking: root.st.speaker === modelData
                            readonly property color sideColor: root.sideOf(modelData) === "pro" ? root.proColor : root.contraColor
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            radius: 14
                            color: speaking ? Qt.rgba(sideColor.r, sideColor.g, sideColor.b, 0.25) : root.fill
                            border.width: mine || speaking ? 2 : 1
                            border.color: mine ? Theme.accent : (speaking ? sideColor : root.line)
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10
                                Text {
                                    text: seat.modelData
                                    color: seat.sideColor
                                    font.pixelSize: Theme.fontSize + 4
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Text {
                                        text: root.nameOf(seat.modelData)
                                        color: Theme.text
                                        font.pixelSize: Theme.fontSize + 2
                                        font.family: Theme.fontFamily
                                        font.bold: seat.mine
                                    }
                                    Text {
                                        text: seat.mine ? "Du" : (seat.mate ? "Teampartner · " : "Gegner · ") + ((root.st.agents ?? {})[seat.modelData]?.style ?? "")
                                        color: Theme.inactiveWorkspace
                                        font.pixelSize: Theme.fontSize - 1
                                        font.family: Theme.fontFamily
                                    }
                                }
                                Text {
                                    visible: seat.speaking
                                    text: ({ thinking: "denkt…", speaking: "spricht", ready: "bereit", recording: "● Aufnahme", transcribing: "transkribiert…" })[root.status] ?? ""
                                    color: root.status === "recording" ? root.errorColor : seat.sideColor
                                    font.pixelSize: Theme.fontSize
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }
                }

                // ================= prep =================
                ColumnLayout {
                    visible: root.phase === "prep"
                    anchors {
                        top: seats.bottom
                        topMargin: 16
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.fmt(root.prepRemaining)
                            color: Theme.text
                            font.pixelSize: 44
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        ConfirmBtn {
                            labelIdle: "Abbrechen"
                            confirmLabel: "Debatte verwerfen?"
                            onConfirmed: root.send({ cmd: "reset" })
                        }
                        Btn {
                            label: "Vorbereitung beenden"
                            primary: true
                            onClicked: root.send({ cmd: "end_prep" })
                        }
                    }
                    Label {
                        text: "Absprache mit deinem Teampartner " + root.nameOf(root.st.teammate ?? "")
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: root.fill
                        ListView {
                            id: prepList
                            anchors.fill: parent
                            anchors.margins: 12
                            clip: true
                            spacing: 8
                            model: root.st.prep_messages ?? []
                            interactive: false
                            onCountChanged: positionViewAtEnd()
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: event => root.scroll(prepList, event)
                            }
                            delegate: Text {
                                required property var modelData
                                width: prepList.width
                                wrapMode: Text.Wrap
                                textFormat: Text.StyledText
                                text: "<b>" + (modelData.from === "me" ? "Du" : root.nameOf(modelData.from)) + ":</b> " + modelData.text
                                color: modelData.from === "me" ? Theme.accent : Theme.text
                                font.pixelSize: Theme.fontSize + 1
                                font.family: Theme.fontFamily
                            }
                        }
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 12
                            visible: root.st.prep_busy ?? false
                            text: root.nameOf(root.st.teammate ?? "") + " schreibt…"
                            color: Theme.inactiveWorkspace
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Field {
                            id: prepField
                            Layout.fillWidth: true
                            placeholder: "Nachricht an deinen Teampartner (Enter)"
                            onSubmitted: sendPrep()
                            function sendPrep() {
                                if (text.trim() === "")
                                    return;
                                root.send({ cmd: "prep_message", text: text.trim() });
                                text = "";
                            }
                        }
                        Btn {
                            label: "Senden"
                            onClicked: prepField.sendPrep()
                        }
                    }
                }

                // ================= debate =================
                ColumnLayout {
                    visible: ["info", "open", "closing"].includes(root.phase)
                    anchors {
                        top: seats.bottom
                        topMargin: 16
                        left: parent.left
                        right: parent.right
                        bottom: controls.top
                        bottomMargin: 12
                    }
                    spacing: 10

                    // ---- clock ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text {
                            id: bigClock
                            readonly property real value: root.status === "grace" ? root.graceRemaining : root.turnRemaining
                            text: root.status === "thinking" || root.status === "transcribing" || (root.status === "ready") ? root.fmt(root.st.turn_seconds ?? 0) : root.fmt(value)
                            color: !root.turnRunning && root.status !== "grace" ? Theme.inactiveWorkspace : (value < 0 ? root.errorColor : (value <= root.warnSeconds ? root.warnColor : Theme.text))
                            font.pixelSize: 40
                            font.family: Theme.fontFamily
                            font.bold: true
                            SequentialAnimation on opacity {
                                running: root.myTurn && root.status === "recording" && bigClock.value <= root.warnSeconds && !root.paused
                                loops: Animation.Infinite
                                onRunningChanged: if (!running)
                                    bigClock.opacity = 1
                                NumberAnimation {
                                    to: 0.4
                                    duration: 400
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 400
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: {
                                    const s = root.status, who = root.nameOf(root.st.speaker ?? "");
                                    if (s === "grace")
                                        return "Ihr seid dran! Selbst sprechen oder " + root.nameOf(root.st.teammate ?? "") + " übernimmt.";
                                    if (root.myTurn && s === "ready")
                                        return "Du bist dran. Starte, wenn du bereit bist.";
                                    if (root.myTurn && s === "recording")
                                        return root.turnRemaining < 0 ? "Zeit überzogen – komm zum Schluss." : "Du sprichst.";
                                    if (s === "transcribing")
                                        return "Deine Rede wird transkribiert…";
                                    if (s === "thinking")
                                        return who + " überlegt…";
                                    if (s === "speaking")
                                        return who + " spricht.";
                                    return "";
                                }
                                color: Theme.text
                                font.pixelSize: Theme.fontSize + 3
                                font.family: Theme.fontFamily
                            }
                            // open debate: total time left
                            Text {
                                visible: root.phase === "open"
                                text: "Offene Debatte: noch " + root.fmt(root.openRemaining) + (root.st.open_side ? "  ·  " + (root.st.open_side === "pro" ? "Pro" : "Kontra") + " ist dran" : "")
                                color: Theme.inactiveWorkspace
                                font.pixelSize: Theme.fontSize
                                font.family: Theme.fontFamily
                            }
                            Rectangle {
                                visible: root.phase === "open"
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: root.fill
                                Rectangle {
                                    width: parent.width * root.openRemaining / 480
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                            }
                        }

                        // ---- turn actions ----
                        Btn {
                            visible: root.status === "grace"
                            primary: true
                            label: "Ich spreche (" + Math.ceil(root.graceRemaining) + ")"
                            onClicked: root.send({ cmd: "claim" })
                        }
                        Btn {
                            visible: root.status === "grace"
                            label: root.nameOf(root.st.teammate ?? "") + ", übernimm"
                            onClicked: root.send({ cmd: "mate" })
                        }
                        Btn {
                            visible: root.myTurn && root.status === "ready"
                            primary: true
                            label: "Rede starten"
                            onClicked: root.send({ cmd: "start_speaking" })
                        }
                        Btn {
                            visible: root.myTurn && root.status === "recording" && (root.st.settings?.voice ?? true)
                            primary: true
                            tint: root.errorColor
                            label: "Rede beenden"
                            onClicked: root.send({ cmd: "finish" })
                        }
                    }

                    // text mode: type the speech instead of speaking
                    RowLayout {
                        Layout.fillWidth: true
                        visible: !(root.st.settings?.voice ?? true) && ((root.myTurn && ["ready", "recording"].includes(root.status)) || root.status === "grace")
                        Field {
                            id: sayField
                            Layout.fillWidth: true
                            multiline: true
                            placeholder: "Deine Rede (Enter = absenden, Shift+Enter = neue Zeile)"
                            onSubmitted: sendSpeech()
                            function sendSpeech() {
                                if (text.trim() === "")
                                    return;
                                root.send({ cmd: "say", text: text.trim() });
                                text = "";
                            }
                        }
                        Btn {
                            label: "Absenden"
                            primary: true
                            onClicked: sayField.sendSpeech()
                        }
                    }

                    // ---- transcript ----
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: root.fill
                        ListView {
                            id: transcriptView
                            anchors.fill: parent
                            anchors.margins: 12
                            clip: true
                            spacing: 14
                            model: transcriptModel
                            interactive: false
                            onCountChanged: Qt.callLater(positionViewAtEnd)
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: event => root.scroll(transcriptView, event)
                            }
                            delegate: Column {
                                id: entry
                                required property string position
                                required property string phase
                                required property string text
                                required property real seconds
                                required property real overtime
                                required property string symbol
                                required property string comment
                                width: transcriptView.width
                                spacing: 3
                                Text {
                                    textFormat: Text.StyledText
                                    text: "<b>" + entry.position + " · " + root.nameOf(entry.position) + "</b>  <font color='" + Theme.inactiveWorkspace + "'>" + root.phaseLabel[entry.phase] + " · " + Math.round(entry.seconds) + " s</font>" + (entry.overtime > 0 ? "  <font color='" + root.errorColor + "'>+" + Math.round(entry.overtime) + " s</font>" : "") + (entry.symbol && root.moves[entry.symbol] ? "  <b><font color='" + root.moves[entry.symbol].color + "'>" + root.moves[entry.symbol].label + "</font></b>" : "")
                                    color: entry.position === root.me ? Theme.accent : (root.sideOf(entry.position) === "pro" ? root.proColor : root.contraColor)
                                    font.pixelSize: Theme.fontSize
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: entry.text
                                    color: Theme.text
                                    font.pixelSize: Theme.fontSize + 1
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }
                }

                // ---- controls (prep + debate) ----
                Flow {
                    id: controls
                    visible: ["info", "open", "closing"].includes(root.phase)
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: 8
                    Btn {
                        label: root.paused ? "Weiter" : "Pause"
                        active: root.paused
                        tint: root.warnColor
                        onClicked: root.send({ cmd: root.paused ? "resume" : "pause" })
                    }
                    Btn {
                        label: "Redner überspringen"
                        onClicked: root.send({ cmd: "skip_speaker" })
                    }
                    ConfirmBtn {
                        labelIdle: "Phase überspringen"
                        tint: root.warnColor
                        onConfirmed: root.send({ cmd: "skip_phase" })
                    }
                    ConfirmBtn {
                        labelIdle: "Debatte beenden"
                        confirmLabel: "Beenden + Feedback?"
                        onConfirmed: root.send({ cmd: "end" })
                    }
                }

                // ================= feedback =================
                // built only while needed: a fresh item when the judge starts, gone again after reset
                Loader {
                    anchors.fill: parent
                    active: root.phase === "judging" || root.phase === "done"
                    sourceComponent: Component {
                    ColumnLayout {
                        spacing: 12

                        Text {
                            visible: root.phase === "judging"
                            text: "Der Juror wertet deine Debatte aus…"
                            color: Theme.text
                            font.pixelSize: Theme.fontSize + 3
                            font.family: Theme.fontFamily
                            SequentialAnimation on opacity {
                                running: root.phase === "judging" && root.shown
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.35
                                    duration: 700
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 700
                                }
                            }
                        }
                        Text {
                            visible: (root.st.result ?? "") !== ""
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: root.st.result ?? ""
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize + 5
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                        Rectangle {
                            visible: root.phase === "done" && (root.st.feedback ?? "") !== ""
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: root.fill
                            Flickable {
                                id: feedbackFlick
                                anchors.fill: parent
                                anchors.margins: 16
                                clip: true
                                contentHeight: feedbackText.implicitHeight
                                interactive: false
                                WheelHandler {
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: event => root.scroll(feedbackFlick, event)
                                }
                                Text {
                                    id: feedbackText
                                    width: feedbackFlick.width
                                    wrapMode: Text.Wrap
                                    textFormat: Text.MarkdownText
                                    text: root.st.feedback ?? ""
                                    color: Theme.text
                                    font.pixelSize: Theme.fontSize + 1
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                        RowLayout {
                            visible: root.phase === "done"
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                text: root.st.log_path ? "Gespeichert: " + root.st.log_path.replace(/^.*\/Vault\/Home\//, "") : ""
                                color: Theme.inactiveWorkspace
                                font.pixelSize: Theme.fontSize - 1
                                font.family: Theme.fontFamily
                            }
                            Btn {
                                primary: true
                                label: "Neue Debatte"
                                onClicked: root.send({ cmd: "reset" })
                            }
                        }
                    }
                    }
                }
            }

            // ---- chess.com-style move annotation toast (bottom right) ----
            Rectangle {
                id: toast
                property var info: ({})
                readonly property var move: root.moves[info.move ?? ""] ?? root.moves.good
                function show(a) {
                    info = a;
                    opacity = 1;
                    hideToast.restart();
                }
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                    bottomMargin: 70
                }
                width: Math.min(380, toastRow.implicitWidth + 28)
                height: toastRow.implicitHeight + 24
                radius: 14
                opacity: 0
                visible: opacity > 0
                color: Theme.background
                border.width: 2
                border.color: move.color
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
                Timer {
                    id: hideToast
                    interval: 7000
                    onTriggered: toast.opacity = 0
                }
                RowLayout {
                    id: toastRow
                    anchors.centerIn: parent
                    spacing: 12
                    // round badge like on chess.com
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 20
                        color: toast.move.color
                        Text {
                            anchors.centerIn: parent
                            text: toast.move.icon
                            color: "white"
                            font.pixelSize: toast.move.glyph ? 18 : 17
                            font.bold: true
                            font.family: toast.move.glyph ? "JetBrainsMono Nerd Font" : Theme.fontFamily
                        }
                    }
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: toast.move.label
                            color: toast.move.color
                            font.pixelSize: Theme.fontSize + 4
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            Layout.maximumWidth: 290
                            wrapMode: Text.Wrap
                            text: toast.info.comment ?? ""
                            color: Theme.text
                            font.pixelSize: Theme.fontSize + 1
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }
        }
    }
}
