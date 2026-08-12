import QtQuick

import "root:/"

// Geometry moves like a drop coming off a lip: it lets go quickly, then surface
// tension drags out the settle and pulls it back into shape at the end. Still
// no long tail — the whole thing is over before it reads as lag.
NumberAnimation {
    duration: Theme.animMorph
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.curveDrop
}
