// Scrollable settings page: title + cards stacked vertically.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Flickable {
    id: root
    property string title
    property string subtitle: ""
    default property alias content: col.data

    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight + 56
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {
        policy: root.contentHeight > root.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
    }

    // ---- fast, smooth wheel scrolling (Flickable's own wheel speed is very slow) ----
    property real wheelStep: 220          // px per mouse-wheel notch
    property real scrollTarget: 0

    function scrollBy(dy) {
        const max = Math.max(0, contentHeight - height);
        scrollTarget = Math.max(0, Math.min(max, (scrollAnim.running ? scrollTarget : contentY) + dy));
        scrollAnim.to = scrollTarget;
        scrollAnim.restart();
    }

    NumberAnimation {
        id: scrollAnim
        target: root
        property: "contentY"
        duration: 180
        easing.type: Easing.OutCubic
    }

    // sits above the content, only takes the wheel (clicks/drags pass through)
    MouseArea {
        parent: root
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.pixelDelta.y !== 0) {
                // touchpad: follow the fingers 1:1 (a bit faster), no animation
                scrollAnim.stop();
                root.contentY = Math.max(0, Math.min(Math.max(0, root.contentHeight - root.height), root.contentY - wheel.pixelDelta.y * 1.5));
            } else {
                root.scrollBy(-wheel.angleDelta.y / 120 * root.wheelStep);
            }
        }
    }

    ColumnLayout {
        id: col
        x: 28
        y: 28
        width: root.width - 56
        spacing: 14

        ColumnLayout {
            Layout.bottomMargin: 6
            spacing: 2
            SLabel {
                text: root.title
                size: Theme.fontSize + 9
                font.weight: Font.Bold
            }
            SLabel {
                visible: root.subtitle !== ""
                Layout.fillWidth: true
                text: root.subtitle
                dim: true
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }
        }
    }
}
