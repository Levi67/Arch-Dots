// Winter mode: master switch, the three features and their tunables (Config.winter).
// The Hyprland plugin side (window caps) is synced by `winterctl apply` after each change.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Winter"
    subtitle: "Snow on the desktop, snow caps on windows and an icy bar. Off = nothing running. Toggle anywhere with SUPER+SHIFT+W."

    readonly property var c: Config.winter

    // window caps live in a Hyprland plugin: let winterctl load/unload it and push its options
    function set(path, v) {
        c.set(path, v);
        if (path === "enabled" || path.startsWith("features") || path.startsWith("windowCaps"))
            syncTimer.restart();
    }
    Timer {
        id: syncTimer
        interval: 250
        onTriggered: {
            sync.running = false;
            sync.running = true;
        }
    }
    Process {
        id: sync
        command: [Quickshell.env("HOME") + "/.config/winter/winterctl", "apply"]
    }
    // option changes need the plugin reloaded with new values: apply only pushes them on load
    Process {
        id: pushCaps
        command: ["hyprctl", "eval", "hl.config({ plugin = { snowcaps = { grow_minutes = " + page.c.get("windowCaps.growMinutes", 30) + ", max_height = " + page.c.get("windowCaps.maxHeight", 32) + " } } })"]
    }

    SCard {
        SRow {
            label: "Winter mode"
            hint: "Master switch"
            SSwitch {
                checked: page.c.get("enabled", false)
                onToggled: v => page.set("enabled", v)
            }
        }
    }

    SCard {
        title: "Snowfall"
        icon: "snow"
        enabled: page.c.get("enabled", false)

        SRow {
            label: "Snowfall behind windows"
            SSwitch {
                checked: page.c.get("features.snowfall", true)
                onToggled: v => page.set("features.snowfall", v)
            }
        }
        SRow {
            label: "Density"
            enabled: page.c.get("features.snowfall", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 0.2
                to: 3
                stepSize: 0.1
                decimals: 1
                suffix: "×"
                value: page.c.get("snowfall.density", 1)
                onCommitted: v => page.set("snowfall.density", v)
            }
        }
        SRow {
            label: "Density on empty workspaces"
            enabled: page.c.get("features.snowfall", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 0.2
                to: 4
                stepSize: 0.1
                decimals: 1
                suffix: "×"
                value: page.c.get("snowfall.emptyDensity", 2.2)
                onCommitted: v => page.set("snowfall.emptyDensity", v)
            }
        }
        SRow {
            label: "Fall speed"
            enabled: page.c.get("features.snowfall", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 0.2
                to: 3
                stepSize: 0.1
                decimals: 1
                suffix: "×"
                value: page.c.get("snowfall.speed", 1)
                onCommitted: v => page.set("snowfall.speed", v)
            }
        }
        SRow {
            label: "Frame rate"
            hint: "Lower = less CPU/GPU (also drives the bar flakes)"
            enabled: page.c.get("features.snowfall", true) || page.c.get("features.bar", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 10
                to: 144
                stepSize: 1
                suffix: " fps"
                value: page.c.get("snowfall.fps", 60)
                onCommitted: v => page.set("snowfall.fps", v)
            }
        }
    }

    SCard {
        title: "Snow pile"
        icon: "snow"
        enabled: page.c.get("enabled", false) && page.c.get("features.snowfall", true)

        SRow {
            label: "Pile up on empty workspaces"
            SSwitch {
                checked: page.c.get("pile.enabled", true)
                onToggled: v => page.set("pile.enabled", v)
            }
        }
        SRow {
            label: "Max height"
            enabled: page.c.get("pile.enabled", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 10
                to: 200
                stepSize: 5
                suffix: " px"
                value: page.c.get("pile.maxHeight", 70)
                onCommitted: v => page.set("pile.maxHeight", v)
            }
        }
        SRow {
            label: "Time to grow"
            enabled: page.c.get("pile.enabled", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 1
                to: 60
                stepSize: 1
                suffix: " min"
                value: page.c.get("pile.growMinutes", 15)
                onCommitted: v => page.set("pile.growMinutes", v)
            }
        }
        SRow {
            label: "Time to melt"
            enabled: page.c.get("pile.enabled", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 1
                to: 60
                stepSize: 1
                suffix: " min"
                value: page.c.get("pile.meltMinutes", 10)
                onCommitted: v => page.set("pile.meltMinutes", v)
            }
        }
    }

    SCard {
        title: "Window snow caps"
        icon: "snow"
        enabled: page.c.get("enabled", false)

        SRow {
            label: "Snow caps on windows"
            hint: "Hyprland plugin, unloaded when off"
            SSwitch {
                checked: page.c.get("features.windowCaps", true)
                onToggled: v => page.set("features.windowCaps", v)
            }
        }
        SRow {
            label: "Time to full size"
            enabled: page.c.get("features.windowCaps", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 1
                to: 120
                stepSize: 1
                suffix: " min"
                value: page.c.get("windowCaps.growMinutes", 30)
                onCommitted: v => {
                    page.c.set("windowCaps.growMinutes", Math.round(v));
                    pushCaps.running = true;
                }
            }
        }
        SRow {
            label: "Max thickness"
            enabled: page.c.get("features.windowCaps", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 4
                to: 64
                stepSize: 1
                suffix: " px"
                value: page.c.get("windowCaps.maxHeight", 32)
                onCommitted: v => {
                    page.c.set("windowCaps.maxHeight", Math.round(v));
                    pushCaps.running = true;
                }
            }
        }
    }

    SCard {
        title: "Snow on the Launcher & wallpaper picker"
        icon: "snow"
        enabled: page.c.get("enabled", false) && page.c.get("features.windowCaps", true)

        SRow {
            label: "Time to pile up"
            hint: "Counts only while the popup is open; kept between opens"
            SSlider {
                Layout.preferredWidth: 300
                from: 0.5
                to: 20
                stepSize: 0.5
                decimals: 1
                suffix: " min"
                value: page.c.get("popupCaps.growMinutes", 2)
                onCommitted: v => page.set("popupCaps.growMinutes", v)
            }
        }
        SRow {
            label: "Time to melt"
            hint: "While the popup is closed"
            SSlider {
                Layout.preferredWidth: 300
                from: 1
                to: 120
                stepSize: 1
                suffix: " min"
                value: page.c.get("popupCaps.meltMinutes", 30)
                onCommitted: v => page.set("popupCaps.meltMinutes", v)
            }
        }
    }

    SCard {
        title: "Icy bar"
        icon: "snow"
        enabled: page.c.get("enabled", false)

        SRow {
            label: "Icy glass bar"
            hint: "Own frosty colors instead of the wallpaper palette"
            SSwitch {
                checked: page.c.get("features.bar", true)
                onToggled: v => page.set("features.bar", v)
            }
        }
        SRow {
            label: "Snow-globe flakes in the bubbles"
            enabled: page.c.get("features.bar", true)
            SSwitch {
                checked: page.c.get("bar.flakes", true)
                onToggled: v => page.set("bar.flakes", v)
            }
        }
        SRow {
            label: "Flake amount"
            enabled: page.c.get("features.bar", true) && page.c.get("bar.flakes", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 0.2
                to: 3
                stepSize: 0.1
                decimals: 1
                suffix: "×"
                value: page.c.get("bar.flakeDensity", 1)
                onCommitted: v => page.set("bar.flakeDensity", v)
            }
        }
        SRow {
            label: "Frost / glass strength"
            enabled: page.c.get("features.bar", true)
            SSlider {
                Layout.preferredWidth: 300
                from: 0
                to: 1.5
                stepSize: 0.05
                decimals: 2
                value: page.c.get("bar.frost", 1)
                onCommitted: v => page.set("bar.frost", v)
            }
        }
        SRow {
            label: "Glass tint"
            hint: "#AARRGGBB - keep alpha above 4D or the blur stops"
            enabled: page.c.get("features.bar", true)
            SField {
                Layout.preferredWidth: 160
                value: page.c.get("bar.tint", "#7014202C")
                onCommitted: t => {
                    if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(t))
                        page.set("bar.tint", t.toUpperCase());
                    else
                        text = value;
                }
            }
        }
    }
}
