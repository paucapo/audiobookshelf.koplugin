local AudiobookshelfApi = require("audiobookshelf/audiobookshelfapi")
local Event = require("ui/event")
local LuaSettings = require("luasettings")
local Math = require("optmath")
local UIManager = require("ui/uimanager")
local logger = require("logger")

local PUSH_DELAY = 4

local AudiobookshelfSync = {}

function AudiobookshelfSync:getBookMapFile()
    return string.gsub(debug.getinfo(1).source, "^@(.+/)[^/]+$", "%1") .. "/../audiobookshelf_book_map.lua"
end

function AudiobookshelfSync:getBookId(ui)
    if not ui.document then return nil end
    local filepath = ui.document.file
    if not filepath then return nil end
    local book_map = LuaSettings:open(self:getBookMapFile()):readSetting("book_map") or {}
    return book_map[filepath]
end

function AudiobookshelfSync:getPercent(ui)
    if ui.document.info.has_pages then
        return Math.roundPercent(ui.paging:getLastPercent())
    else
        return Math.roundPercent(ui.rolling:getLastPercent())
    end
end

function AudiobookshelfSync:push(ui)
    local book_id = self:getBookId(ui)
    if not book_id then return end

    local ok, err = pcall(function()
        local percent = self:getPercent(ui)
        AudiobookshelfApi:updateProgress(book_id, {
            progress = percent,
            ebookProgress = percent,
            isFinished = percent >= 0.99,
        })
        logger.dbg("Audiobookshelf: pushed", percent * 100, "%")
    end)
    if not ok then
        logger.warn("Audiobookshelf: push failed:", err)
    end
end

function AudiobookshelfSync:pull(ui)
    local book_id = self:getBookId(ui)
    if not book_id then return end

    local ok, err = pcall(function()
        local progress = AudiobookshelfApi:getProgress(book_id)
        if progress and progress.ebookProgress and progress.ebookProgress > 0 then
            if math.abs(progress.ebookProgress - self:getPercent(ui)) > 0.005 then
                ui:handleEvent(Event:new("GotoPercent", progress.ebookProgress * 100))
                logger.dbg("Audiobookshelf: synced to", progress.ebookProgress * 100, "%")
            end
        end
    end)
    if not ok then
        logger.warn("Audiobookshelf: pull failed:", err)
    end
end

function AudiobookshelfSync:schedulePush(plugin)
    UIManager:unschedule(plugin.push_task)
    UIManager:scheduleIn(PUSH_DELAY, plugin.push_task)
end

function AudiobookshelfSync:cancelSchedule(plugin)
    UIManager:unschedule(plugin.push_task)
end

function AudiobookshelfSync:saveBookMapping(filepath, book_id)
    local settings = LuaSettings:open(self:getBookMapFile())
    local book_map = settings:readSetting("book_map") or {}
    book_map[filepath] = book_id
    settings:saveSetting("book_map", book_map)
    settings:flush()
end

return AudiobookshelfSync
