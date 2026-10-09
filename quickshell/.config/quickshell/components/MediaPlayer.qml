import "../theme"
// components/MediaPlayer.qml
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets

Item {
    id: root

    // ---- settings ----
    property int barCount: 24
    // visual slots across the whole song
    property int cavaBands: 48
    // cava's internal frequency resolution
    property int barWidth: 3
    property int barSpacing: 3
    property int maxBarHeight: 18
    property int artSize: 22
    property int iconSize: 12
    property real seekStep: 10 // seconds per scroll tick (mouse wheel notch)
    property real pendingSeek: 0 // accumulated seconds, applied after scrolling stops
    // ---- find Spotify ----
    readonly property var player: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            if ((p.identity ?? "").toLowerCase().includes("spotify") || (p.dbusName ?? "").toLowerCase().includes("spotify"))
                return p;
        }
        return null;
    }
    readonly property bool playing: player !== null && player.isPlaying
    // ---- progress ----
    // position shown in the UI: real position + not-yet-applied scroll
    readonly property real displayPosition: {
        if (!player)
            return 0;

        const pos = player.position + pendingSeek;
        return player.length > 0 ? Math.min(player.length, Math.max(0, pos)) : Math.max(0, pos);
    }
    readonly property real progress: (player && player.length > 0) ? Math.min(1, Math.max(0, displayPosition / player.length)) : 0
    // first bar appears at 0:01, then grows with progress
    readonly property int playedBars: (player && displayPosition >= 1) ? Math.min(barCount, Math.max(1, Math.ceil(progress * barCount))) : 0
    readonly property int barStep: barWidth + barSpacing
    readonly property int barsTotalWidth: barCount * barStep - barSpacing
    // ---- cava ----
    property var levels: []

    // Squeeze the full spectrum into `played` bars: bar i covers a slice of bands
    function levelFor(i, played) {
        if (!levels || levels.length === 0 || played <= 0)
            return 0;

        const n = levels.length;
        const start = Math.floor(i * n / played);
        const end = Math.max(start + 1, Math.floor((i + 1) * n / played));
        let sum = 0, max = 0;
        for (let k = start; k < end && k < n; k++) {
            const v = levels[k] ?? 0;
            sum += v;
            if (v > max)
                max = v;
        }
        const avg = sum / (end - start);
        return Math.min(1, (avg * 0.5 + max * 0.5) / 100);
    }

    visible: player !== null
    implicitHeight: artSize
    implicitWidth: visible ? row.implicitWidth : 0

    // MPRIS position isn't pushed automatically, so poll while playing
    Timer {
        interval: 500
        running: root.playing
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // Applies the accumulated scroll once, after scrolling has stopped
    Timer {
        id: seekDebounce

        interval: 100 // ms of no scrolling before the seek happens
        repeat: false
        onTriggered: {
            const amount = root.pendingSeek;
            root.pendingSeek = 0;
            if (root.player && root.player.canSeek && amount !== 0) {
                root.player.seek(amount);
                root.player.positionChanged();
            }
        }
    }

    // Re-read the position right after the track changes (it's cached otherwise)
    Connections {
        function onTrackChanged() {
            seekDebounce.stop();
            root.pendingSeek = 0;
            root.player.positionChanged();
            postSkipRefresh.restart();
        }

        target: root.player
    }

    // Spotify sometimes reports the new position a moment late, so refresh again
    Timer {
        id: postSkipRefresh

        interval: 250
        repeat: false
        onTriggered: {
            if (root.player) {
                root.player.positionChanged();
            }
        }
    }

    Process {
        id: cava

        running: root.playing
        command: ["sh", "-c", "cat > /tmp/qs_cava.conf <<'EOF'\n" + "[general]\nbars = " + root.cavaBands + "\nframerate = 30\n" + "[output]\nmethod = raw\nraw_target = /dev/stdout\n" + "data_format = ascii\nascii_max_range = 100\n" + "bar_delimiter = 59\nframe_delimiter = 10\n" + "EOF\nexec cava -p /tmp/qs_cava.conf"]

        stdout: SplitParser {
            onRead: data => {
                return root.levels = data.split(";").map(Number);
            }
        }
    }

    // ---- layout ----
    Row {
        id: row

        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        // Song icon
        ClippingRectangle {
            width: root.artSize
            height: root.artSize
            radius: 6
            color: Theme.inactiveWorkspace

            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // Progress area: cava bars (played) + straight line (remaining)
        Item {
            width: root.barsTotalWidth
            height: root.maxBarHeight
            anchors.verticalCenter: parent.verticalCenter

            // played part -> live cava bars
            Row {
                id: playedRow

                spacing: root.barSpacing
                height: parent.height

                Repeater {
                    model: root.playedBars

                    Rectangle {
                        required property int index
                        readonly property real level: root.playing ? root.levelFor(index, root.playedBars) : 0

                        width: root.barWidth
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        height: Math.max(3, level * root.maxBarHeight)
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation {
                                duration: 60
                            }
                        }
                    }
                }
            }

            // remaining part -> one straight line
            Rectangle {
                x: root.playedBars * root.barStep
                width: Math.max(0, root.barsTotalWidth - x)
                height: 3
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inactiveWorkspace
                visible: width > 0
            }
        }

        // Play / pause indicator
        Item {
            width: root.iconSize
            height: root.iconSize
            anchors.verticalCenter: parent.verticalCenter

            // play triangle
            Shape {
                anchors.fill: parent
                visible: !root.playing
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Theme.text
                    strokeColor: "transparent"
                    startX: 2
                    startY: 0

                    PathLine {
                        x: root.iconSize
                        y: root.iconSize / 2
                    }

                    PathLine {
                        x: 2
                        y: root.iconSize
                    }

                    PathLine {
                        x: 2
                        y: 0
                    }
                }
            }

            // pause bars
            Row {
                anchors.centerIn: parent
                spacing: 3
                visible: root.playing

                Rectangle {
                    width: 3
                    height: root.iconSize
                    radius: 1
                    color: Theme.text
                }

                Rectangle {
                    width: 3
                    height: root.iconSize
                    radius: 1
                    color: Theme.text
                }
            }
        }
    }

    // ---- interaction (extends over the whole bubble padding) ----
    MouseArea {
        anchors.fill: parent
        anchors.margins: -(Theme.padding * 2)
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (!root.player)
                return;

            if (mouse.button === Qt.RightButton) {
                if (root.player.canGoNext) {
                    root.pendingSeek = 0;
                    root.player.next();
                    postSkipRefresh.restart();
                }
            } else {
                if (root.player.canTogglePlaying)
                    root.player.togglePlaying();
            }
        }
        onWheel: wheel => {
            if (!root.player || !root.player.canSeek)
                return;

            // proportional: a mouse notch is 120, touchpads send smaller values
            const next = root.pendingSeek + wheel.angleDelta.y / 120 * root.seekStep;
            // clamp so scrolling past the start/end doesn't build up a dead zone
            const maxForward = root.player.length > 0 ? root.player.length - root.player.position : Infinity;
            root.pendingSeek = Math.min(maxForward, Math.max(-root.player.position, next));
            seekDebounce.restart();
        }
    }
}
