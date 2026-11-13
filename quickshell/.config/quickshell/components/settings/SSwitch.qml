// Controlled toggle: shows `checked`, emits toggled(newValue) - the owner writes the setting.
import QtQuick
import "../../theme"

Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 42
    implicitHeight: 24
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, root.checked ? 0 : 0.15)
        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        Rectangle {
            width: parent.height - 6
            height: width
            radius: width / 2
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.background : Theme.text
            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
