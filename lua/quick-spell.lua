local function find_misspelled_word(max_iterations)
    local back_pos = vim.api.nvim_win_get_cursor(0)
    local front_pos = vim.api.nvim_win_get_cursor(0)

    -- Checks the the word in the specified direction.
    -- Returns if a misspelled word is found
    local function check_direction(command, pos)
        vim.api.nvim_win_set_cursor(0, pos)

        local bad_word = vim.fn.spellbadword(vim.fn.expand("<cword>"))[1]
        if bad_word ~= '' then return bad_word end

        vim.cmd("normal! " .. command)
        local new_pos = vim.api.nvim_win_get_cursor(0)
        -- Tables are passed by reference; do this to assign the new table
        pos[1], pos[2] = new_pos[1], new_pos[2]

        return nil
    end

    local bad_word
    for _ = 1, max_iterations do
        -- Check back
        bad_word = check_direction("b", back_pos)
        if bad_word then return bad_word end
        print("{" .. back_pos[1] .. "," .. back_pos[2] .. "}")

        -- Check front
        bad_word = check_direction("w", front_pos)
        if bad_word then return bad_word end
        print("{" .. front_pos[1] .. "," .. front_pos[2] .. "}")
    end

    return nil
end

-- Finds the closest misspelled word and corrects it
--
local function correct_word()
    -- code containing all the main logic of the program
    local function main_logic()
        local misspelled_word = find_misspelled_word(1000)
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

    if not vim.wo.spell then error("Spelling is not enabled!") end

    -- Wrap the logic so that the cursor position is always reset
    local initial_pos = vim.api.nvim_win_get_cursor(0)
    main_logic()
    vim.api.nvim_win_set_cursor(0, initial_pos)
end

return {
    correct_word = correct_word
}
