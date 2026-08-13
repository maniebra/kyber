# kyber

A Quickshell desktop shell for Hyprland. Dark, mostly grey, one blue accent,
frosted glass panels that slide out of the bar and the left rail. There's a
cyberpunk streak to it, segmented meters, corner brackets, mono readouts,
kept quiet enough to live with all day.

## What's in it

A bar across the top and a thin rail down the left edge. Everything else hangs
off one of those two and tucks back when you're done with it.

**Bar** (`bar/`), workspaces, focused window, clock, CPU and RAM, tray, status
island. The clock's little status dot is the media indicator: hover it and a
small panel drops down with the current track, cover art, a seek bar, transport
buttons, and a player switcher if more than one thing is making noise.

**Control center** (`modules/ControlCenter.qml`), right-click the clock. Toggles
for Wi-Fi, Bluetooth, VPN, do-not-disturb and the mic; volume and brightness
faders; media; notification history. Three sub-pages behind the icons at the top
right: Wi-Fi networks (with your VPN profiles listed underneath), a full
Bluetooth device page (connect, disconnect, forget, battery levels, scanning),
and the power actions.

**Dashboard** (`modules/Dashboard.qml`), left-click the clock. Weather, calendar,
live meters, a bigger media view.

**Left rail** (`modules/LeftRail.qml`), app menu button up top, then your
keyboard layout, then clipboard history, and running apps along the bottom.
Left-click an app to focus it, middle-click for a new window.

**App menu** (`modules/Launcher.qml`), slides out of the rail. Type to filter,
arrows or tab to move, enter to launch, escape to leave.

**Clipboard** (`modules/ClipboardPanel.qml`), same idea, for everything you've
copied. Enter or click to put an entry back on the clipboard, Delete or
middle-click to drop one. History survives a restart; it's kept in
`~/.local/state/quickshell/`.

**On-screen readouts**, change the volume or brightness and a small bar drops
out of the top; switch keyboard layout and a badge slides out of the rail. Both
leave on their own.

**Notifications** (`modules/NotificationLayer.qml`), toasts under the bar. Click
runs the default action, right-click dismisses, hovering pauses the timer, and
critical ones stay until you deal with them.

Everything under `services/` is a singleton doing the unglamorous work: Pipewire
audio, UPower battery, `/proc` for CPU and RAM, nmcli for network and VPN,
brightnessctl plus a sysfs watch for the backlight, MPRIS for media, the
notification server, the clipboard watcher, and the shared UI state the windows
bind against.

## Fonts

Icons come from [Lucide](https://lucide.dev), which isn't packaged for Arch.
Install it once or every icon shows up as tofu:

```sh
curl -Lo ~/.local/share/fonts/lucide.ttf \
    https://unpkg.com/lucide-static@latest/font/lucide.ttf
fc-cache -f
```

Text is SF Pro Text, numbers and small readouts are JetBrainsMono Nerd Font.
Both are set in `Theme.qml` if you'd rather use something else.

## Theming

`Theme.qml` holds all of it: colours, spacing, radii, fonts, animation timings.
The surfaces are deliberately see-through, the frosted look is the compositor
blurring what's behind them, not a gradient.

## Hyprland setup

Layer rules only apply when a surface is first mapped, so after editing them run
`hyprctl reload` **and** restart the shell.

Lua:

```lua
hl.layer_rule({
    name  = "kyber-blur",
    match = { namespace = "^kyber-.*$" },
    blur  = true,
    ignore_alpha = 0.05,
})
```

The namespace pattern is matched against the whole string, so `"^kyber-"` on its
own matches nothing and you get no blur at all. `ignore_alpha` needs to sit
between 0 and the alpha of `Theme.panel`: it skips blurring pixels dimmer than
the threshold, which is what stops the transparent padding around a panel from
smearing into a pale rectangle.

Classic config:

```ini
layerrule = blur, kyber-.*
layerrule = ignorealpha 0.05, kyber-.*
```

Blur strength is global (`decoration:blur`); `size = 7, passes = 3` looks about
right.

## Keybinds

The shell listens on IPC, so bind these to whatever you like:

```sh
qs -c kyber ipc call shell toggleLauncher
qs -c kyber ipc call shell toggleClipboard
qs -c kyber ipc call shell toggleControlCenter
qs -c kyber ipc call shell toggleDashboard
qs -c kyber ipc call shell toggleDnd
qs -c kyber ipc call shell close
```

What's bound here:

```lua
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs -c kyber ipc call shell toggleLauncher"))
hl.bind(mainMod .. " + V",     hl.dsp.exec_cmd("qs -c kyber ipc call shell toggleClipboard"))
```

## Optional dependencies

`brightnessctl` for the brightness slider, `nmcli` for the network and VPN
controls, `wl-clipboard` for clipboard history. No playerctl, media comes
straight from MPRIS.
