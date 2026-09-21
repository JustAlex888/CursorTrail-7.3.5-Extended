# CursorTrail 7.3.5 Extended

[English](README.md) | [Русский](README_RU.md)

**CursorTrail 7.3.5 Extended** is an extended adaptation of **CursorTrail by UppyDan (DJU)** for **World of Warcraft: Legion 7.3.5**.

It preserves the original Legion-compatible CursorTrail foundation while adding and adapting functionality from later CursorTrail releases, expanding the configuration UI, visual effects, cursor halo system, profiles, localization, and Legion 7.3.5 compatibility behavior.

> This is not a UWoW-exclusive addon. Development and testing were performed primarily on the **UWoW x1** server, but the addon is intended for the **World of Warcraft: Legion 7.3.5 client in general**.

## Compatibility

- **World of Warcraft: Legion 7.3.5**
- **Interface: 70300**
- Lua/API behavior is kept compatible with the Legion 7.3.5 client and avoids Retail-only APIs where they are not available.

## Opening the settings

In game chat:

```text
/ct
```

or:

```text
/CursorTrail
```

Running `/ct` with no arguments toggles the main settings window.

## Main features

CursorTrail 7.3.5 Extended provides three independent visual layers. Each layer can be enabled or disabled separately, so you can use only one layer, any combination of two, or all three together.

### 3D Effects

Animated in-game model effects that follow the cursor.

Available effects:

- Electric — Blue, Long
- Electric — Blue, Short
- Electric — Green, Short
- Electric — Green Pulse
- Light
- Ghostly
- Pulse — Green
- Pulse — Yellow
- Swirl — Nature
- Sphere — Orange

Settings:

- effect type;
- size;
- X offset;
- Y offset;
- opacity.

The extended 3D catalog and model calibration work were adapted for Legion 7.3.5 using later CursorTrail releases as donor/reference sources.

### 2D Effects

Flat textures that follow the cursor independently of the 3D layer.

Available effects:

- Disk
- Glow
- Cross 1
- Cross 2
- Swirl

Settings:

- effect type;
- size;
- X offset;
- Y offset;
- opacity;
- color.

### Cursor Halo

An independent halo surrounding the cursor, designed to keep the pointer visible in visually busy combat scenes.

Shapes:

- Circle
- Square

Styles:

- **Single Color** — uses a user-selected color;
- **Spectral** — uses a built-in multicolor spectral gradient.

Settings:

- shape;
- style;
- thickness 1–5;
- size;
- opacity;
- color for Single Color style;
- rotation on/off;
- reverse rotation;
- rotation speed 1–5.

The halo rotates as a complete texture. A rotating spectral circle appears as a moving color stream, while the square visibly rotates around the cursor center. Reverse Rotation changes the direction.

### Display

**Show only in combat** can automatically hide all enabled cursor effects outside combat and show them again when combat begins.

Disabled visual layers do not update their cursor position, avoiding unnecessary work.

### Profiles

The addon supports shared user profiles. You can create a profile, save the current settings, select an existing profile, and delete profiles you no longer need.

Profiles are stored in `CursorTrail_ProfilesDB`; per-character active settings are stored in `CursorTrail_PlayerConfig`. These technical identifiers remain unchanged for compatibility with existing saved settings.

## Localization

Russian and English interfaces are included.

Normally the addon follows the WoW client locale:

- `ruRU` → Russian;
- `enUS`, `enGB`, and other client locales → English.

A manual language override is also available for testing or preference:

```text
/ct english
/ct en
/ct ru
/ct russian
```

After changing the override, run:

```text
/reload
```

The override affects CursorTrail only; it does not change the WoW client or Windows language.

## Commands

User-facing commands:

- `/ct` or `/CursorTrail` — open/close the settings window;
- `/ct help` — show the built-in command list;
- `/ct reload` — reload current CursorTrail settings;
- `/ct reset` — reset CursorTrail settings to defaults;
- `/ct combat` — toggle Show only in combat;
- `/ct english` or `/ct en` — force English after `/reload`;
- `/ct ru` or `/ct russian` — force Russian after `/reload`.

The addon also retains several technical diagnostic/calibration commands from the development lineage; they are shown by `/ct help` where applicable.

## Installation

1. Download the prepared release archive from **GitHub Releases**.
2. Extract the archive directly into:

```text
World of Warcraft\Interface\AddOns\
```

3. The final path should be:

```text
World of Warcraft\Interface\AddOns\CursorTrail\CursorTrail.toc
```

4. Start or restart World of Warcraft. If necessary, enable the addon in the AddOns list on the character screen.

## Download

For normal installation, download the prepared release archive from the repository's **GitHub Releases** page:

```text
CursorTrail-7.3.5-1.0.0.zip
```

Do **not** use GitHub's automatically generated `Source code.zip` or `Source code.tar.gz` archives as the normal installation package. Those archives reflect the repository layout, while the prepared release ZIP is packaged so it can be extracted directly into `Interface\AddOns`.

## Project origin

**Based on CursorTrail by UppyDan (DJU). Extensively adapted and expanded for World of Warcraft 7.3.5.**

Primary historical base:

- CursorTrail 7.3.5.1

Later CursorTrail releases used as donor/reference sources during development:

- CursorTrail 8.2.0.6
- CursorTrail 8.3.0.3
- CursorTrail 10.1.0.1

These later releases were used to study and backport compatible model catalogs, calibration concepts, shape/texture behavior, and selected visual resources while preserving Legion 7.3.5 compatibility.

See [CREDITS_AND_LEGAL.md](CREDITS_AND_LEGAL.md) for detailed provenance and legal notes.

## Credits

- **Original CursorTrail:** UppyDan (DJU)
- **Extended 7.3.5 adaptation, project maintenance, final design decisions and in-game testing:** JustAlex888
- **Primary development/testing environment:** UWoW x1
- **Development assistance:** ChatGPT by OpenAI

Development and testing were performed primarily on the UWoW x1 server. This is historical development/testing information and does **not** mean the addon is technically tied to UWoW.

## Development with ChatGPT

Developed extensively with the assistance of ChatGPT by OpenAI, including code generation, refactoring, compatibility adaptation, UI development, debugging, localization and documentation. Final design decisions, in-game testing and project maintenance are performed by the project maintainer.

ChatGPT/OpenAI assistance is credited transparently; OpenAI is not presented as the owner, publisher, or original author of CursorTrail.

## License

The original CursorTrail project is published under the **GNU General Public License version 3 (GPLv3)**. This project preserves that license and the original attribution.

See [LICENSE](LICENSE) and [CREDITS_AND_LEGAL.md](CREDITS_AND_LEGAL.md).

Official CursorTrail project page: <https://www.curseforge.com/wow/addons/cursortrail>
