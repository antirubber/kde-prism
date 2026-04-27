# kde-prism

A desktop theme for KDE Plasma with a dark, high-contrast aesthetic.

Adapted from [gnome-prism](https://github.com/zachfeldman/gnome-prism) by Zach Feldman, originally designed by Gaurav Singh with design input from Ross Jernigan.

**Design tokens:**
- Background: `#000000`
- Accent/stroke: `#BDA7F0` (lavender)
- Highlight: `#FF7447` (orange)
- Surface: `#191919`

## What's included

| Component | Path | Description |
|---|---|---|
| Plasma color scheme | `themes/kde-prism/plasma-colors/KDEPrism.colors` | System-wide KDE color palette |
| Plasma desktop theme | `themes/kde-prism/plasma-theme/` | Plasma shell theme (metadata.json + colors, Plasma 6 format) |
| Konsole color scheme | `themes/kde-prism/konsole/KDEPrism.colorscheme` | Terminal emulator palette |
| Konsole profile | `apps/konsole/KDEPrism.profile` | Konsole profile with font + theme |
| Alacritty theme | `apps/alacritty/kde-prism.toml` | Terminal emulator theme |
| Kitty theme | `apps/kitty/kde-prism.conf` | Terminal emulator theme |
| Kate color scheme | `apps/kate/kde-prism.xml` | KDE advanced text editor theme |
| GTK theme | `themes/kde-prism/` (gtk-3.0, gtk-4.0) | GTK 3/4 theme for GTK apps under KDE |
| Icon theme | `themes/kde-prism/icons/gnome-prism/` | 100+ app + status icons (inherits Breeze) |
| Wallpaper | `assets/backgrounds/` | Default background |
| Firefox userChrome | `apps/firefox/userchrome/` | Browser chrome overrides |
| Firefox theme add-on | `apps/firefox/gnome-prism-theme/` | Firefox theme manifest |
| Vivaldi CSS mod | `apps/vivaldi/mods/custom.css` | Browser UI overrides |
| Cursor/VS Code settings | `apps/cursor/gnome-prism-settings.json` | Editor color theme |
| VS Code color theme | `apps/vscode/gnome-prism-color-theme.json` | VS Code standalone theme |
| Tilix color scheme | `apps/tilix/gnome-prism.json` | Terminal palette (design tokens reference) |

## Install

```bash
./scripts/install-kde.sh
```

This installs:
- Plasma color scheme to `~/.local/share/color-schemes/`
- Plasma desktop theme to `~/.local/share/plasma/desktoptheme/`
- Konsole color scheme to `~/.local/share/konsole/`
- GTK theme to `~/.themes/` and `~/.local/share/themes/`
- GTK4/libadwaita override to `~/.config/gtk-4.0/gtk.css`
- Icon theme to `~/.icons/` and `~/.local/share/icons/`
- Wallpaper to `~/.local/share/backgrounds/`
- DM Mono font to `~/.local/share/fonts/`
- Desktop entry overrides for Snap apps
- Cursor/VS Code color settings
- Firefox userChrome.css
- Vivaldi CSS mod

And applies settings via `kwriteconfig6` (or `kwriteconfig5`), `plasma-apply-colorscheme`, and `plasma-apply-wallpaperimage` where available.

After running the install script, restart plasmashell for all changes to take effect:

```bash
systemctl restart --user plasma-plasmashell
```

## Uninstall

```bash
./scripts/uninstall-kde.sh
```

Removes all installed files, clears Plasma caches, and resets KDE color/icon/theme/font settings to defaults.

## Re-applying Theme Settings

If a Plasma update resets your settings, re-run the install script. To re-apply manually:

```bash
plasma-apply-colorscheme KDEPrism
kwriteconfig6 --file kdeglobals --group Icons --key Theme gnome-prism
kwriteconfig6 --file plasmarc --group Theme --key name kde-prism
```

## App-Specific Setup

### Firefox

Two levels of Firefox theming are available:

1. **Theme add-on** (`apps/firefox/gnome-prism-theme/`) — install as a temporary extension in Firefox
2. **userChrome.css** — deeper UI customization (applied automatically by install script)

### Vivaldi

The install script deploys the CSS mod to `~/.local/share/kde-prism/vivaldi/mods/`. Enable it:

1. Open `vivaldi://flags` and turn on "Allow CSS modifications"
2. Open `vivaldi://settings/appearance`
3. Set Custom UI Modifications folder to `~/.local/share/kde-prism/vivaldi/mods`
4. Restart Vivaldi

### Cursor / VS Code

The install script automatically applies `apps/cursor/gnome-prism-settings.json` to `~/.config/Cursor/User/settings.json`.

### Konsole

The install script copies the color scheme and profile. To use it:

1. Open Konsole → Settings → Edit Current Profile → Appearance
2. Select **KDE Prism** from the color scheme list

Or switch to the KDE Prism profile directly:

1. Open Konsole → Settings → Switch Profile → **KDE Prism**

### Alacritty

The install script copies the theme to `~/.config/alacritty/themes/kde-prism.toml`. If no `alacritty.toml` exists, it creates one with the theme import. For existing configs, add:

```toml
import = ["~/.config/alacritty/themes/kde-prism.toml"]
```

### Kitty

The install script copies the theme to `~/.config/kitty/themes/kde-prism.conf`. To enable:

```bash
echo 'include themes/kde-prism.conf' >> ~/.config/kitty/kitty.conf
```

Or in Kitty's terminal: `kitty +kitten themes kde-prism`

### Kate

The install script copies the color scheme to `~/.local/share/katecolor-schemes/kde-prism.xml`. To use it:

1. Open Kate → Settings → Configure Kate → Fonts & Colors
2. Select **kde-prism** from the scheme list

## Plasma 6 Compatibility

The theme uses **metadata.json** (Plasma 6 / KF6 format) for the desktop theme, which is required by Plasma 6 as shipped in Debian 13 (Trixie). Key compatibility details:

- **metadata.json** uses `"KPackageStructure": "Plasma/DesktopTheme"` for proper kpackage integration
- The desktop theme's `colors` file omits `[ColorEffects:Disabled]` and `[ColorEffects:Inactive]` sections per KDE docs (these belong only in the standalone `.colors` file)
- The standalone `.colors` file includes all sections including `[ColorEffects:Disabled]`, `[ColorEffects:Inactive]`, and `[Colors:Header]`
- The icon theme inherits from `breeze` first, then `Adwaita`, then `hicolor`
- The `plasmarc` file disables blur/contrast effects (appropriate for an opaque dark theme)
- The install script prefers `kwriteconfig6` (Plasma 6) and falls back to `kwriteconfig5` (Plasma 5)
- Plasma cache is cleared during install so theme changes are immediately visible

## Architecture

KDE Plasma uses a different theming system than GNOME:

- **Color schemes** (`~/.local/share/color-schemes/*.colors`) define the palette for all Qt/KDE widgets, including `[Colors:Window]`, `[Colors:View]`, `[Colors:Button]`, `[Colors:Header]`, `[Colors:Selection]`, `[Colors:Tooltip]`, and `[Colors:Complementary]`. This covers what the GTK theme and GNOME Shell CSS handle in the GNOME version.
- **Desktop themes** (`~/.local/share/plasma/desktoptheme/`) control Plasma shell visuals (panels, popups, widgets). This theme provides a `colors` file and `metadata.json` but no SVGs — it inherits Breeze's SVGs while overriding the color palette.
- **GTK theme** is still needed for GTK apps running under KDE. The install script copies the GTK3/GTK4 themes and configures `gtk-3.0/settings.ini` and `.gtkrc-2.0` for seamless integration.
- **Konsole color schemes** (`~/.local/share/konsole/*.colorscheme`) are the KDE equivalent of the Tilix terminal palette.

## Troubleshooting

**Theme not appearing in System Settings:**
1. Confirm install ran without `sudo`
2. Check `~/.local/share/plasma/desktoptheme/kde-prism/` exists
3. Check `~/.local/share/color-schemes/KDEPrism.colors` exists
4. Clear Plasma cache: `rm -rf ~/.cache/plasma* ~/.cache/kconfig* ~/.cache/icon-cache.kcache`
5. Restart plasmashell: `systemctl restart --user plasma-plasmashell`
6. If still not visible, log out and back in

**GTK apps not themed under KDE:**
1. Check `~/.config/gtk-3.0/settings.ini` has `gtk-theme-name=gnome-prism`
2. Check `~/.config/gtk-4.0/gtk.css` exists
3. Re-run `./scripts/install-kde.sh`

**Icons not showing:**
1. Run `gtk-update-icon-cache -q -t -f ~/.local/share/icons/gnome-prism`
2. Clear icon cache: `rm ~/.cache/icon-cache.kcache`
3. Log out and back in

## Credits

- **Gaurav Singh** — theme design
- **Ross Jernigan** ([@bonkrat](https://github.com/bonkrat)) — design input and guidance
- **Zach Feldman** ([@zachfeldman](https://github.com/zachfeldman)) — original [gnome-prism](https://github.com/zachfeldman/gnome-prism) implementation

The GTK themes, icon theme, Firefox userChrome, Vivaldi CSS mod, Cursor/VS Code settings, and wallpaper are adapted from [gnome-prism](https://github.com/zachfeldman/gnome-prism) under the MIT License.