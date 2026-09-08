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
pkg install vlc mpv xarchiver file-roller fastfetch htop -y

read -p "Install LibreOffice? It's a large download. (y/n) " install_libreoffice
if [[ "$install_libreoffice" == "y" || "$install_libreoffice" == "Y" ]]; then
    pkg install libreoffice -y
else
    echo "Skipping LibreOffice."
fi

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
echo " Step 12: Fix xdg-desktop-portal (Chromium file picker)"
echo "=================================================="
echo "This patches and rebuilds xdg-desktop-portal so Chromium's"
echo "file open/save/upload dialogs work on Termux Native."
echo "This step compiles from source and can take a while."
cat > "$HOME/fix-xdg-desktop-portal.sh" << 'FIXPORTALEOF'
#!/data/data/com.termux/files/usr/bin/bash
#
# fix-xdg-desktop-portal.sh
#
# Patches and rebuilds xdg-desktop-portal on Termux (native, no proot/chroot)
# so Chromium's file picker (open/save/upload dialogs) works.
#
# Background: Chromium's Termux build has no GTK support, so it depends
# entirely on the xdg-desktop-portal FileChooser D-Bus interface. That
# daemon fails to register unsandboxed ("host") apps because it tries to
# open /proc/<pid>/root, which Android's SELinux policy blocks with EACCES
# even for same-UID processes. The upstream code only expects EACCES to
# mean "fuse rootfs" and treats anything else as fatal, so app-info
# detection never falls through to the host-app case.
#
# This script:
#   1. Installs build dependencies
#   2. Clones the xdg-desktop-portal source matching the installed version
#   3. Patches the EACCES handling in the flatpak/linyaps app-info probes
#   4. Patches libglnx for missing strdupa() (Bionic has no GNU strdupa)
#   5. Disables the document-portal (needs fuse3, unavailable on Termux
#      and not needed for FileChooser) and test/sandboxed-validation
#      dependencies (bubblewrap, unavailable on Termux)
#   6. Compiles targeting Android API 30 (memfd_create/getrandom need
#      that even though libc.so on a modern device has them)
#   7. Backs up the original binary and installs the patched one
#
# Safe to re-run; it always starts from a clean checkout.
#
# Requirements: none beyond a working Termux + x11-repo with `chromium`
# and `xdg-desktop-portal` / `xdg-desktop-portal-kde` already installed.

set -euo pipefail

PREFIX="/data/data/com.termux/files/usr"
SRC_DIR="$HOME/xdp-src"
BACKUP_DIR="$HOME/xdg-desktop-portal-backups"
PORTAL_BIN="$PREFIX/libexec/xdg-desktop-portal"

log()  { printf '\033[32m[+] %s\033[0m\n' "$1"; }
warn() { printf '\033[33m[!] %s\033[0m\n' "$1"; }
die()  { printf '\033[31m[x] %s\033[0m\n' "$1" >&2; exit 1; }

[[ -n "${TERMUX_VERSION:-}" ]] || die "This script is only for native Termux, not proot/chroot."

# ---------------------------------------------------------------------------
log "Step 1/7: Install dependencies"
# ---------------------------------------------------------------------------
DEPS=(git python ninja pkg-config glib dbus json-glib gdk-pixbuf gstreamer geoclue pipewire xdg-desktop-portal xdg-desktop-portal-kde kdialog)
FAILED_DEPS=()

for dep in "${DEPS[@]}"; do
    if ! pkg install -y "$dep"; then
        FAILED_DEPS+=("$dep")
    fi
done

if [[ ${#FAILED_DEPS[@]} -gt 0 ]]; then
    warn "The following packages failed to install (names may differ on this device): ${FAILED_DEPS[*]}"
    warn "Check the correct name with: pkg search <name>, then install it manually before continuing."
    read -rp "Continue and try to build anyway? (y/n) " reply
    [[ $reply == y || $reply == Y ]] || exit 1
fi

pip install --quiet meson --break-system-packages

command -v meson  > /dev/null || die "meson failed to install"
command -v ninja  > /dev/null || die "ninja failed to install"

# ---------------------------------------------------------------------------
log "Step 2/7: Clone source (version matched to the installed package)"
# ---------------------------------------------------------------------------
INSTALLED_VERSION=$(pkg show xdg-desktop-portal 2>/dev/null | awk -F': ' '/^Version/{print $2; exit}') || true
INSTALLED_VERSION=${INSTALLED_VERSION:-1.22.1}
log "Detected installed version: $INSTALLED_VERSION"

rm -rf "$SRC_DIR"
if ! git clone --branch "$INSTALLED_VERSION" --depth 1 \
        https://github.com/flatpak/xdg-desktop-portal.git "$SRC_DIR" 2> "$HOME/xdp-clone.log"; then
    warn "Tag $INSTALLED_VERSION not found, falling back to 1.22.1"
    rm -rf "$SRC_DIR"
    git clone --branch 1.22.1 --depth 1 \
        https://github.com/flatpak/xdg-desktop-portal.git "$SRC_DIR"
fi

log "Downloading subprojects (libglnx, gvdb) -- needed before patching"
cd "$SRC_DIR"
meson subprojects download

# ---------------------------------------------------------------------------
log "Step 3/7: Patch EACCES handling (flatpak & linyaps app-info probes)"
# ---------------------------------------------------------------------------
python3 - "$SRC_DIR" << 'PYEOF'
import sys

base = sys.argv[1]

def patch(path, old, new, label):
    with open(path) as f:
        content = f.read()
    if new.strip() in content:
        print(f"  - already patched, skip: {label}")
        return
    if old not in content:
        print(f"  ! FAILED, old text not found in {label} -- source may have changed, check manually.")
        sys.exit(1)
    content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(content)
    print(f"  - patched: {label}")

patch(
    f"{base}/src/xdp-app-info-flatpak.c",
    '''      if (errno == EACCES)
        {
          struct statfs buf;

          /* Access to the root dir isn't allowed. This can happen if the root is on a fuse
           * filesystem, such as in a toolbox container. We will never have a fuse rootfs
           * in the flatpak case, so in that case its safe to ignore this and
           * continue to detect other types of apps.
           */
          if (statfs (root_path, &buf) == 0 &&
              buf.f_type == 0x65735546) /* FUSE_SUPER_MAGIC */
            {
              g_set_error (error, XDP_APP_INFO_ERROR, XDP_APP_INFO_ERROR_WRONG_APP_KIND,
                           "Not a flatpak (fuse rootfs)");
              return -1;
            }
        }''',
    '''      if (errno == EACCES)
        {
          /* Access to the root dir isn't allowed. This can happen if the root is on a fuse
           * filesystem, or due to platform sandboxing (e.g. Android SELinux) that blocks
           * reading /proc/<pid>/root even for same-uid processes. We will never have a
           * fuse rootfs in the flatpak case, so it's safe to treat this as "not a flatpak"
           * and continue detecting other app types (eventually falling back to host app).
           */
          g_set_error (error, XDP_APP_INFO_ERROR, XDP_APP_INFO_ERROR_WRONG_APP_KIND,
                       "Not a flatpak (root dir inaccessible)");
          return -1;
        }''',
    "xdp-app-info-flatpak.c",
)

patch(
    f"{base}/src/xdp-app-info-linyaps.c",
    '''      if (errno == EACCES)
        {
          struct statfs buf;
          if (statfs (root_path, &buf) == 0 &&
              buf.f_type == 0x65735546) /* FUSE_SUPER_MAGIC */
          {
            g_set_error (error, XDP_APP_INFO_ERROR,
                         XDP_APP_INFO_ERROR_WRONG_APP_KIND,
                         "Not a linyaps (fuse rootfs)");
            return -1;
          }
        }''',
    '''      if (errno == EACCES)
        {
          g_set_error (error, XDP_APP_INFO_ERROR,
                       XDP_APP_INFO_ERROR_WRONG_APP_KIND,
                       "Not a linyaps (root dir inaccessible)");
          return -1;
        }''',
    "xdp-app-info-linyaps.c",
)
PYEOF

# ---------------------------------------------------------------------------
log "Step 4/7: Patch meson.build (skip document-portal/fuse3) & libglnx (strdupa)"
# ---------------------------------------------------------------------------
python3 - "$SRC_DIR" << 'PYEOF'
import sys
base = sys.argv[1]

# Skip document-portal subdir (needs fuse3, not on Termux, not needed for FileChooser)
mpath = f"{base}/meson.build"
with open(mpath) as f:
    c = f.read()
c = c.replace(
    "subdir('document-portal')",
    "# subdir('document-portal')  # skipped: needs fuse3, unavailable on Termux, not needed for FileChooser",
)
c = c.replace(
    "fuse3_dep = dependency('fuse3', version: '>= 3.10.0')",
    "fuse3_dep = dependency('fuse3', version: '>= 3.10.0', required: false)",
)
with open(mpath, "w") as f:
    f.write(c)
print("  - meson.build patched (document-portal skipped, fuse3 optional)")

# strdupa compat shim for Bionic (Android libc), used in libglnx
compat_macro = '''#include "libglnx-config.h"

/* strdupa is a GNU libc extension not available on Bionic (Android/Termux).
 * Emulate it with a macro combining alloca + memcpy. */
#ifndef strdupa
#include <alloca.h>
#define strdupa(s) \\
  (__extension__ ({ \\
    const char *__old = (s); \\
    size_t __len = strlen (__old) + 1; \\
    char *__new = (char *) alloca (__len); \\
    (char *) memcpy (__new, __old, __len); \\
  }))
#endif
'''

for fname in ("glnx-fdio.c", "glnx-shutil.c"):
    fpath = f"{base}/subprojects/libglnx/{fname}"
    with open(fpath) as f:
        content = f.read()
    if "strdupa is a GNU libc extension" in content:
        print(f"  - already patched, skip: {fname}")
        continue
    if '#include "libglnx-config.h"' not in content:
        print(f"  ! FAILED, include anchor not found in {fname}")
        sys.exit(1)
    content = content.replace('#include "libglnx-config.h"', compat_macro, 1)
    with open(fpath, "w") as f:
        f.write(content)
    print(f"  - patched: {fname}")
PYEOF

# ---------------------------------------------------------------------------
log "Step 5/7: meson setup"
# ---------------------------------------------------------------------------
cd "$SRC_DIR"
rm -rf builddir
CFLAGS="-target aarch64-linux-android30" meson setup builddir \
    -Dtests=disabled \
    -Dsandboxed-image-validation=disabled \
    -Dsandboxed-sound-validation=disabled

# ---------------------------------------------------------------------------
log "Step 6/7: Compile (ninja) -- this can take a while, be patient"
# ---------------------------------------------------------------------------
cd "$SRC_DIR/builddir"
ninja

[[ -x src/xdg-desktop-portal ]] || die "Build failed, output binary not found."

# ---------------------------------------------------------------------------
log "Step 7/7: Backup old binary, install the patched one"
# ---------------------------------------------------------------------------
mkdir -p "$BACKUP_DIR"
pkill -9 -f "$PORTAL_BIN\$" > /dev/null 2>&1 || true

if [[ -f "$PORTAL_BIN" && ! -f "$BACKUP_DIR/xdg-desktop-portal.orig" ]]; then
    cp "$PORTAL_BIN" "$BACKUP_DIR/xdg-desktop-portal.orig"
    log "Original binary backed up to: $BACKUP_DIR/xdg-desktop-portal.orig"
fi

cp "$SRC_DIR/builddir/src/xdg-desktop-portal" "$PORTAL_BIN"
chmod 755 "$PORTAL_BIN"

log "DONE. xdg-desktop-portal has been patched and installed at:"
echo "    $PORTAL_BIN"
echo
echo "How to use:"
echo "  1. Make sure xdg-desktop-portal-kde is also running (same D-Bus session):"
echo "     $PREFIX/lib/libexec/xdg-desktop-portal-kde &"
echo "  2. Run the patched daemon:"
echo "     $PORTAL_BIN &"
echo "  3. Open chromium-browser and try Ctrl+O / file upload."
echo
echo "To roll back to the original binary:"
echo "  cp $BACKUP_DIR/xdg-desktop-portal.orig $PORTAL_BIN"
FIXPORTALEOF
chmod +x "$HOME/fix-xdg-desktop-portal.sh"
"$HOME/fix-xdg-desktop-portal.sh" || echo "   [!] xdg-desktop-portal fix failed or was skipped. You can re-run it later with: ~/fix-xdg-desktop-portal.sh"

echo "=================================================="
echo " DONE"
echo "=================================================="
echo "All packages are installed. Next steps (manual):"
echo "1. Open the 'Anland Termux' app on Android."
echo "2. Run: ~/startplasma-anland.sh"

apt-mark hold xwayland mesa mesa-vulkan-icd-freedreno weston layer-shell-qt mutter libical spidermonkey
