// This is a template! Wallust will turn this into your real Theme.qml
import QtQuick

pragma Singleton

QtObject {
    // --- DYNAMIC WALLUST COLORS ---
    // Using Wallust variables ensures it adapts to your wallpaper automatically.
    
    // Deep, tinted background derived from your wallpaper with a touch of darkness
    readonly property color background: "{{background}}"
    
    // Semi-transparent bar background for that clean glass/blur look
    // (Using a dark semi-transparent fallback overlay keeps readability high)
    readonly property color barBackground: "{{background | strip | blend('#000000', 0.4) | alpha(0.75)}}"

    // Primary accent color (grabs a vibrant mid-tone from your wallpaper)
    readonly property color accent: "{{color2}}"

    // High-contrast text color for readability against dark or light elements
    readonly property color text: "{{foreground}}"

    // Workspace & UI states
    readonly property color activeWorkspace: "{{color4}}"
    readonly property color inactiveWorkspace: "{{color8}}"

    // --- SPACING & SIZING (Kept exactly as you like them) ---
    readonly property int bubbleHeight: 30
    readonly property int padding: 8
    readonly property int fontSize: 13
    readonly property int textSize: 20
    readonly property int gapSize: 5
    readonly property int barPadding: 8

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