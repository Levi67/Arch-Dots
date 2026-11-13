// Text input; emits committed(text) on Enter / focus loss when the text changed.
import QtQuick
import QtQuick.Controls
import "../../theme"

TextField {
    id: root
    property string value: ""
    signal committed(string text)

    text: value
    implicitWidth: 220
    implicitHeight: 30
    leftPadding: 10
    rightPadding: 10
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    placeholderTextColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
    selectByMouse: true
    verticalAlignment: TextInput.AlignVCenter

    onEditingFinished: if (text !== value)
        committed(text)
    onValueChanged: if (!activeFocus)
        text = value

    background: Rectangle {
        radius: 10
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
    }
}
