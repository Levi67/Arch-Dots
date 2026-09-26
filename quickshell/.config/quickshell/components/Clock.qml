// components/Clock.qml
import QtQuick
import "../theme"

Text {
    id: clock
    property color textColor: "black" // Allows you to set this from Bar.qml
    property int textSize: Theme.textSize
    
    color: textColor
    font.pixelSize: textSize
    
    // This updates the text automatically without needing an external 'date' process
    text: Qt.formatDateTime(new Date(), "hh:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
    }
}