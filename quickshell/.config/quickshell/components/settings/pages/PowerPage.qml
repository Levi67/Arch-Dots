// Power: power profile (power-profiles-daemon) and night light (hyprsunset, see theme/NightLight.qml).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../../theme"
import ".."

SPage {
    id: page
    title: "Power & night light"
    subtitle: "Night light runs hyprsunset only while it's on."

    readonly property var p: Config.power

    SCard {
        title: "Power profile"
        icon: "bolt"

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: [
                    {
                        p: PowerProfile.PowerSaver,
                        icon: "leaf",
                        label: "Power saver"
                    },
                    {
                        p: PowerProfile.Balanced,
                        icon: "speedo",
                        label: "Balanced"
                    },
                    {
                        p: PowerProfile.Performance,
                        icon: "rocket",
                        label: "Performance"
                    }
                ]
                delegate: SButton {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 40
                    visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                    icon: modelData.icon
                    text: modelData.label
                    primary: PowerProfiles.profile === modelData.p
                    onClicked: PowerProfiles.profile = modelData.p
                }
            }
        }
    }

    SCard {
        title: "Night light"
        icon: "night"

        SLabel {
            visible: !NightLight.available
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            dim: true
            text: "hyprsunset isn't installed: sudo pacman -S hyprsunset"
        }

        SRow {
            label: "When"
            SCombo {
                Layout.preferredWidth: 220
                options: [
                    {
                        label: "Manually",
                        value: "manual"
                    },
                    {
                        label: "Fixed times",
                        value: "times"
                    },
                    {
                        label: "Sunset to sunrise",
                        value: "sun"
                    }
                ]
                current: NightLight.schedule
                onPicked: v => page.p.set("nightLight.schedule", v)
            }
        }

        SRow {
            visible: NightLight.schedule === "manual"
            label: "Night light"
            SSwitch {
                checked: NightLight.manualOn
                onToggled: v => page.p.set("nightLight.enabled", v)
            }
        }

        SRow {
            visible: NightLight.schedule === "times"
            label: "From – to"
            hint: "24h, e.g. 21:00 – 07:00"
            RowLayout {
                spacing: 6
                SField {
                    Layout.preferredWidth: 80
                    horizontalAlignment: TextInput.AlignHCenter
                    value: NightLight.from
                    onCommitted: t => NightLight.minutes(t) >= 0 ? page.p.set("nightLight.from", t.trim()) : (text = value)
                }
                SLabel {
                    text: "–"
                }
                SField {
                    Layout.preferredWidth: 80
                    horizontalAlignment: TextInput.AlignHCenter
                    value: NightLight.to
                    onCommitted: t => NightLight.minutes(t) >= 0 ? page.p.set("nightLight.to", t.trim()) : (text = value)
                }
            }
        }

        SRow {
            visible: NightLight.schedule === "sun"
            label: "Today"
            hint: "From the weather location (Theme → Weather)"
            SLabel {
                dim: true
                text: NightLight.sun ? "sunset " + Qt.formatTime(NightLight.sun.set, "HH:mm") + "  ·  sunrise " + Qt.formatTime(NightLight.sun.rise, "HH:mm") : (isNaN(NightLight.lat) ? "Locating…" : "No sunset today")
            }
        }

        SRow {
            visible: NightLight.schedule !== "manual"
            label: "Right now"
            hint: NightLight.override !== null ? "Flipped by hand until the next switch-over" : "Following the schedule"
            SSwitch {
                checked: NightLight.active
                onToggled: NightLight.toggle()
            }
        }

        SRow {
            label: "Warmth"
            hint: "Lower = warmer / more orange"
            SSlider {
                Layout.preferredWidth: 300
                from: 2000
                to: 6000
                stepSize: 100
                suffix: "K"
                value: NightLight.temperature
                onCommitted: v => page.p.set("nightLight.temperature", v)
            }
        }
    }
}
