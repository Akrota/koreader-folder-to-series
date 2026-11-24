-- Ordner zu Reihe: einen Plan aus ozr_planner.lua ausfuehren.
-- Verschieben wie KOReaders Ausschneiden/Einfuegen (FileManager:pasteFileFromClipboard): Datei umbenennen,
-- DocSettings.updateLocation (Lesestand, .sdr), Verlauf und Sammlungen nachziehen.
-- Reihe eintragen wie BookInfo:setCustomMetadata: custom_props in KOReaders Custom-Metadaten-Datei, dazu
-- die Buecher-Datenbank (bookinfo), aus der ZenOS die Reihen liest.
local DocSettings = require("docsettings")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")

local Executor = {}

local function splitPath(path)
    local dir, name = path:match("^(.*/)([^/]+)$")
    return dir or "./", name or path
end

--- Bibliothek (bookinfo) die Reihe sofort kennen lassen, auch wenn das Buch noch nicht eingelesen ist.
-- Gibt es keine Zeile, wird eine kleine angelegt (ohne Titelbild: cover_fetched leer, die Bibliothek liest
-- es beim Anzeigen ganz ein und uebernimmt dabei die eigenen Angaben). ZenOS liest die Reihen von hier.
function Executor.ensureRow(file, series, index)
    local ok_b, BIM = pcall(require, "bookinfomanager")
    if not (ok_b and BIM and BIM.openDbConnection) then return end
    pcall(function()
        local dir, name = splitPath(file)
        BIM:openDbConnection()
        local stmt = BIM.db_conn:prepare("SELECT bcid FROM bookinfo WHERE directory=? AND filename=?;")
        stmt:bind(dir, name)
        local row = stmt:step()
        stmt:clearbind():reset()
        stmt:close()
        if row then
            BIM:setBookInfoProperties(file, { series = series, series_index = index or false })
        else
            local ins = BIM.db_conn:prepare("INSERT INTO bookinfo (directory, filename, in_progress, series, series_index) VALUES (?, ?, 0, ?, ?);")
            ins:bind(dir, name, series, index)
            ins:step()
            ins:clearbind():reset()
            ins:close()
        end
    end)
end

--- Zeile der Buecher-Datenbank mitnehmen (behaelt Titelbild und Angaben, kein neues Einlesen noetig).
local function moveRow(from, to)
    local ok_b, BIM = pcall(require, "bookinfomanager")
    if not (ok_b and BIM and BIM.openDbConnection) then return end
    local ok = pcall(function()
        local fdir, fname = splitPath(from)
        local tdir, tname = splitPath(to)
        BIM:openDbConnection()
        local del = BIM.db_conn:prepare("DELETE FROM bookinfo WHERE directory=? AND filename=?;")
        del:bind(tdir, tname)
        del:step()
        del:clearbind():reset()
        del:close()
        local up = BIM.db_conn:prepare("UPDATE bookinfo SET directory=?, filename=? WHERE directory=? AND filename=?;")
        up:bind(tdir, tname, fdir, fname)
        up:step()
        up:clearbind():reset()
        up:close()
    end)
    if not ok and BIM.deleteBookInfo then pcall(BIM.deleteBookInfo, BIM, from) end
end

--- Reihe und Nummer als eigene Buchangabe speichern (wie "Buchinformationen bearbeiten").
function Executor.setSeries(file, series, index)
    local cmf = DocSettings:findCustomMetadataFile(file)
    local settings
    if cmf then
        settings = DocSettings.openSettingsFile(cmf)
    else
        settings = DocSettings.openSettingsFile()
        -- Original-Angaben aus der Buecher-Datenbank, sonst nur der Dateiname (wie KOReader es ergaenzt)
        local props = {}
        local ok_b, BIM = pcall(require, "bookinfomanager")
        if ok_b and BIM and BIM.getDocProps then
            local ok_p, p = pcall(BIM.getDocProps, BIM, file)
            if ok_p and type(p) == "table" then props = p end
        end
        local ok, BookInfo = pcall(require, "apps/filemanager/filemanagerbookinfo")
        if ok and BookInfo.extendProps then
            local ok_x, p = pcall(BookInfo.extendProps, props, file)
            if ok_x and type(p) == "table" then props = p end
        end
        props.display_title = nil
        settings:saveSetting("doc_props", props) -- Kopie der Original-Angaben, wie KOReader es macht
    end
    local custom = settings:readSetting("custom_props", {})
    custom.series = series
    custom.series_index = index
    settings:flushCustomMetadata(file)
    -- Buecher-Datenbank (Bibliothek, ZenOS) gleich mitziehen, auch fuer noch nicht eingelesene Buecher
    Executor.ensureRow(file, series, index)
end

--- Hat das Buch schon eine Reihe? (selbst eingetragen oder aus der Datei, so wie die Bibliothek es kennt)
-- @return Reihenname oder nil
function Executor.existingSeries(file)
    local cmf = DocSettings:findCustomMetadataFile(file)
    if cmf then
        local custom = DocSettings.openSettingsFile(cmf):readSetting("custom_props")
        if type(custom) == "table" and type(custom.series) == "string" and custom.series ~= "" then
            -- Reparatur: Reihe eingetragen, aber die Bibliothek kennt sie noch nicht -> nachtragen
            Executor.ensureRow(file, custom.series, tonumber(custom.series_index))
            return custom.series
        end
    end
    local ok_b, BookInfoManager = pcall(require, "bookinfomanager")
    if ok_b and BookInfoManager and BookInfoManager.getDocProps then
        local ok, props = pcall(BookInfoManager.getDocProps, BookInfoManager, file)
        if ok and type(props) == "table" and type(props.series) == "string" and props.series ~= "" then return props.series end
    end
    return nil
end

--- Eine Datei samt Lesestand verschieben. @return true bei Erfolg
function Executor.move(from, to)
    if lfs.attributes(to, "mode") then return false end -- nie ueberschreiben
    local ok, err = os.rename(from, to)
    if not ok then
        logger.warn("OrdnerZuReihe: move failed", from, to, err)
        return false
    end
    pcall(DocSettings.updateLocation, from, to, false)
    local ok_h, ReadHistory = pcall(require, "readhistory")
    if ok_h then pcall(ReadHistory.updateItem, ReadHistory, from, to) end
    local ok_c, ReadCollection = pcall(require, "readcollection")
    if ok_c then pcall(ReadCollection.updateItem, ReadCollection, from, to) end
    moveRow(from, to)
    return true
end

local function isEmpty(dir)
    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." then return false end
    end
    return true
end

--- Alle Reihen, die die Bibliothek schon kennt: { ["kleingeschrieben"] = { name = "Original", count = n } }
function Executor.knownSeries()
    local known = {}
    local ok_b, BIM = pcall(require, "bookinfomanager")
    if not (ok_b and BIM and BIM.openDbConnection) then return known end
    pcall(function()
        BIM:openDbConnection()
        local stmt = BIM.db_conn:prepare("SELECT series, COUNT(*) FROM bookinfo WHERE series IS NOT NULL AND series != '' GROUP BY series;")
        for row in stmt:rows() do
            local name, count = row[1], tonumber(row[2]) or 0
            if type(name) == "string" then
                local key = name:lower()
                if not known[key] or count > known[key].count then known[key] = { name = name, count = count } end
            end
        end
        stmt:close()
    end)
    return known
end

--- Alle Dateien einer Reihe, wie die Bibliothek sie kennt (nur solche, die es noch gibt).
-- @return Liste voller Pfade, sortiert nach Bandnummer
function Executor.seriesFiles(series)
    local list = {}
    local ok_b, BIM = pcall(require, "bookinfomanager")
    if not (ok_b and BIM and BIM.openDbConnection) then return list end
    pcall(function()
        BIM:openDbConnection()
        local stmt = BIM.db_conn:prepare("SELECT directory, filename, series_index FROM bookinfo WHERE series=?;")
        stmt:bind(series)
        while true do
            local row = stmt:step()
            if not row then break end
            local path = tostring(row[1]) .. tostring(row[2])
            if lfs.attributes(path, "mode") == "file" then
                list[#list + 1] = { path = path, index = tonumber(row[3]) }
            end
        end
        stmt:clearbind():reset()
        stmt:close()
    end)
    table.sort(list, function(a, b)
        if (a.index or 0) ~= (b.index or 0) then return (a.index or 0) < (b.index or 0) end
        return a.path < b.path
    end)
    local paths = {}
    for i, e in ipairs(list) do paths[i] = e.path end
    return paths
end

--- Plan fuer "Reihe hierher holen": alle Baende einer Reihe in den Zielordner.
-- @return { series, target, moves = {{from,to,name}}, here = n (schon dort), keep = {{name,reason}}, dirs = {Quellordner} }
function Executor.planGather(series, target, files)
    target = target:gsub("/+$", "")
    local plan = { series = series, target = target, moves = {}, here = 0, keep = {}, dirs = {} }
    local seen_dirs, taken = {}, {}
    for _, from in ipairs(files or Executor.seriesFiles(series)) do
        local dir, name = splitPath(from)
        local d = dir:gsub("/+$", "")
        if d == target then
            plan.here = plan.here + 1
        else
            local to = target .. "/" .. name
            if lfs.attributes(to, "mode") or taken[to] then
                plan.keep[#plan.keep + 1] = { name = name, reason = "exists" }
            else
                taken[to] = true
                plan.moves[#plan.moves + 1] = { from = from, to = to, name = name }
                if not seen_dirs[d] then seen_dirs[d] = true; plan.dirs[#plan.dirs + 1] = d end
            end
        end
    end
    return plan
end

--- "Reihe hierher holen" ausfuehren. opts.is_protected(dir) -> Ordner nie loeschen.
-- Ein Quellordner wird nur geloescht, wenn er danach wirklich leer ist (und nicht ueber dem Ziel liegt).
-- @return { moved = n, failed = {names}, deleted = n }
function Executor.runGather(plan, opts)
    opts = opts or {}
    local result = { moved = 0, failed = {}, deleted = 0 }
    for _, m in ipairs(plan.moves) do
        if Executor.move(m.from, m.to) then
            result.moved = result.moved + 1
        else
            result.failed[#result.failed + 1] = m.name
        end
    end
    for _, d in ipairs(plan.dirs) do
        local above_target = (plan.target .. "/"):sub(1, #d + 1) == d .. "/"
        local protected = opts.is_protected and opts.is_protected(d)
        if not above_target and not protected and lfs.attributes(d, "mode") == "directory" and isEmpty(d) then
            if lfs.rmdir(d) then result.deleted = result.deleted + 1 end
        end
    end
    return result
end

--- Plan ausfuehren. @return { moved = n, failed = {names}, folder_deleted = bool }
-- opts.no_move: nur Reihe eintragen, Comics bleiben, wo sie sind
function Executor.run(plan, opts)
    opts = opts or {}
    local result = { moved = 0, failed = {}, folder_deleted = false }
    if opts.no_move then
        for _, m in ipairs(plan.moves) do
            local ok, err = pcall(Executor.setSeries, m.from, plan.series, m.index)
            if ok then result.moved = result.moved + 1 else
                logger.warn("OrdnerZuReihe: setting series failed", m.from, err)
                result.failed[#result.failed + 1] = m.name
            end
        end
        return result
    end
    for _, m in ipairs(plan.moves) do
        if m.to and Executor.move(m.from, m.to) then
            local ok, err = pcall(Executor.setSeries, m.to, plan.series, m.index)
            if not ok then logger.warn("OrdnerZuReihe: setting series failed", m.to, err) end
            result.moved = result.moved + 1
        else
            result.failed[#result.failed + 1] = m.name
        end
    end
    -- Nur loeschen, wenn wirklich nichts mehr drin ist (auch keine .sdr-Reste)
    if plan.delete_folder and isEmpty(plan.dir) then
        result.folder_deleted = lfs.rmdir(plan.dir) and true or false
    end
    return result
end

return Executor
