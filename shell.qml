import Quickshell
import Quickshell.Io
import QtQuick

import "bar"
import "modules"
import "root:/services"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Bar { screen: modelData }
            LeftRail { screen: modelData }
            NotificationLayer { screen: modelData; screenName: modelData.name }
            ControlCenter { screen: modelData; screenName: modelData.name }
            Launcher { screen: modelData; screenName: modelData.name }
            Dashboard { screen: modelData; screenName: modelData.name }
            KeyboardOsd { screen: modelData; screenName: modelData.name }
            MediaPopover { screen: modelData; screenName: modelData.name }
            LevelOsd { screen: modelData; screenName: modelData.name }
            ClipboardPanel { screen: modelData; screenName: modelData.name }
            EmojiPanel { screen: modelData; screenName: modelData.name }
            Runner { screen: modelData; screenName: modelData.name }
        }
    }

    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            Globals.toggleLauncher();
        }

        function toggleRunner(): void {
            Globals.toggleRunner();
        }

        function toggleClipboard(): void {
            Globals.toggleClipboard();
        }

        function toggleEmoji(): void {
            Globals.toggleEmoji();
        }

        function toggleControlCenter(): void {
            Globals.toggleControlCenter();
        }

        function toggleDashboard(): void {
            Globals.toggleDashboard();
        }

        function toggleDnd(): void {
            Globals.dnd = !Globals.dnd;
        }

        function close(): void {
            Globals.closeAll();
        }
    }
}
