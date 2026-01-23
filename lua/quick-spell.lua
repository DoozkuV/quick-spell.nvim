local M = {}

--- Finds the nearest misspelled word using Vim's built-in spell navigation.
--- @return string|nil word The misspelled word, or nil if none found
--- @return integer[]|nil pos The position {row, col} of the misspelled word
local function find_nearest_misspelled()
    local initial_pos = vim.api.nvim_win_get_cursor(0)

    -- Check if current word is misspelled first
    local current_word = vim.fn.expand("<cword>")
    if current_word ~= "" and vim.fn.spellbadword(current_word)[1] ~= "" then
        return current_word, initial_pos
    end

    -- Use Vim's native spell search - much more reliable than manual iteration
    local saved_ws = vim.o.wrapscan
    vim.o.wrapscan = false

    -- Search backward: [s moves to previous misspelled word
    vim.cmd("silent! normal! [s")
    local back_pos = vim.api.nvim_win_get_cursor(0)
    local back_word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]
    local back_dist = math.huge
    if back_word ~= "" and (back_pos[1] ~= initial_pos[1] or back_pos[2] ~= initial_pos[2]) then
        back_dist = math.abs(initial_pos[1] - back_pos[1]) * 1000 + math.abs(initial_pos[2] - back_pos[2])
    elseif back_word ~= "" then
        -- [s landed on current position, word under cursor is misspelled
        vim.o.wrapscan = saved_ws
        return back_word, back_pos
    end

    -- Restore and search forward: ]s moves to next misspelled word
    vim.api.nvim_win_set_cursor(0, initial_pos)
    vim.cmd("silent! normal! ]s")
    local front_pos = vim.api.nvim_win_get_cursor(0)
    local front_word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]
    local front_dist = math.huge
    if front_word ~= "" and (front_pos[1] ~= initial_pos[1] or front_pos[2] ~= initial_pos[2]) then
        front_dist = math.abs(initial_pos[1] - front_pos[1]) * 1000 + math.abs(initial_pos[2] - front_pos[2])
    end

    vim.o.wrapscan = saved_ws
    vim.api.nvim_win_set_cursor(0, initial_pos)

    -- Return the nearest one
    if back_word ~= "" and (front_word == "" or back_dist <= front_dist) then
        return back_word, back_pos
    elseif front_word ~= "" then
        return front_word, front_pos
    end

    return nil, nil
end

--- Corrects the nearest misspelled word using vim.ui.select.
function M.correct_word()
    if not vim.wo.spell then
        vim.notify("Spelling is not enabled in this buffer", vim.log.levels.WARN)
        return
    end

    local initial_pos = vim.api.nvim_win_get_cursor(0)
    local misspelled_word, word_pos = find_nearest_misspelled()

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

        vim.api.nvim_win_set_cursor(0, word_pos)

        if idx == 1 then
            vim.cmd("spellgood " .. vim.fn.fnameescape(misspelled_word))
            vim.notify("Added '" .. misspelled_word .. "' to spell file", vim.log.levels.INFO)
        else
            -- Safe replacement using register to avoid command injection
            local saved_reg = vim.fn.getreg('"')
            local saved_regtype = vim.fn.getregtype('"')
            vim.fn.setreg('"', suggestions[idx - 1])
            vim.cmd('normal! "_ciw""P')
            vim.fn.setreg('"', saved_reg, saved_regtype)
        end

        vim.api.nvim_win_set_cursor(0, initial_pos)
    end)
end

return M
