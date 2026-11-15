// All desktop settings, one JSON per area (see ConfigFile.qml).
//   defaults: ~/.config/quickshell/defaults/<area>.json   (tracked in Arch-Dots)
//   yours:    ~/.config/desktop/<area>.json                (local, only your changes)
// Edited by the settings window, read by the bar, winter mode, night light, ...
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string liveDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/desktop"
    readonly property string defaultsDir: Quickshell.shellPath("defaults")

    readonly property alias winter: winterCfg
    readonly property alias theme: themeCfg
    readonly property alias bar: barCfg
    readonly property alias power: powerCfg
    readonly property alias displays: displaysCfg
    readonly property alias rgb: rgbCfg

    // "~/x" -> "/home/you/x"
    function expand(path) {
        return (path ?? "").startsWith("~") ? Quickshell.env("HOME") + path.slice(1) : (path ?? "");
    }

    ConfigFile {
        id: winterCfg
        name: "winter"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }
    ConfigFile {
        id: themeCfg
        name: "theme"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }
    ConfigFile {
        id: barCfg
        name: "bar"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }
    ConfigFile {
        id: powerCfg
        name: "power"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }
    ConfigFile {
        id: displaysCfg
        name: "displays"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }
    ConfigFile {
        id: rgbCfg
        name: "rgb"
        defaultsDir: root.defaultsDir
        liveDir: root.liveDir
    }

    // make sure ~/.config/desktop exists (writes go there) and import old settings once
    Process {
        running: true
        command: [Quickshell.shellPath("scripts/desktop-migrate")]
    }
}
