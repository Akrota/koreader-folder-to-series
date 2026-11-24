-- Beschreibung auf Deutsch oder Englisch, je nach KOReader-Sprache
local ok, lang = pcall(function() return G_reader_settings:readSetting("language") end)
local de = ok and type(lang) == "string" and lang:sub(1, 2):lower() == "de"
return {
    version = "0.4.0",
    fullname = de and "Ordner zu Reihe" or "Folder to series",
    description = de
        and "Macht aus einem Comic-Ordner eine Reihe: trägt Reihe und Bandnummer ein, schiebt die Comics eine Ebene höher und löscht den leeren Ordner."
        or "Turns a comic folder into a series: sets series and number, moves the comics one level up and removes the empty folder.",
}
