import QtQuick
import "../../theme"

Text {
    property bool dim: false
    property int size: Theme.fontSize
    color: dim ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6) : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: size
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
