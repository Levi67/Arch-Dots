// RGB: case lighting through rgbctl (theme/Rgb.qml). Off at every boot; on = a gradient
// in the wallust colors (the icy palette while winter mode is on), follows theme changes live.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../theme"
import ".."

SPage {
    id: page
    title: "RGB"
    subtitle: "Case lighting. Always off after a reboot; follows the theme colors while on."

    readonly property var c: Config.rgb

    Component.onCompleted: Rgb.refresh()

    function label(d) {
        if (d.server === "openlinkhub")
            return "Case fans";
        if (d.name.indexOf("Vengeance") >= 0 || d.name.indexOf("DRAM") >= 0 || d.name.indexOf("DDR") >= 0)
            return "RAM" + (d.key.indexOf("#") >= 0 ? " stick " + d.key.split("#")[1] : "");
        if (d.name.indexOf("ASUS") >= 0)
            return "Motherboard";
        return d.name;
    }
    function detail(d) {
        const leds = d.zones.reduce((n, z) => n + z.leds, 0);
        return d.name + " · " + leds + " LEDs · " + (d.server === "openlinkhub" ? "OpenLinkHub" : "OpenRGB");
    }
    function icon(d) {
        return d.server === "openlinkhub" ? "fan" : label(d).startsWith("RAM") ? "memory" : "chip";
    }

    SCard {
        title: "Case RGB"
        icon: "rgb"

        SLabel {
            visible: !Rgb.available
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            dim: true
            text: "Neither OpenRGB nor OpenLinkHub answers: systemctl status openrgb openlinkhub"
        }

        SRow {
            label: "Lighting"
            hint: Rgb.on ? (Config.winter.get("enabled", false) ? "Winter palette" : "Wallpaper colors") : "Off until you turn it on"
            SSwitch {
                checked: Rgb.on
                onToggled: v => Rgb.setOn(v)
            }
        }

        SRow {
            label: "Brightness"
            SSlider {
                Layout.preferredWidth: 300
                from: 5
                to: 100
                stepSize: 5
                suffix: "%"
                value: Rgb.brightness
                onCommitted: v => page.c.set("brightness", v)
            }
        }

        SRow {
            label: "Gradient direction"
            hint: "Case fans run front bottom → front top → rear"
            SCombo {
                Layout.preferredWidth: 220
                options: [
                    {
                        label: "Forward",
                        value: "forward"
                    },
                    {
                        label: "Reverse",
                        value: "reverse"
                    }
                ]
                current: page.c.get("direction", "forward")
                onPicked: v => page.c.set("direction", v)
            }
        }
    }

    SCard {
        title: "Devices"
        icon: "chip"

        SLabel {
            visible: Rgb.devices.length === 0
            dim: true
            text: "No devices found."
        }

        Repeater {
            model: Rgb.devices
            delegate: SRow {
                required property var modelData
                label: page.label(modelData)
                hint: page.detail(modelData)
                SSwitch {
                    checked: page.c.get("devices", {})[modelData.key] !== false
                    onToggled: v => page.c.set("devices." + modelData.key, v)
                }
            }
        }
    }

    SCard {
        title: "Motherboard ARGB headers"
        icon: "rgb"
        visible: headers.count > 0

        SLabel {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            dim: true
            text: "The board can't tell what's plugged in: enter the LED count of whatever is connected (0 = nothing)."
        }

        Repeater {
            id: headers
            model: Rgb.devices.filter(d => d.server === "openrgb").reduce((all, d) => all.concat(d.zones.filter(z => z.name.startsWith("Addressable RGB Header"))), [])
            delegate: SRow {
                required property var modelData
                label: modelData.name.replace("Addressable RGB ", "ARGB ")
                hint: modelData.leds + " LEDs right now"
                SField {
                    Layout.preferredWidth: 80
                    horizontalAlignment: TextInput.AlignHCenter
                    value: String(page.c.get("argbLeds", {})[modelData.name] ?? 0)
                    onCommitted: t => {
                        const n = parseInt(t, 10);
                        if (isNaN(n) || n < 0 || n > 500) {
                            text = value;
                            return;
                        }
                        page.c.set("argbLeds." + modelData.name, n);
                    }
                }
            }
        }
    }
}
