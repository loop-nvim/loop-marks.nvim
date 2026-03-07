local M             = {}
local uitools       = require("loop.tools.uitools")
local floatwin      = require("loop.tools.floatwin")
local config        = require('loop-marks').config
local extmarks      = require('loop.extmarks')
local selector      = require("loop.tools.selector")

---@class loopmarks.NoteDetails
---@field file string File path
---@field lnum integer Line number
---@field text string

---@class loopmarks.NoteData
---@field text string

local _init_done    = false

local _last_note_id = 1000

---@type loop.extmarks.GroupFunctions
local _extmarks_group

local function _norm(file)
    if not file or file == "" then return file end
    return vim.fn.fnamemodify(file, ":p")
end

--- Add a new note.
---@param file string File path
---@param lnum integer Line number
---@param text string Optional text
---@return boolean added
local function _set_source_note(file, lnum, text)
    local id = _last_note_id + 1
    _last_note_id = id
    ---@type loopmarks.NoteData
    local note = {
        text = text
    }
    text = (" %s %s"):format(config.note_symbol, text or "Note")
    _extmarks_group.set_file_extmark(id, file, lnum, 0, {
            virt_text     = { { text, "Todo" } },
            virt_text_pos = "eol",
            hl_mode       = "combine",
        },
        note)
    return true
end

---@param notes loopmarks.NoteDetails[]
local function _set_notes(notes)
    _extmarks_group.remove_extmarks()
    table.sort(notes, function(a, b)
        if a.file ~= b.file then return tostring(a.file) < tostring(b.file) end
        return (a.lnum or 0) < (b.lnum or 0)
    end)
    for _, nd in ipairs(notes) do
        local file = vim.fn.fnamemodify(nd.file, ":p")
        _set_source_note(file,
            nd.lnum,
            nd.text
        )
    end
    return true, nil
end

---@param file string File path
---@param lnum integer Line number
local function _remove_note(file, lnum)
    local info = _extmarks_group.get_extmark_by_location(file, lnum, false)
    if not info then return end
    _extmarks_group.remove_extmark(info.id)
end

-------- PUBLIC API --------

---@param file string
---@param lnum number
---@param message string
function M.set_note(file, lnum, message)
    if type(message) == "string" and #message > 0 then
        file = _norm(file)
        local info = _extmarks_group.get_extmark_by_location(file, lnum, false)
        if info then
            _extmarks_group.remove_extmark(info.id)
        end
        _set_source_note(file, lnum, message)
    end
end

---@param file string
---@param lnum number
---@return string? mesage
local function _get_note(file, lnum)
    local info = _extmarks_group.get_extmark_by_location(file, lnum, false)
    if not info then return end
    return info.user_data.text
end

---@param file string
function M.clear_file_notes(file)
    _extmarks_group.remove_file_extmarks(file)
end

--- clear all notes.
function M.clear_all_notes()
    _extmarks_group.remove_extmarks()
end

---@return loopmarks.NoteDetails[]
function M.get_notes()
    ---@type loopmarks.NoteDetails[]
    local details = {}
    local marks_info = _extmarks_group.get_extmarks(true)
    if marks_info then
        for _, info in ipairs(marks_info) do
            table.insert(details,
                {
                    file = info.file,
                    lnum = info.lnum,
                    text = info.user_data.text
                })
        end
    end
    return details
end

---@param notes loopmarks.NoteDetails[]
function M.set_notes(notes)
    _set_notes(notes)
end

---@param command nil
---| "set"
---| "text"
---| "delete"
---| "clear_file"
---| "clear_all"
---@param ws_dir string
function M.notes_command(command, ws_dir)
    assert(type(ws_dir) == "string")
    command = command and command:match("^%s*(.-)%s*$") or ""
    if command == "" or command == "set" then
        local file, lnum = uitools.get_current_file_and_line()
        if file and lnum then
            local note = _get_note(file, lnum)
            floatwin.input_at_cursor({ prompt = "Note", default_text = note }, function(message)
                if message and message ~= "" then
                    M.set_note(file, lnum, message)
                end
            end)
        end
    elseif command == "delete" then
        local file, lnum = uitools.get_current_file_and_line()
        if file and lnum then
            _remove_note(file, lnum)
        end
    elseif command == "clear_file" then
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(bufnr) then
            local full_path = vim.api.nvim_buf_get_name(bufnr)
            if full_path and full_path ~= "" then
                uitools.confirm_action("Clear notes in file", false, function(accepted)
                    if accepted == true then
                        M.clear_file_notes(full_path)
                    end
                end)
            end
        end
    elseif command == "clear_all" then
        uitools.confirm_action("Clear all notes", false, function(accepted)
            if accepted == true then
                M.clear_all_notes()
            end
        end)
    else
        vim.notify('Invalid notes subcommand: ' .. tostring(command))
    end
end

---@param wsdir string
function M.select_note(wsdir)
    ---@param details loopmarks.NoteDetails
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

    local details_list = M.get_notes()
    if #details_list == 0 then
        vim.notify('No notes set')
        return
    end

    table.sort(details_list, function(a, b)
        if a.file ~= b.file then return tostring(a.file) < tostring(b.file) end
        return (a.lnum or 0) < (b.lnum or 0)
    end)

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
            prompt = "Notes",
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

    _extmarks_group = extmarks.define_group("Notes", { priority = config.note_sign_priority })
    -- Highlight group (feel free to change link or define your own)
    local hl = "LoopMarksNote"
    vim.api.nvim_set_hl(0, hl, { link = "Todo" }) -- or "Special", "WarningMsg", etc.
end

return M
