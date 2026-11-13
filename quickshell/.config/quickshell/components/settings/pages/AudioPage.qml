// Audio: output/input devices (pick the default, volume, mute) and per-app volume.
// Straight from PipeWire; PipeWire/WirePlumber remember all of this themselves.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Audio"
    subtitle: "Click a device to make it the default."

    // by node type (media.class & co. in `properties` only arrive once a node is tracked)
    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: nodes.filter(n => n.type === PwNodeType.AudioSource || n.type === PwNodeType.AudioDuplex)
    readonly property var playing: nodes.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var recording: nodes.filter(n => n.type === PwNodeType.AudioInStream)

    // nodes only report volume/mute while tracked
    PwObjectTracker {
        objects: page.sinks.concat(page.sources, page.playing, page.recording)
    }

    function label(n) {
        return n.description || n.nickname || n.name;
    }
    function appName(n) {
        const p = n.properties;
        return p["application.name"] || p["media.name"] || n.name;
    }

    // one device / stream line: [icon] name [default ✓]  then  [mute] ──slider──
    component NodeRow: ColumnLayout {
        id: row
        required property var node
        property bool selectable: false
        property bool isDefault: false
        property string iconName: "speaker"
        property string appIcon: ""
        property string title: page.label(node)
        signal select

        Layout.fillWidth: true
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 10
            color: row.isDefault ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, hover.containsMouse && row.selectable ? 0.08 : 0)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                IconImage {
                    visible: row.appIcon !== ""
                    implicitSize: 18
                    source: row.appIcon !== "" ? Quickshell.iconPath(row.appIcon, true) : ""
                }
                SIcon {
                    visible: row.appIcon === ""
                    name: row.iconName
                    size: 16
                    color: row.isDefault ? Theme.accent : Theme.text
                }
                SLabel {
                    Layout.fillWidth: true
                    text: row.title
                    font.weight: row.isDefault ? Font.Bold : Font.Normal
                }
                SLabel {
                    visible: row.isDefault
                    text: "Default"
                    dim: true
                    size: Theme.fontSize - 2
                }
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                enabled: row.selectable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.select()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            spacing: 10
            SIcon {
                name: row.node.audio?.muted ? "volOff" : "volHigh"
                size: 17
                color: row.node.audio?.muted ? Theme.inactiveWorkspace : Theme.text
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (row.node.audio)
                        row.node.audio.muted = !row.node.audio.muted
                }
            }
            SSlider {
                Layout.fillWidth: true
                enabled: row.node.audio !== null && row.node.audio !== undefined
                from: 0
                to: 1
                value: row.node.audio?.volume ?? 0
                format: v => Math.round(v * 100) + "%"
                onMoved: v => {
                    row.node.audio.muted = false;
                    row.node.audio.volume = v;
                }
            }
        }
    }

    SCard {
        title: "Output"
        icon: "headphones"
        Repeater {
            model: page.sinks
            delegate: NodeRow {
                required property var modelData
                node: modelData
                selectable: true
                isDefault: modelData === Pipewire.defaultAudioSink
                iconName: "speaker"
                onSelect: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
        SLabel {
            visible: page.sinks.length === 0
            text: "No output devices"
            dim: true
        }
    }

    SCard {
        title: "Input"
        icon: "mic"
        Repeater {
            model: page.sources
            delegate: NodeRow {
                required property var modelData
                node: modelData
                selectable: true
                isDefault: modelData === Pipewire.defaultAudioSource
                iconName: "mic"
                onSelect: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
        SLabel {
            visible: page.sources.length === 0
            text: "No input devices"
            dim: true
        }
    }

    SCard {
        title: "Applications"
        icon: "app"
        Repeater {
            model: page.playing
            delegate: NodeRow {
                required property var modelData
                node: modelData
                title: page.appName(modelData)
                appIcon: modelData.properties["application.icon-name"] ?? ""
                iconName: "app"
            }
        }
        SLabel {
            visible: page.playing.length === 0
            text: "Nothing is playing"
            dim: true
        }
    }

    SCard {
        visible: page.recording.length > 0
        title: "Recording"
        icon: "mic"
        Repeater {
            model: page.recording
            delegate: NodeRow {
                required property var modelData
                node: modelData
                title: page.appName(modelData)
                appIcon: modelData.properties["application.icon-name"] ?? ""
                iconName: "mic"
            }
        }
    }
}
