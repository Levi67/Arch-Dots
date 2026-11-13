// Dropdown. options: [{ label, value }] (or plain strings); emits activated(value).
import QtQuick
import QtQuick.Controls
import "../../theme"

ComboBox {
    id: root
    property var options: []
    property var current
    signal picked(var value)

    readonly property var norm: options.map(o => typeof o === "object" ? o : ({
                label: String(o),
                value: o
            }))

    model: norm
    textRole: "label"
    valueRole: "value"
    currentIndex: norm.findIndex(o => JSON.stringify(o.value) === JSON.stringify(current))
    displayText: currentIndex >= 0 ? norm[currentIndex].label : (current === undefined || current === null ? "" : String(current))
    onActivated: index => picked(norm[index].value)

    implicitWidth: 220
    implicitHeight: 30
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    background: Rectangle {
        radius: 10
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, root.hovered ? 0.12 : 0.07)
        border.width: 1
        border.color: root.popup.visible ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
    }

    contentItem: Text {
        leftPadding: 10
        rightPadding: 28
        text: root.displayText
        color: Theme.text
        font: root.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: SIcon {
        x: root.width - width - 8
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron"
        size: 16
        rotation: 90
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
    }

    delegate: ItemDelegate {
        id: d
        required property var modelData
        required property int index
        width: root.popup.width - 8
        x: 4
        height: 30
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: d.modelData.label
            color: Theme.text
            font: root.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 8
            color: d.highlighted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : "transparent"
            border.width: root.currentIndex === d.index ? 1 : 0
            border.color: Theme.accent
        }
    }

    popup: Popup {
        y: root.height + 4
        width: Math.max(root.width, 180)
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 320)
        padding: 4
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            radius: 12
            color: Theme.background
            border.width: 1
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
        }
    }
}
