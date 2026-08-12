//@ pragma UseQApplication

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
        }
    }

    // `qs -c kyber ipc call shell toggleLauncher` — wire these to hyprland binds
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            Globals.toggleLauncher();
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
