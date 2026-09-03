#!/data/data/com.termux/files/usr/bin/bash
#
# install-anland-plasma.sh
# Installs KDE Plasma (via Anland: Termux) on Termux Native for devices with a Snapdragon/Adreno GPU.
#
# Guide source: https://github.com/lfdevs/anland-termux/blob/main/docs/user-guide.md
#
# IMPORTANT NOTES BEFORE RUNNING:
# 1. All .deb URLs (anland daemon, xwayland, kwin, layer-shell-qt, mesa/freedreno)
#    are hardcoded below based on the current release. If newer versions come out,
#    check https://github.com/lfdevs/anland-termux/releases/latest and
#    https://github.com/lfdevs/termux-packages/releases, then update the URL_* variables.
# 2. Two Android APKs MUST be installed manually (cannot be done from this script):
#      - AnlandTermux-<version>.apk  (from GitHub release lfdevs/anland-termux)
#      - Termux:API.apk              (from F-Droid or github.com/termux/termux-api/releases)
#    After installing AnlandTermux.apk, LONG-PRESS its icon to open its settings.
# 3. Storage access and battery optimization exemption both require you to tap
#    through an Android system dialog/screen. The script triggers these prompts,
#    but you must confirm them manually on the Android side.
#
# Run: chmod +x install-anland-plasma.sh && ./install-anland-plasma.sh

set -e

# ==== Package URLs (update here when a new release is available) ====
URL_ANLAND="https://github.com/lfdevs/anland-termux/releases/download/5.13.3/anland_5.13.3_aarch64.deb"
URL_KWIN="https://github.com/lfdevs/anland-termux/releases/download/5.13.3/kwin-anland_6.7.4_aarch64.deb"
URL_XWAYLAND="https://github.com/lfdevs/anland-termux/releases/download/5.13.3/xwayland_24.1.12-2_aarch64.deb"
URL_LAYERSHELLQT="https://github.com/lfdevs/termux-packages/releases/download/layer-shell-qt_6.7.4-1/layer-shell-qt_6.7.4-1_aarch64.deb"
URL_MESA="https://github.com/lfdevs/termux-packages/releases/download/freedreno-26.2.0-devel-20260709/mesa_26.2.0-1_aarch64.deb"
URL_MESA_VULKAN="https://github.com/lfdevs/termux-packages/releases/download/freedreno-26.2.0-devel-20260709/mesa-vulkan-icd-freedreno_26.2.0-1_aarch64.deb"

ANLAND_VER="5.13.3"

WORKDIR="$HOME/anland-install"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "=================================================="
echo " Step 0: Base update & upgrade + x11-repo + core tools"
echo "=================================================="
pkg update -y
pkg upgrade -y
pkg install x11-repo -y
pkg install curl wget procps -y

echo "=================================================="
echo " Step 1: Storage access & battery optimization"
echo "=================================================="
echo "-> Requesting storage access (tap 'Allow' on the Android prompt):"
termux-setup-storage
sleep 2

echo "-> Opening battery optimization settings."
echo "   Find 'Termux' (and 'Anland Termux' separately) in the list and set to"
echo "   'Don't optimize' / 'Unrestricted' so the daemon isn't killed in the background."
am start -a android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS >/dev/null 2>&1 || \
    echo "   [!] Could not auto-open the settings screen. Open manually: Settings > Apps > Battery."
read -p "Press Enter once storage access is granted and battery settings are set..." _

echo "=================================================="
echo " Step 2: Install KDE Plasma"
echo "=================================================="
pkg install plasma dolphin konsole -y

echo "=================================================="
echo " Step 3: Android APKs"
echo "=================================================="
echo "-> SKIPPED in this script (must be done manually):"
echo "   1. Install AnlandTermux-${ANLAND_VER}.apk"
echo "      from: https://github.com/lfdevs/anland-termux/releases/latest"
echo "      After installing, LONG-PRESS the app icon to open its settings."
echo "   2. Install Termux:API.apk from F-Droid or:"
echo "      https://github.com/termux/termux-api/releases"
read -p "Have you installed BOTH APKs above? Press Enter to continue..." _

echo "=================================================="
echo " Step 4: termux-api package"
echo "=================================================="
pkg install termux-api -y

echo "=================================================="
echo " Step 5: Chromium"
echo "=================================================="
pkg install chromium -y

echo "=================================================="
echo " Step 6: Additional apps"
echo "=================================================="
pkg install vlc mpv xarchiver file-roller fastfetch htop libreoffice -y

echo "=================================================="
echo " Step 7: Anland daemon"
echo "=================================================="
ANLAND_DEB="$(basename "$URL_ANLAND")"
[ -f "$ANLAND_DEB" ] || curl -LO "$URL_ANLAND"
pkg reinstall "./${ANLAND_DEB}" -y

echo "=================================================="
echo " Step 8: XWayland + KWin (Anland variant)"
echo "=================================================="
XWAYLAND_DEB="$(basename "$URL_XWAYLAND")"
KWIN_DEB="$(basename "$URL_KWIN")"
[ -f "$XWAYLAND_DEB" ] || curl -LO "$URL_XWAYLAND"
[ -f "$KWIN_DEB" ] || curl -LO "$URL_KWIN"
pkg reinstall "./${XWAYLAND_DEB}" "./${KWIN_DEB}" -y

echo "=================================================="
echo " Step 9: LayerShellQt + PipeWire + Freedreno driver"
echo "=================================================="
echo "-> Installing PipeWire (for audio):"
pkg install pipewire -y

echo "-> Installing LayerShellQt (required for Plasma Wayland on Termux Native):"
LSQT_DEB="$(basename "$URL_LAYERSHELLQT")"
[ -f "$LSQT_DEB" ] || curl -LO "$URL_LAYERSHELLQT"
pkg reinstall "./${LSQT_DEB}" -y

echo "-> Installing Freedreno (KGSL) driver:"
MESA_DEB="$(basename "$URL_MESA")"
MESA_VK_DEB="$(basename "$URL_MESA_VULKAN")"
[ -f "$MESA_DEB" ] || curl -LO "$URL_MESA"
[ -f "$MESA_VK_DEB" ] || curl -LO "$URL_MESA_VULKAN"
pkg reinstall "./${MESA_DEB}" "./${MESA_VK_DEB}" -y

echo "=================================================="
echo " Step 10: Hold/pin packages"
echo "=================================================="
apt-mark hold xwayland kwin-anland mesa mesa-vulkan-icd-freedreno weston layer-shell-qt mutter libical spidermonkey 2>/dev/null || true

HOLD_FILE="$PREFIX/etc/apt/preferences.d/hold-anland-package"
mkdir -p "$(dirname "$HOLD_FILE")"
cat > "$HOLD_FILE" <<'EOF'
Package: xwayland kwin-anland mesa mesa-vulkan-icd-freedreno weston layer-shell-qt mutter libical spidermonkey
Pin: release *
Pin-Priority: -1
EOF
echo "Permanent hold file created at: $HOLD_FILE"

echo "=================================================="
echo " Step 11: Plasma starter script"
echo "=================================================="
cd "$HOME"
curl -LO https://github.com/lfdevs/anland-termux/raw/refs/heads/main/scripts/startplasma-anland.sh
chmod +x ./startplasma-anland.sh

echo "=================================================="
echo " DONE"
echo "=================================================="
echo "All packages are installed. Next steps (manual):"
echo "1. Start the daemon:"
echo "     killall anland > /dev/null 2>&1; anland > /dev/null 2>&1 &"
echo "     pkill -TERM -x anland-compatible; anland-compatible &   # if using the -compatible APK"
echo "2. Open the 'Anland Termux' app on Android."
echo "3. Run: ~/startplasma-anland.sh"
