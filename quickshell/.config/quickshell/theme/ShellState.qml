// Shared UI state of the bar shell: which settings surfaces are open and where.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Nerd Font (Material Design) icons used by the status bubble, quick panel and settings
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property var icons: ({
            volHigh: 0xF057E, volMed: 0xF0580, volLow: 0xF057F, volOff: 0xF0581, mute: 0xF075F,
            mic: 0xF036C, micOff: 0xF036D, headphones: 0xF02CB, speaker: 0xF04C3,
            wifi: 0xF05A9, wifiOff: 0xF05AA, wifi1: 0xF091F, wifi2: 0xF0922, wifi3: 0xF0925, wifi4: 0xF0928,
            ethernet: 0xF0200, lan: 0xF0318,
            bt: 0xF00AF, btOff: 0xF00B2, btConn: 0xF00B1,
            night: 0xF0594, sun: 0xF0599, sunset: 0xF059A,
            cog: 0xF0493, snow: 0xF0717, palette: 0xF03D8, monitor: 0xF0379, power: 0xF0425,
            bolt: 0xF140B, speedo: 0xF04C5, leaf: 0xF032A, rocket: 0xF0463,
            close: 0xF0156, check: 0xF012C, lock: 0xF033E, refresh: 0xF0450, folder: 0xF024B,
            font: 0xF06D6, chevron: 0xF0142, app: 0xF003B, brightness: 0xF00DF, terminal: 0xF018D,
            plus: 0xF0415, minus: 0xF0374,
            rgb: 0xF1051, fan: 0xF0210, memory: 0xF035B, chip: 0xF061A, swap: 0xF04E1
        })
    function icon(name) {
        return String.fromCodePoint(icons[name] ?? 0x3F);
    }

    // quick panel (drops down from the status bubble)
    property bool quickOpen: false
    property var quickScreen: null

    // full settings overlay
    property bool settingsOpen: false
    property string settingsPage: "winter"
    property var settingsScreen: null

    function toggleQuick(screen) {
        if (quickOpen && quickScreen === screen) {
            quickOpen = false;
        } else {
            quickScreen = screen;
            quickOpen = true;
        }
    }

    function openSettings(page, screen) {
        if (page)
            settingsPage = page;
        settingsScreen = screen ?? quickScreen ?? null;
        quickOpen = false;
        settingsOpen = true;
    }
}
