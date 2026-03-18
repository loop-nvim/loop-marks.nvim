local bookmarks = require('loop-marks.bookmarks')
local notes = require('loop-marks.notes')

local _init_done = false
---@type loop.Extension
local extension =
{
    on_workspace_load = function(ext_api)
        if not _init_done then
            _init_done = true
            require('loop-marks.bookmarks').init()
            require('loop-marks.notes').init()
        end
        local state = ext_api.get_storage()
        bookmarks.set_bookmarks(state.get("marks") or {})
        notes.set_notes(state.get("notes") or {})
        ext_api.register_user_command("mark", require("loop-marks.bookmarks_cmd").get_cmd_provider(ext_api))
        ext_api.register_user_command("note", require("loop-marks.notes_cmd").get_cmd_provider(ext_api))
    end,
    on_workspace_unload = function(_)
        bookmarks.clear_all_bookmarks()
        notes.clear_all_notes()
    end,
    on_state_will_save = function(ext_api)
        local state = ext_api.get_storage()
        state.set("marks", bookmarks.get_bookmarks())
        state.set("notes", notes.get_notes())
    end,
}
return extension
