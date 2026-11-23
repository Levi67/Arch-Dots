// Theme: wallpaper folder, wallust colors, fonts (Quickshell + kitty) and the bar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Theme"
    subtitle: "Wallpaper, colors, fonts and what the bar shows."

    readonly property var t: Config.theme
    readonly property var b: Config.bar
    readonly property string home: Quickshell.env("HOME")

    // ---- helpers ----
    Process {
        id: run
    }
    function exec(cmd) {
        run.running = false;
        run.command = cmd;
        run.running = true;
    }

    // wallust palette, read from the kitty colors it generates
    property var palette: []
    FileView {
        id: colors
        path: page.home + "/.config/kitty/wallust-colors.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const map = {};
            for (const line of text().split("\n")) {
                const m = /^(color\d+|background|foreground)\s+(#[0-9a-fA-F]{6})/.exec(line.trim());
                if (m)
                    map[m[1]] = m[2];
            }
            const out = [];
            for (let i = 0; i < 16; ++i)
                if (map["color" + i])
                    out.push(map["color" + i]);
            page.palette = out;
            page.paletteBg = map.background ?? "";
            page.paletteFg = map.foreground ?? "";
        }
    }
    property string paletteBg
    property string paletteFg

    readonly property var families: Qt.fontFamilies()
    readonly property var monoFamilies: families.filter(f => /mono|code|term|consol|courier|nerd font mono|iosevka|hack/i.test(f))

    function applyTerminalFont() {
        exec([Quickshell.shellPath("scripts/apply-terminal-font"), t.get("terminal.family", "JetBrainsMono Nerd Font"), String(t.get("terminal.size", 12))]);
    }

    // ---- wallpaper ----
    SCard {
        title: "Wallpaper"
        icon: "folder"

        SRow {
            label: "Wallpaper folder"
            hint: "Scanned with subfolders by the wallpaper picker"
            SField {
                Layout.preferredWidth: 320
                value: page.t.get("wallpaper.dir", "")
                placeholderText: "~/Pictures/Wallpapers"
                onCommitted: v => page.t.set("wallpaper.dir", v.trim())
            }
        }
        SRow {
            label: "waypaper backend"
            SCombo {
                Layout.preferredWidth: 200
                options: [
                    {
                        label: "waypaper default",
                        value: ""
                    },
                    "swww", "hyprpaper", "mpvpaper", "swaybg", "wallutils", "feh", "xwallpaper"]
                current: page.t.get("wallpaper.backend", "")
                onPicked: v => page.t.set("wallpaper.backend", v)
            }
        }
        SRow {
            label: "Pick a wallpaper"
            SButton {
                text: "Open picker"
                icon: "palette"
                onClicked: {
                    ShellState.settingsOpen = false;
                    page.exec(["qs", "ipc", "call", "wallpaper", "open"]);
                }
            }
        }
    }

    // ---- colors ----
    SCard {
        title: "Colors (wallust)"
        icon: "palette"

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: page.palette
                delegate: Rectangle {
                    required property var modelData
                    width: 34
                    height: 34
                    radius: 9
                    color: modelData
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                }
            }
        }
        SRow {
            label: "Extra saturation"
            hint: "0 = as wallust picks them"
            SSlider {
                Layout.preferredWidth: 300
                from: 0
                to: 100
                stepSize: 5
                suffix: "%"
                value: page.t.get("wallust.saturation", 0)
                onCommitted: v => page.t.set("wallust.saturation", Math.round(v))
            }
        }
        SRow {
            label: "Ensure readable contrast"
            SSwitch {
                checked: page.t.get("wallust.checkContrast", false)
                onToggled: v => page.t.set("wallust.checkContrast", v)
            }
        }
        SRow {
            label: "Regenerate colors"
            hint: "Runs wallust on the current wallpaper with these options"
            SButton {
                text: run.running ? "Working…" : "Regenerate"
                icon: "refresh"
                enabled: !run.running
                onClicked: page.exec([page.home + "/.config/scripts/wallpaper/wallpaper-theme"])
            }
        }
    }

    // ---- fonts ----
    SCard {
        title: "Fonts"
        icon: "font"

        SRow {
            label: "Bar & popups font"
            SCombo {
                Layout.preferredWidth: 300
                options: ["sans-serif"].concat(page.families)
                current: page.t.get("font.family", "JetBrainsMono Nerd Font")
                onPicked: v => page.t.set("font.family", v)
            }
        }
        SRow {
            label: "Bar text size"
            SSlider {
                Layout.preferredWidth: 300
                from: 12
                to: 28
                stepSize: 1
                suffix: " px"
                value: page.t.get("font.barSize", 20)
                onCommitted: v => page.t.set("font.barSize", v)
            }
        }
        SRow {
            label: "Popup text size"
            SSlider {
                Layout.preferredWidth: 300
                from: 10
                to: 20
                stepSize: 1
                suffix: " px"
                value: page.t.get("font.uiSize", 13)
                onCommitted: v => page.t.set("font.uiSize", v)
            }
        }
        SRow {
            label: "Terminal font (kitty)"
            SCombo {
                Layout.preferredWidth: 300
                options: page.monoFamilies.length ? page.monoFamilies : page.families
                current: page.t.get("terminal.family", "JetBrainsMono Nerd Font")
                onPicked: v => {
                    page.t.set("terminal.family", v);
                    page.applyTerminalFont();
                }
            }
        }
        SRow {
            label: "Terminal font size"
            SSlider {
                Layout.preferredWidth: 300
                from: 8
                to: 24
                stepSize: 0.5
                decimals: 1
                suffix: " pt"
                value: page.t.get("terminal.size", 12)
                onCommitted: v => {
                    page.t.set("terminal.size", v);
                    page.applyTerminalFont();
                }
            }
        }
    }

    // ---- bar ----
    SCard {
        title: "Bar"
        icon: "monitor"

        SLabel {
            text: "Show the bar on"
            dim: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: Quickshell.screens
                delegate: SButton {
                    required property var modelData
                    readonly property var only: page.b.get("monitors", [])
                    readonly property bool on: only.length === 0 || only.includes(modelData.name)
                    text: modelData.name
                    icon: on ? "check" : "close"
                    primary: on
                    onClicked: {
                        const all = Quickshell.screens.map(s => s.name);
                        let list = only.length === 0 ? all.slice() : only.slice();
                        if (on)
                            list = list.filter(n => n !== modelData.name);
                        else
                            list.push(modelData.name);
                        if (list.length === 0)
                            return;     // keep at least one bar
                        page.b.set("monitors", all.every(n => list.includes(n)) ? [] : list);
                    }
                }
            }
        }

        SLabel {
            Layout.topMargin: 6
            text: "Modules"
            dim: true
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            rowSpacing: 10
            Repeater {
                model: [
                    {
                        k: "workspaces",
                        l: "Workspaces"
                    },
                    {
                        k: "stats",
                        l: "System stats"
                    },
                    {
                        k: "clock",
                        l: "Clock"
                    },
                    {
                        k: "timers",
                        l: "Voice timers"
                    },
                    {
                        k: "weather",
                        l: "Weather"
                    },
                    {
                        k: "voice",
                        l: "Voice assistant"
                    },
                    {
                        k: "media",
                        l: "Media player"
                    },
                    {
                        k: "status",
                        l: "Status / quick settings"
                    }
                ]
                delegate: SRow {
                    required property var modelData
                    label: modelData.l
                    SSwitch {
                        checked: page.b.get("modules." + modelData.k, true)
                        onToggled: v => page.b.set("modules." + modelData.k, v)
                    }
                }
            }
        }
    }

    SCard {
        title: "Clock"
        icon: "sun"

        SRow {
            label: "24-hour clock"
            SSwitch {
                checked: page.b.get("clock.hour24", true)
                onToggled: v => page.b.set("clock.hour24", v)
            }
        }
        SRow {
            label: "Show seconds"
            SSwitch {
                checked: page.b.get("clock.seconds", false)
                onToggled: v => page.b.set("clock.seconds", v)
            }
        }
        SRow {
            label: "Date"
            hint: "Shown before the time"
            SCombo {
                Layout.preferredWidth: 220
                options: [
                    {
                        label: "No date",
                        value: ""
                    },
                    {
                        label: Qt.formatDate(new Date(), "ddd dd.MM."),
                        value: "ddd dd.MM."
                    },
                    {
                        label: Qt.formatDate(new Date(), "ddd d. MMM"),
                        value: "ddd d. MMM"
                    },
                    {
                        label: Qt.formatDate(new Date(), "dd.MM.yyyy"),
                        value: "dd.MM.yyyy"
                    },
                    {
                        label: Qt.formatDate(new Date(), "yyyy-MM-dd"),
                        value: "yyyy-MM-dd"
                    },
                    {
                        label: Qt.formatDate(new Date(), "dddd"),
                        value: "dddd"
                    }
                ]
                current: page.b.get("clock.date", "")
                onPicked: v => page.b.set("clock.date", v)
            }
        }
    }

    SCard {
        title: "Weather"
        icon: "sunset"

        SRow {
            label: "City"
            hint: "Looked up on open-meteo.com; leave coordinates empty to use it"
            SField {
                Layout.preferredWidth: 220
                value: page.b.get("weather.location", "")
                onCommitted: v => page.b.set("weather.location", v.trim())
            }
        }
        SRow {
            label: "Exact coordinates"
            hint: "Latitude, longitude (optional, wins over the city)"
            SField {
                Layout.preferredWidth: 220
                readonly property var lat: page.b.get("weather.latitude", null)
                readonly property var lon: page.b.get("weather.longitude", null)
                value: typeof lat === "number" && typeof lon === "number" ? lat + ", " + lon : ""
                placeholderText: "52.52, 13.40"
                onCommitted: v => {
                    const m = /^\s*(-?\d+(?:\.\d+)?)\s*[,; ]\s*(-?\d+(?:\.\d+)?)\s*$/.exec(v);
                    page.b.set("weather.latitude", m ? +m[1] : null);
                    page.b.set("weather.longitude", m ? +m[2] : null);
                    if (!m)
                        text = "";
                }
            }
        }
        SRow {
            label: "Unit"
            SCombo {
                Layout.preferredWidth: 160
                options: [
                    {
                        label: "°C",
                        value: "celsius"
                    },
                    {
                        label: "°F",
                        value: "fahrenheit"
                    }
                ]
                current: page.b.get("weather.unit", "celsius")
                onPicked: v => page.b.set("weather.unit", v)
            }
        }
        SRow {
            label: "Refresh every"
            SSlider {
                Layout.preferredWidth: 300
                from: 5
                to: 60
                stepSize: 5
                suffix: " min"
                value: page.b.get("weather.refreshMinutes", 10)
                onCommitted: v => page.b.set("weather.refreshMinutes", v)
            }
        }
    }

    SCard {
        title: "System stats"
        icon: "speedo"

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 24
            rowSpacing: 10
            Repeater {
                model: [
                    {
                        k: "cpu",
                        l: "CPU usage"
                    },
                    {
                        k: "cpuTemp",
                        l: "CPU temperature"
                    },
                    {
                        k: "ram",
                        l: "RAM"
                    },
                    {
                        k: "gpu",
                        l: "GPU"
                    }
                ]
                delegate: SRow {
                    required property var modelData
                    label: modelData.l
                    SSwitch {
                        checked: page.b.get("stats." + modelData.k, true)
                        onToggled: v => page.b.set("stats." + modelData.k, v)
                    }
                }
            }
        }
        SRow {
            label: "GPU shows"
            enabled: page.b.get("stats.gpu", true)
            SCombo {
                Layout.preferredWidth: 160
                options: [
                    {
                        label: "Usage %",
                        value: false
                    },
                    {
                        label: "Temperature",
                        value: true
                    }
                ]
                current: page.b.get("stats.gpuTemp", false)
                onPicked: v => page.b.set("stats.gpuTemp", v)
            }
        }
        SRow {
            label: "Hot temperature"
            hint: "Temperatures from here on are highlighted"
            SSlider {
                Layout.preferredWidth: 300
                from: 50
                to: 100
                stepSize: 1
                suffix: "°C"
                value: page.b.get("stats.hotTemp", 80)
                onCommitted: v => page.b.set("stats.hotTemp", v)
            }
        }
        SRow {
            label: "Update every"
            SSlider {
                Layout.preferredWidth: 300
                from: 1
                to: 10
                stepSize: 1
                suffix: " s"
                value: page.b.get("stats.updateSeconds", 2)
                onCommitted: v => page.b.set("stats.updateSeconds", v)
            }
        }
    }
}
