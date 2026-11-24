# Änderungen

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
