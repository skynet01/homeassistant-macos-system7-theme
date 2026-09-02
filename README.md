# MacOS System 7 Theme for Home Assistant

[![Release](https://img.shields.io/github/v/release/skynet01/homeassistant-macos-system7-theme)](https://github.com/skynet01/homeassistant-macos-system7-theme/releases/latest)
[![HACS](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/hacs/integration)
[![License](https://img.shields.io/github/license/skynet01/homeassistant-macos-system7-theme)](LICENSE)
[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Theme-41BDF5)](https://www.home-assistant.io/)

A pair of global light themes that make Home Assistant feel like a Macintosh running
System 7. The primary version is designed for black-and-white e-ink displays; a color
variant keeps the same window chrome while using a restrained classic Mac palette.
Your existing dashboards and entities stay intact.

> [!WARNING]
> Most of this project was written by AI robots. It may be sloppy, overly specific,
> or broken by a future Home Assistant frontend update. Its primary target is an
> e-ink display, not universal perfection. Bug reports and cleanup pull requests are
> welcome.

## Screenshots

<table>
  <tr>
    <td width="50%"><img src="images/eink-display.jpg" alt="MacOS System 7 theme on a physical e-ink Home Assistant display"><br><sub>Monochrome theme on a physical e-ink panel</sub></td>
    <td width="50%"><img src="images/color-dashboard.jpg" alt="MacOS System 7 color theme dashboard"><br><sub>Color theme with graphs, gauges, bars, and entity rows</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="images/mobile-dashboard.jpg" alt="MacOS System 7 e-ink theme on a narrow mobile dashboard"><br><sub>Narrow dashboard with native rows, Bubble Card, and thermostat styling</sub></td>
    <td width="50%"><img src="images/system-dialog.png" alt="Home Assistant settings dialog styled like System 7"><br><sub>System 7 dialog controls on a Home Assistant configuration page</sub></td>
  </tr>
</table>

## Included themes

| Theme | Purpose |
|---|---|
| `MacOS System 7 eink theme` | Applies a frontend-wide grayscale filter, one-bit dithering, and e-ink-oriented contrast. |
| `MacOS System 7 color theme` | Preserves semantic colors with a restrained System 7 palette. |

Both themes provide square window frames, striped Chicago title bars, dithered desktop
wallpaper, Geneva body text, compact System 7 buttons, hard shadows, styled scrollbars,
left-side square state controls, readable sliders, global configuration-page styling,
and responsive spacing. They are normal global Home Assistant themes: no dashboard
configuration or bundled entities are required.

## Requirements

The complete interface treatment depends on both of these frontend extensions:

- [UI eXtension (UIX)](https://github.com/Lint-Free-Technology/uix) - required for
  reliable styling across Home Assistant shadow roots, dialogs, settings pages, rows,
  and current cards.
- [card-mod](https://github.com/thomasloven/lovelace-card-mod) - required for legacy
  compatibility paths and theme styling outside ordinary dashboard cards. Install it
  as a frontend module as described by card-mod if you want settings/sidebar styling
  to load everywhere.

Install both through HACS before enabling this theme. The YAML will load without them,
but much of the System 7 chrome will be missing.

## Supported custom cards

These integrations are optional. The theme contains explicit compatibility styling
for them when they are already used by a dashboard.

| Custom card | Theme coverage |
|---|---|
| [Bubble Card](https://github.com/Clooos/Bubble-Card) | Rows, separators, sub-buttons, sliders, and camera/image buttons |
| [Bar Card](https://github.com/custom-cards/bar-card) | Rounded dithered tracks, fills, values, and shadow removal |
| [Mini Graph Card](https://github.com/kalkih/mini-graph-card) | System 7 headers, Chicago values, graph surfaces, and header icons |
| [Mini Media Player](https://github.com/kalkih/mini-media-player) | Slider knobs, controls, nested cards, and artwork contrast |
| [Simple Weather Card](https://github.com/kalkih/simple-weather-card) | Chicago title/temperature and divider cleanup |
| [Simple Thermostat](https://github.com/nervetattoo/simple-thermostat) | Chicago title/temperature and nested-card cleanup |
| [Text Divider Row](https://github.com/iantrich/text-divider-row) | Chicago dividers and targeted mobile clipping repair |
| [Stack In Card](https://github.com/custom-cards/stack-in-card) | Outer window ownership, nested surfaces, titles, and controls |
| [Vertical Stack In Card](https://github.com/ofekashery/vertical-stack-in-card) | Outer window ownership, nested surfaces, titles, and controls |

Native Home Assistant cards, tiles, entity rows, gauges, graphs, weather cards,
more-info dialogs, configuration pages, and navigation chrome are also styled.

## Installation with HACS

### 1. Install the required frontend extensions

Install [UIX](https://github.com/Lint-Free-Technology/uix) and
[card-mod](https://github.com/thomasloven/lovelace-card-mod) through HACS. Follow the
card-mod documentation for its recommended frontend-module setup.

### 2. Enable themes in Home Assistant

Add this to `configuration.yaml` if themes are not already enabled:

```yaml
frontend:
  themes: !include_dir_merge_named themes
```

### 3. Add this repository to HACS

1. Open HACS.
2. Open the three-dot menu and choose **Custom repositories**.
3. Add this URL:

   ```text
   https://github.com/skynet01/homeassistant-macos-system7-theme
   ```

4. Select **Theme** as the category and install it.

[![Open your Home Assistant instance and open this repository in HACS](https://my.home-assistant.io/badges/hacs_repository.svg)](https://my.home-assistant.io/redirect/hacs_repository/?owner=skynet01&repository=homeassistant-macos-system7-theme&category=theme)

### 4. Install the bundled fonts

HACS theme installation does not place document-level font assets in `/config/www`.
Using the Terminal/SSH add-on, copy the three files from this repository into
`/config/www/macintosh-eink/`. For release `v1.0.0`:

```sh
mkdir -p /config/www/macintosh-eink
curl -L https://raw.githubusercontent.com/skynet01/homeassistant-macos-system7-theme/v1.0.0/assets/Chicago.woff -o /config/www/macintosh-eink/Chicago.woff
curl -L https://raw.githubusercontent.com/skynet01/homeassistant-macos-system7-theme/v1.0.0/assets/Geneva.ttf -o /config/www/macintosh-eink/Geneva.ttf
curl -L https://raw.githubusercontent.com/skynet01/homeassistant-macos-system7-theme/v1.0.0/assets/fonts.css -o /config/www/macintosh-eink/fonts.css
```

Then add this dashboard resource as a **Stylesheet**:

```text
/local/macintosh-eink/fonts.css?v=1.0.0
```

The resource is what registers Chicago and Geneva at document level. Theme CSS inside
shadow roots cannot provide a reusable global font registration.

### 5. Reload and select the theme

1. Reload themes from Home Assistant Developer Tools, or restart Home Assistant.
2. Hard-refresh the browser or clear the Home Assistant frontend cache.
3. Open your profile and select `MacOS System 7 eink theme` or
   `MacOS System 7 color theme`.

## Manual installation

1. Copy `themes/macintosh_eink.yaml` and `themes/macintosh_eink_color.yaml` into a
   directory included by `frontend.themes`.
2. Copy `assets/Chicago.woff`, `assets/Geneva.ttf`, and `assets/fonts.css` to
   `/config/www/macintosh-eink/`.
3. Add `/local/macintosh-eink/fonts.css?v=1.0.0` as a Stylesheet dashboard resource.
4. Install UIX and card-mod, reload themes, hard-refresh, and select a theme.

## Troubleshooting

- **Chicago or Geneva is missing:** verify the three `/config/www/macintosh-eink/`
  files, open `/local/macintosh-eink/fonts.css` directly, and hard-refresh.
- **Cards look plain:** verify UIX and card-mod are loaded. UIX supplies most modern
  shadow-root styling.
- **Settings or the sidebar lose styling:** install card-mod as a frontend module,
  following its official documentation, then restart Home Assistant.
- **A custom card changed after an update:** custom cards and Home Assistant regularly
  change their internal DOM. Open an issue with the card name, version, and screenshot.
- **E-ink refresh is slow:** the theme disables animation where possible, but dashboard
  polling frequency, graphs, cameras, and the browser still control most refresh work.

## Inspiration and authorship

The visual direction was inspired by classic Macintosh System 7 and by
[dmellok/tesserae](https://github.com/dmellok/tesserae), an excellent e-ink dashboard
companion. Tesserae is a separate project; this theme does not contain its code.

The implementation and iterative CSS archaeology were performed primarily by AI
robots under human direction. Expect some selectors to be inelegant. The goal is a
convincing, functional e-ink interface rather than pristine framework code.

## Versioning

Releases use semantic versioning. The repository `VERSION` file contains the release
number and tags add the `v` prefix, beginning with `v1.0.0`.

## License and fonts

Project-owned theme code and documentation are licensed under GPL-3.0. The bundled
Chicago and Geneva font binaries are third-party works and are **not** relicensed by
the project GPL. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before copying,
redistributing, or using them beyond the provider terms.
