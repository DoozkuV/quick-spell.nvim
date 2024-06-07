local function find_next_misspelled_word()
    local current_line = vim.fn.line('.')
    local last_line = vim.fn.line('$')
    for line = current_line, last_line do
        vim.fn.cursor(line, 1)
        local col = vim.fn.search('\\<\\k\\+\\>', 'n')
        if col ~= 0 then
            local bad_word = vim.fn.spellbadword()[1]
            if bad_word ~= '' then
                return bad_word
            end
        end
    end
    return nil
end

local function correct_word_helper()
    local misspelled_word = find_next_misspelled_word()
    if not misspelled_word then
        print("No misspelled words found")
        return
    end

    local suggestions = vim.fn.spellsuggest(misspelled_word)
    if #suggestions == 0 then
        print("No suggestions found for: " .. misspelled_word)
        return
    end

    local prompt = {
        "Choose a correction for: " .. misspelled_word,
        "Mark Word as Good: 0",
    }
    for i, suggestion in ipairs(suggestions) do
        table.insert(prompt, i .. ": " .. suggestion)
    end

    local choice = vim.fn.inputlist(prompt)
    if choice < 0 or choice > #suggestions then
        print("No valid choice made")
    elseif choice == 0 then
        vim.cmd('spellgood ' .. misspelled_word)
    else
        -- Replace the misspelled word with the chosen suggestion
        vim.cmd('normal! ciw' .. suggestions[choice])
    end
end

-- Func to be exported
-- Effectively acts as a wrapper func around the helper that returns
-- the cursor back to it's original position regardless of the outcome
local function correct_word()
    -- Save cursor position
    local initial_pos = vim.api.nvim_win_get_cursor(0)
    correct_word_helper()
    vim.api.nvim_win_set_cursor(0, initial_pos)
end


return { correct_word = correct_word }
