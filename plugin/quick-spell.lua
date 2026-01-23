if vim.g.loaded_quick_spell then return end
vim.g.loaded_quick_spell = true

local function create_command(buf)
    pcall(vim.api.nvim_buf_del_user_command, buf, "QuickSpell")
    vim.api.nvim_buf_create_user_command(buf, "QuickSpell", function()
        require("quick-spell").correct_word()
    end, { desc = "Correct nearest misspelled word" })
end

local function delete_command(buf)
    pcall(vim.api.nvim_buf_del_user_command, buf, "QuickSpell")
end

local group = vim.api.nvim_create_augroup("quick-spell", { clear = true })

-- Handle spell option changes
vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "spell",
    callback = function(args)
        local buf = args.buf
        -- spell is window-local, use vim.v.option_new for the new value
        if vim.v.option_new == "1" then
            create_command(buf)
        else
            delete_command(buf)
        end
    end,
})

-- Handle buffers that already have spell enabled
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
        if vim.wo.spell then
            create_command(args.buf)
        end
    end,
})
