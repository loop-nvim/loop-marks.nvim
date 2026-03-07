local M                   = {}
local uitools             = require("loop.tools.uitools")
local floatwin            = require("loop.tools.floatwin")
local config              = require('loop-marks').config
local loopsigns           = require('loop.signs')
local selector            = require("loop.tools.selector")

---@class loopmarks.BookmarkDetails
---@field file string
---@field lnum integer
---@field text string

local _init_done          = false

---@type loop.signs.Group
local _sign_group

local _bookmark_sign_name = "bookmark"

local function _norm(file)
    if not file or file == "" then return file end
    return vim.fn.fnamemodify(file, ":p")
end

--- Add a new bookmark.
---@param file string
---@param lnum integer
---@param text string
local function _set_source_bookmark(file, lnum, text)
    file = _norm(file)
    _sign_group.set_file_sign(
        math.random(1, 2 ^ 31), -- unique id
        file,
        lnum,
        _bookmark_sign_name,
        { text = text }
    )
end

---@param bookmarks loopmarks.BookmarkDetails[]
local function _set_bookmarks(bookmarks)
    _sign_group.remove_signs()
    table.sort(bookmarks, function(a, b)
        if a.file ~= b.file then return a.file < b.file end
        return (a.lnum or 0) < (b.lnum or 0)
    end)
    for _, bm in ipairs(bookmarks) do
        _set_source_bookmark(bm.file, bm.lnum, bm.text)
    end
end

---@param file string
---@param lnum integer
local function _remove_bookmark(file, lnum)
    local info = _sign_group.get_sign_by_location(file, lnum, false)
    if info then
        _sign_group.remove_file_sign(info.id)
    end
end

-------- PUBLIC API --------

---@param file string
---@param lnum number
---@param message string
function M.set_bookmark(file, lnum, message)
    if type(message) ~= "string" or message == "" then return end
    file = _norm(file)
    _remove_bookmark(file, lnum)
    _set_source_bookmark(file, lnum, message)
end

---@param file string
---@param lnum number
---@return string? message
local function _get_bookmark(file, lnum)
    file = _norm(file)
    for _, s in ipairs(_sign_group.get_signs(false)) do
        if s.file == file and s.lnum == lnum then
            return s.user_data.text
        end
    end
end

---@param file string
function M.clear_file_bookmarks(file)
    file = _norm(file)
    _sign_group.remove_file_signs(file)
end

function M.clear_all_bookmarks()
    _sign_group.remove_signs()
end

---@return loopmarks.BookmarkDetails[]
function M.get_bookmarks()
    local result = {}
    for _, s in ipairs(_sign_group.get_signs(true)) do
        table.insert(result, {
            file = s.file,
            lnum = s.lnum,
            text = s.user_data.text,
        })
    end
    return result
end

---@param bookmarks loopmarks.BookmarkDetails[]
function M.set_bookmarks(bookmarks)
    _set_bookmarks(bookmarks)
end

---@param command nil | "set" | "delete" | "clear_file" | "clear_all"
---@param ws_dir string
function M.bookmarks_command(command, ws_dir)
    command = command and command:match("^%s*(.-)%s*$") or ""
    if command == "" or command == "set" then
        local file, lnum = uitools.get_current_file_and_line()
        if file and lnum then
            local bookmark = _get_bookmark(file, lnum)
            floatwin.input_at_cursor({ prompt = "Name", default_text = bookmark }, function(message)
                if message and message ~= "" then
                    M.set_bookmark(file, lnum, message)
                end
            end)
        end
    elseif command == "delete" then
        local file, lnum = uitools.get_current_file_and_line()
        if file and lnum then
            _remove_bookmark(file, lnum)
        end
    elseif command == "clear_file" then
        local buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(buf) then
            local full_path = vim.api.nvim_buf_get_name(buf)
            uitools.confirm_action("Clear bookmarks in file", false, function(accepted)
                if accepted then
                    M.clear_file_bookmarks(full_path)
                end
            end)
        end
    elseif command == "clear_all" then
        uitools.confirm_action("Clear all bookmarks", false, function(accepted)
            if accepted then
                M.clear_all_bookmarks()
            end
        end)
    else
        vim.notify('Invalid bookmarks subcommand: ' .. tostring(command))
    end
end

---@param wsdir string
function M.select_bookmark(wsdir)
    local details_list = M.get_bookmarks()
    if #details_list == 0 then
        vim.notify('No bookmarks set')
        return
    end

    table.sort(details_list, function(a, b)
        if a.file ~= b.file then return a.file < b.file end
        return (a.lnum or 0) < (b.lnum or 0)
    end)

    local function format_path(details)
        local file = details.file
        if wsdir then
            file = vim.fs.relpath(wsdir, file) or file
        end
        local parts = {}
        table.insert(parts, file)
        table.insert(parts, ":")
        table.insert(parts, tostring(details.lnum))
        return table.concat(parts, '')
    end

    local cur_file, cur_lnum = uitools.get_current_file_and_line()

    local initial
    local choices = {}
    for _, details in ipairs(details_list) do
        table.insert(choices, {
            label      = details.text:gsub("\n", " "),
            virt_lines = { { { format_path(details), "Comment" } } },
            file       = details.file,
            lnum       = details.lnum,
            data       = details,
        })
        if not initial and cur_file == details.file and cur_lnum == details.lnum then
            initial = #choices
        end
    end

    selector.select({
            prompt = "Bookmarks",
            items = choices,
            file_preview = true,
            initial = initial,
        },
        function(selected)
            if selected and selected.file then
                uitools.smart_open_file(selected.file, selected.lnum)
            end
        end
    )
end

function M.init()
    if _init_done then return end
    _init_done = true
    assert(not _sign_group)

    local hl = "LoopmarksBookmarksSign"
    vim.api.nvim_set_hl(0, hl, { link = "Directory" })

    _sign_group = loopsigns.define_group("bookmarks", { priority = config.mark_sign_priority })
    _sign_group.define_sign(_bookmark_sign_name, config.mark_symbol, hl)
end

return M
