import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property bool primary: false
    property bool flat: false
    signal clicked

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 30
    radius: 10
    opacity: enabled ? 1 : 0.4
    color: primary ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, flat ? (area.containsMouse ? 0.08 : 0) : (area.containsMouse ? 0.16 : 0.09))
    border.width: flat || primary ? 0 : 1
    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        SIcon {
            visible: root.icon !== ""
            name: root.icon
            size: 15
            color: root.primary ? Theme.background : Theme.text
        }
        SLabel {
            visible: root.text !== ""
            text: root.text
            color: root.primary ? Theme.background : Theme.text
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
