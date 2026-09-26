// shell.qml
import Quickshell

import "components" as UI

ShellRoot {
    // 1. DATA LAYER (Optional but recommended)
    // Put your logic, timers, and Hyprland IPC listeners here.
    Scope {
        id: globalState
        property string activeWorkspace: "1"
    }

    // 2. VISUAL LAYER
    // This tells Quickshell to actually build the Bar window.
    UI.Bar {
        // You can pass data from your Scope down into the Bar here
    }
}