# 2D Asset Pipeline

This branch is for rebuilding the game with 2D assets.

The downloaded `assets/2d` sources stay local and are ignored by Git. Deploy the
checked-in `web/game` build on Render; rebuilding it requires restoring those
sources locally. See `DEPLOY_2D_RENDER.md`.

## Where to put downloaded archives

Put the original itch.io downloads here:

```text
assets/_incoming_zips/
```

That folder is intentionally ignored by Git. Keep the raw `.zip`, `.rar`, or `.7z`
files there as your local source library, then extract only the files the game
actually uses into the organized folders below.

## Godot-ready asset folders

Use these folders for files that should be imported by Godot:

```text
assets/2d/characters/    animated characters, portraits, NPCs
assets/2d/tilesets/      tilemaps, terrain, floors, walls
assets/2d/backgrounds/   parallax layers, skyboxes, static backdrops
assets/2d/props/         furniture, interactables, pickups, decorations
assets/2d/ui/            buttons, icons, panels, cursors
assets/2d/audio/         music, ambience, SFX
assets/2d/packs/         multi-category packs kept together as one source
```

## Recommended workflow

1. Copy the downloaded archives into `assets/_incoming_zips/`.
2. Extract each pack locally.
3. Pick the production-ready files only, usually `.png`, `.webp`, `.ogg`, `.wav`,
   `.ttf`, `.otf`, `.aseprite`, or `.tsx`.
4. Move those chosen files into the matching `assets/2d/...` folder.
5. Keep each asset pack in its own subfolder, for example:

```text
assets/2d/characters/kenney_tiny_town/
assets/2d/tilesets/cute_farm_pack/
assets/2d/ui/fantasy_ui_pack/
```

## Naming tips

Prefer lowercase names with underscores:

```text
player_idle.png
player_walk_sheet.png
grass_tileset.png
button_primary.png
```

Avoid spaces and special characters in filenames. Godot handles them, but clean
names make scripts, exports, and future batch imports much less annoying.

## Licensing

For each pack, keep a small `LICENSE.txt` or `SOURCE.txt` inside that pack's
subfolder if itch.io included one. If the license only exists on the download
page, copy the asset title, author, URL, license, and download date into
`SOURCE.txt`.

See `docs/ASSET_INVENTORY_2D.md` for the current import locations and known
license restrictions.
