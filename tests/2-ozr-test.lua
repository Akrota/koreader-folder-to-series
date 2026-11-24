-- Test (Windows-Claude, 04.11.2026): Ordner zu Reihe mit nachgebauter Ordnerstruktur unter OZR_DIR
-- (comics/akira mit 3 Baenden, comics/fanatical mit 2x Saga + 1 Einzelcomic, geschuetzter Ordner).
local UIManager = require("ui/uimanager")
local OUT = os.getenv("OZR_TEST_OUT") or "."
local ROOT = os.getenv("OZR_DIR") or "/work/ozr"
local f = io.open(OUT .. "/ozr-results.txt", "w")
local function log(...) local p = {} for i = 1, select("#", ...) do p[#p+1] = tostring(select(i, ...)) end f:write(table.concat(p, " ") .. "\n"); f:flush() end
local function check(n, ok) log(ok and "PASS" or "FAIL", n) end
local lfs = require("libs/libkoreader-lfs")
local function exists(p) return lfs.attributes(p, "mode") ~= nil end

UIManager:scheduleIn(4, function()
  local ok, e = pcall(function()
    local ui = require("apps/reader/readerui").instance
    local ozr = ui.ordnerzureihe
    check("Plugin geladen", ozr ~= nil)
    local P, X = ozr.Planner, ozr.Executor
    local DocSettings = require("docsettings")
    -- Reste frueherer Testlaeufe aus der Buecher-Datenbank entfernen (Testordner wird jedes Mal neu gebaut)
    pcall(function()
      local BIM0 = require("bookinfomanager")
      BIM0:openDbConnection()
      BIM0.db_conn:exec("DELETE FROM bookinfo WHERE directory LIKE '" .. ROOT .. "/%';")
    end)

    -- Akira: 3 Baende, Ordner wird leer und geloescht
    local plan = P.plan(ROOT .. "/comics/akira")
    check("Akira: Reihe = Ordnername, gross geschrieben", plan.series == "Akira")
    check("Akira: 3 Comics zum Verschieben", #plan.moves == 3)
    check("Akira: Ordner soll geloescht werden", plan.delete_folder == true)
    log("INFO Vorschau:", (ozr:previewText(plan):gsub("\n", " | ")))
    local r = X.run(plan)
    check("Akira: 3 verschoben", r.moved == 3 and #r.failed == 0)
    check("Akira: Dateien eine Ebene hoeher", exists(ROOT .. "/comics/Akira (1988) #2.cbz"))
    check("Akira: Ordner geloescht", r.folder_deleted and not exists(ROOT .. "/comics/akira"))
    local cmf = DocSettings:findCustomMetadataFile(ROOT .. "/comics/Akira (1988) #2.cbz")
    local custom = cmf and DocSettings.openSettingsFile(cmf):readSetting("custom_props")
    log("INFO Eigene Angaben:", custom and custom.series, custom and custom.series_index)
    check("Akira: Reihe und Band 2 eingetragen", custom and custom.series == "Akira" and custom.series_index == 2)
    -- So liest die Bibliothek (und damit ZenOS) die Angaben beim Einlesen eines Buchs
    local BookInfo = require("apps/filemanager/filemanagerbookinfo")
    local ext = BookInfo.extendProps({}, ROOT .. "/comics/Akira (1988) #2.cbz")
    check("Bibliothek uebernimmt Reihe beim Einlesen (extendProps)", ext.series == "Akira" and ext.series_index == 2)
    -- Bibliothek liest den Comic wirklich ein (Buecher-Datenbank, aus der ZenOS die Reihen nimmt)
    local ok_b, BIM = pcall(require, "bookinfomanager")
    if ok_b then
      -- Sofort nach dem Verschieben, ohne Einlesen: Reihe steht schon in der Datenbank (alle 3, nicht nur angezeigte)
      local n_ok = 0
      for _, f in ipairs({ "Akira (1988) #1.cbz", "Akira (1988) #2.cbz", "Akira (1988) #3.cbz" }) do
        local p = BIM:getDocProps(ROOT .. "/comics/" .. f)
        if p and p.series == "Akira" then n_ok = n_ok + 1 end
      end
      check("Datenbank kennt alle 3 Akira sofort (ohne Einlesen)", n_ok == 3)
      local bi = BIM:getBookInfo(ROOT .. "/comics/Akira (1988) #1.cbz")
      check("Neue Zeile laesst Titelbild nachladen (cover_fetched leer)", bi and not bi.cover_fetched)
      -- Reparatur: Datenbankzeile fehlt, Reihe nur in eigenen Angaben -> existingSeries traegt nach
      BIM:deleteBookInfo(ROOT .. "/comics/Akira (1988) #3.cbz")
      X.existingSeries(ROOT .. "/comics/Akira (1988) #3.cbz")
      local p3 = BIM:getDocProps(ROOT .. "/comics/Akira (1988) #3.cbz")
      check("Reparatur: fehlende Zeile nachgetragen (Band 3)", p3 and p3.series == "Akira" and tonumber(p3.series_index) == 3)
      local okx, errx = pcall(BIM.extractBookInfo, BIM, ROOT .. "/comics/Akira (1988) #2.cbz", false)
      if not okx then log("INFO Einlesen:", errx) end
      local props = BIM:getDocProps(ROOT .. "/comics/Akira (1988) #2.cbz")
      log("INFO Buecher-Datenbank nach dem Einlesen:", props and props.series, props and props.series_index)
      check("Buecher-Datenbank hat die Reihe (wie ZenOS sie liest)", props and props.series == "Akira" and tonumber(props.series_index) == 2)
    end

    -- ZenOS: gespeicherte Ordneransicht wird nach dem Eintragen verworfen (sonst kein Stapel)
    local fc0 = ozr.ui.file_chooser
    if fc0 then
      local cleared = false
      fc0._zen_clear_item_table_cache = function() cleared = true end
      ozr:refreshLibrary(ROOT .. "/comics")
      fc0._zen_clear_item_table_cache = nil
      check("ZenOS-Ordneransicht wird erneuert", cleared)
    end

    -- Fanatical: Ordnername ist keine Reihe -> im Prototyp wird der Ordnername genommen (Schritt 2: lose Comics)
    -- Hier nur der Schutz: geschuetzter Ordner wird nie geloescht
    local plan2 = P.plan(ROOT .. "/comics/schutz", { protected = true })
    check("Geschuetzt: wird nicht geloescht", plan2.delete_folder == false)
    local r2 = X.run(plan2)
    check("Geschuetzt: Comics trotzdem verschoben, Ordner bleibt", r2.moved == 2 and exists(ROOT .. "/comics/schutz"))

    -- Reihenname: Grossschreibung nur bei ganz klein geschriebenen Ordnern, eigener Name moeglich
    check("Name: akira -> Akira", P.seriesName("akira") == "Akira")
    check("Name: one piece -> One Piece", P.seriesName("one piece") == "One Piece")
    check("Name: X-Men bleibt", P.seriesName("X-Men") == "X-Men" and P.seriesName("dEUS") == "dEUS")
    check("Name: eigener Name aus der Vorschau", P.plan(ROOT .. "/comics/one piece", { series = "One Piece (Carlsen)" }).series == "One Piece (Carlsen)")

    -- Einzelner Comic: nichts zu tun
    local plan3 = P.plan(ROOT .. "/comics/einzeln")
    check("Einzelner Comic: nichts verschieben", #plan3.moves == 0)

    -- Gleicher Name schon oben: nicht ueberschreiben, Ordner bleibt
    local plan4 = P.plan(ROOT .. "/comics/doppelt")
    check("Gleicher Name: bleibt liegen, Ordner bleibt", #plan4.keep == 1 and plan4.delete_folder == false)
    local r4 = X.run(plan4)
    check("Gleicher Name: der andere wurde verschoben", r4.moved == 1 and exists(ROOT .. "/comics/doppelt"))
    -- Schon in einer Reihe: wird nicht noch einmal angefasst
    local S = ROOT .. "/sammel"
    X.setSeries(S .. "/fertig/Hellboy 01.cbz", "Hellboy", 1)
    X.setSeries(S .. "/fertig/Hellboy 02.cbz", "Hellboy", 2)
    check("Vorhandene Reihe wird erkannt", X.existingSeries(S .. "/fertig/Hellboy 01.cbz") == "Hellboy")
    local pf = P.plan(S .. "/fertig", ozr:planOpts(S .. "/fertig"))
    check("Schon in Reihe: nichts verschieben, nicht ueberschreiben", #pf.moves == 0 and #pf.keep == 2 and pf.keep[1].reason == "series")
    -- Unterordner als Reihen (Sammel-Ordner)
    local plans = P.planSubfolders(S, ozr:planOpts(S))
    local by = {}
    for _, p in ipairs(plans) do by[p.dir:match("([^/]+)$")] = p end
    check("Unterordner: saga wird Reihe Saga (2 Comics)", by.saga and by.saga.series == "Saga" and #by.saga.moves == 2)
    check("Unterordner: einzelner Comic bleibt", by.einzel and #by.einzel.moves == 0)
    check("Unterordner: schon in Reihe bleibt", by.fertig and #by.fertig.moves == 0)
    ozr:startSubfolders(S)
    local txt = ozr.preview and ozr.preview.text or ""
    log("INFO Vorschau Unterordner:", (txt:gsub("\n", " | ")))
    check("Vorschau Unterordner nennt Saga und die uebersprungenen", txt:find("Saga", 1, true) and txt:find("schon in einer Reihe", 1, true))
    ozr.preview.ok_callback()
    UIManager:close(ozr.preview)
    while UIManager:getTopmostVisibleWidget() and UIManager:getTopmostVisibleWidget().name ~= "ReaderUI" do
      UIManager:close(UIManager:getTopmostVisibleWidget())
    end
    check("Unterordner: Saga liegt jetzt im Sammel-Ordner, saga-Ordner geloescht", exists(S .. "/Saga #1.cbz") and not exists(S .. "/saga"))
    check("Unterordner: fertig und einzel unberuehrt", exists(S .. "/fertig/Hellboy 01.cbz") and exists(S .. "/einzel/Solo.cbz"))
    check("Lose Comics im Sammel-Ordner werden nicht angefasst", exists(S .. "/Lose.cbz") and X.existingSeries(S .. "/Lose.cbz") == nil)

    -- Nachbau der echten Ordner des Nutzers (nur die Namen): Fanatical ist ein Sammelordner
    local E = ROOT .. "/echt"
    local eplans = P.planSubfolders(E, ozr:planOpts(E))
    local ep = {}
    for _, p in ipairs(eplans) do ep[p.dir:match("([^/]+)$")] = p end
    check("Echt: Akira wird Reihe Akira", ep["Akira (01-38) (1988)"] and ep["Akira (01-38) (1988)"].series == "Akira" and #ep["Akira (01-38) (1988)"].moves == 2)
    check("Echt: Saga wird Reihe Saga", ep["Saga 01 - 12 (Cross Cult)"] and ep["Saga 01 - 12 (Cross Cult)"].series == "Saga" and #ep["Saga 01 - 12 (Cross Cult)"].moves == 2)
    check("Echt: Blame wird Reihe", ep.Blame and #ep.Blame.moves == 2)
    check("Echt: Fanatical ist Sammelordner, bleibt komplett", ep.Fanatical and ep.Fanatical.collection and #ep.Fanatical.moves == 0)
    ozr:startSubfolders(E)
    local etxt = ozr.preview and ozr.preview.text or ""
    log("INFO Vorschau echt:", (etxt:gsub("\n", " | ")))
    check("Echt: Vorschau nennt Fanatical als uebersprungen", etxt:find("Sammelordner", 1, true) and etxt:find("Fanatical", 1, true))
    UIManager:close(ozr.preview)
    local fp = P.plan(E .. "/Fanatical", ozr:planOpts(E .. "/Fanatical"))
    check("Echt: direkt auf Fanatical gibt eine Warnung", fp.looks_like_series == false and ozr:previewText(fp):find("verschiedenen Titeln", 1, true) ~= nil)

    -- Reihenname aus Dateinamen
    check("Dateiname: Saga #1 -> Saga", P.seriesFromFilename("Saga #1.cbz") == "Saga")
    check("Dateiname: Batman 012 -> Batman", P.seriesFromFilename("Batman 012.cbz") == "Batman")
    check("Dateiname: One Piece Vol. 105 -> One Piece", P.seriesFromFilename("One Piece Vol. 105.cbz") == "One Piece")
    check("Dateiname: Spider-Man 2099 #3 -> Spider-Man 2099", P.seriesFromFilename("Spider-Man 2099 #3.cbz") == "Spider-Man 2099")
    check("Dateiname: X-Men (1991) 001 (digital) -> X-Men", P.seriesFromFilename("X-Men (1991) 001 (digital).cbz") == "X-Men")
    check("Dateiname: Watchmen -> keine Reihe", P.seriesFromFilename("Watchmen.cbz") == nil)
    check("Dateiname: 324 - Berserk -> Berserk, Band 324", P.seriesFromFilename("324 - Berserk.cbz") == "Berserk" and P.parseIndex("324 - Berserk.cbz") == 324)
    check("Dateiname: 100 Bullets 01 -> 100 Bullets", P.seriesFromFilename("100 Bullets 01.cbz") == "100 Bullets")
    check("Berserk-Ordner sieht nach Reihe aus", P.looksLikeSeries({ "324 - Berserk.cbz", "325 - Berserk.cbz", "326 - Berserk.cbz" }))
    local ci, cn = P.comicInfo(ROOT .. "/gekauft/abc.cbz")
    check("ComicInfo: Reihe Hellboy, Nummer 3", ci == "Hellboy" and cn == 3)

    -- Lose Comics: Saga (2), Batman (2), Hellboy aus ComicInfo (2), akira (2, gibt es schon als "Akira"), Watchmen einzeln
    local loose, single = P.planLoose(ROOT .. "/gekauft", ozr:planOpts(ROOT .. "/gekauft"))
    local names = {}
    for _, p in ipairs(loose) do names[#names + 1] = p.series .. ":" .. #p.moves end
    log("INFO lose Reihen:", table.concat(names, ", "), "einzeln:", single)
    check("Lose: 4 Reihen erkannt, Watchmen einzeln", #loose == 4 and single == 1)
    ozr:startLoose(ROOT .. "/gekauft")
    local ltxt = ozr.preview and ozr.preview.text or ""
    log("INFO Vorschau lose:", (ltxt:gsub("\n", " | ")))
    check("Vorhandene Reihe uebernommen (akira -> Akira, gibt es schon)", ltxt:find("Akira: 2 Comics – gibt es schon", 1, true) ~= nil)
    -- Auswahl: Batman abwaehlen, dann nur eintragen
    UIManager:close(ozr.preview)
    for _, p in ipairs(loose) do end
    ozr:chooseDialog(ROOT .. "/gekauft", (function()
      local plans2 = P.planLoose(ROOT .. "/gekauft", ozr:planOpts(ROOT .. "/gekauft"))
      ozr:adoptKnown(plans2)
      for _, p in ipairs(plans2) do if p.series == "Batman" then p.selected = false end end
      ozr._plans2 = plans2
      return plans2
    end)(), "Test", 0, 1, true)
    check("Auswahl-Dialog zeigt Haken", ozr.chooser ~= nil)
    UIManager:close(ozr.chooser)
    ozr:showPlans(ROOT .. "/gekauft", ozr._plans2, "Test", 0, 1, true)
    ozr.preview.run(true) -- "Nur eintragen"
    UIManager:close(ozr.preview)
    while UIManager:getTopmostVisibleWidget() and UIManager:getTopmostVisibleWidget().name ~= "ReaderUI" do
      UIManager:close(UIManager:getTopmostVisibleWidget())
    end
    check("Nur eintragen: Saga bekommt Reihe und bleibt liegen", X.existingSeries(ROOT .. "/gekauft/Saga #1.cbz") == "Saga" and exists(ROOT .. "/gekauft/Saga #1.cbz"))
    check("Abgewaehlt: Batman bleibt ohne Reihe", X.existingSeries(ROOT .. "/gekauft/Batman 001.cbz") == nil)
    check("ComicInfo-Reihe eingetragen: Hellboy", X.existingSeries(ROOT .. "/gekauft/abc.cbz") == "Hellboy")
    check("Vorhandene Schreibweise: Akira", X.existingSeries(ROOT .. "/gekauft/akira #4.cbz") == "Akira")
    check("Einzel-Comic unberuehrt", X.existingSeries(ROOT .. "/gekauft/Watchmen.cbz") == nil)
    local items = {}; ozr:addToMainMenu(items)
    local msub = items.ordnerzureihe and items.ordnerzureihe.sub_item_table or {}
    -- Reihe hierher holen: alle Akira (comics, gekauft, echt) in einen neuen Ordner "ziel"
    lfs.mkdir(ROOT .. "/ziel")
    ozr:startGather(ROOT .. "/ziel")
    check("Holen: Reihenauswahl erscheint", ozr.chooser ~= nil)
    UIManager:close(ozr.chooser)
    ozr:previewGather("Akira", ROOT .. "/ziel")
    local gp = ozr.preview and ozr.preview.plan
    log("INFO Vorschau holen:", ozr.preview and (ozr.preview.text:gsub("\n", " | ")))
    check("Holen: Akira aus mehreren Ordnern gefunden", gp and #gp.moves == 5 and #gp.dirs == 2)
    local gr = ozr.preview.run()
    while UIManager:getTopmostVisibleWidget() and UIManager:getTopmostVisibleWidget().name ~= "ReaderUI" do
      UIManager:close(UIManager:getTopmostVisibleWidget())
    end
    check("Holen: alle verschoben, nichts fehlgeschlagen", gr.moved == #gp.moves and #gr.failed == 0)
    check("Holen: Akira #1 samt Lesestand im Ziel", exists(ROOT .. "/ziel/Akira (1988) #1.cbz") and exists(ROOT .. "/ziel/Akira (1988) #1.sdr") and not exists(ROOT .. "/comics/Akira (1988) #1.cbz"))
    check("Holen: Reihe bleibt erhalten", X.existingSeries(ROOT .. "/ziel/akira #4.cbz") == "Akira")
    check("Holen: Ordner mit anderem Inhalt bleibt (gekauft)", exists(ROOT .. "/gekauft") and exists(ROOT .. "/comics"))
    ozr:previewGather("Akira", ROOT .. "/ziel")
    check("Holen: zweites Mal nichts mehr zu tun", ozr.preview == nil)
    while UIManager:getTopmostVisibleWidget() and UIManager:getTopmostVisibleWidget().name ~= "ReaderUI" do
      UIManager:close(UIManager:getTopmostVisibleWidget())
    end
    check("Menue: 5 Ordner-Eintraege und Wie funktioniert das? zuletzt", #msub == 6 and msub[6].text == "Wie funktioniert das?" and msub[1].text_func():find("als Reihe zusammenfassen", 1, true))

    -- Vorschau fuer das Foto (Ordner "one piece" mit 2 Baenden)
    ozr:startFolder(ROOT .. "/comics/one piece")
    check("Vorschau erscheint mit Knopf Name aendern", ozr.preview ~= nil)
  end)
  if not ok then log("ERROR", e); f:close(); UIManager:quit(); return end
  UIManager:scheduleIn(2, function()
    os.execute("touch /work/ozr-shot-ready")
    UIManager:scheduleIn(3, function() f:close(); UIManager:quit() end)
  end)
end)
