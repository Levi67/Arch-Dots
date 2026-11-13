// A Nerd Font icon by name (see ShellState.icons)
import QtQuick
import "../../theme"

Text {
    property string name
    property int size: 18
    text: ShellState.icon(name)
    color: Theme.text
    font.family: ShellState.iconFont
    font.pixelSize: size
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
