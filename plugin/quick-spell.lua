print("Quick test plugin is executed!")

vim.api.nvim_create_augroup("quick-spell", { clear = true })
vim.api.nvim_create_autocmd("OptionSet", {
    group = "quick-spell",
    pattern = "spell",
    callback = function()
        print("Quick Spell Enabled!")
        if vim.wo.spell then
            vim.api.nvim_buf_create_user_command(0, "QuickSpell",
                function() require("quick-spell").correct_word() end,
                { nargs = 0 })
        else
            vim.api.nvim_buf_del_user_command(0, "QuickSpell")
        end
    end
})
