// components/QuickPanel.qml
// Quick settings dropdown under the status bubble: volume + output, Wi-Fi, Bluetooth,
// night light, case RGB (+ brightness while on), power profile. The gear opens the full settings (SUPER+I).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import "../theme"
import "settings" as S
import "winter" as WinterUI

PanelWindow {
    id: panel
    required property var barWindow

    screen: barWindow.screen
    visible: ShellState.quickOpen && ShellState.quickScreen === barWindow.screen
    color: "transparent"
    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: Theme.sideMargin
    }
    implicitWidth: 400
    implicitHeight: card.implicitHeight

    WlrLayershell.namespace: "quickshell-quick"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // click anywhere else closes it (the bar counts as inside, so the bubble can toggle it)
    // (armed a moment after showing: a grab on a not-yet-mapped surface is cleared at once)
    property bool grabArmed: false
    Timer {
        id: armGrab
        interval: 80
        onTriggered: panel.grabArmed = panel.visible
    }
    HyprlandFocusGrab {
        active: panel.grabArmed
        windows: [panel, panel.barWindow]
        onCleared: ShellState.quickOpen = false
    }

    onVisibleChanged: {
        grabArmed = false;
        if (visible)
            armGrab.restart();
        else
            outputs.expanded = false;
    }

    // ---- state ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    PwObjectTracker {
        objects: [panel.sink]
    }

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: adapter ? (adapter.devices.values.find(d => d.connected) ?? null) : null

    function nodeName(n) {
        return n ? (n.description || n.nickname || n.name) : "No output";
    }

    // ---- pieces ----
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active
        property bool available: true
        property string page
        signal toggled

        Layout.fillWidth: true
        implicitHeight: 76
        radius: 14
        opacity: available ? 1 : 0.45
        color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, area.containsMouse ? 0.1 : 0.06)
        border.width: 1
        border.color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            // left: toggle, right: open its settings page
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    ShellState.openSettings(tile.page, panel.screen);
                else if (tile.available)
                    tile.toggled();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2
            S.SIcon {
                name: tile.icon
                size: 20
                color: tile.active ? Theme.accent : Theme.text
                Layout.alignment: Qt.AlignLeft
            }
            S.SLabel {
                Layout.fillWidth: true
                text: tile.title
                font.weight: Font.Bold
                size: Theme.fontSize - 1
            }
            S.SLabel {
                Layout.fillWidth: true
                text: tile.subtitle
                dim: true
                size: Theme.fontSize - 3
            }
        }
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 32
        radius: 20
        color: Theme.barBackground
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
        clip: true

        Keys.onEscapePressed: ShellState.quickOpen = false
        focus: true

        // same snow globe as the bar bubbles while winter mode is on
        Loader {
            anchors.fill: parent
            active: Winter.barFlakes
            sourceComponent: WinterUI.BubbleFlakes {
                radius: card.radius
            }
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // header
            RowLayout {
                Layout.fillWidth: true
                S.SLabel {
                    Layout.fillWidth: true
                    text: "Quick settings"
                    font.weight: Font.Bold
                    size: Theme.fontSize + 2
                }
                S.SButton {
                    icon: "cog"
                    flat: true
                    implicitWidth: 34
                    onClicked: ShellState.openSettings("", panel.screen)
                }
            }

            // volume
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                S.SIcon {
                    name: !panel.sink || panel.sink.audio?.muted ? "volOff" : "volHigh"
                    size: 20
                    color: panel.sink?.audio?.muted ? Theme.inactiveWorkspace : Theme.text
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (panel.sink?.audio)
                            panel.sink.audio.muted = !panel.sink.audio.muted
                    }
                }
                S.SSlider {
                    Layout.fillWidth: true
                    enabled: panel.sink?.audio !== undefined
                    from: 0
                    to: 1
                    value: panel.sink?.audio?.volume ?? 0
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => {
                        panel.sink.audio.muted = false;
                        panel.sink.audio.volume = v;
                    }
                }
            }

            // output device (expands into a list)
            ColumnLayout {
                id: outputs
                property bool expanded: false
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 10
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, outArea.containsMouse ? 0.1 : 0.05)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        S.SIcon {
                            name: "speaker"
                            size: 16
                        }
                        S.SLabel {
                            Layout.fillWidth: true
                            text: panel.nodeName(panel.sink)
                        }
                        S.SIcon {
                            name: "chevron"
                            size: 16
                            rotation: outputs.expanded ? 270 : 90
                        }
                    }
                    MouseArea {
                        id: outArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: outputs.expanded = !outputs.expanded
                    }
                }

                Repeater {
                    model: outputs.expanded ? panel.sinks : []
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool current: modelData === panel.sink
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 8
                        color: rowArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 34
                            anchors.rightMargin: 10
                            S.SLabel {
                                Layout.fillWidth: true
                                text: panel.nodeName(modelData)
                                dim: !current
                            }
                            S.SIcon {
                                visible: current
                                name: "check"
                                size: 15
                                color: Theme.accent
                            }
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Pipewire.preferredDefaultAudioSink = modelData;
                                outputs.expanded = false;
                            }
                        }
                    }
                }
            }

            // toggles (right click = open the page)
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Tile {
                    icon: Networking.wifiEnabled ? "wifi" : "wifiOff"
                    title: "Wi-Fi"
                    subtitle: !Networking.wifiEnabled ? "Off" : panel.wifiNet ? panel.wifiNet.name : (panel.wired ? "Ethernet" : "Not connected")
                    active: Networking.wifiEnabled
                    available: panel.wifi !== null
                    page: "network"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                Tile {
                    icon: panel.btDevice ? "btConn" : (panel.adapter?.enabled ? "bt" : "btOff")
                    title: "Bluetooth"
                    subtitle: !panel.adapter ? "Unavailable" : !panel.adapter.enabled ? "Off" : panel.btDevice ? panel.btDevice.name : "On"
                    active: panel.adapter?.enabled ?? false
                    available: panel.adapter !== null
                    page: "network"
                    onToggled: panel.adapter.enabled = !panel.adapter.enabled
                }
                Tile {
                    icon: "night"
                    title: "Night light"
                    subtitle: !NightLight.available ? "Not installed" : NightLight.active ? NightLight.temperature + "K" : (NightLight.schedule === "manual" ? "Off" : NightLight.schedule === "sun" ? "At sunset" : "From " + NightLight.from)
                    active: NightLight.active
                    available: NightLight.available
                    page: "power"
                    onToggled: NightLight.toggle()
                }
                Tile {
                    icon: "rgb"
                    title: "RGB"
                    subtitle: !Rgb.available ? "Unavailable" : Rgb.on ? Rgb.brightness + "%" : "Off"
                    active: Rgb.on
                    available: Rgb.available
                    page: "rgb"
                    onToggled: Rgb.toggle()
                }
            }

            // RGB brightness (only while it's on)
            RowLayout {
                Layout.fillWidth: true
                visible: Rgb.on
                spacing: 10
                S.SIcon {
                    name: "rgb"
                    size: 20
                }
                S.SSlider {
                    Layout.fillWidth: true
                    from: 5
                    to: 100
                    stepSize: 5
                    value: Rgb.brightness
                    format: v => Math.round(v) + "%"
                    onCommitted: v => Config.rgb.set("brightness", v)
                }
            }

            // power profile
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        {
                            p: PowerProfile.PowerSaver,
                            icon: "leaf",
                            label: "Saver"
                        },
                        {
                            p: PowerProfile.Balanced,
                            icon: "speedo",
                            label: "Balanced"
                        },
                        {
                            p: PowerProfile.Performance,
                            icon: "rocket",
                            label: "Performance"
                        }
                    ]
                    delegate: S.SButton {
                        required property var modelData
                        Layout.fillWidth: true
                        visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                        icon: modelData.icon
                        text: modelData.label
                        primary: PowerProfiles.profile === modelData.p
                        onClicked: PowerProfiles.profile = modelData.p
                    }
                }
            }
        }
    }
}
