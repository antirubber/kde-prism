#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

KDE_THEME_NAME="kde-prism"
COLORSCHEME_NAME="KDEPrism"
GNOME_THEME_NAME="gnome-prism"
PREFIX="${HOME}"

usage() {
  cat <<EOF
Usage: $0 [--prefix <path>] [--help]

Remove ${KDE_THEME_NAME} files from KDE Plasma user paths.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      [[ $# -ge 2 ]] || { echo "Missing value for --prefix" >&2; exit 1; }
      PREFIX="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

COLORSCHEME_DEST="${PREFIX}/.local/share/color-schemes/${COLORSCHEME_NAME}.colors"
PLASMA_THEME_DEST="${PREFIX}/.local/share/plasma/desktoptheme/${KDE_THEME_NAME}"
KONSOLE_DEST="${PREFIX}/.local/share/konsole/${COLORSCHEME_NAME}.colorscheme"
GTK_THEME_DEST_LEGACY="${PREFIX}/.themes/${GNOME_THEME_NAME}"
GTK_THEME_DEST_XDG="${PREFIX}/.local/share/themes/${GNOME_THEME_NAME}"
GTK4_OVERRIDE_DEST="${PREFIX}/.config/gtk-4.0/gtk.css"
ICONS_DEST_LEGACY="${PREFIX}/.icons/${GNOME_THEME_NAME}"
ICONS_DEST_XDG="${PREFIX}/.local/share/icons/${GNOME_THEME_NAME}"
BACKGROUNDS_DEST="${PREFIX}/.local/share/backgrounds/${GNOME_THEME_NAME}"
APPS_DEST="${PREFIX}/.local/share/applications"
VIVALDI_MODS_DEST="${PREFIX}/.local/share/kde-prism/vivaldi"
DM_MONO_DIR="${PREFIX}/.local/share/fonts/DMMono"

rm -rf "${COLORSCHEME_DEST}"
rm -rf "${PLASMA_THEME_DEST}"
rm -f  "${KONSOLE_DEST}"
rm -rf "${GTK_THEME_DEST_LEGACY}" "${GTK_THEME_DEST_XDG}"
rm -f  "${GTK4_OVERRIDE_DEST}"
rm -rf "${ICONS_DEST_LEGACY}" "${ICONS_DEST_XDG}"
rm -rf "${BACKGROUNDS_DEST}"
rm -rf "${VIVALDI_MODS_DEST}"
rm -rf "${DM_MONO_DIR}"
rm -f  "${PREFIX}/.config/gtk-3.0/settings.ini"
rm -f  "${PREFIX}/.gtkrc-2.0"

rm -f "${APPS_DEST}/firefox_firefox.desktop"
rm -f "${APPS_DEST}/thunderbird_thunderbird.desktop"
rm -f "${APPS_DEST}/snap-store_snap-store.desktop"
rm -f "${APPS_DEST}/spotify_spotify.desktop"
rm -f "${APPS_DEST}/factory-reset-tools_factory-reset-tools.desktop"
rm -f "${APPS_DEST}/firmware-updater_firmware-updater.desktop"
rm -f "${APPS_DEST}/firmware-updater_firmware-updater-app.desktop"
rm -f "${APPS_DEST}/com.yubico.yubioath.desktop"

fc-cache -f "${PREFIX}/.local/share/fonts" 2>/dev/null || true

rm -rf "${PREFIX}/.cache/plasma"* 2>/dev/null || true
rm -rf "${PREFIX}/.cache/kconfig"* 2>/dev/null || true
rm -rf "${PREFIX}/.cache/icon-cache.kcache" 2>/dev/null || true

if [[ "${PREFIX}" == "${HOME}" ]]; then
  for cmd in kwriteconfig6 kwriteconfig5; do
    if command -v "${cmd}" >/dev/null 2>&1; then
      "${cmd}" --file kdeglobals --group General --key ColorScheme --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group General --key font --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group General --key fixed --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group General --key toolBarFont --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group General --key menuFont --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group WM --key activeFont --delete 2>/dev/null || true
      "${cmd}" --file kdeglobals --group Icons --key Theme --delete 2>/dev/null || true
      "${cmd}" --file plasmarc --group Theme --key name --delete 2>/dev/null || true
      "${cmd}" --file plasmashellrc --group "PlasmaViews" --group "Panel 1" --key thickness --delete 2>/dev/null || true
      "${cmd}" --file plasmashellrc --group "PlasmaViews" --group "Panel 1" --key location --delete 2>/dev/null || true
      "${cmd}" --file plasmashellrc --group "PlasmaViews" --group "Panel 1" --key floating --delete 2>/dev/null || true
      "${cmd}" --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image --delete 2>/dev/null || true
      "${cmd}" --file konsolerc --group "Desktop Entry" --key DefaultProfile --delete 2>/dev/null || true
      break
    fi
  done
fi

echo "Removed:"
echo "  ${COLORSCHEME_DEST}"
echo "  ${PLASMA_THEME_DEST}"
echo "  ${KONSOLE_DEST}"
echo "  ${GTK_THEME_DEST_LEGACY}"
echo "  ${GTK_THEME_DEST_XDG}"
echo "  ${GTK4_OVERRIDE_DEST}"
echo "  ${ICONS_DEST_LEGACY}"
echo "  ${ICONS_DEST_XDG}"
echo "  ${BACKGROUNDS_DEST}"
echo "  ${VIVALDI_MODS_DEST}"
echo "  ${DM_MONO_DIR}"
echo "  ${PREFIX}/.config/gtk-3.0/settings.ini"
echo "  ${PREFIX}/.gtkrc-2.0"
echo ""
echo "Color scheme, icon theme, plasma theme, and font settings have been reset."
echo "Plasma caches have been cleared."
echo "Log out and back in for all changes to take effect."