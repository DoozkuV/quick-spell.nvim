local M = {}

---@class SpellMatch
---@field word string
---@field pos integer[] {row, col}
---@field dist? number

---Calculate distance from initial position (rows weighted more heavily)
---@param pos integer[]
---@param initial_pos integer[]
---@return number
local function calc_distance(pos, initial_pos)
    -- TODO: Consider a better algorithm for this - why do we need to approximate?
    return math.abs(initial_pos[1] - pos[1]) * 1000 + math.abs(initial_pos[2] - pos[2])
end

---Check if cursor position falls within a word's bounds
---@param cursor_pos integer[]
---@param word_pos integer[]
---@param word_len integer
---@return boolean
local function cursor_is_in_word(cursor_pos, word_pos, word_len)
    if cursor_pos[1] ~= word_pos[1] then return false end
    return cursor_pos[2] >= word_pos[2] and cursor_pos[2] < word_pos[2] + word_len
end

---Check if cursor is on a misspelled word
---@return SpellMatch?
local function get_misspelled_at_cursor()
    local word = vim.fn.expand("<cword>")
    if word == "" or vim.fn.spellbadword(word)[1] == "" then
        return nil
    end

    local initial_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! b")
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, initial_pos)

    return { word = word, pos = pos }
end

---Search in a direction and return match with distance
---@param forward boolean search forward?
---@param initial_pos integer[]
---@return SpellMatch?
local function search_direction(forward, initial_pos)
    -- TODO: Refactor the params for this function - forward should probably be a kwarg
    local cmd = forward and "]s" or "[s"
    vim.cmd("silent! normal! " .. cmd)
    local pos = vim.api.nvim_win_get_cursor(0)
    local word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]

    if word == "" then
        return nil
    end

    return {
        word = word,
        pos = pos,
        dist = calc_distance(pos, initial_pos),
    }
end

---@param skip_cursor_word boolean
---@return SpellMatch?
function M.find_nearest(skip_cursor_word)
    local initial_pos = vim.api.nvim_win_get_cursor(0)
    local saved_ws = vim.o.wrapscan
    vim.o.wrapscan = false

    -- Cursor word is guaranteed closest if misspelled
    if not skip_cursor_word then
        local match = get_misspelled_at_cursor()
        if match then
            vim.o.wrapscan = saved_ws
            return match
        end
    end

    -- Search both directions
    local back = search_direction(false, initial_pos)
    vim.api.nvim_win_set_cursor(0, initial_pos)
    local fwd = search_direction(true, initial_pos)

    -- Cleanup
    vim.o.wrapscan = saved_ws
    vim.api.nvim_win_set_cursor(0, initial_pos)

    -- Filter out cursor word when skipping
    if skip_cursor_word then
        if back and cursor_is_in_word(initial_pos, back.pos, #back.word) then back = nil end
        if fwd and cursor_is_in_word(initial_pos, fwd.pos, #fwd.word) then fwd = nil end
    end

    -- Direct comparison
    if not back then return fwd end
    if not fwd then return back end
    return back.dist <= fwd.dist and back or fwd
end

return M
