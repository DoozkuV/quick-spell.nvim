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
    return math.abs(initial_pos[1] - pos[1]) * 1000 -- Weigh rows more heavily
        + math.abs(initial_pos[2] - pos[2])
end

---Check if cursor position falls within a word's bounds (includes position after word for insert mode)
---@param cursor_pos integer[]
---@param word_pos integer[]
---@param word_len integer
---@return boolean
local function cursor_is_in_word(cursor_pos, word_pos, word_len)
    return cursor_pos[1] == word_pos[1]
        and cursor_pos[2] >= word_pos[2]
        and cursor_pos[2] <= word_pos[2] + word_len
end

---Check if cursor is on a misspelled word
---@return SpellMatch?
local function get_misspelled_at_cursor()
    local word = vim.fn.expand("<cword>")
    if word == "" or vim.fn.spellbadword(word)[1] == "" then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()

    -- Find word start (convert to 1-indexed for string ops, then back to 0-indexed)
    local start = cursor[2] + 1
    while start > 1 and line:sub(start - 1, start - 1):match("[%w']") do
        start = start - 1
    end

    return { word = word, pos = { cursor[1], start - 1 } }
end

---Search in a direction and return match with distance
---@param initial_pos integer[]
---@param forward boolean
---@return SpellMatch?
local function search_direction(initial_pos, forward)
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

---Search in a direction, optionally skipping cursor word
---@param initial_pos integer[]
---@param forward boolean
---@param skip_cursor_word boolean
---@return SpellMatch?
local function search_skip_cursor(initial_pos, forward, skip_cursor_word)
    local result = search_direction(initial_pos, forward)

    if skip_cursor_word and result and cursor_is_in_word(initial_pos, result.pos, #result.word) then
        vim.api.nvim_win_set_cursor(0, result.pos)
        result = search_direction(initial_pos, forward)
        if result and cursor_is_in_word(initial_pos, result.pos, #result.word) then
            return nil
        end
    end

    return result
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
    local back = search_skip_cursor(initial_pos, false, skip_cursor_word)
    vim.api.nvim_win_set_cursor(0, initial_pos)
    local fwd = search_skip_cursor(initial_pos, true, skip_cursor_word)

    -- Cleanup
    vim.o.wrapscan = saved_ws
    vim.api.nvim_win_set_cursor(0, initial_pos)

    -- Return nearest
    if not back then return fwd end
    if not fwd then return back end
    return back.dist <= fwd.dist and back or fwd
end

return M
