// components/Timers.qml
// Timers and stopwatches started by the voice assistant (~/bin/voice-tools.py), one bubble each.
//   timer      shrinking ring + time left; rings and announces itself when done
//   stopwatch  stopwatch icon + time elapsed
// Click a bubble to stop/dismiss it. A finished timer dismisses itself after a minute.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root

    // ---- settings ----
    property string timerFile: "/tmp/voice-assistant/timers.json"
    property string sayCommand: "/home/claude-agent/bin/voice-say"
    property string alarmSound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    property bool announce: true // only one bar should ring on multi-monitor setups
    property string iconFont: "JetBrainsMono Nerd Font"
    property int ringSize: 18
    property real autoDismissSecs: 60
    property color doneColor: "#E06C75"

    // ---- state ----
    property var timers: []
    property real now: Date.now() / 1000
    property var rung: ({}) // ids we've already announced

    spacing: Theme.bubbleSpacing

    Process {
        running: true
        command: ["sh", "-c", `
            f="${root.timerFile}"; prev="-"
            while :; do
                cur=$(tr -d '\\n' < "$f" 2>/dev/null)
                [ -z "$cur" ] && cur="[]"
                [ "$cur" != "$prev" ] && echo "$cur" && prev=$cur
                sleep 0.5
            done`]

        stdout: SplitParser {
            onRead: data => {
                try {
                    const list = JSON.parse(data);
                    root.timers = Array.isArray(list) ? list : [];
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: root.timers.length > 0
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now() / 1000;
            for (const t of root.timers) {
                if (t.kind !== "timer")
                    continue;
                const over = root.now - (t.start + t.duration);
                if (over >= 0 && !root.rung[t.id]) {
                    root.rung[t.id] = true;
                    if (root.announce)
                        Quickshell.execDetached([root.sayCommand, "--sound", root.alarmSound, "Your timer is done."]);
                }
                if (over > root.autoDismissSecs && root.announce)
                    root.remove(t.id);
            }
        }
    }

    // Rewrite the file without this id (atomic replace, same as voice-tools.py does).
    function remove(id) {
        const rest = root.timers.filter(t => t.id !== id);
        root.timers = rest;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" > "$2.$$.tmp" && mv -f "$2.$$.tmp" "$2"',
            "sh", JSON.stringify(rest), root.timerFile]);
    }

    function fmt(secs) {
        const s = Math.max(0, Math.ceil(secs));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
        return (h > 0 ? h + ":" : "") + mm + ":" + String(r).padStart(2, "0");
    }

    Repeater {
        model: root.timers

        Bubble {
            id: bubble
            required property var modelData
            readonly property bool isTimer: modelData.kind === "timer"
            readonly property real secsLeft: modelData.start + modelData.duration - root.now
            readonly property bool done: isTimer && secsLeft <= 0
            readonly property real fraction: isTimer && modelData.duration > 0 ? Math.max(0, Math.min(1, secsLeft / modelData.duration)) : 1

            Item {
                width: root.ringSize
                height: Theme.bubbleHeight

                // background track
                Shape {
                    anchors.centerIn: parent
                    width: root.ringSize
                    height: root.ringSize
                    visible: bubble.isTimer
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Qt.alpha(Theme.accent, 0.2)
                        strokeWidth: 2.5
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: root.ringSize / 2
                            centerY: root.ringSize / 2
                            radiusX: root.ringSize / 2 - 1.5
                            radiusY: root.ringSize / 2 - 1.5
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }
                }
                // remaining time: shrinks clockwise from 12 o'clock
                Shape {
                    anchors.centerIn: parent
                    width: root.ringSize
                    height: root.ringSize
                    visible: bubble.isTimer && !bubble.done
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.accent
                        strokeWidth: 2.5
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: root.ringSize / 2
                            centerY: root.ringSize / 2
                            radiusX: root.ringSize / 2 - 1.5
                            radiusY: root.ringSize / 2 - 1.5
                            startAngle: -90
                            sweepAngle: 360 * bubble.fraction
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: !bubble.isTimer || bubble.done
                    text: String.fromCodePoint(bubble.done ? 0xf0020 : 0xf051b) // alarm / stopwatch
                    font.family: root.iconFont
                    font.pixelSize: 15
                    color: bubble.done ? root.doneColor : Theme.accent

                    SequentialAnimation on opacity {
                        running: bubble.done
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) parent.opacity = 1
                        NumberAnimation { to: 0.3; duration: 400 }
                        NumberAnimation { to: 1; duration: 400 }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: bubble.isTimer ? (bubble.done ? "done" : root.fmt(bubble.secsLeft)) : root.fmt(root.now - bubble.modelData.start)
                color: bubble.done ? root.doneColor : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
                font.features: { "tnum": 1 } // digits don't jiggle while counting
            }

            // Parented to the bubble itself, not its content row, so it doesn't take part in the layout.
            MouseArea {
                parent: bubble
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (bubble.done && root.announce)
                        Quickshell.execDetached([root.sayCommand, "--stop"]);
                    root.remove(bubble.modelData.id);
                }
            }
        }
    }
}
