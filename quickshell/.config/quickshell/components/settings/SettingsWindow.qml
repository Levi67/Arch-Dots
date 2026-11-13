// The full settings overlay (SUPER+I, or the gear in the quick panel).
//   qs ipc call settings toggle | open <page> | close | quick  (quick = the bar's quick panel)
//   qs ipc call settings get <area> <path>          e.g. get bar clock.hour24
//   qs ipc call settings set <area> <path> <json>   e.g. set bar clock.seconds true
// Pages: winter, theme, audio, network, displays, power. Every change is saved instantly
// (Config.* -> ~/.config/desktop/*.json); only Displays asks before keeping a change.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../winter" as WinterUI

Scope {
    id: root

    readonly property var pages: [
        {
            id: "winter",
            label: "Winter",
            icon: "snow",
            file: "WinterPage.qml"
        },
        {
            id: "theme",
            label: "Theme",
            icon: "palette",
            file: "ThemePage.qml"
        },
        {
            id: "audio",
            label: "Audio",
            icon: "volHigh",
            file: "AudioPage.qml"
        },
        {
            id: "network",
            label: "Network",
            icon: "wifi",
            file: "NetworkPage.qml"
        },
        {
            id: "displays",
            label: "Displays",
            icon: "monitor",
            file: "DisplaysPage.qml"
        },
        {
            id: "power",
            label: "Power",
            icon: "power",
            file: "PowerPage.qml"
        }
    ]

    function focusedScreen() {
        const mon = Hyprland.focusedMonitor;
        return Quickshell.screens.find(s => mon && s.name === mon.name) ?? Quickshell.screens[0];
    }

    function open(page) {
        ShellState.openSettings(page, ShellState.settingsScreen && ShellState.settingsOpen ? ShellState.settingsScreen : focusedScreen());
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            if (ShellState.settingsOpen)
                ShellState.settingsOpen = false;
            else
                root.open("");
        }
        function open(page: string): void {
            root.open(page);
        }
        function close(): void {
            ShellState.settingsOpen = false;
        }
        function get(area: string, path: string): string {
            return Config[area] ? JSON.stringify(Config[area].get(path, null)) : "unknown area";
        }
        function set(area: string, path: string, value: string): string {
            if (!Config[area])
                return "unknown area (winter, theme, bar, power, displays)";
            try {
                Config[area].set(path, JSON.parse(value));
                return "ok";
            } catch (e) {
                return "value must be JSON: " + e;
            }
        }
        function quick(): void {
            ShellState.toggleQuick(root.focusedScreen());
        }
    }

    PanelWindow {
        id: win
        visible: ShellState.settingsOpen
        screen: ShellState.settingsScreen ?? root.focusedScreen()
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // light dim (so snow & co. stay visible while you tune them); click outside closes
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.2)
            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.settingsOpen = false
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(1080, parent.width - 80)
            height: Math.min(760, parent.height - 120)
            radius: 22
            // the bar's glass, but denser: pages are long text and sit over busy windows
            color: Qt.rgba(Theme.barBackground.r, Theme.barBackground.g, Theme.barBackground.b, Math.max(Theme.barBackground.a, 0.82))
            border.width: 1
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
            clip: true
            focus: true
            Keys.onEscapePressed: ShellState.settingsOpen = false

            // eat clicks so they don't reach the backdrop
            MouseArea {
                anchors.fill: parent
                onClicked: card.forceActiveFocus()
            }

            opacity: 0
            scale: 0.97
            states: State {
                when: win.visible
                PropertyChanges {
                    card.opacity: 1
                    card.scale: 1
                }
            }
            transitions: Transition {
                NumberAnimation {
                    properties: "opacity,scale"
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                anchors.fill: parent
                active: Winter.barFlakes && win.visible
                sourceComponent: WinterUI.BubbleFlakes {
                    radius: card.radius
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ---- sidebar ----
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 210
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        RowLayout {
                            Layout.bottomMargin: 14
                            Layout.leftMargin: 6
                            Layout.topMargin: 6
                            spacing: 8
                            SIcon {
                                name: "cog"
                                size: 20
                                color: Theme.accent
                            }
                            SLabel {
                                text: "Settings"
                                size: Theme.fontSize + 4
                                font.weight: Font.Bold
                            }
                        }

                        Repeater {
                            model: root.pages
                            delegate: Rectangle {
                                id: navItem
                                required property var modelData
                                readonly property bool current: ShellState.settingsPage === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 38
                                radius: 11
                                color: current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, navArea.containsMouse ? 0.07 : 0)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    spacing: 10
                                    SIcon {
                                        name: navItem.modelData.icon
                                        size: 17
                                        color: navItem.current ? Theme.accent : Theme.text
                                    }
                                    SLabel {
                                        Layout.fillWidth: true
                                        text: navItem.modelData.label
                                        font.weight: navItem.current ? Font.Bold : Font.Normal
                                    }
                                }
                                MouseArea {
                                    id: navArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellState.settingsPage = navItem.modelData.id
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        SLabel {
                            Layout.fillWidth: true
                            Layout.leftMargin: 6
                            text: "Saved automatically"
                            dim: true
                            size: Theme.fontSize - 2
                        }
                    }
                }

                // ---- page ----
                Loader {
                    id: pageLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: win.visible
                    readonly property var page: root.pages.find(p => p.id === ShellState.settingsPage) ?? root.pages[0]
                    source: "pages/" + page.file
                }
            }
        }
    }
}
