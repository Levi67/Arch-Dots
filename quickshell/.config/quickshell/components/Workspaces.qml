import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"

Row {
    spacing: 8
    
    Repeater {
        model: [1, 2, 3, 4, 5]

        delegate: Rectangle {
            id: workspaceDot
            
            width: isFocused ? 24 : 12 
            height: 12
            radius: height / 2
            
            property bool isFocused: Hyprland.focusedWorkspace.id == modelData
            
            // Uses accent for the active pill, barBackground for inactive
            color: isFocused ? Theme.activeWorkspace : Theme.inactiveWorkspace
            
            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execute(["hyprctl", "dispatch", "workspace", modelData.toString()])
                }
            }
        }
    }
}