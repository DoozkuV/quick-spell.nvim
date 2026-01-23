local M = {}

--- Replaces the word at the given position with a new word.
--- @param pos integer[] Position {row, col} of the word to replace
--- @param old_word string The word to replace
--- @param new_word string The replacement text
function M.replace_word_at(pos, old_word, new_word)
    local start_col = pos[2]
    local end_col = start_col + #old_word
    vim.api.nvim_buf_set_text(0, pos[1] - 1, start_col, pos[1] - 1, end_col, { new_word })
end

--- Finds the nearest misspelled word using Vim's built-in spell navigation.
--- @param skip_cursor_word boolean Whether to skip the word at cursor (for insert mode)
--- @return string|nil word The misspelled word, or nil if none found
--- @return integer[]|nil pos The position {row, col} of the misspelled word
local function find_nearest_misspelled(skip_cursor_word)
    local initial_pos = vim.api.nvim_win_get_cursor(0)

    -- Check if current word is misspelled first (skip if requested - word is being typed)
    if not skip_cursor_word then
        local current_word = vim.fn.expand("<cword>")
        if current_word ~= "" and vim.fn.spellbadword(current_word)[1] ~= "" then
            -- Move to start of word to get correct position
            vim.cmd("normal! b")
            local word_start = vim.api.nvim_win_get_cursor(0)
            return current_word, word_start
        end
    end

    -- Use Vim's native spell search - much more reliable than manual iteration
    local saved_ws = vim.o.wrapscan
    vim.o.wrapscan = false

    -- Search backward: [s moves to previous misspelled word
    vim.cmd("silent! normal! [s")
    local back_pos = vim.api.nvim_win_get_cursor(0)
    local back_word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]
    local back_dist = math.huge
    local back_is_cursor_word = back_pos[1] == initial_pos[1] and back_pos[2] == initial_pos[2]
    if back_word ~= "" and not back_is_cursor_word then
        back_dist = math.abs(initial_pos[1] - back_pos[1]) * 1000 + math.abs(initial_pos[2] - back_pos[2])
    elseif back_word ~= "" and not skip_cursor_word then
        -- [s landed on current position, word under cursor is misspelled (only valid if not skipping)
        vim.o.wrapscan = saved_ws
        return back_word, back_pos
    end

    -- Restore and search forward: ]s moves to next misspelled word
    vim.api.nvim_win_set_cursor(0, initial_pos)
    vim.cmd("silent! normal! ]s")
    local front_pos = vim.api.nvim_win_get_cursor(0)
    local front_word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]
    local front_dist = math.huge
    local front_is_cursor_word = front_pos[1] == initial_pos[1] and front_pos[2] == initial_pos[2]
    if front_word ~= "" and not front_is_cursor_word then
        front_dist = math.abs(initial_pos[1] - front_pos[1]) * 1000 + math.abs(initial_pos[2] - front_pos[2])
    end

    vim.o.wrapscan = saved_ws
    vim.api.nvim_win_set_cursor(0, initial_pos)

    -- Return the nearest one (excluding cursor word if skip requested)
    local back_valid = back_word ~= "" and (not skip_cursor_word or not back_is_cursor_word)
    local front_valid = front_word ~= "" and (not skip_cursor_word or not front_is_cursor_word)

    if back_valid and (not front_valid or back_dist <= front_dist) then
        return back_word, back_pos
    elseif front_valid then
        return front_word, front_pos
    end

    return nil, nil
end

--- Corrects the nearest misspelled word using vim.ui.select.
--- @param opts? { skip_cursor_word?: boolean } Options table
---   - skip_cursor_word: Skip the word at cursor (useful when called from insert mode)
function M.correct_word(opts)
    opts = opts or {}

    if not vim.wo.spell then
        vim.notify("Spelling is not enabled in this buffer", vim.log.levels.WARN)
        return
    end

    local initial_pos = vim.api.nvim_win_get_cursor(0)
    local misspelled_word, word_pos = find_nearest_misspelled(opts.skip_cursor_word)

    if not misspelled_word or not word_pos then
        vim.notify("No misspelled words found", vim.log.levels.INFO)
        return
    end

    local suggestions = vim.fn.spellsuggest(misspelled_word, 10)
    if #suggestions == 0 then
        vim.notify("No suggestions for: " .. misspelled_word, vim.log.levels.WARN)
        return
    end

    -- Build choices list
    local choices = { "Mark as correct" }
    vim.list_extend(choices, suggestions)

    vim.ui.select(choices, {
        prompt = "Correct '" .. misspelled_word .. "':",
    }, function(choice, idx)
        if not choice then return end

        if idx == 1 then
            vim.api.nvim_win_set_cursor(0, word_pos)
            vim.cmd("spellgood " .. vim.fn.fnameescape(misspelled_word))
            vim.notify("Added '" .. misspelled_word .. "' to spell file", vim.log.levels.INFO)
        else
            M.replace_word_at(word_pos, misspelled_word, suggestions[idx - 1])
        end

        vim.api.nvim_win_set_cursor(0, initial_pos)
    end)
end

return M
