# CursorTrail 7.3.5 Extended — Credits, Origin and Legal Notes

Version 1.0.0

## Status of this project

**CursorTrail 7.3.5 Extended** is a user-maintained modification/adaptation of the existing CursorTrail addon. It is not presented as a new original addon and does not claim authorship of the original CursorTrail project, its name, concept, original source code, or original project assets.

The adaptation began as a personal-use project for a small group of players and was later prepared for public distribution. Public distribution does not change the original attribution or license obligations.

## Original project

- **Project:** CursorTrail
- **Original author:** UppyDan (DJU)
- **Historical Legion base used for this adaptation:** CursorTrail 7.3.5.1
- **Official project page:** <https://www.curseforge.com/wow/addons/cursortrail>

The supplied historical CursorTrail archives identify **UppyDan (DJU)** as the author in their TOC metadata.

The official CursorTrail project page identifies the project license as **GNU General Public License version 3 (GPLv3)**. The historical ZIP archives reviewed for this adaptation did not include a standalone license file, so the standard GPLv3 text is included with this project as `LICENSE` / `LICENSE.txt` while preserving the original project attribution.

## Extended adaptation and maintenance

- **Extended Legion 7.3.5 adaptation, project maintenance, final design decisions and in-game testing:** JustAlex888
- **Development assistance:** ChatGPT by OpenAI

This credit describes modification and maintenance work only. It does not claim authorship or ownership of the original CursorTrail project.

## Development and testing environment

**Development and testing were performed primarily on the UWoW x1 server.**

This is historical information about the development/testing environment. CursorTrail 7.3.5 Extended is positioned for the **World of Warcraft: Legion 7.3.5 client generally** and is not technically designed as an UWoW-exclusive addon.

The project is not presented as an official UWoW product or as being endorsed by UWoW.

## Development with ChatGPT

Developed extensively with the assistance of ChatGPT by OpenAI, including code generation, refactoring, compatibility adaptation, UI development, debugging, localization and documentation. Final design decisions, in-game testing and project maintenance are performed by the project maintainer.

This acknowledgement does not state or imply that ChatGPT or OpenAI owns, publishes, or originally authored CursorTrail.

## Source and donor versions used

### CursorTrail 7.3.5.1

Primary historical Legion 7.3.5 code base. It was used to preserve the original Legion-compatible architecture and core cursor-model behavior.

### CursorTrail 8.2.0.6

Used as a donor/reference for the expanded 3D model catalog and model calibration/math concepts adapted back to Legion 7.3.5. `CursorTrailTrails.lua` records this origin in its source comments.

### CursorTrail 8.3.0.3

Used as an additional reference while comparing later CursorTrail model handling and implementation changes.

### CursorTrail 10.1.0.1

Used as a donor/reference for selected 2D shape textures and later shape/texture architecture.

The following packaged textures were verified as byte-identical to files from the CursorTrail 10.1.0.1 archive used during development:

- `Circle 1.tga`
- `Glow.tga`
- `Cross 1.tga`
- `Cross 2.tga`
- `Swirl.tga`
- `Ring 1.tga`
- `Ring 2.tga`
- `Ring 3.tga`
- `Ring 4.tga`
- `Ring Soft 1.tga`
- `Ring Soft 2.tga`

These are resources from the same CursorTrail project lineage and remain subject to the applicable GPLv3 project license and original attribution.

## Work created or substantially reworked for this adaptation

The extended 7.3.5 version includes substantial adaptation and new/reworked integration work, including:

- redesigned Russian/English configuration UI for Legion 7.3.5;
- separation into independent 3D, 2D, and Cursor Halo layers;
- Legion-compatible selection/calibration of multiple 3D effects;
- independent 2D effect handling and color/offset controls;
- Circle/Square halo architecture with thickness levels 1–5;
- new `Ring 5.tga` and Square halo texture set used by the extended halo system;
- new high-quality spectral Circle/Square halo texture sets;
- whole-halo rotation, reverse direction, and speed controls;
- profile integration and migration/compatibility handling for existing settings;
- Russian and English localization, including a manual language override;
- cursor-tracking optimization for disabled visual layers;
- documentation and public-release packaging.

These changes do not alter the attribution of the original CursorTrail project.

## World of Warcraft assets and trademarks

The addon references World of Warcraft model paths supplied by the game client. Those game models are not distributed as standalone model files in this package.

World of Warcraft, Blizzard Entertainment, and related names, trademarks, artwork, models, and game assets belong to their respective rights holders. This project does not claim ownership of those materials.

CursorTrail 7.3.5 Extended is an unofficial user modification and is not an official product of Blizzard Entertainment.

## License

The CursorTrail project is identified by its official CurseForge project page as licensed under the **GNU General Public License version 3 (GPLv3)**.

The complete GPLv3 text is included in this repository as `LICENSE` and in the installable addon package as `LICENSE.txt`.

Nothing in this credits/legal notice is intended to replace, narrow, or expand the terms of GPLv3. If this explanatory text and the applicable license ever conflict, the applicable license controls.

No additional proprietary restriction is asserted by this adaptation over the original CursorTrail project.

## Russian summary / Русское резюме

**CursorTrail 7.3.5 Extended** — пользовательская расширенная адаптация существующего аддона CursorTrail для **World of Warcraft: Legion 7.3.5**.

Оригинальный проект: **CursorTrail**. Оригинальный автор: **UppyDan (DJU)**. Основная историческая база: **CursorTrail 7.3.5.1**. Более поздние версии 8.2.0.6, 8.3.0.3 и 10.1.0.1 использовались как донорские/справочные версии того же проекта.

Расширенная адаптация, сопровождение, финальные решения и игровое тестирование: **JustAlex888**.

**Разработка и основное тестирование проводились на сервере UWoW x1.** Это историческая информация о среде разработки и тестирования; она не означает технической привязки аддона к UWoW.

Проект в значительной степени разрабатывался при помощи ChatGPT от OpenAI, включая генерацию и переработку кода, адаптацию совместимости, разработку интерфейса, отладку, локализацию и документацию. Финальные решения, игровое тестирование и сопровождение проекта выполняются владельцем проекта.

Автор адаптации не заявляет авторство оригинального CursorTrail, его названия, концепции, исходного кода или исходных материалов проекта. Сохраняются исходное авторство и лицензия GPLv3.
