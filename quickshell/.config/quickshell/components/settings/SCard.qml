// A titled group of settings rows.
import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root
    property string title: ""
    property string icon: ""
    default property alias content: col.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 28
    radius: 14
    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
    border.width: 1
    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            visible: root.title !== ""
            spacing: 8
            SIcon {
                visible: root.icon !== ""
                name: root.icon
                size: 16
                color: Theme.accent
            }
            SLabel {
                text: root.title
                font.weight: Font.Bold
                size: Theme.fontSize + 1
            }
        }
    }
}
