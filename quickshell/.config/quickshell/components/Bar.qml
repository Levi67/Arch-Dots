import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
    id: root
    property string time

    Variants {
        // settings window -> Theme -> Bar: which monitors get a bar (empty list = all)
        model: {
            const only = Config.bar.get("monitors", []);
            return only.length ? Quickshell.screens.filter(s => only.includes(s.name)) : Quickshell.screens;
        }

        Scope {
            id: perScreen
            required property var modelData

            PanelWindow {
                id: barWindow
                property var modelData: perScreen.modelData
                screen: modelData

                // Correct Quickshell Wayland properties
                WlrLayershell.namespace: "quickshell"
                //Wl.exclusiveZone: height

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: layout.implicitHeight
                color: Theme.debugColor

                // Replace RowLayout { id: layout ... } with this:
                // Replace your RowLayout section with this:
                Item {
                    id: layout
                    anchors.fill: parent

                    // 1. Restore the height: Use the height of your tallest bubble + your vertical margins
                    // If Theme.bubbleHeight isn't defined, you can use a fixed number like 40
                    implicitHeight: (Theme.bubbleHeight || 40) + (Theme.verticalMargin * 2)

                    // SECTION 1: Left Side (Workspaces)
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.sideMargin
                        anchors.verticalCenter: parent.verticalCenter // Vertically centers the bubble in the bar
                        spacing: Theme.bubbleSpacing

                        Bubble {
                            visible: Config.bar.get("modules.workspaces", true)
                            Workspaces {}
                        }
                        Bubble {
                            visible: Config.bar.get("modules.stats", true)
                            SystemStats {}
                        }
                    }

                    // SECTION 2: Center (Clock) - DEAD CENTER
                    Row {
                        id: centerRow
                        anchors.centerIn: parent
                        Bubble {
                            visible: Config.bar.get("modules.clock", true)
                            Clock {
                                textColor: Theme.text
                                textSize: Theme.textSize
                            }
                        }
                    }

                    // Voice-assistant timers/stopwatches, right-aligned against the clock
                    Timers {
                        visible: Config.bar.get("modules.timers", true)
                        anchors.right: centerRow.left
                        anchors.rightMargin: Theme.bubbleSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        announce: barWindow.modelData === Quickshell.screens[0]
                    }

                    // Weather bubble right next to the clock
                    Row {
                        anchors.left: centerRow.right
                        anchors.leftMargin: Theme.bubbleSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        Bubble {
                            visible: Config.bar.get("modules.weather", true)
                            Weather {}
                        }
                    }

                    // SECTION 3: Right Side
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.sideMargin
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.bubbleSpacing

                        // Voice assistant yes/no prompt; only visible while Claude waits for approval
                        Bubble {
                            visible: approval.pending
                            ApprovalPrompt {
                                id: approval
                                announce: barWindow.modelData === Quickshell.screens[0]
                            }
                        }
                        // Voice assistant status: no padding so the pill is a circle (1:1)
                        Bubble {
                            visible: Config.bar.get("modules.voice", true)
                            horizontalPadding: 0
                            VoiceStatus {}
                        }
                        Bubble {
                            visible: Config.bar.get("modules.media", true)
                            MediaPlayer {}
                        }
                        // volume / network / bluetooth / night light; click = quick panel
                        Bubble {
                            visible: Config.bar.get("modules.status", true)
                            QuickStatus {
                                screen: barWindow.screen
                            }
                        }
                    }
                }
            }

            // quick settings dropdown for this screen
            QuickPanel {
                barWindow: barWindow
            }
        }
    }
}
