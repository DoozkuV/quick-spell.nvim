local M = {}

---@param pos integer[]
---@param old_word string
---@param new_word string
function M.replace_word(pos, old_word, new_word)
    vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2], pos[1] - 1, pos[2] + #old_word, { new_word })
end

return M
