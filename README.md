# PhunLewt

Zone based lewt reducers and respawner for Project Zomboid Build 42.

## Configuration storage

Admin customisations made in the PhunLewt editor are stored as JSON:

- Single-player: `<zomboid directory>/Lua/PhunLewt.json`
- Multiplayer: `<zomboid directory>/Server/<server-name>/Lua/PhunLewt.json` (server only — clients never hold this file)

The file is written whenever configs are saved, and read once on load into `ModData`. Static data shipped with the mod is still plain Lua loaded through `require`; only this mutable admin file is JSON.

## Migrating from `PhunLewt.txt` (Build 42.20.4)

Build 42.20.4 removed `loadstring`, `load` and `loadfile` from the game's Lua runtime. PhunLewt previously stored customisations as executable Lua source in `PhunLewt.txt` and reloaded them with `loadstring`, so that file can no longer be read. Storage has moved to `PhunLewt.json`.

Existing `PhunLewt.txt` files must be converted before updating:

1. Back up `PhunLewt.txt`.
2. Open the [Phun configuration converter](https://phunzoider.github.io/PhunZones/converter/). It runs entirely in the browser and does not upload files.
3. Select or drag `PhunLewt.txt` into the converter.
4. Download the generated `PhunLewt.json`.
5. Place it in the same `Lua` directory as the old file.
6. Restart, then confirm your configs appear in the editor before deleting `PhunLewt.txt`.

If `PhunLewt.txt` is present but `PhunLewt.json` is not, the mod starts with no customisations and logs the conversion instructions to the console. Nothing is deleted or overwritten — the old file is left alone.

Configuration files containing hand-written Lua logic (functions, calls, expressions) cannot be converted; the converter accepts data tables only. Those need to be re-created in the editor, or exported once from an older game/mod version.
