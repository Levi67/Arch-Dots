// Snowfall behind all windows (bottom layer), one surface per monitor.
// Truly empty workspaces get heavier snow and a pile that grows along the
// bottom edge and slowly melts once the workspace isn't empty/visible anymore.
// A monitor showing a fullscreen window hides its surface entirely.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"

Scope {
    id: root

    // workspace id -> { level: 0..1, t: ms, growing: bool }; levels are
    // advanced lazily from timestamps, so hidden workspaces cost nothing.
    property var piles: ({})

    function pileLevel(wsId, growing, now) {
        const p = piles[wsId] || { level: 0, t: now, growing: false };
        const dt = now - p.t;
        if (p.growing)
            p.level = Math.min(1, p.level + dt / Winter.pileGrowMs);
        else
            p.level = Math.max(0, p.level - dt / Winter.pileMeltMs);
        p.t = now;
        p.growing = growing && Winter.pileOn;
        piles[wsId] = p;
        return p.level;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
            readonly property var ws: hyprMonitor ? hyprMonitor.activeWorkspace : null
            readonly property bool wsEmpty: ws !== null && ws.toplevels.values.length === 0
            readonly property bool covered: ws !== null && ws.hasFullscreen

            visible: !covered
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "winter-snow"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}  // click-through

            ShaderEffect {
                id: snow
                anchors.fill: parent

                property real time: 0
                property real density: win.wsEmpty ? Winter.emptyDensity : Winter.density
                property real speed: Winter.speed
                property real pile: 0
                property real pileHeight: Winter.pileMaxHeight
                property real seed: (win.modelData.x / 2560 + 1) * 0.37
                property vector2d resolution: Qt.vector2d(width, height)

                Behavior on density { NumberAnimation { duration: 2500; easing.type: Easing.InOutQuad } }

                fragmentShader: Qt.resolvedUrl("shaders/snow.frag.qsb")
            }

            Timer {
                property real start: Date.now()
                interval: Math.round(1000 / Winter.fps)
                repeat: true
                running: win.visible
                onTriggered: {
                    const now = Date.now();
                    snow.time = ((now - start) / 1000) % 3600; // keep float32 precision in the shader
                    if (win.ws)
                        snow.pile = root.pileLevel(win.ws.id, win.wsEmpty, now);
                }
            }
        }
    }
}
