import Quickshell
import QtQuick
import "components"
import "theme"

ShellRoot {
    // winter mode recolors these popups too (icy glass, snow caps on Launcher / wallpaper picker)
    // (a Binding, not onCompleted: it also holds across Quickshell's hot reloads)
    Binding {
        target: Winter
        property: "themeOverride"
        value: true
    }

    Launcher {}
    WallpaperPicker {}
    Debate {}
}
