# Anland Plasma for Termux

Automated installer script to run **KDE Plasma** on **Termux Native** using [Anland: Termux](https://github.com/lfdevs/anland-termux), no root required, for devices with a **Snapdragon (Adreno GPU)** chipset.

This script automates most of the steps from the [official Anland: Termux user guide](https://github.com/lfdevs/anland-termux/blob/main/docs/user-guide.md), plus a few extra apps (browser, media player, office suite, etc.) and a shutdown launcher for the desktop.

## What gets installed

- `curl`, `wget`, `procps` (needed for a working `pkill`, since Termux's default `pkill` can throw "Bad system call" on some Android devices)
- KDE Plasma (`plasma`, `dolphin`, `konsole`)
- XWayland + KWin (Anland variant)
- Anland daemon
- LayerShellQt (required for Plasma Wayland on Termux Native)
- Freedreno (KGSL) driver for GPU acceleration
- PipeWire (audio)
- Chromium
- Extra apps: VLC, MPV, Xarchiver, File Roller, Fastfetch, Htop, LibreOffice
- A patched, rebuilt `xdg-desktop-portal` so Chromium's file open/save/upload dialogs work (compiled from source, takes a while)

## Requirements

- Android 8+ with a **Snapdragon (Adreno GPU)** chipset
- Termux from [GitHub releases](https://github.com/termux/termux-app/releases) — **not** the Play Store version
- At least 3-4 GB of free storage
- A stable internet connection (several files are downloaded during install)

## How to use

1. Open Termux and run:

   ```bash
   curl -LO https://raw.githubusercontent.com/asveroid/anland-plasma-termux/main/install-anland-plasma.sh
   chmod +x install-anland-plasma.sh
   ./install-anland-plasma.sh
   ```

2. The script will pause a few times for manual steps:
   - **Storage access & battery optimization** — an Android dialog/settings screen will appear; confirm it manually (for battery, find "Termux", and later "Anland Termux" separately, and set both to "Don't optimize"/"Unrestricted").
   - **Install 2 Android APKs** (cannot be done from the script):
     - `AnlandTermux-<version>.apk` from the [latest release](https://github.com/lfdevs/anland-termux/releases/latest)
     - `Termux:API.apk` from [F-Droid](https://f-droid.org/) or [GitHub](https://github.com/termux/termux-api/releases)

   Press Enter in Termux after completing each step to continue.

3. Open the **Anland Termux** app on Android.

4. Back in Termux, run:

   ```bash
   ~/startplasma-anland.sh
   ```

5. The KDE Plasma desktop will appear inside the Anland Termux app.

## Notes

- The `xdg-desktop-portal` fix compiles from source and can take several minutes depending on your device. It's safe to re-run later with `~/fix-xdg-desktop-portal.sh` if it fails or times out during install.

- Package versions (`anland`, `xwayland`, `kwin-anland`, etc.) are hardcoded in the script based on the release available at the time it was written. If a newer release comes out, check [Anland: Termux releases](https://github.com/lfdevs/anland-termux/releases/latest) and [termux-packages releases](https://github.com/lfdevs/termux-packages/releases), then update the `URL_*` variables at the top of the script.
- Devices with a non-Adreno GPU (MediaTek, Exynos, Tensor) will likely only work with software rendering (LLVMpipe) and may not be able to fully run the Wayland desktop.

## Credits

- [lfdevs/anland-termux](https://github.com/lfdevs/anland-termux) — the core Anland: Termux project
- [lfdevs/termux-packages](https://github.com/lfdevs/termux-packages) — Freedreno driver & LayerShellQt

## License

This script is provided for personal/community use. Feel free to modify it to fit your device.
