// One settings area: defaults/<name>.json (shipped in the repo) overlaid with
// ~/.config/desktop/<name>.json (local, untracked; only holds what you changed).
//   data              merged view, bind to this
//   get("a.b", def)   read a value from the merged view
//   set("a.b", v)     change a value; saved immediately (removed again if it equals the default)
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property string name
    required property string defaultsDir
    required property string liveDir

    property var defaults: ({})
    property var local: ({})
    readonly property var data: merge(defaults, local)

    function isObj(v) {
        return v !== null && typeof v === "object" && !Array.isArray(v);
    }

    function merge(a, b) {
        if (!isObj(a) || !isObj(b))
            return b === undefined ? a : b;
        const out = Object.assign({}, a);
        for (const k in b)
            out[k] = (k in a) ? merge(a[k], b[k]) : b[k];
        return out;
    }

    function walk(obj, parts) {
        let o = obj;
        for (const p of parts) {
            if (o === null || o === undefined || typeof o !== "object")
                return undefined;
            o = o[p];
        }
        return o;
    }

    function get(path, def) {
        const v = walk(data, path.split("."));
        return v === undefined || v === null ? def : v;
    }

    function set(path, value) {
        const parts = path.split(".");
        const next = JSON.parse(JSON.stringify(local));
        const same = JSON.stringify(walk(defaults, parts)) === JSON.stringify(value);

        // walk down, creating objects; remember the chain so empty parents can be pruned
        const chain = [next];
        let o = next;
        for (let i = 0; i < parts.length - 1; ++i) {
            if (!isObj(o[parts[i]])) {
                if (same)
                    return writeIfChanged(next);
                o[parts[i]] = {};
            }
            o = o[parts[i]];
            chain.push(o);
        }
        const key = parts[parts.length - 1];
        if (same) {
            delete o[key];
            for (let i = chain.length - 1; i > 0; --i)
                if (Object.keys(chain[i]).length === 0)
                    delete chain[i - 1][parts[i - 1]];
        } else {
            o[key] = value;
        }
        writeIfChanged(next);
    }

    function writeIfChanged(next) {
        const text = JSON.stringify(next, null, 2) + "\n";
        if (text === JSON.stringify(local, null, 2) + "\n")
            return;
        local = next;
        liveFile.setText(text);
    }

    function parse(view, apply) {
        let text = "";
        try {
            text = view.text();
        } catch (e) {}
        if (text.trim() === "") {
            apply({});
            return true;
        }
        try {
            apply(JSON.parse(text));
            return true;
        } catch (e) {
            return false;
        }
    }

    FileView {
        id: defFile
        path: root.defaultsDir + "/" + root.name + ".json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(defFile, v => root.defaults = v)
    }

    FileView {
        id: liveFile
        path: root.liveDir + "/" + root.name + ".json"
        watchChanges: true
        printErrors: false
        atomicWrites: false
        onFileChanged: reload()
        onLoaded: {
            // usually caught mid-write by another program (winterctl); look again shortly
            if (!root.parse(liveFile, v => root.local = v) && retry.attempts++ < 10)
                retry.restart();
            else
                retry.attempts = 0;
        }
        onLoadFailed: root.local = ({})
    }

    Timer {
        id: retry
        property int attempts: 0
        interval: 150
        onTriggered: liveFile.reload()
    }
}
