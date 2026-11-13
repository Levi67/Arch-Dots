// Network: Wi-Fi (scan, connect with password, forget), Ethernet status, Bluetooth pairing.
// Wi-Fi/Ethernet via NetworkManager, Bluetooth via bluez (Quickshell's own services).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Network"
    subtitle: "Wi-Fi, Ethernet and Bluetooth."

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired && d.nmManaged !== false)
    readonly property var networks: wifi ? wifi.networks.values.slice().filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: adapter ? adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || String(a.name).localeCompare(String(b.name))) : []

    // scan only while this page is open
    property string expanded: ""          // network whose password field is open
    Component.onCompleted: {
        if (wifi)
            wifi.scannerEnabled = true;
        if (adapter && adapter.enabled)
            adapter.discovering = true;
    }
    Component.onDestruction: {
        if (wifi)
            wifi.scannerEnabled = false;
        if (adapter)
            adapter.discovering = false;
    }

    function strengthIcon(s) {
        return s >= 0.75 ? "wifi4" : s >= 0.5 ? "wifi3" : s >= 0.25 ? "wifi2" : "wifi1";
    }

    // ---- Wi-Fi ----
    SCard {
        title: "Wi-Fi"
        icon: "wifi"

        SRow {
            label: "Wi-Fi"
            hint: !page.wifi ? "No Wi-Fi adapter" : !Networking.wifiHardwareEnabled ? "Blocked by a hardware switch / rfkill" : ""
            SSwitch {
                enabled: page.wifi !== null
                checked: Networking.wifiEnabled
                onToggled: v => Networking.wifiEnabled = v
            }
        }

        Repeater {
            model: Networking.wifiEnabled ? page.networks : []
            delegate: ColumnLayout {
                id: net
                required property var modelData
                readonly property bool secured: modelData.security !== WifiSecurityType.Open
                readonly property bool open: page.expanded === modelData.name
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 10
                    color: net.modelData.connected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, netArea.containsMouse ? 0.07 : 0)

                    MouseArea {
                        id: netArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const n = net.modelData;
                            if (n.connected)
                                return;
                            if (n.known || !net.secured)
                                n.connect();
                            else
                                page.expanded = net.open ? "" : n.name;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 10
                        SIcon {
                            name: page.strengthIcon(net.modelData.signalStrength)
                            size: 17
                            color: net.modelData.connected ? Theme.accent : Theme.text
                        }
                        SLabel {
                            Layout.fillWidth: true
                            text: net.modelData.name
                            font.weight: net.modelData.connected ? Font.Bold : Font.Normal
                        }
                        SIcon {
                            visible: net.secured
                            name: "lock"
                            size: 14
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                        }
                        SLabel {
                            visible: net.modelData.stateChanging || net.modelData.connected
                            text: net.modelData.stateChanging ? "Connecting…" : "Connected"
                            dim: true
                            size: Theme.fontSize - 2
                        }
                        SButton {
                            visible: net.modelData.connected
                            text: "Disconnect"
                            flat: true
                            onClicked: net.modelData.disconnect()
                        }
                        SButton {
                            visible: net.modelData.known
                            text: "Forget"
                            flat: true
                            onClicked: net.modelData.forget()
                        }
                    }
                }

                // password
                RowLayout {
                    visible: net.open
                    Layout.fillWidth: true
                    Layout.leftMargin: 36
                    spacing: 8
                    SField {
                        id: psk
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "Password for " + net.modelData.name
                        onVisibleChanged: if (visible) {
                            text = "";
                            forceActiveFocus();
                        }
                        onAccepted: connectBtn.clicked()
                    }
                    SButton {
                        id: connectBtn
                        text: "Connect"
                        primary: true
                        enabled: psk.text.length >= 8
                        onClicked: {
                            net.modelData.connectWithPsk(psk.text);
                            page.expanded = "";
                        }
                    }
                }
            }
        }

        SLabel {
            visible: Networking.wifiEnabled && page.wifi !== null && page.networks.length === 0
            text: "Scanning…"
            dim: true
        }
    }

    // ---- Ethernet ----
    SCard {
        visible: page.wiredDevices.length > 0
        title: "Ethernet"
        icon: "ethernet"

        Repeater {
            model: page.wiredDevices
            delegate: SRow {
                required property var modelData
                label: modelData.name
                hint: !modelData.hasLink ? "Cable unplugged" : modelData.connected ? "Connected" + (modelData.linkSpeed > 0 ? " · " + (modelData.linkSpeed >= 1000 ? modelData.linkSpeed / 1000 + " Gbit/s" : modelData.linkSpeed + " Mbit/s") : "") + (modelData.address ? " · " + modelData.address : "") : "Not connected"
                SIcon {
                    name: "ethernet"
                    size: 18
                    color: modelData.connected ? Theme.accent : Theme.inactiveWorkspace
                }
            }
        }
    }

    // ---- Bluetooth ----
    SCard {
        title: "Bluetooth"
        icon: "bt"

        SLabel {
            visible: !page.adapter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            dim: true
            text: "Bluetooth isn't available. Install bluez + bluez-utils and start it: sudo pacman -S bluez bluez-utils && sudo systemctl enable --now bluetooth"
        }

        SRow {
            visible: page.adapter !== null
            label: "Bluetooth"
            hint: page.adapter?.discovering ? "Looking for devices…" : ""
            SSwitch {
                checked: page.adapter?.enabled ?? false
                onToggled: v => {
                    page.adapter.enabled = v;
                    if (v)
                        discoverLater.restart();
                }
            }
            Timer {
                id: discoverLater
                interval: 1500
                onTriggered: if (page.adapter?.enabled)
                    page.adapter.discovering = true
            }
        }

        Repeater {
            model: page.adapter?.enabled ? page.btDevices : []
            delegate: Rectangle {
                id: dev
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 10
                color: modelData.connected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 10
                    SIcon {
                        name: dev.modelData.connected ? "btConn" : "bt"
                        size: 17
                        color: dev.modelData.connected ? Theme.accent : Theme.text
                    }
                    SLabel {
                        Layout.fillWidth: true
                        text: dev.modelData.name || dev.modelData.address
                        font.weight: dev.modelData.connected ? Font.Bold : Font.Normal
                    }
                    SLabel {
                        visible: dev.modelData.batteryAvailable
                        text: Math.round(dev.modelData.battery * 100) + "%"
                        dim: true
                        size: Theme.fontSize - 2
                    }
                    SLabel {
                        visible: dev.modelData.pairing || dev.modelData.state === BluetoothDeviceState.Connecting
                        text: dev.modelData.pairing ? "Pairing…" : "Connecting…"
                        dim: true
                        size: Theme.fontSize - 2
                    }
                    SButton {
                        visible: !dev.modelData.paired
                        text: "Pair"
                        onClicked: {
                            dev.modelData.trusted = true;
                            dev.modelData.pair();
                        }
                    }
                    SButton {
                        visible: dev.modelData.paired
                        text: dev.modelData.connected ? "Disconnect" : "Connect"
                        flat: dev.modelData.connected
                        onClicked: dev.modelData.connected ? dev.modelData.disconnect() : dev.modelData.connect()
                    }
                    SButton {
                        visible: dev.modelData.paired
                        text: "Forget"
                        flat: true
                        onClicked: dev.modelData.forget()
                    }
                }
            }
        }
    }
}
