pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool shamsiPrimary: false

    readonly property var monthsFa: [
        "Farvardin", "Ordibehesht", "Khordad", "Tir", "Mordad", "Shahrivar",
        "Mehr", "Aban", "Azar", "Dey", "Bahman", "Esfand"
    ]

    readonly property var weekdaysFa: [
        "Sha", "Yek", "Do", "Se", "Cha", "Pan", "Jom"
    ]

    function div(a, b) {
        return Math.trunc(a / b);
    }

    function mod(a, b) {
        return a - b * div(a, b);
    }

    function g2d(gy, gm, gd) {
        let d = div((gy + div(gm - 8, 6) + 100100) * 1461, 4)
            + div(153 * mod(gm + 9, 12) + 2, 5) + gd - 34840408;
        return d - div(div(gy + 100100 + div(gm - 8, 6), 100) * 3, 4) + 752;
    }

    function d2g(jdn) {
        let j = 4 * jdn + 139361631;
        j += div(div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
        const i = div(mod(j, 1461), 4) * 5 + 308;
        const gd = div(mod(i, 153), 5) + 1;
        const gm = mod(div(i, 153), 12) + 1;
        return {
            y: div(j, 1461) - 100100 + div(8 - gm, 6),
            m: gm,
            d: gd
        };
    }

    function jalCal(jy) {
        const breaks = [-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
                        1635, 1701, 1866, 2020, 2620, 3202, 3502, 3735, 3982, 4643];
        const gy = jy + 621;
        let leapJ = -14;
        let jp = breaks[0];
        let jump = 0;

        for (let i = 1; i < breaks.length; i++) {
            const jm = breaks[i];
            jump = jm - jp;
            if (jy < jm)
                break;
            leapJ += div(jump, 33) * 8 + div(mod(jump, 33), 4);
            jp = jm;
        }

        let n = jy - jp;
        leapJ += div(n, 33) * 8 + div(mod(n, 33) + 3, 4);
        if (mod(jump, 33) === 4 && jump - n === 4)
            leapJ += 1;

        const leapG = div(gy, 4) - div((div(gy, 100) + 1) * 3, 4) - 150;
        const march = 20 + leapJ - leapG;

        if (jump - n < 6)
            n = n - jump + div(jump + 4, 33) * 33;

        let leap = mod(mod(n + 1, 33) - 1, 4);
        if (leap === -1)
            leap = 4;

        return { leap: leap, gy: gy, march: march };
    }

    function j2d(jy, jm, jd) {
        const r = jalCal(jy);
        return g2d(r.gy, 3, r.march) + (jm - 1) * 31 - div(jm, 7) * (jm - 7) + jd - 1;
    }

    function d2j(jdn) {
        const gy = d2g(jdn).y;
        let jy = gy - 621;
        const r = jalCal(jy);
        let k = jdn - g2d(r.gy, 3, r.march);

        if (k >= 0) {
            if (k <= 185)
                return { y: jy, m: 1 + div(k, 31), d: mod(k, 31) + 1 };
            k -= 186;
        } else {
            jy -= 1;
            k += 179;
            if (r.leap === 1)
                k += 1;
        }

        return { y: jy, m: 7 + div(k, 30), d: mod(k, 30) + 1 };
    }

    function toJalali(date) {
        return d2j(g2d(date.getFullYear(), date.getMonth() + 1, date.getDate()));
    }

    function fromJalali(jy, jm, jd) {
        const g = d2g(j2d(jy, jm, jd));
        return new Date(g.y, g.m - 1, g.d);
    }

    function jalaliMonthLength(jy, jm) {
        if (jm <= 6)
            return 31;
        if (jm <= 11)
            return 30;
        return jalCal(jy).leap === 1 ? 30 : 29;
    }

    function jalaliLabel(date) {
        const j = toJalali(date);
        return `${j.d} ${root.monthsFa[j.m - 1]} ${j.y}`;
    }

    function selfCheck() {
        const cases = [
            [[2026, 8, 13], [1405, 5, 22]],
            [[2026, 3, 21], [1405, 1, 1]],
            [[2024, 3, 20], [1403, 1, 1]],
            [[2025, 3, 20], [1403, 12, 30]],
            [[2000, 1, 1], [1378, 10, 11]],
            [[1979, 2, 11], [1357, 11, 22]]
        ];

        for (const [g, j] of cases) {
            const got = toJalali(new Date(g[0], g[1] - 1, g[2]));
            if (got.y !== j[0] || got.m !== j[1] || got.d !== j[2]) {
                console.warn("Calendar: jalali conversion wrong for", g, "->",
                             got.y, got.m, got.d, "expected", j);
                return false;
            }

            const back = fromJalali(j[0], j[1], j[2]);
            if (back.getFullYear() !== g[0] || back.getMonth() + 1 !== g[1]
                || back.getDate() !== g[2]) {
                console.warn("Calendar: reverse conversion wrong for", j);
                return false;
            }
        }

        return true;
    }

    property var events: []

    readonly property var upcoming: {
        const now = new Date();
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        return root.events
            .filter(e => e.date >= start)
            .sort((a, b) => a.date - b.date || a.time.localeCompare(b.time));
    }

    function eventsOn(date) {
        const key = date.toDateString();
        return root.events.filter(e => e.date.toDateString() === key);
    }

    function parseAgenda(text) {
        const out = [];

        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line === "" || line.startsWith("#"))
                continue;

            const m = line.match(/^(j?)(\d{4})-(\d{1,2})-(\d{1,2})\s+(?:(\d{1,2}:\d{2})\s+)?(.+)$/);
            if (!m)
                continue;

            const y = parseInt(m[2]);
            const mo = parseInt(m[3]);
            const d = parseInt(m[4]);

            out.push({
                date: m[1] === "j"
                    ? root.fromJalali(y, mo, d)
                    : new Date(y, mo - 1, d),
                time: m[5] ?? "",
                title: m[6]
            });
        }

        return out;
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.config/kyber/agenda.txt`
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.events = root.parseAgenda(text())
        onLoadFailed: root.events = []
    }

    FileView {
        id: prefs

        path: Quickshell.statePath("kyber/calendar.json")
        blockLoading: true
        printErrors: false

        onLoaded: {
            try {
                root.shamsiPrimary = JSON.parse(text()).shamsiPrimary === true;
            } catch (e) {
            }
        }
    }

    onShamsiPrimaryChanged: prefs.setText(
        JSON.stringify({ shamsiPrimary: root.shamsiPrimary }))

    function togglePrimary() {
        root.shamsiPrimary = !root.shamsiPrimary;
    }

    Component.onCompleted: selfCheck()
}
