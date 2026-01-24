if vim.g.loaded_quick_spell then return end
vim.g.loaded_quick_spell = true

local group = vim.api.nvim_create_augroup("quick-spell", { clear = true })

vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "spell",
    callback = function(args)
        if vim.v.option_new == "1" then
            vim.api.nvim_buf_create_user_command(args.buf, "QuickSpell", function()
                require("quick-spell").correct_word()
            end, { desc = "Correct nearest misspelled word" })
        else
            pcall(vim.api.nvim_buf_del_user_command, args.buf, "QuickSpell")
        end
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
        if vim.wo.spell then
            pcall(vim.api.nvim_buf_del_user_command, args.buf, "QuickSpell")
            vim.api.nvim_buf_create_user_command(args.buf, "QuickSpell", function()
                require("quick-spell").correct_word()
            end, { desc = "Correct nearest misspelled word" })
        end
    end,
})
