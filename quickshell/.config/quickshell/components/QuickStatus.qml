// components/QuickStatus.qml
// Status icons in the bar (volume, network, bluetooth, night light).
// Click: quick panel. Scroll: volume. Middle click: mute.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import "../theme"
import "settings" as S

Row {
    id: root
    property var screen: null
    spacing: 10

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [root.sink]
    }
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btConnected: adapter ? adapter.devices.values.some(d => d.connected) : false

    function volumeIcon() {
        if (!sink || muted)
            return "volOff";
        return volume >= 0.66 ? "volHigh" : volume >= 0.33 ? "volMed" : "volLow";
    }

    function netIcon() {
        if (wired)
            return "ethernet";
        if (wifiNet) {
            const s = wifiNet.signalStrength;
            return s >= 0.75 ? "wifi4" : s >= 0.5 ? "wifi3" : s >= 0.25 ? "wifi2" : "wifi1";
        }
        return "wifiOff";
    }

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }

    component Glyph: S.SIcon {
        size: Theme.textSize - 2
        height: Theme.bubbleHeight
        anchors.verticalCenter: parent.verticalCenter
    }

    Glyph {
        name: root.volumeIcon()
        color: root.muted ? Theme.inactiveWorkspace : Theme.text
    }
    Glyph {
        name: root.netIcon()
        color: root.wired || root.wifiNet ? Theme.text : Theme.inactiveWorkspace
    }
    Glyph {
        visible: root.adapter !== null
        name: root.btConnected ? "btConn" : (root.adapter?.enabled ? "bt" : "btOff")
        color: root.adapter?.enabled ? Theme.text : Theme.inactiveWorkspace
    }
    Glyph {
        visible: NightLight.active
        name: "night"
        color: Theme.accent
    }

    // the Bubble around us is wider than this Row; cover it all
    MouseArea {
        parent: root.parent?.parent ?? root
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.sink.audio.muted;
            } else if (mouse.button === Qt.RightButton) {
                ShellState.openSettings("audio", root.screen);
            } else {
                ShellState.toggleQuick(root.screen);
            }
        }
        onWheel: wheel => root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
