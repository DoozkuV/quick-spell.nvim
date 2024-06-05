local function find_next_misspelled_word()
    local current_line = vim.fn.line('.')
    local last_line = vim.fn.line('w0')
    for line = current_line, last_line do
        vim.fn.cursor(line, 1)
        local col = vim.fn.search('\\<\\k\\+\\>', 'n')
        if col ~= 0 and vim.fn.spellbadword() ~= '' then
            return true
        end
    end
    return false
end

-- Func to be exported
local function find_and_fix_next_misspelled_word()
    -- Save cursor position
    local initial_pos = vim.api.nvim_win_get_cursor(0)

    if not find_next_misspelled_word() then
        print("No more misspelled words found")
        return
    end

    -- Run the spell checker command `z=`
    vim.fn.spellsuggest()
    -- Create an autocmd group to return to the initial position
    vim.cmd([[
    augroup ReturnToInitialPosition
        autocmd!
        autocmd CmdlineLeave : ++once lua vim.api.nvim_win_get_cursor(0, { ]] ..
        initial_pos[1] .. ", " .. initial_pos[2] .. [[ })
    augroup END]])
end


return { find_and_fix_next_misspelled_word = find_and_fix_next_misspelled_word }
