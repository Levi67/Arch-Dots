import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import "./theme"

ShellRoot {
    // --- THE IPC HANDLER ---
    IpcHandler {
        target: "launcher" // Required unique name for 'qs ipc call'
        
        // Explicitly defined return type (: void) is required for registration
        function toggle(): void {
            launcherWindow.visible = !launcherWindow.visible;
        }
    }

    PanelWindow {
        id: launcherWindow
        implicitWidth: 600
        implicitHeight: 700
        color: "transparent" 
        visible: false 

        WlrLayershell.namespace: "launcher"
        WlrLayershell.layer: WlrLayer.Overlay 
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible) {
                openAnim.restart();
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

        Rectangle {
            id: rootRect
            anchors.fill: parent
            color: Theme.barBackground 
            radius: 20
            border.color: Qt.darker(Theme.accent, 1.6) 
            border.width: 1
            clip: true
            opacity: 0
            y: 20

            ParallelAnimation {
                id: openAnim
                NumberAnimation { target: rootRect; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutCubic }
                NumberAnimation { target: rootRect; property: "y"; from: 20; to: 0; duration: 150; easing.type: Easing.OutQuint }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding * 2.5 
                spacing: Theme.gapSize * 2

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    focus: true
                    leftPadding: Theme.padding * 2  
                    rightPadding: Theme.padding * 2 
                    topPadding: Theme.padding
                    bottomPadding: Theme.padding
                    placeholderText: "Search apps..."
                    placeholderTextColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    color: Theme.text
                    font.pixelSize: Theme.textSize
                    verticalAlignment: TextInput.AlignVCenter 

                    background: Rectangle {
                        implicitHeight: Theme.bubbleHeight + 16 
                        color: Theme.barBackground
                        radius: 12
                        border.color: parent.activeFocus ? Qt.darker(Theme.accent, 1.5) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        border.width: 1
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            let results = DesktopEntries.applications.values.filter(app => 
                                app.name.toLowerCase().includes(searchInput.text.toLowerCase())
                            );
                            if (results.length > 0) {
                                results[0].execute();
                                launcherWindow.visible = false; 
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            launcherWindow.visible = false; 
                        }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Theme.gapSize
                    model: DesktopEntries.applications.values.filter(app => 
                        app.name.toLowerCase().includes(searchInput.text.toLowerCase())
                    )

                    delegate: ItemDelegate {
                        id: delegateItem
                        width: list.width
                        height: Theme.bubbleHeight + Theme.padding 
                        background: Rectangle {
                            color: hovered ? Theme.inactiveWorkspace : "transparent"
                            radius: 8
                            border.width: hovered ? 1 : 0
                            border.color: Qt.darker(Theme.accent, 1.6)
                        }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.bubbleSpacing
                            IconImage {
                                source: Quickshell.iconPath(modelData.icon, true)
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                //sourceSize.width: 32
                                //sourceSize.height: 32
                                Layout.alignment: Qt.AlignVCenter 
                            }
                            Text {
                                text: modelData.name
                                color: Theme.text
                                font.pixelSize: Theme.fontSize
                                Layout.alignment: Qt.AlignVCenter 
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                        onClicked: {
                            modelData.execute();
                            launcherWindow.visible = false; 
                        }
                    }

                    Behavior on contentY {
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuint }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        acceptedButtons: Qt.NoButton 
                        onWheel: (wheel) => {
                            let scrollStep = (Theme.bubbleHeight + Theme.padding + list.spacing) * 4;
                            if (wheel.angleDelta.y > 0) {
                                list.contentY = Math.max(list.originY, list.contentY - scrollStep);
                            } else {
                                list.contentY = Math.min(list.contentHeight - list.height, list.contentY + scrollStep);
                            }
                        }
                    }
                }
            }
        }
    }
}