# Folder to Series for KOReader

*Deutsch: [README.de.md](README.de.md)*

A KOReader plugin that turns comic folders into **series with volume numbers**. If your comics lie in folders like `Akira/Akira 01.cbz`, this sets series and number for each comic, moves the comics one level up and removes the empty folder. Libraries that show series as stacks (like ZenOS) then show one stack per series instead of a folder.

**Status: prototype / beta.** It moves and deletes files. Read "Important" first and try it on a small folder.

## Features

- **Combine as series:** the folder name becomes the series, the volume number comes from the file name (`#22`, `Vol. 105`, `Band 7`, `v01`, `Volume 2` and so on). Brackets such as years are skipped.
- **Combine subfolders as series:** for a parent folder like `comics`: every subfolder becomes its own series. Folders whose file names look like different titles (not one series) are skipped as collections.
- **Detect series in loose comics:** for mixed folders. The series comes from the comic file (ComicInfo.xml) or the file name. Either "Set + move" (one level up) or "Only set" (comics stay where they are).
- **Bring a series here:** pick a series from the list the library knows, and all its comics from all folders are moved into the current folder.
- **Preview first:** every action shows what will happen, and nothing happens without your tap. "Choose …" lets you deselect single series.
- **Existing series are respected:** comics that already have a series are skipped. If a series already exists (for example "Batman"), it is extended with the same spelling.
- Reading position, notes and the library entry move along with each comic.
- Menus and texts are in German or English, following KOReader's language.

## Important

- **Files are moved.** Comics are renamed into the folder one level up, like KOReader's cut and paste. Reading position and notes (the `.sdr` data), history and collections are moved along, and the library database row (including the cover) goes with the comic.
- **Nothing is overwritten.** If a file with the same name already exists at the target, the comic stays where it is.
- **Only empty folders are deleted,** and only after a move. A folder that still contains anything stays.
- **"Never delete this folder"** protects a folder: series inside are still moved up, but the folder itself is kept. Use it for folders you want to keep, for example your main comics folder.
- A series needs at least 2 comics. Single comics stay as they are.
- The series is stored like KOReader's "Book information" edit (custom metadata). The original comic files are not changed.
- Try it on a copy or a small folder first. There is no undo.

## Installation

1. Download the ZIP from [Releases](../../releases) and unpack it, or download this repository.
2. Copy the folder **`ordnerzureihe.koplugin`** to KOReader's `plugins` folder. On a Kobo, that is `.adds/koreader/plugins/`.
3. Restart KOReader.

## Usage

**In the library, long-press a folder.** The plugin adds these buttons: "Combine as series", "Combine subfolders as series" (only if the folder has subfolders), "Detect series in loose comics", "Bring a series here …" and "Never delete this folder" (or "Allow deleting this folder again").

**Or through the menu,** for the folder that is currently open in the library: top menu → tools icon (wrench) → **Folder to series**:

- **Combine "…" as series**
- **Combine subfolders of "…" as series**
- **Detect series in loose comics in "…"**
- **Bring a series to "…" …**
- **Never delete "…"** (checkbox)
- **How does it work?** (short explanation)

In the preview, "Change name" lets you type another series name. In multi-series previews, "Choose …" lets you tick or untick each series.

## ZenOS

- The plugin reads series from the library database, which ZenOS uses for its series view, and refreshes ZenOS' saved folder view after changes.
- ZenOS shows buttons from plugins in the long-press menu only if **ZenOS settings → Library → Context menu → "Plugin actions"** is switched on (off by default). The menu entry **Folder to series** in the tools menu works without it.
- ZenOS does not stack a folder that contains only one series and no loose books. That is ZenOS' own behaviour, not a plugin error.
- After moving many comics, the library may take a moment to read the covers and stack the series.

## Tested on

Kobo Libra Colour with KOReader 2026.07.1 and ZenOS.

The `tests` folder holds the automated test used during development (`2-ozr-test.lua`). It needs a KOReader test environment.

## Who made this

The code was written entirely by **Claude**, an AI by Anthropic (in Claude Code). The owner of this repository came up with the idea, tested the plugin on a Kobo and gave feedback, but did not write the code.

There is no warranty and no guaranteed support. Bug reports are welcome as [issues](../../issues). Please attach `crash.log` from the KOReader folder.

## License

[MIT](LICENSE)
