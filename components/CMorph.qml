import QtQuick

import "root:/"

ColorAnimation {
    duration: Theme.animMorph
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.curveFlow
}
