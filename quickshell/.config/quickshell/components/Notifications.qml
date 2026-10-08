import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
    id: root

    property bool dnd: false

    readonly property string notifyMonitor: "DP-2"

    // Theme has no urgent colors, so these are hardcoded
    readonly property color cUrgent: "#fab387"    // critical card border
    readonly property color cCritical: "#f38ba8"  // critical headline

    function pickScreen() {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === notifyMonitor)
                return Quickshell.screens[i]
        }
        return Quickshell.screens[0]  // fallback if that monitor is unplugged
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: n => {
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) {
                n.expire()
                return
            }
            n.tracked = true
        }
    }

    PanelWindow {
        screen: root.pickScreen()
        visible: server.trackedNotifications.values.length > 0
        color: "transparent"
        implicitWidth: 360
        implicitHeight: col.implicitHeight + Theme.gapSize

        anchors { top: true; right: true }
        margins {
            top: Theme.verticalMargin
            right: Theme.sideMargin
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notifications"

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: Theme.bubbleSpacing

            Repeater {
                model: server.trackedNotifications

                delegate: Rectangle {
                    id: card
                    required property Notification modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                    Layout.fillWidth: true
                    implicitHeight: content.implicitHeight + Theme.padding * 2
                    radius: Math.min(height / 2, 20)
                    color: Theme.barBackground
                    border.width: critical ? 1 : 0
                    border.color: root.cUrgent

                    // Auto-expire: 5 s cap (10 s for critical), respects shorter app timeouts
                    Timer {
                        running: true
                        interval: {
                            const t = card.modelData.expireTimeout
                            const cap = card.critical ? 10000 : 5000
                            const ms = t <= 0 ? cap : (t > 100 ? t : t * 1000)
                            return Math.min(ms, cap)
                        }
                        onTriggered: card.modelData.expire()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.modelData.dismiss()
                    }

                    ColumnLayout {
                        id: content
                        anchors {
                            fill: parent
                            leftMargin: Theme.padding * 2
                            rightMargin: Theme.padding * 2
                            topMargin: Theme.padding
                            bottomMargin: Theme.padding
                        }
                        spacing: 2

                        // App name
                        Text {
                            text: card.modelData.appName
                            color: Theme.inactiveWorkspace
                            font.pixelSize: Theme.fontSize - 2
                            font.bold: true
                        }

                        // Headline (red when critical)
                        Text {
                            visible: text !== ""
                            text: card.modelData.summary
                            color: card.critical ? root.cCritical : Theme.text
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        // Body
                        Text {
                            visible: text !== ""
                            text: card.modelData.body
                            color: Theme.text
                            opacity: 0.8
                            font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        // Action buttons
                        RowLayout {
                            visible: card.modelData.actions.length > 0
                            spacing: 6

                            Repeater {
                                model: card.modelData.actions

                                delegate: Rectangle {
                                    required property var modelData
                                    radius: height / 2
                                    color: Theme.inactiveWorkspace
                                    implicitWidth: lbl.implicitWidth + 16
                                    implicitHeight: lbl.implicitHeight + 6

                                    Text {
                                        id: lbl
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: Theme.background
                                        font.pixelSize: Theme.fontSize - 2
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: parent.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Toggle Do Not Disturb: qs ipc call notifications toggleDnd
    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.dnd = !root.dnd }
    }
}