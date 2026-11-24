-- Ordner zu Reihe: Plan fuer einen Ordner aufstellen (noch nichts aendern).
-- Stand 04.11.2026, erster Teil des Prototyps (Windows-Claude). Ausfuehren, Vorschau und Menue folgen.
--
-- Regeln (mit dem Nutzer abgestimmt, siehe OFFEN.md "Ordner zu Reihe"):
--  * Comics im Ordner bekommen den Ordnernamen als Reihe, die Nummer aus dem Dateinamen
--    ("Akira (1988) #22.cbz" -> 22; Jahreszahlen in Klammern zaehlen nicht).
--  * Eine Reihe braucht mindestens 2 Teile, sonst bleibt der Comic, wie er ist.
--  * Comics wandern eine Ebene hoeher (in den Ordner darueber). Liegt dort schon eine Datei mit
--    demselben Namen, bleibt der Comic liegen (nie ueberschreiben).
--  * Der Ordner wird nur geloescht, wenn er danach wirklich leer ist und nicht geschuetzt ist.
local lfs = require("libs/libkoreader-lfs")

local Planner = {}

Planner.BOOK_EXT = { cbz = true, cbr = true, cb7 = true, cbt = true, pdf = true, epub = true, djvu = true }

local function ext_of(name)
    return (name:match("%.([^./]+)$") or ""):lower()
end

--- Bandnummer aus einem Dateinamen, oder nil.
-- Vorrang: "#12", dann "Band/Vol./Tome/Issue 12", dann die letzte Zahl, die keine Jahreszahl in Klammern ist.
function Planner.parseIndex(filename)
    local base = filename:gsub("%.[^.]+$", "")
    -- Klammern entfernen: "(1988)", "[Cross Cult, 2013]", "(Nihei Tsutomu)", "(v. 2)"
    local clean = base:gsub("%b()", " "):gsub("%b[]", " ")
    local n = clean:match("#%s*(%d+%.?%d*)")
    if not n then
        local lower = clean:lower()
        n = lower:match("volume%s*(%d+%.?%d*)") or lower:match("vol%.?%s*(%d+%.?%d*)")
            or lower:match("%f[%w]v%.?%s*(%d+%.?%d*)") or lower:match("band%s*(%d+%.?%d*)")
            or lower:match("tome%s*(%d+%.?%d*)") or lower:match("issue%s*(%d+%.?%d*)")
    end
    if not n then
        -- letzte freistehende Zahl ("Batman 012", "Saga - 03")
        for num in clean:gmatch("%f[%w](%d+%.?%d*)%f[^%w.]") do n = num end
    end
    return n and tonumber(n) or nil
end

--- Reihenname aus dem Ordnernamen: ganz klein geschriebene Namen bekommen grosse Anfangsbuchstaben
-- ("akira" -> "Akira", "one piece" -> "One Piece"); sonst bleibt der Name, wie er ist ("X-Men", "dEUS").
function Planner.seriesName(folder)
    -- Zusaetze im Ordnernamen weg: "(01-38)", "(1988)", "[Carlsen]", "01 - 12" am Ende
    local name = folder:gsub("%b()", " "):gsub("%b[]", " ")
    name = name:gsub("%s+%d+%s*%-%s*%d+%s*$", " ")
    name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("[%s%-_,:]+$", "")
    if name == "" then name = folder end
    if name ~= name:lower() then return name end
    return (name:gsub("(%f[%w])(%l)", function(_, c) return c:upper() end))
end

--- Sieht der Ordner nach EINER Reihe aus? Die meisten Comics (mind. 60 %) tragen im Dateinamen denselben
-- Reihennamen. Ein Sammelordner wie "Fanatical" (lauter verschiedene Titel) faellt dabei durch.
-- (Planner.seriesFromFilename steht weiter unten, wird erst beim Aufruf gebraucht.)
function Planner.looksLikeSeries(names)
    if #names < 2 then return false end
    local count, best = {}, 0
    for _, name in ipairs(names) do
        local s = Planner.seriesFromFilename(name)
        if s then
            local key = s:lower()
            count[key] = (count[key] or 0) + 1
            if count[key] > best then best = count[key] end
        end
    end
    return best >= 2 and best >= #names * 0.6
end

--- Plan fuer einen Ordner.
-- @return { series = Name, parent = Zielordner, moves = { {from, to, index, name} }, keep = { {name, reason} },
--           delete_folder = bool }
function Planner.plan(dir, opts)
    opts = opts or {}
    dir = dir:gsub("/+$", "")
    local parent, folder = dir:match("^(.*)/([^/]+)$")
    local series = folder and (opts.series or Planner.seriesName(folder))
    local plan = { series = series, parent = parent, dir = dir, moves = {}, keep = {}, delete_folder = false }
    if not (parent and series) then return plan end
    local books, others = {}, 0
    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." then
            local path = dir .. "/" .. name
            local mode = lfs.attributes(path, "mode")
            if mode == "file" and Planner.BOOK_EXT[ext_of(name)] and name:sub(1, 2) ~= "._" then
                books[#books + 1] = name
            elseif name:match("%.sdr$") and mode == "directory" then
                -- Begleitordner von KOReader (Lesestand), wandert mit dem Buch
            else
                others = others + 1
                plan.keep[#plan.keep + 1] = { name = name, reason = "other" }
            end
        end
    end
    table.sort(books)
    -- Comics, die schon eine Reihe haben, nicht noch einmal anfassen (bleiben liegen, nichts wird ueberschrieben)
    local fresh = {}
    for _, name in ipairs(books) do
        local existing = opts.existing_series and opts.existing_series(dir .. "/" .. name)
        if existing then
            plan.keep[#plan.keep + 1] = { name = name, reason = "series", series = existing }
        else
            fresh[#fresh + 1] = name
        end
    end
    books = fresh
    plan.looks_like_series = Planner.looksLikeSeries(books)
    if #books < 2 then
        for _, name in ipairs(books) do plan.keep[#plan.keep + 1] = { name = name, reason = "single" } end
        return plan
    end
    for _, name in ipairs(books) do
        local to = parent .. "/" .. name
        if lfs.attributes(to, "mode") then
            plan.keep[#plan.keep + 1] = { name = name, reason = "exists" }
        else
            plan.moves[#plan.moves + 1] = { from = dir .. "/" .. name, to = to, name = name, index = Planner.parseIndex(name) }
        end
    end
    plan.delete_folder = #plan.keep == 0 and others == 0 and not opts.protected
    return plan
end

--- Unterordner eines Ordners (z. B. "comics"), die Comics enthalten: je einer wird zu seiner Reihe.
-- @return Liste von Plaenen (nur solche, in denen es etwas zu tun gibt), dazu alle Plaene fuer die Vorschau
function Planner.planSubfolders(dir, opts)
    opts = opts or {}
    dir = dir:gsub("/+$", "")
    local subs = {}
    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." and not name:match("%.sdr$") and name:sub(1, 1) ~= "." then
            if lfs.attributes(dir .. "/" .. name, "mode") == "directory" then subs[#subs + 1] = name end
        end
    end
    table.sort(subs)
    local plans = {}
    for _, name in ipairs(subs) do
        local sub = dir .. "/" .. name
        local p = Planner.plan(sub, {
            protected = opts.is_protected and opts.is_protected(sub),
            existing_series = opts.existing_series,
        })
        -- Sammelordner (verschiedene Titel) nicht als Reihe nehmen: alles bleibt drin
        if #p.moves > 0 and not p.looks_like_series then
            p.collection = true
            p.moves = {}
            p.delete_folder = false
        end
        plans[#plans + 1] = p
    end
    return plans
end

--- Reihenname aus einem Dateinamen, oder nil (dann Einzelband).
-- "Saga #1" -> "Saga", "Batman 012" -> "Batman", "One Piece Vol. 105" -> "One Piece",
-- "Spider-Man 2099 #3" -> "Spider-Man 2099", "X-Men (1991) 001 (digital)" -> "X-Men", "Watchmen" -> nil
function Planner.seriesFromFilename(filename)
    local base = filename:gsub("%.[^.]+$", "")
    base = base:gsub("%b()", " "):gsub("%b[]", " ")
    -- Nummer vorne, Name dahinter: "324 - Berserk", "012_Saga", "05. One Piece"
    local lead = base:match("^%s*%d+%.?%d*%s*[%-–_:%.]+%s*(.-)%s*$")    if lead and lead:find("%a") then
        lead = lead:gsub("%s+", " ")
        return lead
    end
    local name
    local cut = base:find("#", 1, true)
    if cut then
        name = base:sub(1, cut - 1)
    else
        local lower = base:lower()
        for _, word in ipairs({ "volume", "vol%.?", "v%.?", "band", "tome", "issue", "teil", "chapter", "kapitel" }) do
            local s = lower:find("%f[%w]" .. word .. "%s*%d")
            if s then name = base:sub(1, s - 1) break end
        end
        if not name then
            -- letzte freistehende Zahl am Ende ("Batman 012", "Saga - 03")
            local s = base:find("%f[%w]%d+%.?%d*%s*$")
            if s then name = base:sub(1, s - 1) end
        end
        if not name then
            -- Zahl mit Untertitel dahinter ("Ghost in the Shell 2 Human-Error Processor"): Name davor
            local s = base:find("%s%d+%.?%d*%s+%a")
            if s then name = base:sub(1, s) end
        end
    end
    if not name then return nil end
    name = name:gsub("[%s%-_,:%.]+$", ""):gsub("^%s+", ""):gsub("%s+", " ")
    if name == "" then return nil end
    return name
end

--- Reihe und Nummer aus ComicInfo.xml in einer CBZ (wie viele Comic-Programme sie schreiben), oder nil.
function Planner.comicInfo(path)
    if not path:lower():match("%.cbz$") then return nil end
    local ok_a, Archiver = pcall(require, "ffi/archiver")
    if not ok_a then return nil end
    local reader = Archiver.Reader:new()
    if not reader:open(path) then return nil end
    local xml
    for entry in reader:iterate() do
        if entry.mode == "file" and entry.path:lower():match("comicinfo%.xml$") then
            xml = reader:extractToMemory(entry.path)
            break
        end
    end
    reader:close()
    if not xml then return nil end
    local series = xml:match("<Series>%s*(.-)%s*</Series>")
    if not series or series == "" then return nil end
    series = series:gsub("&amp;", "&"):gsub("&apos;", "'"):gsub("&quot;", '"')
    return series, tonumber(xml:match("<Number>%s*([%d%.]+)%s*</Number>"))
end

--- Lose Comics eines Ordners nach Reihen gruppieren (nur Reihen mit mindestens 2 Comics).
-- @return Liste von Plaenen wie Planner.plan (eine Reihe je Plan), dazu Zahl der Einzelbaende und der schon eingeordneten
function Planner.planLoose(dir, opts)
    opts = opts or {}
    dir = dir:gsub("/+$", "")
    local parent = dir:match("^(.*)/[^/]+$")
    local groups, order, single, skipped = {}, {}, 0, 0
    local names = {}
    for name in lfs.dir(dir) do
        local path = dir .. "/" .. name
        if lfs.attributes(path, "mode") == "file" and Planner.BOOK_EXT[ext_of(name)] and name:sub(1, 2) ~= "._" then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local path = dir .. "/" .. name
        if opts.existing_series and opts.existing_series(path) then
            skipped = skipped + 1
        else
            local series, index = Planner.comicInfo(path)
            if not series then
                series = Planner.seriesFromFilename(name)
                index = Planner.parseIndex(name)
            end
            if series then
                local key = series:lower()
                if not groups[key] then
                    groups[key] = { series = series, items = {} }
                    order[#order + 1] = key
                end
                table.insert(groups[key].items, { name = name, index = index })
            else
                single = single + 1
            end
        end
    end
    local plans = {}
    for _, key in ipairs(order) do
        local g = groups[key]
        if #g.items < 2 then
            single = single + #g.items
        else
            local plan = { series = g.series, parent = parent, dir = dir, moves = {}, keep = {}, delete_folder = false, loose = true }
            for _, it in ipairs(g.items) do
                local to = parent and (parent .. "/" .. it.name)
                if to and lfs.attributes(to, "mode") then
                    plan.keep[#plan.keep + 1] = { name = it.name, reason = "exists" }
                else
                    plan.moves[#plan.moves + 1] = { from = dir .. "/" .. it.name, to = to, name = it.name, index = it.index }
                end
            end
            plans[#plans + 1] = plan
        end
    end
    return plans, single, skipped
end

--- Hat der Ordner Unterordner? (dann ist "Unterordner als Reihen" sinnvoll)
function Planner.hasSubfolders(dir)
    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." and not name:match("%.sdr$") and name:sub(1, 1) ~= "."
                and lfs.attributes(dir .. "/" .. name, "mode") == "directory" then
            return true
        end
    end
    return false
end

return Planner
