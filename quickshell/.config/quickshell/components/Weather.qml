// components/Weather.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 6

    // ---- settings ----
    property int refreshMinutes: 10

    property int textSize: Theme.textSize
    property string emojiFont: "Noto Color Emoji"

    // ---- state ----
    property real temp: NaN
    property int code: -1
    property bool isDay: true
    property real gust: 0
    property string unit: "celsius"

    // cached geocoding result so we only look the city up once
    property string geoName: ""
    property real geoLat: 0
    property real geoLon: 0

    // ---- config: .env (yours, not in git) falls back to .env.example (in git) ----
    FileView {
        id: envFile
        path: Quickshell.shellPath(".env")
        blockLoading: true
        printErrors: false
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
        const base = parseEnv(readFile(envExample));
        const mine = parseEnv(readFile(envFile));
        return Object.assign({}, base, mine);
    }

    // ---- networking ----
    function getJson(url, cb) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200)
                return;
            try {
                cb(JSON.parse(xhr.responseText));
            } catch (e) {}
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fetchWeather(lat, lon, unit) {
        const url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code,is_day,wind_gusts_10m" + "&temperature_unit=" + unit;
        getJson(url, data => {
            const c = data.current;
            if (!c)
                return;
            root.temp = c.temperature_2m;
            root.code = c.weather_code;
            root.isDay = c.is_day === 1;
            root.gust = c.wind_gusts_10m ?? 0;
            root.unit = unit;
        });
    }

    function refresh() {
        const cfg = loadConfig();
        const unit = (cfg.WEATHER_UNIT ?? "celsius").toLowerCase() === "fahrenheit" ? "fahrenheit" : "celsius";

        // exact coordinates in .env skip the city lookup
        if (cfg.WEATHER_LATITUDE && cfg.WEATHER_LONGITUDE) {
            fetchWeather(cfg.WEATHER_LATITUDE, cfg.WEATHER_LONGITUDE, unit);
            return;
        }

        const name = cfg.WEATHER_LOCATION;
        if (!name)
            return;

        if (geoName === name) {
            fetchWeather(geoLat, geoLon, unit);
            return;
        }

        getJson("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(name), data => {
            if (!data.results || data.results.length === 0)
                return;
            root.geoName = name;
            root.geoLat = data.results[0].latitude;
            root.geoLon = data.results[0].longitude;
            fetchWeather(root.geoLat, root.geoLon, unit);
        });
    }

    Timer {
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ---- WMO weather code -> emoji ----
    function emojiFor(code, isDay, gust) {
        if (code < 0)
            return "…";
        if (code === 96 || code === 99)
            return "🧊";              // thunderstorm with hail
        if (code === 95)
            return "⛈️";                              // thunderstorm
        if (gust >= 60)
            return "💨";                               // stormy / very windy
        if (code === 0)
            return isDay ? "☀️" : "🌙";               // clear
        if (code === 1)
            return isDay ? "🌤️" : "🌙";               // mostly clear
        if (code === 2)
            return "⛅";                               // partly cloudy
        if (code === 3)
            return "☁️";                               // overcast
        if (code === 45 || code === 48)
            return "🌫️";              // fog
        if (code >= 51 && code <= 57)
            return "🌦️";                // drizzle
        if (code >= 61 && code <= 67)
            return "🌧️";                // rain
        if (code >= 71 && code <= 77)
            return "❄️";                // snow
        if (code >= 80 && code <= 82)
            return "🌧️";                // rain showers
        if (code === 85 || code === 86)
            return "🌨️";              // snow showers
        return "🌡️";
    }

    Text {
        text: root.emojiFor(root.code, root.isDay, root.gust)
        font.pixelSize: root.textSize
        font.family: root.emojiFont
        height: Theme.bubbleHeight
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0      // nudge emoji: negative = up, positive = down
    }
    Text {
        text: isNaN(root.temp) ? "--" : Math.round(root.temp) + (root.unit === "fahrenheit" ? "°F" : "°C")
        color: Theme.text
        font.pixelSize: root.textSize - 2
        font.family: Theme.fontFamily
        font.weight: Font.Bold
        height: Theme.bubbleHeight
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0      // nudge temperature: negative = up, positive = down
    }
}
