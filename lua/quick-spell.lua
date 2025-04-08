--- Checks for misspelled words in a given direction and updates the cursor position.
--- @param command string Movement command ("b" for backward, "w" for forward). Must be a valid `normal!` command.
--- @param pos integer[] Current cursor position as `{row, col}` (1-indexed). This table is mutated in-place.
--- @return string|nil # The misspelled word if found, otherwise `nil`.
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

--- Searches for misspelled words in both directions (backward/forward) within a limit.
--- @param max_iterations integer Maximum number of words to check in each direction.
--- @return string|nil # The first misspelled word found, or `nil` if none are detected.
local function find_misspelled_word(max_iterations)
    local back_pos                  = vim.api.nvim_win_get_cursor(0)
    local front_pos                 = vim.api.nvim_win_get_cursor(0)
    local line_count                = vim.api.nvim_buf_line_count(0)
    local back_active, front_active = true, true

    -- Checks the word in the specified direction.
    -- Returns if a misspelled word is found
    local bad_word
    for _ = 1, max_iterations do
        if back_active then
            local ok, result = pcall(check_direction, "b", back_pos)
            if not ok then
                back_active = false
            elseif result then
                return result
            end
        end


        if front_active then
            local ok, result = pcall(check_direction, "w", front_pos)
            if not ok then
                front_active = false
            elseif result then
                return result
            end
        end

        if not back_active and not front_active then
            break
        end
    end

    return nil
end

-- Finds the closest misspelled word and corrects it
local function correct_word()
    if not vim.wo.spell then
        vim.notify("Spelling is not enabled in this buffer!", vim.log.levels.WARN)
        return
    end

    local initial_pos = vim.api.nvim_win_get_cursor(0)

    local misspelled_word = find_misspelled_word(1000)
    if not misspelled_word then
        vim.notify("No misspelled words found", vim.log.levels.INFO)
        vim.api.nvim_win_set_cursor(0, initial_pos)
        return
    end

    local suggestions = vim.fn.spellsuggest(misspelled_word)
    if #suggestions == 0 then
        vim.notify("No suggestions found for: " .. misspelled_word, vim.log.levels.WARN)
        vim.api.nvim_win_set_cursor(0, initial_pos)
        return
    end

    local choices = { "0: Mark Word as Good" }
    for i, suggestion in ipairs(suggestions) do
        table.insert(choices, i .. ": " .. suggestion)
    end

    -- local choice = vim.fn.inputlist(prompt)
    vim.ui.select(choices, {
        prompt = "Choose a correction for: " .. misspelled_word,
    }, function(selection)
        if not selection then
            vim.api.nvim_win_set_cursor(0, initial_pos)
            return
        end

        selection = tonumber(selection:match("^(%d+):"))
        if selection == 0 then
            vim.cmd('spellgood ' .. misspelled_word)
        else
            vim.cmd('normal! ciw' .. suggestions[selection])
        end
        vim.api.nvim_win_set_cursor(0, initial_pos)
    end)
end

return {
    correct_word = correct_word
}
