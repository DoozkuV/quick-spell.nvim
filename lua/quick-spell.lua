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
    local back_pos = vim.api.nvim_win_get_cursor(0)
    local front_pos = vim.api.nvim_win_get_cursor(0)

    -- Checks the word in the specified direction.
    -- Returns if a misspelled word is found
    local bad_word
    for _ = 1, max_iterations do
        -- Check back
        bad_word = check_direction("b", back_pos)
        if bad_word then return bad_word end

        -- Check front
        bad_word = check_direction("w", front_pos)
        if bad_word then return bad_word end
    end

    return nil
end

local function correct_word()
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
        "Cancel: 0",
        "Mark Word as Good: 1",
    }
    for i, suggestion in ipairs(suggestions) do
        table.insert(prompt, i + 1 .. ": " .. suggestion)
    end

    local choice = vim.fn.inputlist(prompt)
    if choice == 1 then
        vim.cmd('spellgood ' .. misspelled_word)
    elseif choice > 1 and choice < #suggestions then
        vim.cmd('normal! ciw' .. suggestions[choice - 1])
    end
end
-- Finds the closest misspelled word and corrects it
--
local function main()
    if not vim.wo.spell then error("Spelling is not enabled!") end
    -- Wrap the logic so that the cursor position is always reset
    local initial_pos = vim.api.nvim_win_get_cursor(0)
    correct_word()
    vim.api.nvim_win_set_cursor(0, initial_pos)
end

return {
    correct_word = main
}
