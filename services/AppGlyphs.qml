pragma Singleton

import Quickshell

Singleton {
    id: root

    // Lucide glyph per app, matched by substring against the desktop entry's
    // id, name and icon name. First match wins, so keep specific rules first.
    readonly property var rules: [
        // browsers
        ["firefox|zen-browser|librewolf|waterfox", "\ue0d2"],
        ["chromium|chrome|brave|vivaldi|opera|edge|epiphany|midori|qutebrowser|tor-browser", "\ue0e8"],
        // terminals and dev
        ["kitty|alacritty|foot|wezterm|konsole|ghostty|terminal|tilix|xterm", "\ue20a"],
        ["code|vscodium|zed|sublime|jetbrains|idea|pycharm|clion|goland|webstorm|android-studio|qtcreator", "\ue093"],
        ["nvim|vim|emacs|helix|kate|gedit|nano|geany", "\ue131"],
        ["git|lazygit|gitkraken|sourcetree|github", "\ue0e2"],
        ["docker|podman|distrobox|toolbox|boxes|virt-manager|virtualbox|qemu", "\ue4d5"],
        ["postgres|mysql|sqlite|dbeaver|redis|mongo|beekeeper", "\ue0ad"],
        // chat and mail
        ["discord|telegram|signal|whatsapp|element|matrix|slack|teams|zulip|revolt|hexchat|irc", "\ue116"],
        ["thunderbird|geary|evolution|mailspring|bluemail|mail", "\ue10f"],
        ["zoom|jitsi|skype|meet", "\ue1a5"],
        // media
        ["spotify|elisa|rhythmbox|clementine|strawberry|amberol|lollypop|audacious|tauon|deadbeef|ncmpcpp|cmus|mpd", "\ue122"],
        ["mpv|vlc|celluloid|totem|haruna|kodi|jellyfin|plex|stremio", "\ue0d0"],
        ["obs|kdenlive|shotcut|davinci|handbrake|openshot", "\ue1a5"],
        ["audacity|ardour|lmms|reaper|carla|pipewire|pavucontrol|easyeffects|helvum|qpwgraph|mixer|volume", "\ue29a"],
        ["gimp|krita|inkscape|blender|darktable|rawtherapee|pinta|drawing|aseprite", "\ue1dd"],
        ["figma|penpot|excalidraw", "\ue131"],
        ["viewer|imv|feh|eog|loupe|gwenview|shotwell|nomacs|digikam|photo|image", "\ue0f6"],
        ["camera|cheese|webcam", "\ue064"],
        ["screenshot|grim|flameshot|spectacle|scan", "\ue257"],
        // files, docs, office
        ["nautilus|dolphin|thunar|nemo|caja|pcmanfm|ranger|yazi|nnn|files|filelight|baobab", "\ue0d7"],
        ["writer|word|abiword|libreoffice-writer|onlyoffice-document", "\ue0cc"],
        ["calc|sheet|excel|gnumeric|onlyoffice-spreadsheet", "\ue2f9"],
        ["impress|powerpoint|presentation", "\ue4ae"],
        ["libreoffice|onlyoffice|wps", "\ue0ff"],
        ["okular|evince|zathura|pdf|xreader|papers|foliate|calibre|koreader|ebook|reader", "\ue05f"],
        ["obsidian|logseq|joplin|notion|anytype|zim|standardnotes|notes|zettlr|marktext|typora", "\ue303"],
        ["anki|mnemosyne|study|learn|duolingo", "\ue234"],
        // system and utilities
        ["settings|preferences|config|control|tweaks|gnome-control-center|systemsettings", "\ue154"],
        ["monitor|htop|btop|resources|task-manager|mission-center|stacer", "\ue038"],
        ["disk|gparted|partition|filesystem|udisk", "\ue0ed"],
        ["archive|ark|xarchiver|file-roller|engrampa|peazip", "\ue041"],
        ["printer|cups|print", "\ue141"],
        ["bluetooth|blueman|bluedevil", "\ue05c"],
        ["network|nm-|wifi|connection-editor|wireshark", "\ue125"],
        ["vpn|openvpn|wireguard|mullvad|proton-vpn|tailscale", "\ue158"],
        ["keepass|bitwarden|keepassxc|1password|vault|seahorse|keyring|gnupg|kleopatra", "\ue0fd"],
        ["nextcloud|dropbox|syncthing|megasync|rclone|onedrive|drive|cloud", "\ue088"],
        ["transmission|qbittorrent|deluge|torrent|aria|motrix|jdownloader", "\ue0b2"],
        ["pacman|octopi|pamac|discover|gnome-software|synaptic|flatpak|appimage|store|software", "\ue129"],
        ["steam|lutris|heroic|bottles|wine|proton|retroarch|game|dolphin-emu|ppsspp|minecraft", "\ue0df"],
        ["calculator|galculator|qalculate|kcalc", "\ue1bc"],
        ["calendar|khal|korganizer", "\ue063"],
        ["clock|timer|alarm|stopwatch|pomodoro", "\ue251"],
        ["maps|gnome-maps|organicmaps|osm", "\ue110"],
        ["weather", "\ue216"],
        ["chatgpt|claude|copilot|ollama|llm", "\ue412"],
        ["keyboard|layout|input|ibus|fcitx", "\ue284"],
        ["display|monitor-setup|randr|wdisplays|nwg-displays", "\ue11d"],
        ["theme|appearance|wallpaper|nwg-look|lxappearance|qt5ct|qt6ct|kvantum", "\ue1dd"],
        ["font|fontconfig|typecatcher", "\ue198"],
        ["emoji|character|picker", "\ue164"],
        ["bank|finance|money|ledger|homebank|gnucash|kmymoney", "\ue204"],
        ["shop|cart|amazon|store", "\ue15c"],
        ["translate|dictionary|language", "\ue0fe"],
        ["mission|space|stellarium|celestia|astro", "\ue286"],
        ["chemistry|physics|matlab|octave|jupyter|rstudio|sage|lab", "\ue0d5"],
        ["health|fitness|workout", "\ue36e"],
        ["power|battery|tlp|upower", "\ue140"],
        ["trash|cleaner|bleachbit", "\ue18e"]
    ]

    // XDG Categories fallback, checked in this order.
    readonly property var categoryGlyphs: [
        ["WebBrowser", "\ue0e8"],
        ["TerminalEmulator", "\ue20a"],
        ["Development", "\ue093"],
        ["InstantMessaging", "\ue116"],
        ["Email", "\ue10f"],
        ["Audio", "\ue122"],
        ["Video", "\ue0d0"],
        ["Photography", "\ue064"],
        ["Graphics", "\ue1dd"],
        ["Game", "\ue0df"],
        ["Office", "\ue0cc"],
        ["Education", "\ue234"],
        ["Science", "\ue0d5"],
        ["FileManager", "\ue0d7"],
        ["Network", "\ue125"],
        ["Security", "\ue158"],
        ["Settings", "\ue154"],
        ["System", "\ue0a9"],
        ["Utility", "\ue1b1"]
    ]

    readonly property string fallback: "\ue426" // app-window

    function forText(text) {
        const hay = String(text ?? "").toLowerCase();
        if (hay === "")
            return root.fallback;
        for (const rule of root.rules) {
            // token match, so "top" does not fire on "desktop"
            if (new RegExp(`(?:^|[^a-z0-9])(?:${rule[0]})(?![a-z0-9])`).test(hay))
                return rule[1];
        }
        return "";
    }

    function forEntry(entry) {
        if (!entry)
            return root.fallback;

        const hit = root.forText(
            `${entry.id ?? ""} ${entry.name ?? ""} ${entry.icon ?? ""}`
            + ` ${entry.genericName ?? ""}`);
        if (hit !== "")
            return hit;

        const cats = entry.categories ?? [];
        for (const pair of root.categoryGlyphs) {
            if (cats.indexOf(pair[0]) !== -1)
                return pair[1];
        }
        return root.fallback;
    }
}
