// Winter mode settings, read live from Config.winter (defaults/winter.json + ~/.config/desktop/winter.json).
// Every visual winter part checks its own *On flag, so a settings app only
// has to edit the JSON (master "enabled" + one flag per feature).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var cfg: Config.winter.data

    readonly property bool enabled: cfg.enabled === true
    readonly property bool snowfallOn: enabled && feature("snowfall")
    readonly property bool barOn: enabled && feature("bar")
    readonly property bool capsOn: enabled && feature("windowCaps")

    // snow caps (windows: hypr-snowcaps plugin; Launcher / wallpaper picker: components/winter/PopupSnowCap.qml)
    readonly property real capMaxHeight: num(cfg.windowCaps, "maxHeight", 32)
    readonly property real popupCapGrowMs: Math.max(0.1, num(cfg.popupCaps, "growMinutes", 2)) * 60000
    readonly property real popupCapMeltMs: Math.max(0.1, num(cfg.popupCaps, "meltMinutes", 30)) * 60000

    // tunables with defaults, so a partial/missing config still works
    readonly property real density: num(cfg.snowfall, "density", 1.0)
    readonly property real emptyDensity: num(cfg.snowfall, "emptyDensity", 2.2)
    readonly property real speed: num(cfg.snowfall, "speed", 1.0)
    readonly property int fps: Math.max(10, Math.min(240, num(cfg.snowfall, "fps", 60)))

    readonly property bool pileOn: !cfg.pile || cfg.pile.enabled !== false
    readonly property real pileMaxHeight: num(cfg.pile, "maxHeight", 70)
    readonly property real pileGrowMs: num(cfg.pile, "growMinutes", 15) * 60000
    readonly property real pileMeltMs: num(cfg.pile, "meltMinutes", 10) * 60000

    // bar winter palette (dark smoky ice glass over the Hyprland blur, white text), independent of wallust
    property bool themeOverride: false // set by the shell that owns the bar
    readonly property color barTint: str(cfg.bar, "tint", "#7014202C")
    readonly property color barText: str(cfg.bar, "text", "#FFFFFF")
    readonly property color barInactive: str(cfg.bar, "inactive", "#B3FFFFFF")
    readonly property color barAccent: str(cfg.bar, "accent", "#FFFFFF")
    readonly property bool barFlakes: themeOverride && barOn && (!cfg.bar || cfg.bar.flakes !== false)
    readonly property real barFlakeDensity: num(cfg.bar, "flakeDensity", 1.0)
    readonly property real barFrost: num(cfg.bar, "frost", 1.0)

    // shared animation clock (seconds) for the bubble flakes; only ticks while they exist
    property real clock: 0
    Timer {
        property real start: Date.now()
        interval: Math.round(1000 / root.fps)
        repeat: true
        running: root.barFlakes
        onTriggered: root.clock = ((Date.now() - start) / 1000) % 3600
    }

    function feature(name) {
        return !cfg.features || cfg.features[name] !== false;
    }

    function str(obj, key, def) {
        return obj && typeof obj[key] === "string" ? obj[key] : def;
    }

    function num(obj, key, def) {
        return obj && typeof obj[key] === "number" ? obj[key] : def;
    }

}
