// shell.qml
import Quickshell
import QtQuick

import "components" as UI
import "components/winter" as WinterUI
import "components/settings" as SettingsUI
import "theme"

ShellRoot {
    // 1. DATA LAYER (Optional but recommended)
    // Put your logic, timers, and Hyprland IPC listeners here.
    Scope {
        id: globalState
        property string activeWorkspace: "1"
    }

    // this shell owns the bar, so winter mode may recolor it (popups keep wallust colors)
    // (a Binding, not onCompleted: it also holds across Quickshell's hot reloads)
    Binding {
        target: Winter
        property: "themeOverride"
        value: true
    }

    UI.Notifications {}

    // 2. VISUAL LAYER
    // This tells Quickshell to actually build the Bar window.
    UI.Bar {
        // You can pass data from your Scope down into the Bar here
    }
    UI.WallpaperPicker {}

    // full settings overlay (SUPER+I / gear in the quick panel); the quick panel lives in Bar
    SettingsUI.SettingsWindow {}

    // Winter mode snowfall: only exists while enabled (Config.winter)
    LazyLoader {
        active: Winter.snowfallOn
        component: WinterUI.Snowfall {}
    }
}
