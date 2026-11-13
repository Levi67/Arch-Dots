// components/Clock.qml
import QtQuick
import "../theme"

Text {
    id: clock
    property color textColor: "black" // Allows you to set this from Bar.qml
    property int textSize: Theme.textSize

    // format from the settings window (Theme -> Bar -> Clock)
    readonly property bool hour24: Config.bar.get("clock.hour24", true)
    readonly property bool seconds: Config.bar.get("clock.seconds", false)
    readonly property string dateFormat: Config.bar.get("clock.date", "")
    readonly property string format: (dateFormat !== "" ? dateFormat + "  " : "") + (hour24 ? "HH" : "h") + ":mm" + (seconds ? ":ss" : "") + (hour24 ? "" : " AP")

    color: textColor
    font.pixelSize: textSize
    font.family: Theme.fontFamily
    font.weight: Font.Bold

    function update() {
        text = Qt.formatDateTime(new Date(), format);
    }
    onFormatChanged: update()
    Component.onCompleted: update()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.update()
    }
}
