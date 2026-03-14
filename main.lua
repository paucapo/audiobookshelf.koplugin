local AudiobookshelfBrowser = require("audiobookshelf/audiobookshelfbrowser")
local AudiobookshelfSync = require("audiobookshelf/audiobookshelfsync")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Audiobookshelf = WidgetContainer:extend{
    name = "audiobookshelf",
    is_doc_only = false,
}

function Audiobookshelf:onDispatcherRegisterActions()
    -- none atm
end

function Audiobookshelf:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
    self.push_task = function()
        AudiobookshelfSync:push(self.ui)
    end
end

function Audiobookshelf:onReaderReady()
    AudiobookshelfSync:pull(self.ui)
end

function Audiobookshelf:onPageUpdate()
    AudiobookshelfSync:schedulePush(self)
end

function Audiobookshelf:onSuspend()
    AudiobookshelfSync:cancelSchedule(self)
    AudiobookshelfSync:push(self.ui)
end

function Audiobookshelf:onCloseDocument()
    AudiobookshelfSync:cancelSchedule(self)
    AudiobookshelfSync:push(self.ui)
end

function Audiobookshelf:onCloseWidget()
    AudiobookshelfSync:cancelSchedule(self)
end

function Audiobookshelf:addToMainMenu(menu_items)
    menu_items.audiobookshelf = {
        text = _("Audiobookshelf"),
        sorting_hint = "tools",
        callback = function()
            UIManager:show(AudiobookshelfBrowser:new())
        end
    }
end

return Audiobookshelf
