// components/SystemStats.qml
import QtQuick
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 12

    // ---- settings ----
    property int updateSeconds: 2
    property int hotTemp: 80            // temps at/above this turn accent colored
    property bool showGpuTemp: false    // false = GPU usage %, true = GPU temperature
    property string iconFont: Theme.fontFamily   // must be a Nerd Font (or any installed Nerd Font gets used as fallback)
    property int textSize: Theme.textSize

    // ---- values (filled by the script below) ----
    property int cpu: 0
    property int cpuTemp: 0
    property real ramGb: 0
    property int gpu: 0
    property int gpuTemp: 0

    // One long-running shell loop that prints: cpu|cpuTemp|ramGB|gpu%|gpuTemp
    Process {
        running: true
        command: ["sh", "-c", `
            tempfile=""
            for h in /sys/class/hwmon/hwmon*; do
                case "$(cat $h/name 2>/dev/null)" in
                    k10temp|coretemp|zenpower) tempfile="$h/temp1_input"; break ;;
                esac
            done

            prev_t=0; prev_i=0
            while true; do
                # CPU % from /proc/stat deltas
                read -r _ u n s i w irq sirq st _ < /proc/stat
                t=$((u+n+s+i+w+irq+sirq+st)); idle=$((i+w))
                dt=$((t-prev_t)); di=$((idle-prev_i))
                cpu=0
                [ "$dt" -gt 0 ] && cpu=$(( (100*(dt-di))/dt ))
                prev_t=$t; prev_i=$idle

                # CPU temp in C
                temp=0
                [ -n "$tempfile" ] && temp=$(( $(cat $tempfile) / 1000 ))

                # RAM used in GB (total - available)
                ram=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.2f", (t-a)/1048576}' /proc/meminfo)

                # NVIDIA GPU: usage and temperature
                g=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
                gpu=$(echo "$g" | cut -d, -f1)
                gputemp=$(echo "$g" | cut -d, -f2)
                [ -z "$gpu" ] && gpu=0
                [ -z "$gputemp" ] && gputemp=0

                echo "$cpu|$temp|$ram|$gpu|$gputemp"
                sleep ${root.updateSeconds}
            done
        `]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split("|").map(Number);
                if (p.length < 5 || p.some(isNaN))
                    return;
                root.cpu = p[0];
                root.cpuTemp = p[1];
                root.ramGb = p[2];
                root.gpu = p[3];
                root.gpuTemp = p[4];
            }
        }
    }

    // ---- one "icon + value" item ----
    component Stat: Row {
        property string icon
        property string value
        property color valueColor: Theme.text
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: parent.icon
            color: Theme.accent
            font.pixelSize: root.textSize - 2
            font.family: root.iconFont
            height: Theme.bubbleHeight
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0      // nudge icon: negative = up, positive = down
        }
        Text {
            text: parent.value
            color: parent.valueColor
            font.pixelSize: root.textSize - 2
            font.family: Theme.fontFamily
            font.weight: Font.Bold
            height: Theme.bubbleHeight
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 0      // nudge text: negative = up, positive = down
        }
    }

    // CPU usage
    Stat {
        icon: "\uf2db"
        value: root.cpu + "%"
    }

    // CPU temperature
    Stat {
        icon: "\uf2c9"
        value: root.cpuTemp + "°C"
        valueColor: root.cpuTemp >= root.hotTemp ? Theme.accent : Theme.text
    }

    // RAM used (gauge icon)
    Stat {
        icon: "\udb81\udcc5"
        value: root.ramGb.toFixed(1) + "GB"
    }

    // GPU (usage % or temperature)
    Stat {
        icon: root.showGpuTemp ? "\uf2c9" : "\uf26c"
        value: root.showGpuTemp ? root.gpuTemp + "°C" : root.gpu + "%"
        valueColor: (root.showGpuTemp && root.gpuTemp >= root.hotTemp) ? Theme.accent : Theme.text
    }
}
