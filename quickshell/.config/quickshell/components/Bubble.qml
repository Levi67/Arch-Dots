// components/Bubble.qml
import QtQuick
import "../theme"

Rectangle {
    id: bubbleRoot
    
    default property alias content: container.data 

    property int cornerRadius: 15
    property int horizontalPadding: Theme.padding * 2
    
    color: Theme.barBackground
    radius: height / 2 // Perfect pill shape
    
    // Force the height to match the Theme exactly
    height: Theme.bubbleHeight 
    width: container.implicitWidth + (horizontalPadding * 2)

    Row {
        id: container
        anchors.centerIn: parent
        spacing: 5
    }
}