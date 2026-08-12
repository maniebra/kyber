pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

// Which MPRIS player the shell shows.
//
// A single browser tab can show up three times — Firefox itself, the KDE
// browser-integration bridge, kdeconnect — and only one of those mirrors
// carries the cover art. Picking "first player that is playing" landed on the
// bare Firefox entry, so the art only flashed up in the moment the states
// disagreed. Score every player instead and take the richest one.
Singleton {
    id: root

    function score(p) {
        // Art outranks playback state on purpose: the mirrors disagree about
        // who is "playing" from moment to moment, and chasing that is what made
        // the cover flash in and out. The entry with the artwork is the one
        // actually describing the track.
        return ((p.trackArtUrl ?? "") !== "" ? 8 : 0)
            + ((p.trackTitle ?? "") !== "" ? 4 : 0)
            + (p.playbackState === MprisPlaybackState.Playing ? 2 : 0)
            + (p.canControl ? 1 : 0);
    }

    // A plain binding: it reads every player's scored properties, so it
    // re-evaluates whenever any of them change. dbusName breaks ties so equal
    // players don't swap back and forth on unrelated updates.
    readonly property var current: {
        const all = Mpris.players.values.slice();
        if (all.length === 0)
            return null;

        all.sort((a, b) => {
            const d = root.score(b) - root.score(a);
            return d !== 0 ? d : (a.dbusName < b.dbusName ? -1 : 1);
        });

        return all[0];
    }

    readonly property bool playing:
        Mpris.players.values.some(p => p.playbackState === MprisPlaybackState.Playing)
}
