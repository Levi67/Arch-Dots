// This is a template! Wallust will turn this into your real Theme.qml
pragma Singleton
import QtQuick

QtObject {
    // Colors (Clean, modern dark-mode aesthetic)
    readonly property color background: "#11111b"     // Deep, rich dark base (Catppuccin Crust style)
    readonly property color barBackground: "#bb181825" // Semi-transparent layered dark glass

    readonly property color accent: '#8ba3f3'          // Soft, vibrant rose/coral accent
    readonly property color text: "#cdd6f4"            // Soft, high-readability off-white text
    readonly property color inactiveWorkspace: "#6c7086" // Muted slate gray for background items

    // Spacing & Sizing
    readonly property int bubbleHeight: 30
    readonly property int padding: 8
    readonly property int fontSize: 13

    // Text properties
    readonly property int textSize: 20

    // theme/Theme.qml
    readonly property int gapSize: 5
    readonly property int barPadding: 8

    readonly property color activeWorkspace: "#FFFFFF" // Pure white for active focus

    // The actual height of the pill/bubble
    readonly property int barHeight: 26

    // The transparent space above and below the bubble
    readonly property int verticalMargin: 8

    // The space from the screen edges (Left/Right)
    readonly property int sideMargin: 10

    // The space between different bubbles
    readonly property int bubbleSpacing: 12

    readonly property color debugColor: "transparent"
}
