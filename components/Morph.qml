import QtQuick
import "root:/"

NumberAnimation {
    duration: Theme.animMorph
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.curveDrop
}
