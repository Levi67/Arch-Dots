// Slider: shows `value`; while dragging emits moved(v) (for live things like volume),
// on release emits committed(v) (for settings that are written to disk).
import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    id: root
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property int decimals: 0
    property string suffix: ""
    property bool showValue: true
    property var format: null          // optional function(v) -> string

    signal moved(real value)
    signal committed(real value)

    property real dragValue: value
    readonly property real shown: area.pressed ? dragValue : value
    readonly property real frac: to > from ? Math.max(0, Math.min(1, (shown - from) / (to - from))) : 0

    spacing: 10
    implicitWidth: 240
    Layout.fillWidth: false        // (a layout with a filling child would fill too)
    opacity: enabled ? 1 : 0.4

    function snap(v) {
        v = Math.max(from, Math.min(to, v));
        if (stepSize > 0)
            v = from + Math.round((v - from) / stepSize) * stepSize;
        return +v.toFixed(6);
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 22

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)

            Rectangle {
                width: Math.max(height, parent.width * root.frac)
                height: parent.height
                radius: 3
                color: Theme.accent
            }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            x: (track.width - width) * root.frac
            color: Theme.text
            border.width: 2
            border.color: Theme.accent
            scale: area.pressed ? 1.15 : 1
            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function at(x) {
                return root.snap(root.from + (root.to - root.from) * Math.max(0, Math.min(1, (x - 4) / track.width)));
            }
            onPressed: mouse => {
                root.dragValue = at(mouse.x);
                root.moved(root.dragValue);
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const v = at(mouse.x);
                if (v !== root.dragValue) {
                    root.dragValue = v;
                    root.moved(v);
                }
            }
            onReleased: root.committed(root.dragValue)
        }
    }

    SLabel {
        visible: root.showValue
        Layout.preferredWidth: 58
        horizontalAlignment: Text.AlignRight
        dim: true
        text: root.format ? root.format(root.shown) : root.shown.toFixed(root.decimals) + root.suffix
    }
}
