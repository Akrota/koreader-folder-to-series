# Changelog – Folder to series

*Deutsche Fassung weiter unten.*

## 0.4.0

- New: **Bring a series here**. Pick a series from the list of all known series, and all its volumes from all folders move into the chosen folder, with reading progress, notes and the database row. A preview shows where the comics come from. Same name at the target: the file stays. Source folders that are completely empty afterwards are deleted (not with "never delete", and never a folder above the target).
- After setting a series, ZenOS' saved folder view is refreshed, so new series appear stacked right away.

## 0.3.x

- When moving, the library database row moves along (the cover stays). If a row is missing, the plugin creates a small one, so ZenOS knows the series at once. "Loose comics …" also adds missing rows later.
- Volume number also at the start of the file name ("324 - Berserk", "05. One Piece"), plus "v01", "Volume 2" and square brackets.
- Folder names are cleaned up ("Akira (01-38) (1988)" becomes "Akira"); subtitles behind the number no longer get in the way.
- **Collection folder detection:** a folder only counts as a series if at least 60 % of its file names share the same series name. Otherwise it is skipped under "Subfolders …" and everything stays inside.
- Menu Tools → "Folder to series" for the folder that is open. Needed because ZenOS only shows plugin buttons in the context menu when "Plugin actions" is switched on.

## 0.2.0 – 0.3.0

- New: **Detect series in loose comics** (series from ComicInfo.xml or file name), either "Set + move" or "Only set".
- New: **Combine subfolders as series** for collection folders like "comics".
- New: selection with check marks in every preview with several entries.
- Comics that are already in a series are skipped. Existing series are extended with the same spelling.
- New: "How does it work?" in the menu.

## 0.1.0 (prototype)

- Long-press a folder → "Combine as series" with preview. Series = folder name, volume number from the file name (#22, Vol. 105, Band 7 …).
- Move comics one level up like KOReader's cut and paste, with reading progress and notes. Never overwrites.
- Delete an empty folder only when really nothing is left inside. "Never delete this folder" protects a folder.

---

# Deutsch

## 0.4.0

- Neu: **Reihe hierher holen**. Eine Reihe aus der Liste aller bekannten Reihen wählen, dann werden alle Bände aus allen Ordnern in den gewählten Ordner verschoben, mit Lesestand, Notizen und Datenbankzeile. Vorher zeigt eine Vorschau, woher die Comics kommen. Gleicher Name im Ziel: bleibt liegen. Quellordner, die danach ganz leer sind, werden gelöscht (nicht bei „nie löschen“, nie ein Ordner über dem Ziel).
- Nach dem Eintragen wird die gespeicherte Ordneransicht von ZenOS erneuert, damit neue Reihen sofort gestapelt erscheinen.

## 0.3.x

- Beim Verschieben wandert die Datenbankzeile der Bibliothek mit (Titelbild bleibt). Fehlt eine Zeile, legt das Plugin eine kleine an, damit ZenOS die Reihe sofort kennt. „Lose Comics …“ trägt fehlende Zeilen auch nachträglich ein.
- Bandnummer auch vorne im Dateinamen („324 - Berserk“, „05. One Piece“), außerdem „v01“, „Volume 2“ und eckige Klammern.
- Ordnernamen werden bereinigt („Akira (01-38) (1988)“ wird „Akira“); Untertitel hinter der Nummer stören nicht mehr.
- **Sammelordner-Erkennung:** Ein Ordner gilt nur als Reihe, wenn mindestens 60 % der Dateinamen denselben Reihennamen tragen. Sonst wird er bei „Unterordner …“ übersprungen und alles bleibt drin.
- Menü Werkzeuge → „Ordner zu Reihe“ für den gerade offenen Ordner. Nötig, weil ZenOS Plugin-Knöpfe im Kontextmenü nur zeigt, wenn „Plugin-Aktionen“ eingeschaltet sind.

## 0.2.0 – 0.3.0

- Neu: **Lose Comics als Reihen erkennen** (Reihe aus ComicInfo.xml oder Dateiname), wahlweise „Eintragen + verschieben“ oder „Nur eintragen“.
- Neu: **Unterordner als Reihen zusammenfassen** für Sammelordner wie „comics“.
- Neu: Auswahl mit Haken in jeder Mehrfach-Vorschau.
- Comics, die schon in einer Reihe sind, werden übersprungen. Vorhandene Reihen werden mit derselben Schreibweise ergänzt.
- Neu: „Wie funktioniert das?“ im Menü.

## 0.1.0 (Prototyp)

- Langes Drücken auf einen Ordner → „Als Reihe zusammenfassen“ mit Vorschau. Reihe = Ordnername, Bandnummer aus dem Dateinamen (#22, Vol. 105, Band 7 …).
- Comics eine Ebene höher verschieben wie KOReaders Ausschneiden/Einfügen, mit Lesestand und Notizen. Nie überschreiben.
- Leeren Ordner löschen, nur wenn wirklich nichts mehr darin ist. „Diesen Ordner nie löschen“ schützt einen Ordner.
