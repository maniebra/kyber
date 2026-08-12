# kyber

A Quickshell desktop shell for Hyprland: macOS structure, muted cyberpunk
palette, translucent glass surfaces.

## What's in it

| Piece | File | Notes |
| --- | --- | --- |
| Top bar | `bar/` | Full width, 28px. Launcher, workspaces, focused window, media, clock, CPU/RAM, tray, status island. |
| Control center | `modules/ControlCenter.qml` | Drops out of the bar (`──\____/──` flare). Wi-Fi / Bluetooth / DND / mic toggles, volume + brightness, media transport, notification history, power row. |
| Left rail | `modules/LeftRail.qml` | Thin strip down the left edge: app-menu button at the top, running apps at the bottom (left-click focuses, middle-click opens a new instance). |
| App menu | `modules/Launcher.qml` | Slides out of the rail at mid-height, flares carving it into the rail's edge. App search over `DesktopEntries`: arrows or tab to move, enter to launch, escape to close. |
| Notifications | `modules/NotificationLayer.qml` | Toasts under the bar. Click = default action, right-click = dismiss, hover pauses expiry, critical never auto-expires. |

Services (`services/`) are singletons: Pipewire audio, UPower battery,
`/proc` CPU+RAM, nmcli network, brightnessctl, notification server, and
shared UI state.

## Fonts

Icons are [Lucide](https://lucide.dev), which is not packaged for Arch — install
the font once, or every icon renders as tofu:

```sh
curl -Lo ~/.local/share/fonts/lucide.ttf \
    https://unpkg.com/lucide-static@latest/font/lucide.ttf
fc-cache -f
```

Text uses Inter and JetBrainsMono Nerd Font.

## Theming

Everything lives in `Theme.qml` — palette, metrics, fonts.
Surfaces are deliberately translucent; the frosted look comes from the
compositor blurring what's behind them.

## Hyprland setup

Layer rules are applied when a surface is **mapped**, so after changing them
run `hyprctl reload` *and* restart the shell.

Lua config:

```lua
hl.layer_rule({
    name  = "kyber-blur",
    match = { namespace = "^kyber-.*$" },
    blur  = true,
    ignore_alpha = 0.05,
})
```

The namespace regex is matched against the **whole** string: `"^kyber-"` on
its own matches nothing and you get no blur at all. `ignore_alpha` must sit
between 0 and `Theme.panel`'s alpha — it skips blur under pixels dimmer than
the threshold, which is what keeps the transparent padding around a slab from
blurring into a pale rectangle behind it.

Classic config:

```
layerrule = blur, kyber-.*
layerrule = ignorealpha 0.05, kyber-.*
```

Blur strength is global (`decoration:blur`); `size = 7, passes = 3` gives a
convincing pane.

## Keybinds

The shell exposes IPC, so bind whatever you like:

```
qs -c kyber ipc call shell toggleLauncher
qs -c kyber ipc call shell toggleControlCenter
qs -c kyber ipc call shell toggleDnd
qs -c kyber ipc call shell close
```

Lua:

```lua
hl.bind("SUPER, SPACE", hl.dsp.exec_cmd("qs -c kyber ipc call shell toggleLauncher"))
hl.bind("SUPER, C",     hl.dsp.exec_cmd("qs -c kyber ipc call shell toggleControlCenter"))
```

## Optional dependencies

`brightnessctl` (brightness slider), `nmcli` (network readout + Wi-Fi
toggle), `playerctl` is not needed — media comes from MPRIS directly.
