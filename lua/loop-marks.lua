-- IMPORTANT: keep this module light for lazy loading

local M = {}

---@class loop-marks.Config
---@field stack_levels_limit? number
---@field mark_sign_priority? number
---@field note_sign_priority? number
---@field mark_symbol? string
---@field note_symbol? string

local function _get_default_config()
    ---@type loop-marks.Config
    return {
        mark_sign_priority = 50,
        note_sign_priority = 50,
        mark_symbol = "*",
        note_symbol = "✎",
    }
end

---@type loop-marks.Config
M.config = _get_default_config()

-----------------------------------------------------------
-- Setup (user config)
-----------------------------------------------------------

---@param opts loop-marks.Config?
function M.setup(opts)
    if vim.fn.has("nvim-0.10") ~= 1 then
        error("loop.nvim requires Neovim >= 0.10")
    end

    M.config = vim.tbl_deep_extend("force", _get_default_config(), opts or {})
end

return M
