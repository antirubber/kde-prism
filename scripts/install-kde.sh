#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

KDE_THEME_NAME="kde-prism"
COLORSCHEME_NAME="KDEPrism"
GNOME_THEME_NAME="gnome-prism"
PREFIX="${HOME}"

download_file() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "${dest}" "${url}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${dest}" "${url}"
  else
    echo "Error: neither curl nor wget found; cannot download ${url}" >&2
    return 1
  fi
}

kwriteconfig_cmd=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig_cmd="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig_cmd="kwriteconfig5"
fi

usage() {
  cat <<EOF
Usage: $0 [--prefix <path>] [--help]

Install ${KDE_THEME_NAME} for KDE Plasma.
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

if [[ "${PREFIX}" == "${HOME}" ]] && [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run this script with sudo or as root." >&2
  exit 1
fi

# ── Source paths (all local, no gnome-prism dependency) ──────────────────────
KDE_THEME_SRC="${REPO_ROOT}/themes/${KDE_THEME_NAME}"
COLORSCHEME_SRC="${KDE_THEME_SRC}/plasma-colors/${COLORSCHEME_NAME}.colors"
PLASMA_THEME_SRC="${KDE_THEME_SRC}/plasma-theme"
KONSOLE_SRC="${KDE_THEME_SRC}/konsole/${COLORSCHEME_NAME}.colorscheme"

GTK_THEME_SRC="${KDE_THEME_SRC}"
ICONS_SRC="${KDE_THEME_SRC}/icons/${GNOME_THEME_NAME}"
BACKGROUNDS_SRC="${REPO_ROOT}/assets/backgrounds"
CURSOR_TEMPLATE="${REPO_ROOT}/apps/cursor/gnome-prism-settings.json"
FIREFOX_USERCHROME_CSS="${REPO_ROOT}/apps/firefox/userchrome/userChrome.css"
FIREFOX_USERCONTENT_CSS="${REPO_ROOT}/apps/firefox/userchrome/userContent.css"
FIREFOX_THEME_DIR="${REPO_ROOT}/apps/firefox/gnome-prism-theme"
VIVALDI_CSS="${REPO_ROOT}/apps/vivaldi/mods/custom.css"

# ── Dest paths ────────────────────────────────────────────────────────────────
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

CURSOR_SETTINGS_DIR="${PREFIX}/.config/Cursor/User"
CURSOR_SETTINGS_DEST="${CURSOR_SETTINGS_DIR}/settings.json"

VIVALDI_MODS_DEST="${PREFIX}/.local/share/kde-prism/vivaldi/mods"

# ── Check for KDE Plasma ─────────────────────────────────────────────────────
is_kde=false
if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] && echo "${XDG_CURRENT_DESKTOP}" | grep -qi "KDE"; then
  is_kde=true
fi
if [[ "${DESKTOP_SESSION:-}" == plasma* ]] || [[ "${DESKTOP_SESSION:-}" == *plasma* ]]; then
  is_kde=true
fi
if ! ${is_kde} && [[ "${PREFIX}" == "${HOME}" ]]; then
  echo "Note: KDE Plasma session not detected. Theme files will still be installed," >&2
  echo "but live settings application requires a running Plasma session." >&2
fi

if [[ ! -d "${KDE_THEME_SRC}" ]]; then
  echo "Error: KDE theme source not found: ${KDE_THEME_SRC}" >&2
  exit 1
fi

# ******************************************************************************
# 1. Font: DM Mono
# ******************************************************************************
if ! fc-list | grep -qi "DM Mono"; then
  echo
  echo "=== FONT: DM Mono ==="
  DM_MONO_DIR="${PREFIX}/.local/share/fonts/DMMono"
  mkdir -p "${DM_MONO_DIR}"
  DM_MONO_BASE_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/dmmono"
  DM_MONO_FILES=(DMMono-Light DMMono-LightItalic DMMono-Regular DMMono-Italic DMMono-Medium DMMono-MediumItalic)
  dm_mono_ok=true
  for style in "${DM_MONO_FILES[@]}"; do
    if ! download_file "${DM_MONO_BASE_URL}/${style}.ttf" "${DM_MONO_DIR}/${style}.ttf"; then
      dm_mono_ok=false
      break
    fi
  done
  if ${dm_mono_ok}; then
    fc-cache -f "${DM_MONO_DIR}" 2>/dev/null || true
    echo "Installed DM Mono font to ${DM_MONO_DIR}"
  else
    echo "Warning: failed to download DM Mono font." >&2
  fi
else
  echo
  echo "=== FONT: DM Mono ==="
  echo "DM Mono already installed; skipping."
fi

# ******************************************************************************
# 2. Plasma Color Scheme
# ******************************************************************************
if [[ -f "${COLORSCHEME_SRC}" ]]; then
  echo
  echo "=== PLASMA COLOR SCHEME ==="
  mkdir -p "$(dirname "${COLORSCHEME_DEST}")"
  cp -f "${COLORSCHEME_SRC}" "${COLORSCHEME_DEST}"
  echo "Installed color scheme to ${COLORSCHEME_DEST}"

  if [[ "${PREFIX}" == "${HOME}" ]]; then
    if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
      plasma-apply-colorscheme "${COLORSCHEME_NAME}" || true
      echo "Applied color scheme: ${COLORSCHEME_NAME}"
    elif [[ -n "${kwriteconfig_cmd}" ]]; then
      "${kwriteconfig_cmd}" --file kdeglobals --group General --key ColorScheme "${COLORSCHEME_NAME}" || true
      echo "Set color scheme via ${kwriteconfig_cmd}"
    fi
  fi
fi

# ******************************************************************************
# 3. Plasma Desktop Theme
# ******************************************************************************
if [[ -d "${PLASMA_THEME_SRC}" ]]; then
  echo
  echo "=== PLASMA DESKTOP THEME ==="
  mkdir -p "${PREFIX}/.local/share/plasma/desktoptheme"
  rm -rf "${PLASMA_THEME_DEST}"
  cp -a "${PLASMA_THEME_SRC}" "${PLASMA_THEME_DEST}"
  echo "Installed Plasma theme to ${PLASMA_THEME_DEST}"

  if [[ "${PREFIX}" == "${HOME}" ]] && [[ -n "${kwriteconfig_cmd}" ]]; then
    "${kwriteconfig_cmd}" --file plasmarc --group Theme --key name "${KDE_THEME_NAME}" || true
    echo "Set Plasma theme to ${KDE_THEME_NAME}"
  fi
fi

# ******************************************************************************
# 4. GTK Theme (for GTK apps running under KDE)
# ******************************************************************************
if [[ -d "${GTK_THEME_SRC}" ]]; then
  echo
  echo "=== GTK THEME (for GTK apps) ==="
  mkdir -p "${PREFIX}/.themes" "${PREFIX}/.local/share/themes"
  rm -rf "${GTK_THEME_DEST_LEGACY}" "${GTK_THEME_DEST_XDG}"
  cp -a "${GTK_THEME_SRC}" "${GTK_THEME_DEST_LEGACY}"
  cp -a "${GTK_THEME_SRC}" "${GTK_THEME_DEST_XDG}"
  echo "Installed GTK theme to ${GTK_THEME_DEST_LEGACY}"
  echo "Installed GTK theme to ${GTK_THEME_DEST_XDG}"

  mkdir -p "${PREFIX}/.config/gtk-3.0"
  cat > "${PREFIX}/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=${GNOME_THEME_NAME}
gtk-icon-theme-name=${GNOME_THEME_NAME}
gtk-font-name=DM Mono, 10
gtk-application-prefer-dark-theme=1
EOF
  echo "Configured GTK3 settings"

  cat > "${PREFIX}/.gtkrc-2.0" <<EOF
gtk-theme-name="${GNOME_THEME_NAME}"
gtk-icon-theme-name="${GNOME_THEME_NAME}"
gtk-font-name="DM Mono, 10"
EOF
  echo "Configured GTK2 settings"

  GTK4_OVERRIDE_SRC="${KDE_THEME_SRC}/gtk-4.0/gtk.css"
  if [[ -f "${GTK4_OVERRIDE_SRC}" ]]; then
    mkdir -p "$(dirname "${GTK4_OVERRIDE_DEST}")"
    cp -f "${GTK4_OVERRIDE_SRC}" "${GTK4_OVERRIDE_DEST}"
    echo "Installed GTK4 override to ${GTK4_OVERRIDE_DEST}"
  fi
fi

# ******************************************************************************
# 5. Icon Theme
# ******************************************************************************
if [[ -d "${ICONS_SRC}" ]]; then
  echo
  echo "=== ICON THEME ==="
  mkdir -p "${PREFIX}/.icons" "${PREFIX}/.local/share/icons"
  rm -rf "${ICONS_DEST_LEGACY}" "${ICONS_DEST_XDG}"
  cp -a "${ICONS_SRC}" "${ICONS_DEST_LEGACY}"
  cp -a "${ICONS_SRC}" "${ICONS_DEST_XDG}"
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t -f "${ICONS_DEST_LEGACY}" || true
    gtk-update-icon-cache -q -t -f "${ICONS_DEST_XDG}" || true
  fi
  echo "Installed icon theme to ${ICONS_DEST_LEGACY}"
  echo "Installed icon theme to ${ICONS_DEST_XDG}"

  if [[ "${PREFIX}" == "${HOME}" ]] && [[ -n "${kwriteconfig_cmd}" ]]; then
    "${kwriteconfig_cmd}" --file kdeglobals --group Icons --key Theme "${GNOME_THEME_NAME}" || true
    echo "Set icon theme to ${GNOME_THEME_NAME}"
  fi
fi

# ******************************************************************************
# 6. Wallpaper / Backgrounds
# ******************************************************************************
if [[ -d "${BACKGROUNDS_SRC}" ]]; then
  echo
  echo "=== WALLPAPER ==="
  mkdir -p "${PREFIX}/.local/share/backgrounds"
  rm -rf "${BACKGROUNDS_DEST}"
  cp -a "${BACKGROUNDS_SRC}" "${BACKGROUNDS_DEST}"
  echo "Installed backgrounds to ${BACKGROUNDS_DEST}"

  if [[ "${PREFIX}" == "${HOME}" ]]; then
    shopt -s nullglob
    background_files=("${BACKGROUNDS_DEST}"/*)
    shopt -u nullglob
    if ((${#background_files[@]} > 0)); then
      default_background="${BACKGROUNDS_DEST}/gnome-prism-default-background.jpg"
      if [[ ! -f "${default_background}" ]]; then
        default_background="${background_files[0]}"
      fi

      if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        plasma-apply-wallpaperimage "${default_background}" || true
        echo "Applied wallpaper via plasma-apply-wallpaperimage"
      elif [[ -n "${kwriteconfig_cmd}" ]]; then
        "${kwriteconfig_cmd}" --file plasma-org.kde.plasma.desktop-appletsrc \
          --group Containments --group 1 --group Wallpaper --group org.kde.image --group General \
          --key Image "file://${default_background}" 2>/dev/null || true
        echo "Set wallpaper via ${kwriteconfig_cmd}"
      fi

      if [[ -n "${kwriteconfig_cmd}" ]]; then
        "${kwriteconfig_cmd}" --file kscreenlockerrc \
          --group Greeter --group Wallpaper --group org.kde.image --group General \
          --key Image "file://${default_background}" 2>/dev/null || true
        echo "Set lock screen background"
      fi
    fi
  fi
fi

# ******************************************************************************
# 7. Konsole Color Scheme
# ******************************************************************************
if [[ -f "${KONSOLE_SRC}" ]]; then
  echo
  echo "=== KONSOLE COLOR SCHEME ==="
  mkdir -p "$(dirname "${KONSOLE_DEST}")"
  cp -f "${KONSOLE_SRC}" "${KONSOLE_DEST}"
  echo "Installed Konsole color scheme to ${KONSOLE_DEST}"
fi

# ******************************************************************************
# 7b. Konsole Profile
# ******************************************************************************
KONSOLE_PROFILE_SRC="${REPO_ROOT}/apps/konsole/KDEPrism.profile"
KONSOLE_PROFILE_DEST="${PREFIX}/.local/share/konsole/KDEPrism.profile"
if [[ -f "${KONSOLE_PROFILE_SRC}" ]]; then
  echo
  echo "=== KONSOLE PROFILE ==="
  mkdir -p "$(dirname "${KONSOLE_PROFILE_DEST}")"
  cp -f "${KONSOLE_PROFILE_SRC}" "${KONSOLE_PROFILE_DEST}"
  echo "Installed Konsole profile to ${KONSOLE_PROFILE_DEST}"
fi

# ******************************************************************************
# 7c. Alacritty Color Theme
# ******************************************************************************
ALACRITTY_SRC="${REPO_ROOT}/apps/alacritty/kde-prism.toml"
ALACRITTY_DEST="${PREFIX}/.config/alacritty/themes/kde-prism.toml"
if [[ -f "${ALACRITTY_SRC}" ]]; then
  echo
  echo "=== ALACRITTY COLOR THEME ==="
  mkdir -p "$(dirname "${ALACRITTY_DEST}")"
  cp -f "${ALACRITTY_SRC}" "${ALACRITTY_DEST}"
  echo "Installed Alacritty theme to ${ALACRITTY_DEST}"
  if [[ ! -f "${PREFIX}/.config/alacritty/alacritty.toml" ]]; then
    mkdir -p "${PREFIX}/.config/alacritty"
    cat > "${PREFIX}/.config/alacritty/alacritty.toml" <<'ALACRITTY_EOF'
import = ["~/.config/alacritty/themes/kde-prism.toml"]
ALACRITTY_EOF
    echo "Created minimal alacritty.toml with theme import"
  fi
fi

# ******************************************************************************
# 7d. Kitty Color Theme
# ******************************************************************************
KITTY_SRC="${REPO_ROOT}/apps/kitty/kde-prism.conf"
KITTY_DEST="${PREFIX}/.config/kitty/themes/kde-prism.conf"
if [[ -f "${KITTY_SRC}" ]]; then
  echo
  echo "=== KITTY COLOR THEME ==="
  mkdir -p "$(dirname "${KITTY_DEST}")"
  cp -f "${KITTY_SRC}" "${KITTY_DEST}"
  echo "Installed Kitty theme to ${KITTY_DEST}"
  if [[ -f "${PREFIX}/.config/kitty/kitty.conf" ]]; then
    echo "To enable in Kitty, add to kitty.conf:"
    echo "  include themes/kde-prism.conf"
  fi
fi

# ******************************************************************************
# 7e. Kate Color Scheme
# ******************************************************************************
KATE_SRC="${REPO_ROOT}/apps/kate/kde-prism.xml"
KATE_DEST="${PREFIX}/.local/share/katecolor-schemes/kde-prism.xml"
if [[ -f "${KATE_SRC}" ]]; then
  echo
  echo "=== KATE COLOR SCHEME ==="
  mkdir -p "$(dirname "${KATE_DEST}")"
  cp -f "${KATE_SRC}" "${KATE_DEST}"
  echo "Installed Kate color scheme to ${KATE_DEST}"
fi

# ******************************************************************************
# 8. KDE Font Configuration
# ******************************************************************************
if [[ "${PREFIX}" == "${HOME}" ]] && [[ -n "${kwriteconfig_cmd}" ]]; then
  echo
  echo "=== FONT CONFIGURATION ==="
  "${kwriteconfig_cmd}" --file kdeglobals --group General --key font "DM Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
  "${kwriteconfig_cmd}" --file kdeglobals --group General --key fixed "DM Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
  "${kwriteconfig_cmd}" --file kdeglobals --group General --key toolBarFont "DM Mono,9,-1,5,50,0,0,0,0,0" 2>/dev/null || true
  "${kwriteconfig_cmd}" --file kdeglobals --group General --key menuFont "DM Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
  "${kwriteconfig_cmd}" --file kdeglobals --group WM --key activeFont "DM Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
  echo "Set KDE fonts to DM Mono"
fi

# ******************************************************************************
# 9. Panel Configuration
# ******************************************************************************
if [[ "${PREFIX}" == "${HOME}" ]] && [[ -n "${kwriteconfig_cmd}" ]]; then
  echo
  echo "=== PANEL CONFIGURATION ==="
  "${kwriteconfig_cmd}" --file plasmashellrc \
    --group "PlasmaViews" --group "Panel 1" --group "Defaults" \
    --key thickness 55 2>/dev/null || true
  "${kwriteconfig_cmd}" --file plasmashellrc \
    --group "PlasmaViews" --group "Panel 1" \
    --key thickness 55 2>/dev/null || true
  "${kwriteconfig_cmd}" --file plasmashellrc \
    --group "PlasmaViews" --group "Panel 1" \
    --key location 3 2>/dev/null || true
  "${kwriteconfig_cmd}" --file plasmashellrc \
    --group "PlasmaViews" --group "Panel 1" \
    --key floating 0 2>/dev/null || true
  echo "Configured panel height to 55px at bottom."
fi

# ******************************************************************************
# 10. Desktop Entry Overrides (Snap apps)
# ******************************************************************************
install_desktop_override() {
  local src="${1:-}" dest="${2:-}" icon_name="${3:-}"
  [[ -f "${src}" ]] || return 0
  mkdir -p "${APPS_DEST}"
  python3 - "${src}" "${dest}" "${icon_name}" <<'PY'
import pathlib, re, sys
src = pathlib.Path(sys.argv[1])
dest = pathlib.Path(sys.argv[2])
icon = sys.argv[3]
text = src.read_text(encoding="utf-8")
if re.search(r"^Icon=.*$", text, flags=re.M):
    text = re.sub(r"^Icon=.*$", f"Icon={icon}", text, flags=re.M)
else:
    text += f"\nIcon={icon}\n"
dest.write_text(text, encoding="utf-8")
PY
  echo "  ${dest}"
}

echo
echo "=== DESKTOP ENTRY OVERRIDES ==="

install_desktop_override \
  "/var/lib/snapd/desktop/applications/firefox_firefox.desktop" \
  "${APPS_DEST}/firefox_firefox.desktop" \
  "firefox_firefox"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/thunderbird_thunderbird.desktop" \
  "${APPS_DEST}/thunderbird_thunderbird.desktop" \
  "thunderbird_thunderbird"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/snap-store_snap-store.desktop" \
  "${APPS_DEST}/snap-store_snap-store.desktop" \
  "snap-store_snap-store"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/spotify_spotify.desktop" \
  "${APPS_DEST}/spotify_spotify.desktop" \
  "spotify_spotify"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/factory-reset-tools_factory-reset-tools.desktop" \
  "${APPS_DEST}/factory-reset-tools_factory-reset-tools.desktop" \
  "factory-reset-tools_factory-reset-tools"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/firmware-updater_firmware-updater.desktop" \
  "${APPS_DEST}/firmware-updater_firmware-updater.desktop" \
  "firmware-updater_firmware-updater"

install_desktop_override \
  "/var/lib/snapd/desktop/applications/firmware-updater_firmware-updater-app.desktop" \
  "${APPS_DEST}/firmware-updater_firmware-updater-app.desktop" \
  "firmware-updater_firmware-updater"

install_desktop_override \
  "${PREFIX}/.local/share/applications/com.yubico.yubioath.desktop" \
  "${APPS_DEST}/com.yubico.yubioath.desktop" \
  "com.yubico.yubioath"

# ******************************************************************************
# 11. Cursor / VS Code Settings
# ******************************************************************************
if [[ -f "${CURSOR_TEMPLATE}" ]]; then
  echo
  echo "=== CURSOR / VS CODE SETTINGS ==="
  if [[ -d "${CURSOR_SETTINGS_DIR}" ]] || ([[ "${PREFIX}" == "${HOME}" ]] && command -v cursor >/dev/null 2>&1); then
    mkdir -p "${CURSOR_SETTINGS_DIR}"
    python3 - "${CURSOR_SETTINGS_DEST}" "${CURSOR_TEMPLATE}" <<'PY'
import json, pathlib, sys

dest = pathlib.Path(sys.argv[1])
template = pathlib.Path(sys.argv[2])

template_data = json.loads(template.read_text(encoding="utf-8"))
if dest.exists():
    try:
        dest_data = json.loads(dest.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Cursor settings JSON is invalid ({dest}): {exc}") from exc
else:
    dest_data = {}

def merge_dict(base, overlay):
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            merge_dict(base[key], value)
        else:
            base[key] = value

merge_dict(dest_data, template_data)
if dest_data.get("window.titleBarStyle") == "native" and "window.titleBarStyle" not in template_data:
    del dest_data["window.titleBarStyle"]
dest.write_text(json.dumps(dest_data, indent=2) + "\n", encoding="utf-8")
PY
    echo "Applied Cursor settings to ${CURSOR_SETTINGS_DEST}"
  fi
fi

# ******************************************************************************
# 12. Firefox userChrome
# ******************************************************************************
if [[ "${PREFIX}" == "${HOME}" ]] && [[ -f "${FIREFOX_USERCHROME_CSS}" ]]; then
  echo
  echo "=== FIREFOX ADVANCED THEMING ==="

  FIREFOX_DIR="${PREFIX}/.mozilla/firefox"
  SNAP_FIREFOX_COMMON_DIR="${PREFIX}/snap/firefox/common/.mozilla/firefox"
  SNAP_FIREFOX_CURRENT_DIR="${PREFIX}/snap/firefox/current/.mozilla/firefox"
  PROFILES_INI=""
  PROFILE_PATH=""

  for candidate in "${FIREFOX_DIR}" "${SNAP_FIREFOX_COMMON_DIR}" "${SNAP_FIREFOX_CURRENT_DIR}"; do
    if [[ -f "${candidate}/profiles.ini" ]]; then
      PROFILES_INI="${candidate}/profiles.ini"
      FIREFOX_DIR="${candidate}"
      break
    fi
  done

  if [[ -n "${PROFILES_INI}" ]]; then
    PROFILE_PATH="$(python3 - "${PROFILES_INI}" "${FIREFOX_DIR}" "" <<'PY'
import configparser, pathlib, sys
profiles_ini = pathlib.Path(sys.argv[1])
firefox_dir = pathlib.Path(sys.argv[2])
cp = configparser.RawConfigParser()
cp.read(profiles_ini, encoding="utf-8")
candidates = []
for section in cp.sections():
    if not section.startswith("Profile"):
        continue
    name = cp.get(section, "Name", fallback="")
    path = cp.get(section, "Path", fallback="")
    is_relative = cp.getint(section, "IsRelative", fallback=1)
    if not path:
        continue
    resolved = (firefox_dir / path) if is_relative == 1 else pathlib.Path(path)
    default = cp.getint(section, "Default", fallback=0)
    candidates.append({"name": name, "default": default, "path": resolved})
if not candidates:
    raise SystemExit("No Firefox profiles found")
defaults = [item for item in candidates if item["default"] == 1]
chosen = defaults[0] if defaults else candidates[0]
print(str(chosen["path"]))
PY
)"
  fi

  if [[ -n "${PROFILE_PATH}" ]] && [[ -d "${PROFILE_PATH}" ]]; then
    CHROME_DIR="${PROFILE_PATH}/chrome"
    mkdir -p "${CHROME_DIR}"
    cp -f "${FIREFOX_USERCHROME_CSS}" "${CHROME_DIR}/userChrome.css"
    cp -f "${FIREFOX_USERCONTENT_CSS}" "${CHROME_DIR}/userContent.css"

    USER_JS="${PROFILE_PATH}/user.js"
    python3 - "${USER_JS}" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
pref_line = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
text = path.read_text(encoding="utf-8") if path.exists() else ""
pattern = r'^user_pref\("toolkit\.legacyUserProfileCustomizations\.stylesheets",\s*(true|false)\s*\);\s*$'
if re.search(pattern, text, flags=re.M):
    text = re.sub(pattern, pref_line, text, flags=re.M)
else:
    if text and not text.endswith("\n"):
        text += "\n"
    text += pref_line + "\n"
path.write_text(text, encoding="utf-8")
PY
    echo "Installed Firefox userChrome.css to ${CHROME_DIR}/userChrome.css"
  else
    echo "Warning: No Firefox profile found; skipping userChrome." >&2
  fi
fi

# ******************************************************************************
# 13. Vivaldi UI Mod
# ******************************************************************************
if [[ -f "${VIVALDI_CSS}" ]]; then
  echo
  echo "=== VIVALDI UI MOD ==="
  mkdir -p "${VIVALDI_MODS_DEST}"
  cp -f "${VIVALDI_CSS}" "${VIVALDI_MODS_DEST}/custom.css"
  echo "Installed Vivaldi CSS mod to ${VIVALDI_MODS_DEST}"

  if [[ "${PREFIX}" == "${HOME}" ]]; then
    cat <<EOF
Enable in Vivaldi:
  1) Open vivaldi://flags and turn on "Allow CSS modifications"
  2) Open vivaldi://settings/appearance
  3) Set Custom UI Modifications folder to:
     ${PREFIX}/.local/share/kde-prism/vivaldi/mods
  4) Restart Vivaldi
EOF
  fi
fi

# ******************************************************************************
# 14. Clear Plasma cache
# ******************************************************************************
echo
echo "=== CLEARING PLASMA CACHE ==="
rm -rf "${PREFIX}/.cache/plasma"* 2>/dev/null || true
rm -rf "${PREFIX}/.cache/kconfig"* 2>/dev/null || true
rm -rf "${PREFIX}/.cache/icon-cache.kcache" 2>/dev/null || true
echo "Cleared Plasma theme/icon caches"

# ******************************************************************************
# Done
# ******************************************************************************
cat <<EOF

Installation complete.

What was applied:
  - Plasma color scheme:  ${COLORSCHEME_NAME}
  - Plasma desktop theme: ${KDE_THEME_NAME}
  - Icon theme:           ${GNOME_THEME_NAME}
  - GTK theme:            ${GNOME_THEME_NAME} (for GTK apps under KDE)
  - Konsole scheme:       ${COLORSCHEME_NAME}
  - Alacritty theme:      kde-prism
  - Kitty theme:          kde-prism
  - Kate color scheme:     kde-prism
  - Wallpaper and fonts

To apply all changes immediately, restart plasmashell:
  systemctl restart --user plasma-plasmashell
  # or: plasmashell --replace &

Or log out and back in.

To manually select the color scheme:
  System Settings → Appearance → Colors → KDE Prism

To manually select the Plasma Style:
  System Settings → Appearance → Plasma Style → kde-prism

To manually select the icon theme:
  System Settings → Appearance → Icons → gnome-prism

NOTE: Compatible with KDE Plasma 6 (Debian 13/Trixie) and Plasma 5.
EOF