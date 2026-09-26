import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
    id: root
    property string time

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            // Correct Quickshell Wayland properties
            WlrLayershell.namespace: "quickshell"
            //Wl.exclusiveZone: height 

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: layout.implicitHeight
            color: Theme.debugColor 

            // Replace RowLayout { id: layout ... } with this:
// Replace your RowLayout section with this:
Item {
    id: layout
    anchors.fill: parent
    
    // 1. Restore the height: Use the height of your tallest bubble + your vertical margins
    // If Theme.bubbleHeight isn't defined, you can use a fixed number like 40
    implicitHeight: (Theme.bubbleHeight || 40) + (Theme.verticalMargin * 2)

    // SECTION 1: Left Side (Workspaces)
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.sideMargin
        anchors.verticalCenter: parent.verticalCenter // Vertically centers the bubble in the bar
        
        Bubble {
            // Ensure padding is inside your Bubble component or add it here
            Workspaces { }
        }
    }

    // SECTION 2: Center (Clock) - DEAD CENTER
    Row {
        anchors.centerIn: parent // This ignores the sides and hits the exact middle
        
        Bubble {
            Clock {
                textColor: Theme.text
                textSize: Theme.textSize
            }
        }
    }

    // SECTION 3: Right Side (Balance)
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.sideMargin
        anchors.verticalCenter: parent.verticalCenter

        // To keep the clock perfectly centered, the right side 
        // should ideally have something here. 
        // If it's empty, the clock stays centered, but the bar looks lopsided.
        /*Bubble {
            Text { 
                text: "System" 
                color: Theme.text 
                font.pixelSize: Theme.textSize
            }
        }*/
    }
}
        }
    }
}