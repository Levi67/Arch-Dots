// Frosted glass + snow-globe flakes inside a bar bubble (behind its content).
import QtQuick
import "../../theme"

ShaderEffect {
    id: root

    property real radius: height / 2

    readonly property real time: Winter.clock
    readonly property real count: Math.min(32, Math.max(3, Math.round(width * height / 420 * Winter.barFlakeDensity)))
    readonly property real seed: Math.random() * 100
    readonly property real frost: Winter.barFrost
    readonly property vector2d size: Qt.vector2d(width, height)

    fragmentShader: Qt.resolvedUrl("shaders/bubbleflakes.frag.qsb")
}
