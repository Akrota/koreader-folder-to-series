--[[--
Ordner zu Reihe (Prototyp, Windows-Claude 04.11.2026): lange auf einen Ordner in der Bibliothek druecken
-> "Als Reihe zusammenfassen". Vorschau, dann: Reihe und Bandnummer eintragen, Comics eine Ebene hoeher,
leeren Ordner loeschen. "Diesen Ordner nie loeschen" schuetzt einen Ordner.
--]]
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Executor = require("ozr_executor")
local Planner = require("ozr_planner")

local strings = {
    de = {
        button = "Als Reihe zusammenfassen",
        protect_on = "Diesen Ordner nie löschen",
        protect_off = "Ordner wieder löschen erlauben",
        nothing = "Hier gibt es nichts zusammenzufassen: Eine Reihe braucht mindestens 2 Comics in diesem Ordner.",
        preview = "Reihe „%s“: %d Comics%s\n\nSie werden eine Ebene höher nach „%s“ verschoben, Lesestand und Notizen wandern mit.",
        numbers = " (Band %s–%s)",
        no_numbers = " (ohne erkannte Bandnummern)",
        keep = "\n\nBleiben im Ordner: %d (%s)",
        delete = "\n\nDer leere Ordner wird danach gelöscht.",
        protected = "\n\nDer Ordner ist geschützt und bleibt bestehen.",
        not_empty = "\n\nDer Ordner bleibt bestehen (es bleibt etwas darin).",
        start = "Zusammenfassen",
        rename = "Name ändern",
        rename_title = "Name der Reihe",
        cancel = "Abbrechen",
        ok = "OK",
        done = "Fertig: %d Comics als Reihe „%s“ eingetragen und verschoben.%s",
        failed = "\nNicht verschoben: %s",
        deleted = "\nDer leere Ordner wurde gelöscht.",
        reason_exists = "gleicher Name schon vorhanden",
        reason_other = "andere Datei",
        reason_single = "einzeln",
        reason_series = "schon in einer Reihe",
        button_subs = "Unterordner als Reihen zusammenfassen",
        subs_preview = "Unterordner von „%s“ als Reihen zusammenfassen:",
        sub_line = "• %s: %d Comics",
        sub_deleted = ", Ordner wird danach gelöscht",
        subs_skipped = "\n\n%d Comics sind schon in einer Reihe und bleiben, wie sie sind.",
        subs_done = "Fertig: %d Reihen, %d Comics verschoben, %d leere Ordner gelöscht.",
        nothing_subs = "In den Unterordnern gibt es nichts zusammenzufassen (eine Reihe braucht mindestens 2 Comics).",
        nothing_all_series = "Nichts zu tun: %d Comics sind schon in einer Reihe, der Rest steht einzeln.",
        collections = "\n\nÜbersprungen, sieht nach Sammelordner aus (verschiedene Titel, alles bleibt drin): %s",
        warn_collection = "\n\n⚠ Achtung: Die Dateinamen sehen nach verschiedenen Titeln aus, nicht nach einer Reihe. Für so einen Ordner besser „Lose Comics als Reihen erkennen“ nehmen.",
        button_loose = "Lose Comics als Reihen erkennen",
        loose_preview = "Erkannte Reihen in „%s“ (aus der Comic-Datei oder dem Dateinamen). Beim Verschieben landen sie in „%s“:",
        singles = "\n\n%d Einzel-Comics bleiben, wie sie sind.",
        known = " – gibt es schon (%d), wird ergänzt",
        nothing_loose = "Keine Reihe erkannt: Es braucht mindestens 2 Comics mit gleichem Reihennamen.",
        set_and_move = "Eintragen + verschieben",
        only_set = "Nur eintragen",
        choose = "Auswählen …",
        choose_title = "Welche Reihen? (antippen zum An- und Abwählen)",
        done_choosing = "Fertig",
        none_chosen = "Keine Reihe ausgewählt, es wurde nichts geändert.",
        loose_done = "Fertig: %d Reihen eingetragen (%d Comics), die Comics bleiben, wo sie sind.",
        menu_title = "Ordner zu Reihe",
        menu_this = "„%s“ als Reihe zusammenfassen",
        menu_subs = "Unterordner von „%s“ als Reihen zusammenfassen",
        menu_loose = "Lose Comics in „%s“ als Reihen erkennen",
        menu_protect = "„%s“ nie löschen",
        open_library = "Öffne zuerst in der Bibliothek den Ordner, um den es gehen soll.",
        about = "Wie funktioniert das?",
        about_text = "Macht aus Comic-Ordnern Reihen, die ZenOS und KOReader wie einen Ordner anzeigen. In der Bibliothek lange auf einen Ordner drücken:\n\n"
            .. "• Als Reihe zusammenfassen: Der Ordnername wird die Reihe, die Nummer kommt aus dem Dateinamen (#22, Vol. 105, Band 7 …). Die Comics wandern eine Ebene höher, Lesestand und Notizen kommen mit. Ist der Ordner danach leer, wird er gelöscht.\n"
            .. "• Unterordner als Reihen zusammenfassen: für Ordner wie „comics“, jeder Unterordner wird seine eigene Reihe.\n"
            .. "• Lose Comics als Reihen erkennen: für gemischte Ordner. Reihe aus der Comic-Datei (ComicInfo) oder dem Dateinamen. Wahlweise eintragen und eine Ebene höher schieben oder nur eintragen.\n"
            .. "• Reihe hierher holen: alle Comics einer Reihe aus allen Ordnern in diesen Ordner verschieben.\n"
            .. "• Diesen Ordner nie löschen: Reihen wandern trotzdem nach oben, der Ordner bleibt.\n\n"
            .. "Vorher zeigt eine Vorschau alles an, ohne deinen Klick passiert nichts. Mit „Auswählen …“ lassen sich einzelne Reihen abwählen. Nichts wird überschrieben, Comics mit schon vorhandener Reihe bleiben unverändert, eine Reihe braucht mindestens 2 Comics. Gibt es eine Reihe schon (z. B. „Batman“), wird sie genauso geschrieben ergänzt.",
        menu_gather = "Reihe nach „%s“ holen …",
        button_gather = "Reihe hierher holen …",
        gather_title = "Welche Reihe nach „%s“ holen?",
        gather_none = "Die Bibliothek kennt noch keine Reihen.",
        gather_preview = "Reihe „%s“ nach „%s“ holen: %d Comics aus %s.\n\nLesestand und Notizen wandern mit.",
        gather_here = "\n\nSchon dort: %d",
        gather_keep = "\n\nBleibt liegen (gleicher Name schon im Ziel): %d (%s)",
        gather_delete = "\n\nOrdner, die danach ganz leer sind, werden gelöscht (außer „nie löschen“).",
        gather_nothing = "Alle Comics der Reihe „%s“ liegen schon in „%s“.",
        gather_start = "Holen",
        gather_done = "Fertig: %d Comics der Reihe „%s“ nach „%s“ geholt, %d leere Ordner gelöscht.%s",
        protected_set = "Der Ordner wird nie gelöscht. Reihen darin werden trotzdem nach oben verschoben.",
        protected_unset = "Der Ordner darf wieder gelöscht werden, wenn er leer ist.",
    },
    en = {
        button = "Combine as series",
        protect_on = "Never delete this folder",
        protect_off = "Allow deleting this folder again",
        nothing = "Nothing to combine here: a series needs at least 2 comics in this folder.",
        preview = "Series \"%s\": %d comics%s\n\nThey will be moved one level up to \"%s\"; reading position and notes move along.",
        numbers = " (no. %s–%s)",
        no_numbers = " (no numbers recognised)",
        keep = "\n\nStaying in the folder: %d (%s)",
        delete = "\n\nThe empty folder will be deleted afterwards.",
        protected = "\n\nThe folder is protected and stays.",
        not_empty = "\n\nThe folder stays (something remains in it).",
        start = "Combine",
        rename = "Change name",
        rename_title = "Series name",
        cancel = "Cancel",
        ok = "OK",
        done = "Done: %d comics set as series \"%s\" and moved.%s",
        failed = "\nNot moved: %s",
        deleted = "\nThe empty folder was deleted.",
        reason_exists = "same name already there",
        reason_other = "other file",
        reason_single = "single",
        reason_series = "already in a series",
        button_subs = "Combine subfolders as series",
        subs_preview = "Combine the subfolders of \"%s\" as series:",
        sub_line = "• %s: %d comics",
        sub_deleted = ", folder deleted afterwards",
        subs_skipped = "\n\n%d comics are already in a series and stay as they are.",
        subs_done = "Done: %d series, %d comics moved, %d empty folders deleted.",
        nothing_subs = "Nothing to combine in the subfolders (a series needs at least 2 comics).",
        nothing_all_series = "Nothing to do: %d comics are already in a series, the rest stand alone.",
        collections = "\n\nSkipped, looks like a collection (different titles, everything stays): %s",
        warn_collection = "\n\n⚠ Note: the file names look like different titles, not one series. For such a folder better use \"Detect series in loose comics\".",
        button_loose = "Detect series in loose comics",
        loose_preview = "Series found in \"%s\" (from the comic file or the file name). When moving they go to \"%s\":",
        singles = "\n\n%d standalone comics stay as they are.",
        known = " – already exists (%d), will be extended",
        nothing_loose = "No series found: it needs at least 2 comics with the same series name.",
        set_and_move = "Set + move",
        only_set = "Only set",
        choose = "Choose …",
        choose_title = "Which series? (tap to select or deselect)",
        done_choosing = "Done",
        none_chosen = "No series selected, nothing was changed.",
        loose_done = "Done: %d series set (%d comics), the comics stay where they are.",
        menu_title = "Folder to series",
        menu_this = "Combine \"%s\" as series",
        menu_subs = "Combine subfolders of \"%s\" as series",
        menu_loose = "Detect series in loose comics in \"%s\"",
        menu_protect = "Never delete \"%s\"",
        open_library = "First open the folder in the library that this should apply to.",
        about = "How does it work?",
        about_text = "Turns comic folders into series that ZenOS and KOReader show like a folder. In the library, long-press a folder:\n\n"
            .. "• Combine as series: the folder name becomes the series, the number comes from the file name (#22, Vol. 105 …). The comics move one level up, reading position and notes come along. If the folder is empty afterwards, it is deleted.\n"
            .. "• Combine subfolders as series: for folders like \"comics\", every subfolder becomes its own series.\n"
            .. "• Detect series in loose comics: for mixed folders. Series from the comic file (ComicInfo) or the file name. Either set and move one level up, or only set.\n"
            .. "• Bring a series here: move all comics of a series from all folders into this folder.\n"
            .. "• Never delete this folder: series still move up, the folder stays.\n\n"
            .. "A preview shows everything first, nothing happens without your tap. \"Choose …\" lets you deselect series. Nothing is overwritten, comics that already have a series stay unchanged, a series needs at least 2 comics. If a series already exists (e.g. \"Batman\"), it is extended with the same spelling.",
        menu_gather = "Bring a series to \"%s\" …",
        button_gather = "Bring a series here …",
        gather_title = "Which series to bring to \"%s\"?",
        gather_none = "The library doesn't know any series yet.",
        gather_preview = "Bring series \"%s\" to \"%s\": %d comics from %s.\n\nReading position and notes move along.",
        gather_here = "\n\nAlready there: %d",
        gather_keep = "\n\nStaying (same name already in the target): %d (%s)",
        gather_delete = "\n\nFolders that are completely empty afterwards are deleted (except \"never delete\").",
        gather_nothing = "All comics of the series \"%s\" are already in \"%s\".",
        gather_start = "Bring",
        gather_done = "Done: %d comics of series \"%s\" brought to \"%s\", %d empty folders deleted.%s",
        protected_set = "This folder will never be deleted. Series in it are still moved up.",
        protected_unset = "This folder may be deleted again when it is empty.",
    },
}

local function T(key, ...)
    local ok, lang = pcall(function() return G_reader_settings:readSetting("language") end)
    local l = (ok and type(lang) == "string" and lang:sub(1, 2):lower() == "de") and "de" or "en"
    local s = strings[l][key] or strings.en[key] or key
    if select("#", ...) > 0 then s = string.format(s, ...) end
    return s
end

local PROTECT_KEY = "ordnerzureihe_protected"

local function isProtected(dir)
    local list = G_reader_settings:readSetting(PROTECT_KEY) or {}
    return list[dir] == true
end

local function setProtected(dir, on)
    local list = G_reader_settings:readSetting(PROTECT_KEY) or {}
    list[dir] = on or nil
    G_reader_settings:saveSetting(PROTECT_KEY, list)
end

local function fmtIndex(v)
    if not v then return "?" end
    return (v == math.floor(v)) and tostring(math.floor(v)) or tostring(v)
end

local OrdnerZuReihe = WidgetContainer:extend{
    name = "ordnerzureihe",
    is_doc_only = false,
}

--- Der Ordner, der gerade in der Bibliothek offen ist (nur im Dateimanager)
function OrdnerZuReihe:currentDir()
    local fc = self.ui and self.ui.file_chooser
    local path = fc and fc.path
    if type(path) ~= "string" or path == "" then return nil end
    return (path:gsub("/+$", ""))
end

-- Auch ueber das Menue, fuer den gerade offenen Ordner (falls das lange Druecken in ZenOS
-- die Knoepfe nicht zeigt: ZenOS-Einstellungen -> Bibliothek -> Kontextmenue -> Plugin-Aktionen).
function OrdnerZuReihe:addToMainMenu(menu_items)
    local function name()
        local d = self:currentDir()
        return d and (d:match("([^/]+)$") or d) or "?"
    end
    local function run(fn)
        return function()
            local d = self:currentDir()
            if d then fn(d) else UIManager:show(InfoMessage:new{ text = T("open_library") }) end
        end
    end
    menu_items.ordnerzureihe = {
        text = T("menu_title"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text_func = function() return T("menu_this", name()) end,
                enabled_func = function() return self:currentDir() ~= nil end,
                callback = run(function(d) self:startFolder(d) end),
            },
            {
                text_func = function() return T("menu_subs", name()) end,
                enabled_func = function() local d = self:currentDir() return d ~= nil and Planner.hasSubfolders(d) end,
                callback = run(function(d) self:startSubfolders(d) end),
            },
            {
                text_func = function() return T("menu_loose", name()) end,
                enabled_func = function() return self:currentDir() ~= nil end,
                callback = run(function(d) self:startLoose(d) end),
            },
            {
                text_func = function() return T("menu_gather", name()) end,
                enabled_func = function() return self:currentDir() ~= nil end,
                callback = run(function(d) self:startGather(d) end),
            },
            {
                text_func = function() return T("menu_protect", name()) end,
                enabled_func = function() return self:currentDir() ~= nil end,
                checked_func = function() local d = self:currentDir() return d ~= nil and isProtected(d) end,
                callback = function()
                    local d = self:currentDir()
                    if d then setProtected(d, not isProtected(d)) end
                end,
                separator = true,
            },
            {
                text = T("about"),
                keep_menu_open = true,
                callback = function() UIManager:show(InfoMessage:new{ text = T("about_text") }) end,
            },
        },
    }
end

function OrdnerZuReihe:init()
    if self.ui.menu and self.ui.menu.registerToMainMenu then self.ui.menu:registerToMainMenu(self) end
    if not self.ui.addFileDialogButtons then return end
    self.ui:addFileDialogButtons("ordnerzureihe", function(file, is_file)
        if is_file then return end
        local dir = file:gsub("/+$", "")
        local rows = {
            {
                text = T("button"),
                callback = function()
                    self:closeFileDialog()
                    self:startFolder(dir)
                end,
            },
        }
        -- Sammel-Ordner wie "comics": jeder Unterordner wird zu seiner Reihe
        if Planner.hasSubfolders(dir) then
            rows[#rows + 1] = {
                text = T("button_subs"),
                callback = function()
                    self:closeFileDialog()
                    self:startSubfolders(dir)
                end,
            }
        end
        return rows
    end)
    -- Lose Comics nach Reihen (z. B. ein Ordner mit gekauften Comics)
    self.ui:addFileDialogButtons("ordnerzureihe_loose", function(file, is_file)
        if is_file then return end
        local dir = file:gsub("/+$", "")
        return { {
            text = T("button_loose"),
            callback = function()
                self:closeFileDialog()
                self:startLoose(dir)
            end,
        }, {
            text = T("button_gather"),
            callback = function()
                self:closeFileDialog()
                self:startGather(dir)
            end,
        } }
    end)
    -- Schutz in einer eigenen Zeile (eine Zeile mit drei langen Knoepfen waere zu eng)
    self.ui:addFileDialogButtons("ordnerzureihe_protect", function(file, is_file)
        if is_file then return end
        local dir = file:gsub("/+$", "")
        return { {
            text = isProtected(dir) and T("protect_off") or T("protect_on"),
            callback = function()
                self:closeFileDialog()
                local on = not isProtected(dir)
                setProtected(dir, on)
                UIManager:show(InfoMessage:new{ text = on and T("protected_set") or T("protected_unset"), timeout = 3 })
            end,
        } }
    end)
end

function OrdnerZuReihe:planOpts(dir, series)
    return { protected = isProtected(dir), series = series, existing_series = Executor.existingSeries, is_protected = isProtected }
end

--- Reihennamen an schon bekannte Reihen angleichen ("batman" -> "Batman", wenn es die schon gibt)
function OrdnerZuReihe:adoptKnown(plans)
    local known = Executor.knownSeries()
    for _, p in ipairs(plans) do
        local k = p.series and known[p.series:lower()]
        if k then
            p.series = k.name
            p.known_count = k.count
        end
    end
end

function OrdnerZuReihe:planLine(p)
    local line = T("sub_line", p.series, #p.moves)
    if p.known_count then line = line .. T("known", p.known_count) end
    if p.delete_folder then line = line .. T("sub_deleted") end
    return line
end

--- Vorschau ueber mehrere Reihen: ausfuehren, auswaehlen (Haken) oder bei losen Comics nur eintragen.
function OrdnerZuReihe:showPlans(dir, todo, header, skipped, single, allow_no_move, extra)
    local lines = {}
    for _, p in ipairs(todo) do
        if p.selected ~= false then lines[#lines + 1] = self:planLine(p) end
    end
    local text = header .. "\n\n" .. table.concat(lines, "\n")
    if skipped > 0 then text = text .. T("subs_skipped", skipped) end
    if single and single > 0 then text = text .. T("singles", single) end
    if extra then text = text .. extra end
    self._last_extra = extra
    local function chosen()
        local list = {}
        for _, p in ipairs(todo) do if p.selected ~= false then list[#list + 1] = p end end
        return list
    end
    local function run(no_move)
        local moved, deleted, failed, list = 0, 0, {}, chosen()
        for _, p in ipairs(list) do
            local r = Executor.run(p, { no_move = no_move })
            moved = moved + r.moved
            if r.folder_deleted then deleted = deleted + 1 end
            for _, n in ipairs(r.failed) do failed[#failed + 1] = n end
        end
        self:refreshLibrary(dir)
        local extra = #failed > 0 and T("failed", table.concat(failed, ", ")) or ""
        UIManager:show(InfoMessage:new{ text = T(no_move and "loose_done" or "subs_done", #list, moved, deleted) .. extra })
    end
    local box
    local others = { {
        text = T("choose"),
        callback = function()
            UIManager:close(box)
            self:chooseDialog(dir, todo, header, skipped, single, allow_no_move)
        end,
    } }
    if allow_no_move then
        table.insert(others[1], {
            text = T("only_set"),
            callback = function() UIManager:close(box); run(true) end,
        })
    end
    box = ConfirmBox:new{
        text = text,
        ok_text = allow_no_move and T("set_and_move") or T("start"),
        ok_callback = function() run(false) end,
        other_buttons_first = true,
        other_buttons = others,
    }
    box.run = run -- fuer Tests
    UIManager:show(box)
    self.preview = box -- fuer Tests
end

--- Auswahl mit Haken: jede Reihe an/aus, dann zurueck zur Vorschau
function OrdnerZuReihe:chooseDialog(dir, todo, header, skipped, single, allow_no_move)
    local ButtonDialog = require("ui/widget/buttondialog")
    local dialog
    local buttons = {}
    for _, p in ipairs(todo) do
        buttons[#buttons + 1] = { {
            text = (p.selected ~= false and "☑ " or "☐ ") .. p.series .. " (" .. #p.moves .. ")",
            align = "left",
            callback = function()
                p.selected = p.selected == false
                UIManager:close(dialog)
                self:chooseDialog(dir, todo, header, skipped, single, allow_no_move)
            end,
        } }
    end
    buttons[#buttons + 1] = { {
        text = T("done_choosing"),
        callback = function()
            UIManager:close(dialog)
            local any = false
            for _, p in ipairs(todo) do if p.selected ~= false then any = true end end
            if any then self:showPlans(dir, todo, header, skipped, single, allow_no_move, self._last_extra)
            else UIManager:show(InfoMessage:new{ text = T("none_chosen") }) end
        end,
    } }
    dialog = ButtonDialog:new{ title = T("choose_title"), buttons = buttons }
    UIManager:show(dialog)
    self.chooser = dialog -- fuer Tests
end

--- Alle Unterordner eines Sammel-Ordners als Reihen
function OrdnerZuReihe:startSubfolders(dir)
    local plans = Planner.planSubfolders(dir, self:planOpts(dir))
    local todo, skipped, collections = {}, 0, {}
    for _, p in ipairs(plans) do
        for _, k in ipairs(p.keep) do if k.reason == "series" then skipped = skipped + 1 end end
        if p.collection then collections[#collections + 1] = p.dir:match("([^/]+)$") end
        if #p.moves > 0 then todo[#todo + 1] = p end
    end
    local coll_text = #collections > 0 and T("collections", table.concat(collections, ", ")) or ""
    if #todo == 0 then
        UIManager:show(InfoMessage:new{ text = (skipped > 0 and T("nothing_all_series", skipped) or T("nothing_subs")) .. coll_text })
        return
    end
    self:adoptKnown(todo)
    self:showPlans(dir, todo, T("subs_preview", dir:match("([^/]+)$") or dir), skipped, 0, false, coll_text)
end

--- Lose Comics in einem Ordner nach Reihen erkennen (ComicInfo, sonst Dateiname)
function OrdnerZuReihe:startLoose(dir)
    local plans, single, skipped = Planner.planLoose(dir, self:planOpts(dir))
    if #plans == 0 then
        UIManager:show(InfoMessage:new{ text = T("nothing_loose") })
        return
    end
    self:adoptKnown(plans)
    local parent = (dir:match("^(.*)/[^/]+$") or ""):match("([^/]+)$") or ""
    self:showPlans(dir, plans, T("loose_preview", dir:match("([^/]+)$") or dir, parent), skipped, single, true)
end

--- Reihe hierher holen: Reihe aus der Liste waehlen (alle, die die Bibliothek kennt)
function OrdnerZuReihe:startGather(dir)
    local known = Executor.knownSeries()
    local names = {}
    for _, v in pairs(known) do names[#names + 1] = v end
    if #names == 0 then
        UIManager:show(InfoMessage:new{ text = T("gather_none") })
        return
    end
    table.sort(names, function(a, b) return a.name:lower() < b.name:lower() end)
    local ButtonDialog = require("ui/widget/buttondialog")
    local dialog
    local buttons = {}
    for _, v in ipairs(names) do
        buttons[#buttons + 1] = { {
            text = v.name .. " (" .. v.count .. ")",
            align = "left",
            callback = function()
                UIManager:close(dialog)
                self:previewGather(v.name, dir)
            end,
        } }
    end
    buttons[#buttons + 1] = { { text = T("cancel"), callback = function() UIManager:close(dialog) end } }
    dialog = ButtonDialog:new{ title = T("gather_title", dir:match("([^/]+)$") or dir), buttons = buttons }
    UIManager:show(dialog)
    self.chooser = dialog -- fuer Tests
end

function OrdnerZuReihe:previewGather(series, dir)
    local plan = Executor.planGather(series, dir)
    local target_name = dir:match("([^/]+)$") or dir
    if #plan.moves == 0 then
        local text = T("gather_nothing", series, target_name)
        if #plan.keep > 0 then
            local n = {}
            for _, k in ipairs(plan.keep) do n[#n + 1] = k.name end
            text = text .. T("gather_keep", #plan.keep, table.concat(n, ", "))
        end
        UIManager:show(InfoMessage:new{ text = text })
        self.preview = nil
        return
    end
    local from = {}
    for _, d in ipairs(plan.dirs) do from[#from + 1] = "„" .. (d:match("([^/]+)$") or d) .. "“" end
    local text = T("gather_preview", series, target_name, #plan.moves, table.concat(from, ", "))
    if plan.here > 0 then text = text .. T("gather_here", plan.here) end
    if #plan.keep > 0 then
        local n = {}
        for i, k in ipairs(plan.keep) do if i <= 5 then n[#n + 1] = k.name end end
        text = text .. T("gather_keep", #plan.keep, table.concat(n, ", "))
    end
    text = text .. T("gather_delete")
    local function run()
        local r = Executor.runGather(plan, { is_protected = isProtected })
        self:refreshLibrary(dir)
        local extra = #r.failed > 0 and T("failed", table.concat(r.failed, ", ")) or ""
        UIManager:show(InfoMessage:new{ text = T("gather_done", r.moved, series, target_name, r.deleted, extra) })
        return r
    end
    local box = ConfirmBox:new{ text = text, ok_text = T("gather_start"), ok_callback = run }
    box.run = run -- fuer Tests
    box.plan = plan
    UIManager:show(box)
    self.preview = box -- fuer Tests
end

function OrdnerZuReihe:refreshLibrary(path)
    local fc = self.ui and self.ui.file_chooser
    if fc then
        -- ZenOS merkt sich die Ansicht jedes Ordners (auch ueber Neustarts) und baut sie nur neu, wenn sich
        -- Dateien im Ordner aendern. Eine neue Reihe aendert keine Datei -> gespeicherte Ansicht verwerfen,
        -- so wie ZenOS' eigener Metadaten-Editor es macht (modules/filebrowser/metadata/service.lua).
        if type(fc._zen_clear_item_table_cache) == "function" then
            pcall(fc._zen_clear_item_table_cache, fc)
        end
        pcall(function() fc:changeToPath(path) end)
        pcall(function() fc:refreshPath() end)
    end
    local ok_e, Event = pcall(require, "ui/event")
    if ok_e then UIManager:broadcastEvent(Event:new("BookMetadataChanged")) end
end

function OrdnerZuReihe:closeFileDialog()
    local fm = self.ui
    if fm and fm.file_dialog then UIManager:close(fm.file_dialog) end
end

function OrdnerZuReihe:previewText(plan)
    local lo, hi
    for _, m in ipairs(plan.moves) do
        if m.index then
            lo = (not lo or m.index < lo) and m.index or lo
            hi = (not hi or m.index > hi) and m.index or hi
        end
    end
    local nums = lo and T("numbers", fmtIndex(lo), fmtIndex(hi)) or T("no_numbers")
    local text = T("preview", plan.series, #plan.moves, nums, plan.parent:match("([^/]+)$") or plan.parent)
    if plan.known_count then text = text .. T("known", plan.known_count) end
    if not plan.looks_like_series then text = text .. T("warn_collection") end
    if #plan.keep > 0 then
        local names = {}
        for i, k in ipairs(plan.keep) do
            if i > 3 then names[#names + 1] = "…" break end
            names[#names + 1] = k.name .. " – " .. T("reason_" .. k.reason)
        end
        text = text .. T("keep", #plan.keep, table.concat(names, ", "))
    end
    if plan.delete_folder then
        text = text .. T("delete")
    elseif isProtected(plan.dir) then
        text = text .. T("protected")
    else
        text = text .. T("not_empty")
    end
    return text
end

function OrdnerZuReihe:startFolder(dir, series)
    local plan = Planner.plan(dir, self:planOpts(dir, series))
    if #plan.moves == 0 then
        UIManager:show(InfoMessage:new{ text = T("nothing") })
        return
    end
    -- Gleiche Schreibweise wie eine schon vorhandene Reihe (nicht bei selbst eingegebenem Namen)
    if not series then self:adoptKnown({ plan }) end
    local box
    box = ConfirmBox:new{
        text = self:previewText(plan),
        ok_text = T("start"),
        ok_callback = function() self:execute(plan) end,
        other_buttons_first = true,
        other_buttons = { {
            {
                text = T("rename"),
                callback = function()
                    UIManager:close(box)
                    self:askName(dir, plan.series)
                end,
            },
        } },
    }
    UIManager:show(box)
    self.preview = box -- fuer Tests
end

--- Reihennamen von Hand aendern, danach erneut die Vorschau
function OrdnerZuReihe:askName(dir, current)
    local InputDialog = require("ui/widget/inputdialog")
    local dialog
    dialog = InputDialog:new{
        title = T("rename_title"),
        input = current,
        buttons = { {
            { text = T("cancel"), id = "close", callback = function() UIManager:close(dialog) end },
            {
                text = T("ok"),
                is_enter_default = true,
                callback = function()
                    local name = (dialog:getInputText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    UIManager:close(dialog)
                    if name ~= "" then self:startFolder(dir, name) end
                end,
            },
        } },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function OrdnerZuReihe:execute(plan)
    local result = Executor.run(plan)
    local extra = ""
    if #result.failed > 0 then extra = extra .. T("failed", table.concat(result.failed, ", ")) end
    if result.folder_deleted then extra = extra .. T("deleted") end
    -- Bibliothek neu anzeigen, im Ordner darueber
    local fc = self.ui and self.ui.file_chooser
    if fc then
        pcall(function() fc:changeToPath(plan.parent) end)
        pcall(function() fc:refreshPath() end)
    end
    local ok_e, Event = pcall(require, "ui/event")
    if ok_e then UIManager:broadcastEvent(Event:new("BookMetadataChanged")) end
    UIManager:show(InfoMessage:new{ text = T("done", result.moved, plan.series, extra) })
end

-- Fuer Tests
OrdnerZuReihe.Planner = Planner
OrdnerZuReihe.Executor = Executor

return OrdnerZuReihe
