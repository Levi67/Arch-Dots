// components/WallpaperPicker.qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../theme"

Scope {
    id: root

    // ---- settings ----
    property int columns: 4
    property int cardWidth: 980
    property int cardHeight: 640
    property real scrollStep: 480        // pixels per mouse-wheel notch (bigger = faster)
    readonly property var imageExts: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]
    readonly property var videoExts: ["mp4", "webm", "mkv", "mov"]

    // ---- state ----
    property bool shown: false
    property var targetScreen: null
    property string wallpaperDir: ""     // from .env (WALLPAPER_DIR)
    property string backend: ""          // from .env (WALLPAPER_BACKEND), optional
    property string query: ""
    property var files: []               // [{ path, rel, name, folder, video }]
    property var scanBuffer: []
    property string filesKey: ""         // fingerprint of the file list, to skip needless updates
    property int thumbRev: 0             // goes up every time the thumbnail cache was (re)built

    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wallpaper/thumbs"

    // every word of the search must appear in the path (folder names count too)
    readonly property var filtered: {
        const words = query.toLowerCase().split(/\s+/).filter(w => w.length > 0);
        if (words.length === 0)
            return files;
        return files.filter(f => words.every(w => f.rel.toLowerCase().includes(w)));
    }

    // ---- config: .env (yours) over .env.example (in git) ----
    FileView {
        id: envFile
        path: Quickshell.shellPath(".env")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }
    FileView {
        id: envExample
        path: Quickshell.shellPath(".env.example")
        blockLoading: true
        printErrors: false
    }

    function parseEnv(text) {
        const out = {};
        for (const raw of (text ?? "").split("\n")) {
            const line = raw.trim();
            if (!line || line.startsWith("#"))
                continue;
            const eq = line.indexOf("=");
            if (eq < 1)
                continue;
            out[line.slice(0, eq).trim()] = line.slice(eq + 1).trim().replace(/^["']|["']$/g, "");
        }
        return out;
    }

    function readFile(view) {
        try {
            return view.text();
        } catch (e) {
            return "";
        }
    }

    function loadConfig() {
        const cfg = Object.assign({}, parseEnv(readFile(envExample)), parseEnv(readFile(envFile)));
        let dir = cfg.WALLPAPER_DIR ?? "";
        if (dir.startsWith("~"))
            dir = Quickshell.env("HOME") + dir.slice(1);
        wallpaperDir = dir.replace(/\/+$/, "");
        backend = cfg.WALLPAPER_BACKEND ?? "";
    }

    // ---- scanning the folder (including subfolders) ----
    function buildFindCommand() {
        const args = ["find", "-L", wallpaperDir, "-type", "f", "("];
        const exts = imageExts.concat(videoExts);
        exts.forEach((e, i) => {
            if (i > 0)
                args.push("-o");
            args.push("-iname", "*." + e);
        });
        args.push(")");
        return args;
    }

    Process {
        id: scan
        command: root.buildFindCommand()
        stdout: SplitParser {
            onRead: line => {
                if (line)
                    root.scanBuffer.push(line);
            }
        }
        onExited: {
            const dir = root.wallpaperDir;
            const list = root.scanBuffer.map(p => {
                const rel = p.startsWith(dir + "/") ? p.slice(dir.length + 1) : p;
                const parts = rel.split("/");
                const file = parts[parts.length - 1];
                const dot = file.lastIndexOf(".");
                const ext = dot >= 0 ? file.slice(dot + 1).toLowerCase() : "";
                return {
                    path: p,
                    rel: rel,
                    name: dot > 0 ? file.slice(0, dot) : file,
                    folder: parts.length > 1 ? parts.slice(0, -1).join("/") : "",
                    video: root.videoExts.includes(ext)
                };
            });
            list.sort((a, b) => a.rel.toLowerCase().localeCompare(b.rel.toLowerCase()));

            const key = list.map(f => f.path).join("\n");
            if (key !== root.filesKey) {
                root.filesKey = key;
                root.files = list;
                thumbs.running = true;      // new/removed files -> update the thumbnail cache
            }
        }
    }

    // Thumbnail cache: a small 480px jpg per wallpaper (images AND videos),
    // named by the md5 of the path. Existing ones are skipped, 4 run in parallel.
    Process {
        id: thumbs
        command: ["sh", "-c", `
            mkdir -p "$2"
            export THUMB_DIR="$2"
            find -L "$1" -type f -print0 | xargs -0 -P 4 -n 1 sh -c '
                f="$1"
                h=$(printf "%s" "$f" | md5sum | cut -d" " -f1)
                out="$THUMB_DIR/$h.jpg"
                [ -s "$out" ] && exit 0
                if printf "%s" "$f" | grep -qiE "[.](mp4|webm|mkv|mov)$"; then
                    ffmpeg -nostdin -loglevel error -y -ss 3 -i "$f" -frames:v 1 -vf scale=480:-2 -q:v 4 "$out" \\
                        || ffmpeg -nostdin -loglevel error -y -i "$f" -frames:v 1 -vf scale=480:-2 -q:v 4 "$out"
                elif printf "%s" "$f" | grep -qiE "[.](jpg|jpeg|png|webp|bmp|gif)$"; then
                    ffmpeg -nostdin -loglevel error -y -i "$f" -frames:v 1 -vf scale=480:-2 -q:v 4 "$out"
                fi
                [ -s "$out" ] || rm -f "$out"
            ' _
        `, "sh", root.wallpaperDir, root.thumbDir]
        onExited: root.thumbRev++
    }

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function cacheUrl(path) {
        return fileUrl(thumbDir + "/" + Qt.md5(path) + ".jpg");
    }

    // ---- open / close / apply ----
    function openPicker() {
        loadConfig();

        // show on the monitor that currently has focus
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === mon.name) {
                    targetScreen = Quickshell.screens[i];
                    break;
                }
            }
        }

        search.text = "";
        shown = true;

        if (wallpaperDir !== "") {
            scanBuffer = [];
            scan.running = true;      // only changes the list if files were added/removed
        }
    }

    // build the list and the thumbnail cache at startup, so the first open is instant too
    Component.onCompleted: {
        loadConfig();
        if (wallpaperDir !== "") {
            scanBuffer = [];
            scan.running = true;
        }
    }

    function closePicker() {
        shown = false;
    }

    function apply(i) {
        const f = filtered[i];
        if (!f)
            return;
        const cmd = ["waypaper", "--wallpaper", f.path];
        if (backend !== "")
            cmd.push("--backend", backend);
        applyProc.command = cmd;
        applyProc.running = true;
        closePicker();
    }

    // waypaper sets the wallpaper and runs your post_command (wallpaper-save) -> theme update
    Process {
        id: applyProc
    }

    // qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.shown ? root.closePicker() : root.openPicker();
        }
        function open(): void {
            root.openPicker();
        }
        function close(): void {
            root.closePicker();
        }
    }

    // ---- the popup ----
    PanelWindow {
        id: win
        visible: root.shown
        screen: root.targetScreen ?? Quickshell.screens[0]
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell-wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible)
            search.forceActiveFocus()

        // dimmed backdrop, click outside = close
        Rectangle {
            anchors.fill: parent
            color: "#99000000"
            MouseArea {
                anchors.fill: parent
                onClicked: root.closePicker()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(root.cardWidth, parent.width - 80)
            height: Math.min(root.cardHeight, parent.height - 80)
            radius: 20
            color: Theme.background
            border.width: 1
            border.color: Theme.inactiveWorkspace

            // swallow clicks so the backdrop doesn't close the popup
            MouseArea {
                anchors.fill: parent
            }

            // fast, smooth wheel scrolling (the grid's own wheel handling is too slow)
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const min = grid.originY;
                    const max = Math.max(min, grid.originY + grid.contentHeight - grid.height);
                    const next = grid.contentY - event.angleDelta.y / 120 * root.scrollStep;
                    grid.contentY = Math.min(max, Math.max(min, next));
                }
            }

            // ---- search bar ----
            Rectangle {
                id: searchBox
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                }
                height: 46
                radius: height / 2
                color: Theme.barBackground

                Text {
                    id: searchIcon
                    anchors {
                        left: parent.left
                        leftMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    text: "\udb80\udf49"
                    color: Theme.accent
                    font.pixelSize: Theme.fontSize + 4
                    font.family: Theme.fontFamily
                }

                TextInput {
                    id: search
                    anchors {
                        left: searchIcon.right
                        leftMargin: 12
                        right: parent.right
                        rightMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    selectionColor: Theme.accent
                    font.pixelSize: Theme.fontSize + 2
                    font.family: Theme.fontFamily
                    clip: true
                    focus: true

                    onTextChanged: {
                        root.query = text;
                        grid.currentIndex = 0;
                    }

                    // arrows move through the grid while you keep typing
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            grid.moveCurrentIndexDown();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            grid.moveCurrentIndexUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            grid.moveCurrentIndexLeft();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            grid.moveCurrentIndexRight();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.apply(grid.currentIndex);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.closePicker();
                            event.accepted = true;
                        }
                    }

                    Text {
                        visible: search.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search wallpapers (file or folder name)…"
                        color: Theme.inactiveWorkspace
                        font: search.font
                    }
                }
            }

            // ---- grid ----
            GridView {
                id: grid
                anchors {
                    top: searchBox.bottom
                    topMargin: 14
                    left: parent.left
                    leftMargin: 14
                    right: parent.right
                    rightMargin: 14
                    bottom: footer.top
                    bottomMargin: 6
                }
                clip: true
                interactive: false                 // wheel is handled by the WheelHandler on the card
                cacheBuffer: 1600                  // create tiles ahead of time -> no pop-in while scrolling
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.floor(width / root.columns)
                cellHeight: Math.round(cellWidth * 0.58) + 50
                model: root.filtered
                currentIndex: 0
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                Behavior on contentY {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool current: GridView.isCurrentItem
                    property bool useFallback: false   // cache file missing -> load the original

                    // cache was rebuilt -> try the cached thumbnail again
                    Connections {
                        target: root
                        function onThumbRevChanged() {
                            cell.useFallback = false;
                        }
                    }

                    width: grid.cellWidth
                    height: grid.cellHeight

                    ClippingRectangle {
                        id: thumb
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 6
                        }
                        height: grid.cellHeight - 50
                        radius: 12
                        color: Theme.inactiveWorkspace
                        border.width: cell.current ? 3 : 0
                        border.color: Theme.accent

                        Image {
                            id: img
                            anchors.fill: parent
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 480
                            source: cell.useFallback ? (cell.modelData.video ? "" : root.fileUrl(cell.modelData.path)) : root.cacheUrl(cell.modelData.path)
                            onStatusChanged: if (status === Image.Error && !cell.useFallback)
                                cell.useFallback = true
                        }

                        // shown for videos without a thumbnail (yet)
                        Text {
                            anchors.centerIn: parent
                            visible: cell.modelData.video && img.status !== Image.Ready
                            text: "▶"
                            color: Theme.text
                            font.pixelSize: 28
                        }

                        // small badge on every video
                        Rectangle {
                            visible: cell.modelData.video
                            anchors {
                                top: parent.top
                                right: parent.right
                                margins: 8
                            }
                            width: 24
                            height: 24
                            radius: 12
                            color: "#99000000"
                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                color: "white"
                                font.pixelSize: 10
                            }
                        }
                    }

                    Text {
                        anchors {
                            top: thumb.bottom
                            topMargin: 4
                            left: thumb.left
                            right: thumb.right
                        }
                        text: cell.modelData.name
                        elide: Text.ElideRight
                        color: cell.current ? Theme.accent : Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        anchors {
                            top: thumb.bottom
                            topMargin: 24
                            left: thumb.left
                            right: thumb.right
                        }
                        text: cell.modelData.folder
                        elide: Text.ElideLeft
                        color: Theme.inactiveWorkspace
                        font.pixelSize: Theme.fontSize - 2
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = cell.index
                        onClicked: root.apply(cell.index)
                    }
                }
            }

            // ---- empty states ----
            Text {
                anchors.centerIn: grid
                visible: root.wallpaperDir === ""
                text: "No wallpaper folder set.\nAdd WALLPAPER_DIR=... to your .env"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.inactiveWorkspace
                font.pixelSize: Theme.fontSize + 2
                font.family: Theme.fontFamily
            }
            Text {
                anchors.centerIn: grid
                visible: root.wallpaperDir !== "" && !scan.running && root.filtered.length === 0
                text: root.files.length === 0 ? "No wallpapers found in\n" + root.wallpaperDir : "No match"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.inactiveWorkspace
                font.pixelSize: Theme.fontSize + 2
                font.family: Theme.fontFamily
            }

            // ---- footer ----
            Item {
                id: footer
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 16
                }
                height: 22

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.filtered.length + " / " + root.files.length + " wallpapers" + (scan.running ? "  ·  scanning…" : "") + (thumbs.running ? "  ·  building thumbnail cache…" : "")
                    color: Theme.inactiveWorkspace
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                }
                Text {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: "↑ ↓ ← →  navigate    ⏎  set    esc  close"
                    color: Theme.inactiveWorkspace
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                }
            }
        }
    }
}
