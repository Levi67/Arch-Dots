// components/ApprovalPrompt.qml
// Yes/no prompt for the voice assistant (written by ~/bin/approval-mcp.py). When Claude wants to
// edit or delete one of your files, this appears next to the voice bubble, plays a sound and
// reads the request aloud. Hidden (zero width) when nothing is pending.
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ---- settings ----
    property string approvalDir: "/tmp/voice-assistant-approvals"
    property string sayCommand: "/home/claude-agent/bin/voice-say"
    property string sound: "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
    property bool announce: true // only one bar should talk on multi-monitor setups
    property string iconFont: "JetBrainsMono Nerd Font"
    property color yesColor: "#98C379"
    property color noColor: "#E06C75"

    // ---- current request ----
    property string reqId: ""
    property string title: ""
    property string speech: ""
    property string answered: ""
    readonly property bool pending: reqId !== "" && answered !== reqId

    visible: pending
    implicitHeight: Theme.bubbleHeight
    implicitWidth: pending ? row.implicitWidth : 0

    // Oldest pending request, re-printed only when it changes ("{}" = none).
    Process {
        running: true
        command: ["sh", "-c", `
            d="${root.approvalDir}"; prev="-"
            while :; do
                f=$(ls -1 "$d"/*.req 2>/dev/null | head -n1)
                if [ "$f" != "$prev" ]; then
                    if [ -n "$f" ]; then tr -d '\\n' < "$f"; echo; else echo "{}"; fi
                    prev=$f
                fi
                sleep 0.3
            done`]

        stdout: SplitParser {
            onRead: data => {
                let r = {};
                try {
                    r = JSON.parse(data);
                } catch (e) {}
                const wasPending = root.pending;
                root.title = r.title ?? "";
                root.speech = r.speech ?? "";
                root.reqId = r.id ?? "";
                if (root.pending && root.announce)
                    Quickshell.execDetached([root.sayCommand, "--sound", root.sound, root.speech]);
                else if (wasPending && !root.pending)
                    root.stopSpeaking(); // request timed out or was answered elsewhere
            }
        }
    }

    function stopSpeaking() {
        if (root.announce)
            Quickshell.execDetached([root.sayCommand, "--stop"]);
    }

    function answer(reply) {
        root.stopSpeaking(); // cut the announcement off the moment you click
        const file = root.approvalDir + "/" + root.reqId + ".answer";
        root.answered = root.reqId;
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2.tmp" && mv -f "$2.tmp" "$2"', "sh", reply, file]);
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.Bold
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 220)
        }

        Repeater {
            model: [
                { reply: "yes", glyph: 0xf012c, color: root.yesColor },
                { reply: "no", glyph: 0xf0156, color: root.noColor }
            ]

            Rectangle {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.bubbleHeight - 8
                height: width
                radius: width / 2
                color: mouse.containsMouse ? modelData.color : Qt.alpha(modelData.color, 0.25)

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(parent.modelData.glyph)
                    font.family: root.iconFont
                    font.pixelSize: 14
                    color: mouse.containsMouse ? Theme.background : parent.modelData.color
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.answer(parent.modelData.reply)
                }
            }
        }
    }
}
