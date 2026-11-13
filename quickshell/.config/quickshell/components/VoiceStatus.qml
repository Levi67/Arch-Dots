// components/VoiceStatus.qml
// Voice assistant status (wake-listener.py). Square pill normally, 1:4 while speaking.
//   off         dim mic-off icon        (click to start)
//   idle        spinning arc            waiting for "Claude"
//   listening   pulsing mic             wake word heard, recording the request
//   processing  pulsing brain + timer   transcribing / Claude thinking (pill widens)
//   speaking    speaker + time left     (pill widens)
//   error       red alert               microphone unavailable
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ---- settings ----
    property string stateFile: "/tmp/voice-assistant-state"
    property string startCommand: "/home/claude-agent/bin/voice-loop.sh"
    property string logFile: "/tmp/voice-assistant.log"
    property string iconFont: "JetBrainsMono Nerd Font"
    property int iconSize: 16
    property int wideFactor: 4 // width:height while speaking
    property color errorColor: "#E06C75"

    // ---- state (written by wake-listener.py as "<state> <pid> <speak-until>") ----
    property string state: "off"
    property int pid: 0
    property real speakUntil: 0 // speaking: when it ends; processing: when it started
    property real remaining: 0
    property real elapsed: 0
    readonly property bool running: state !== "off"
    readonly property bool speaking: state === "speaking"
    readonly property bool thinking: state === "processing"
    readonly property bool wide: speaking || thinking
    readonly property bool waiting: state === "idle" || state === "starting"

    implicitHeight: Theme.bubbleHeight
    implicitWidth: wide ? Theme.bubbleHeight * wideFactor : Theme.bubbleHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // One long-running loop; prints only on change. A stale file from a crashed listener reads
    // as "off" because its pid is gone from /proc.
    Process {
        running: true
        command: ["sh", "-c", `
            f="${root.stateFile}"; prev=""
            while :; do
                line="off 0 0"
                if read -r st pid until < "$f" 2>/dev/null && [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
                    line="$st $pid $until"
                fi
                [ "$line" != "$prev" ] && echo "$line" && prev=$line
                sleep 0.25
            done`]

        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(" ");
                root.pid = Number(p[1]) || 0;
                root.speakUntil = Number(p[2]) || 0;
                root.state = p[0] || "off"; // last, so handlers see a consistent pid/speakUntil
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.speaking
        triggeredOnStart: true
        onTriggered: root.remaining = Math.max(0, root.speakUntil - Date.now() / 1000)
    }

    Timer {
        interval: 100
        repeat: true
        running: root.thinking
        triggeredOnStart: true
        onTriggered: root.elapsed = Math.max(0, Date.now() / 1000 - root.speakUntil)
    }

    function formatRemaining(secs) {
        const s = Math.ceil(secs);
        return s < 60 ? s + "s" : Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function formatElapsed(secs) {
        return secs < 60 ? secs.toFixed(1) + "s" : Math.floor(secs / 60) + ":" + String(Math.floor(secs % 60)).padStart(2, "0");
    }

    function iconFor(state) {
        switch (state) {
        case "listening":
            return String.fromCodePoint(0xf036c); // mic
        case "processing":
            return String.fromCodePoint(0xf09d1); // brain
        case "speaking":
            return String.fromCodePoint(0xf057e); // volume-high
        case "error":
            return String.fromCodePoint(0xf0026); // alert
        default:
            return String.fromCodePoint(0xf036d); // mic-off
        }
    }

    // ---- icon area: always a square on the left, so it's centred when the pill is 1:1 ----
    Item {
        id: iconBox
        width: Theme.bubbleHeight
        height: Theme.bubbleHeight
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Shape {
            id: spinner
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            visible: root.waiting
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Theme.accent
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.iconSize / 2
                    centerY: root.iconSize / 2
                    radiusX: root.iconSize / 2 - 1
                    radiusY: root.iconSize / 2 - 1
                    startAngle: 0
                    sweepAngle: 270
                }
            }

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 1600
                loops: Animation.Infinite
                running: spinner.visible
            }
        }

        Text {
            id: icon
            anchors.centerIn: parent
            visible: !root.waiting
            text: root.iconFor(root.state)
            font.family: root.iconFont
            font.pixelSize: root.iconSize
            color: root.state === "error" ? root.errorColor : root.state === "off" ? Theme.inactiveWorkspace : Theme.accent

            // Breathe while listening / thinking.
            SequentialAnimation on opacity {
                running: root.state === "listening" || root.state === "processing"
                loops: Animation.Infinite
                onRunningChanged: if (!running) icon.opacity = 1
                NumberAnimation { to: 0.35; duration: root.state === "listening" ? 450 : 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: root.state === "listening" ? 450 : 800; easing.type: Easing.InOutSine }
            }
        }
    }

    // ---- time left while speaking / time spent thinking ----
    Text {
        anchors.left: iconBox.right
        anchors.right: parent.right
        anchors.rightMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        opacity: root.wide ? 1 : 0
        text: root.speaking ? root.formatRemaining(root.remaining) : root.formatElapsed(root.elapsed)
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        font.weight: Font.Bold

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.running && root.pid > 0)
                Quickshell.execDetached(["kill", "-TERM", String(root.pid)]);
            else if (!root.running)
                Quickshell.execDetached(["sh", "-c", `exec ${root.startCommand} >>${root.logFile} 2>&1`]);
        }
    }
}
