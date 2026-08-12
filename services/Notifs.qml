pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var popups: []
    property var history: []

    readonly property int count: history.length

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            root.history = [notification, ...root.history].slice(0, 50);

            if (!Globals.dnd)
                root.popups = [notification, ...root.popups].slice(0, 5);

            notification.closed.connect(() => root.forget(notification));
        }
    }

    function forget(n) {
        popups = popups.filter(x => x !== n);
        history = history.filter(x => x !== n);
    }

    function dismissPopup(n) {
        popups = popups.filter(x => x !== n);
    }

    function clearHistory() {
        for (const n of history.slice())
            n.dismiss();
        history = [];
        popups = [];
    }
}
