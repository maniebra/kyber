import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

// Toasts under the right end of the bar. Click dismisses, hover pauses the
// expiry timer, critical ones never auto-expire.
PanelWindow {
    id: root

    required property string screenName

    visible: Notifs.popups.length > 0
        && Globals.focusedScreen === screenName

    WlrLayershell.namespace: "kyber-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: 8
        right: 10
    }

    implicitWidth: 360
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    exclusiveZone: 0

    Column {
        id: stack

        anchors.fill: parent
        spacing: 8

        Repeater {
            model: Notifs.popups

            GlassPanel {
                id: toast

                required property var modelData

                readonly property bool critical:
                    modelData.urgency === NotificationUrgency.Critical

                width: parent.width
                height: body.implicitHeight + 22
                radius: Theme.radius
                // critical toasts warm the whole slab instead of wearing a rim
                color: critical
                    ? Qt.tint(Theme.panel, Theme.alpha(Theme.red, 0.22))
                    : Theme.panel

                // slide in from the right
                property real slide: 1
                transform: Translate { x: toast.slide * 40 }
                opacity: 1 - toast.slide

                Component.onCompleted: enter.start()

                NumberAnimation {
                    id: enter
                    target: toast
                    property: "slide"
                    to: 0
                    duration: Theme.animMed
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.curveDrop
                }

                Timer {
                    running: !toast.critical && !toastHover.containsMouse
                    interval: 6000
                    onTriggered: Notifs.dismissPopup(toast.modelData)
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height * 0.55
                    radius: 2
                    color: toast.critical ? Theme.red : Theme.accent
                }

                Row {
                    id: body

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12

                    spacing: 11

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 26
                        visible: source !== ""
                        source: toast.modelData.image !== ""
                            ? toast.modelData.image
                            : Quickshell.iconPath(toast.modelData.appIcon, true)
                        smooth: true
                        mipmap: true
                        antialiasing: true
                    }

                    Column {
                        width: parent.width - 40
                        spacing: 3

                        Text {
                            width: parent.width
                            text: toast.modelData.appName
                            visible: text !== ""
                            color: toast.critical ? Theme.red : Theme.subtext
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            font.capitalization: Font.AllUppercase
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: toast.modelData.summary
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: toast.modelData.body
                            visible: text !== ""
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: 11
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: toastHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            toast.modelData.dismiss();
                            return;
                        }

                        const actions = toast.modelData.actions;
                        if (actions && actions.length > 0)
                            actions[0].invoke();
                        else
                            Notifs.dismissPopup(toast.modelData);
                    }
                }
            }
        }
    }
}
