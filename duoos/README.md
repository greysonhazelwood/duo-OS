# DuoOS

An Arch-based Linux distro with a **Debian layer built in**, a custom **Hyprland** desktop, and a
**start menu that slides in from the right**.

## How "Arch and Debian at the same time" works

```
┌──────────────────────── DuoOS ────────────────────────┐
│  Hyprland + Quickshell UI (start menu, bar, wallpaper) │
│                                                        │
│  Arch host (rolling)           Debian layer (stable)   │
│  pacman, Chaotic-AUR           apt, dpkg, .deb         │
│  FireDragon, LibreOffice       runs in Distrobox,      │
│  kernel, drivers, Hyprland     apps appear in the menu │
└────────────────────────────────────────────────────────┘
```

A single machine can't run two kernels or two init systems as one OS, so DuoOS uses Arch as the host and runs a
full Debian userland next to it in a container. Shared home folder, shared Wayland and audio, native-looking windows.

- `apt install foo` on DuoOS runs apt **inside Debian** and exports the app to the start menu.
- Double-clicking a `.deb` opens **duo-deb-open**: choose *Debian layer* (recommended) or
  *Native Arch package* (converted with `debtap`, installed with `pacman`).
- `pacman` keeps working for the Arch side.

## Included
- **Hyprland** in the new Lua config format (`hyprland.lua`, Hyprland ≥ 0.55), with blur, rounded corners, glow borders and smooth animations
- **Quickshell** shell: gradient wallpaper, floating glass top bar, and the **right-side start menu**
  (tap `Super`, `Super+A`, or click the button on the bar; type to search, Enter launches, Esc closes)
- **FireDragon** (from Chaotic-AUR), default browser
- **LibreOffice** (offline) and **Microsoft 365** launchers (Word, Excel, PowerPoint, Outlook) that open the web apps in FireDragon
- foot terminal, Nautilus, mako notifications, Inter + JetBrains Mono Nerd fonts, Papirus icons

## Build
On Arch (or an Arch VM/container) with internet:
```
sudo ./build.sh
```
The ISO lands in `./out/`. Boot it in a VM first (UEFI recommended). It auto-logs in as `live` (no password) and
starts Hyprland. Install with `archinstall` from a terminal (`Super+Q`).

## Keys
| Key | Action |
|---|---|
| Super (tap) / Super+A | start menu |
| Super+Q / B / E | terminal / FireDragon / files |
| Super+C / V / F | close / float / fullscreen |
| Super+1..5, +Shift | workspace / move window |
| Print | screenshot region to clipboard |

## Honest notes (read before you build)
- **Untested.** I wrote this without being able to build or boot an Arch ISO, so expect to fix small things.
  Debug starting points: `hyprctl configerrors`, `quickshell` run from a terminal (shows QML errors), `journalctl -b`.
- **Hyprland config.** Hyprland 0.55 replaced `hyprland.conf` with Lua. Each bind is wrapped in `pcall`, so a wrong
  function name skips that bind instead of breaking the config. Compare with `/usr/share/hypr/hyprland.lua`.
- **Quickshell** should be in Arch's `extra`; if not, use the AUR/Chaotic `quickshell-git`.
- **Microsoft 365 has no native Linux app.** The launchers open the web apps. Use LibreOffice for offline editing.
- **Debian layer needs internet on first use** (it downloads the Debian image). Rootless Podman inside a *live* ISO
  can be flaky (overlay on overlay); it's reliable once installed to disk.
- Workspace pills in the bar are indicators only (not clickable) since Hyprland's Lua dispatch changed.
- Next steps if you want them: Calamares graphical installer, greetd login screen, lock screen (hyprlock), a real wallpaper, a Debian-based edition.
