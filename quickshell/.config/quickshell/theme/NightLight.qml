// Night light: runs hyprsunset while it should be on.
// Settings: Config.power nightLight { schedule: manual|times|sun, enabled, temperature, from, to }
//   manual - on while `enabled`
//   times  - on between `from` and `to` (HH:MM, may wrap past midnight)
//   sun    - on from sunset to sunrise at the weather location (bar.json -> weather)
// toggle() flips it right now; in a schedule mode that lasts until the next switch-over.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string schedule: Config.power.get("nightLight.schedule", "manual")
    readonly property bool manualOn: Config.power.get("nightLight.enabled", false)
    readonly property int temperature: Math.max(1000, Math.min(6500, Config.power.get("nightLight.temperature", 4000)))
    readonly property string from: Config.power.get("nightLight.from", "21:00")
    readonly property string to: Config.power.get("nightLight.to", "07:00")

    property bool available: false             // hyprsunset installed?
    property bool scheduledOn: false
    property var override: null                // true/false = manual flip until the next switch-over
    property var sun: null                     // { rise: Date, set: Date } for today
    property real lat: NaN
    property real lon: NaN

    readonly property bool active: schedule === "manual" ? manualOn : (override !== null ? override : scheduledOn)

    function toggle() {
        if (schedule === "manual")
            Config.power.set("nightLight.enabled", !manualOn);
        else
            override = !active;
    }

    // ---- schedule ----
    function minutes(hhmm) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(String(hhmm).trim());
        return m ? (+m[1]) * 60 + (+m[2]) : -1;
    }

    function inWindow(now, a, b) {
        if (a < 0 || b < 0 || a === b)
            return false;
        return a < b ? (now >= a && now < b) : (now >= a || now < b);
    }

    function evaluate() {
        const d = new Date();
        const now = d.getHours() * 60 + d.getMinutes();
        let on = false;
        if (schedule === "times") {
            on = inWindow(now, minutes(from), minutes(to));
        } else if (schedule === "sun") {
            if (!isNaN(lat)) {
                sun = sunTimes(d, lat, lon);
                if (sun)
                    on = d < sun.rise || d >= sun.set;
            }
        }
        if (on !== scheduledOn) {
            scheduledOn = on;
            override = null;            // a switch-over ends any manual flip
        }
    }

    onScheduleChanged: {
        override = null;
        if (schedule === "sun")
            locate();
        evaluate();
    }
    onFromChanged: evaluate()
    onToChanged: evaluate()

    Timer {
        interval: 30000
        repeat: true
        running: root.schedule !== "manual"
        triggeredOnStart: true
        onTriggered: root.evaluate()
    }

    // ---- sunrise / sunset (the SunCalc algorithm) ----
    function sunTimes(date, lat, lon) {
        const rad = Math.PI / 180, dayMs = 86400000, J1970 = 2440588, J2000 = 2451545;
        const local = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12);
        const d = local.valueOf() / dayMs - 0.5 + J1970 - J2000;
        const lw = -lon * rad, phi = lat * rad;
        const n = Math.round(d - 0.0009 - lw / (2 * Math.PI));
        const ds = 0.0009 + lw / (2 * Math.PI) + n;
        const M = rad * (357.5291 + 0.98560028 * ds);
        const C = rad * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M));
        const L = M + C + rad * 102.9372 + Math.PI;
        const dec = Math.asin(Math.sin(L) * Math.sin(rad * 23.4397));
        const transit = J2000 + ds + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
        const cosw = (Math.sin(-0.833 * rad) - Math.sin(phi) * Math.sin(dec)) / (Math.cos(phi) * Math.cos(dec));
        if (cosw < -1 || cosw > 1)
            return null;            // polar day/night
        const w = Math.acos(cosw);
        const set = J2000 + 0.0009 + (w + lw) / (2 * Math.PI) + n + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
        const rise = transit - (set - transit);
        const toDate = j => new Date((j + 0.5 - J1970) * dayMs);
        return {
            rise: toDate(rise),
            set: toDate(set)
        };
    }

    // coordinates: exact ones from the weather settings, else look the city up once
    readonly property var weather: Config.bar.get("weather", ({}))
    onWeatherChanged: if (schedule === "sun")
        locate()

    function locate() {
        const w = weather;
        if (typeof w.latitude === "number" && typeof w.longitude === "number") {
            lat = w.latitude;
            lon = w.longitude;
            evaluate();
            return;
        }
        if (!w.location)
            return;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200)
                return;
            try {
                const r = JSON.parse(xhr.responseText).results[0];
                root.lat = r.latitude;
                root.lon = r.longitude;
                root.evaluate();
            } catch (e) {}
        };
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(w.location));
        xhr.send();
    }

    // ---- hyprsunset ----
    // is it installed? also stop a leftover hyprsunset (e.g. from before a Quickshell restart),
    // so the screen is only warm while `active` says so
    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset >/dev/null || exit 1; pkill -x hyprsunset; exit 0"]
        onExited: code => root.available = code === 0
    }

    // runs exactly while night light is on (never set `running` by hand: that would break this binding)
    Process {
        id: sunset
        running: root.available && root.active
        command: ["hyprsunset", "-t", String(root.temperature)]
    }

    // new warmth while it's on: tell the running hyprsunset over its IPC (no restart, no flicker)
    Process {
        id: setTemp
    }
    onTemperatureChanged: if (sunset.running) {
        // command set here, not bound: a binding might still hold the old value at this point
        setTemp.command = ["hyprctl", "hyprsunset", "temperature", String(temperature)];
        setTemp.running = true;
    }
}
