---@class QuickSpellConfig
---@field max_suggestions? integer Max suggestions (default: 10)
---@field skip_cursor_word_modes? string[] Modes to skip cursor word (default: {"i", "R"})
---@field notify? boolean Show notifications (default: true)

local M = {}

M.defaults = {
    max_suggestions = 10,
    skip_cursor_word_modes = { "i", "R" },
    notify = true,
}

M.options = vim.deepcopy(M.defaults)

---@param opts? QuickSpellConfig
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
