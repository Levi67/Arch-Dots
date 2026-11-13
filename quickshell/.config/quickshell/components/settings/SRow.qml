// A settings line: label (+ optional hint) on the left; whatever you put inside
// goes to the right of it (set Layout.preferredWidth on it for a fixed width).
import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    id: root
    property string label
    property string hint: ""

    Layout.fillWidth: true
    spacing: 16
    opacity: enabled ? 1 : 0.45

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 1      // take the leftover space, not the text's width
        Layout.alignment: Qt.AlignVCenter
        spacing: 1
        SLabel {
            Layout.fillWidth: true
            text: root.label
        }
        SLabel {
            Layout.fillWidth: true
            visible: root.hint !== ""
            text: root.hint
            dim: true
            size: Theme.fontSize - 2
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }
}
