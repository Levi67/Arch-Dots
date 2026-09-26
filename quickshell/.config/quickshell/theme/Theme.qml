// This is a template! Wallust will turn this into your real Theme.qml
import QtQuick

pragma Singleton

QtObject {
    // Colors from Wallust
    // Takes the generated background and makes it 15% darker
    readonly property color background: "#000000"
    
    // You can also mix in transparency after darkening
    // This results in #66000000
    readonly property color barBackground: "#88000000"


    readonly property color accent: "#541A1F"
    readonly property color text: "#FEE7DA"
    readonly property color inactiveWorkspace: "#360E0C"
    



    // Spacing & Sizing
    //readonly property int barHeight: 40


    readonly property int bubbleHeight: 30


    readonly property int padding: 8
    readonly property int fontSize: 13

    // Text properties
    readonly property int textSize: 20

    // theme/Theme.qml
    readonly property int gapSize: 5
    readonly property int barPadding: 8

    readonly property color activeWorkspace: "#FFFFFF"
    // readonly property color inactiveWorkspace: '#9393c3'


    // theme/Theme.qml
    // ... your colors ...

    // The actual height of the pill/bubble
    readonly property int barHeight: 26 

    // The transparent space above and below the bubble
    readonly property int verticalMargin: 8

    // The space from the screen edges (Left/Right)
    readonly property int sideMargin: 10 

    // The space between different bubbles
    readonly property int bubbleSpacing: 12

    //readonly property color debugColor: "#66bc4242"

    readonly property color debugColor: "transparent"
}