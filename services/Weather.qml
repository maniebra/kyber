pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in — no API key, no daemon. Location auto-detected by IP
// unless WEATHER_LOCATION is set (e.g. "Tehran").
Singleton {
    id: root

    property int temp: 0
    property string condition: ""
    property string location: ""
    property bool ready: false

    readonly property string place: Quickshell.env("WEATHER_LOCATION") ?? ""

    // nerd-font glyph per wttr condition bucket
    readonly property string icon: {
        const c = condition.toLowerCase();
        if (c.includes("thunder")) return "";
        if (c.includes("snow") || c.includes("sleet")) return "";
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return "";
        if (c.includes("fog") || c.includes("mist")) return "";
        if (c.includes("overcast")) return "";
        if (c.includes("cloud")) return "";
        return "";
    }

    Process {
        id: fetch

        command: ["curl", "-sf", "--max-time", "10",
                  `https://wttr.in/${root.place}?format=j1`]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "")
                    return;
                try {
                    const cur = JSON.parse(text).current_condition[0];
                    root.temp = parseInt(cur.temp_C);
                    root.condition = cur.weatherDesc[0].value;
                    const a = JSON.parse(text).nearest_area?.[0];
                    root.location = a?.areaName?.[0]?.value ?? root.place;
                    root.ready = true;
                } catch (e) {
                    // leave the last good reading on screen
                }
            }
        }
    }

    Timer {
        interval: 900000 // 15 min; wttr.in asks callers not to hammer it
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }
}
