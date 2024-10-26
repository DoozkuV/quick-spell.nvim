-- TODO: Do Neovim version validation
if vim.g.loaded_quick_spell then
    return
end
vim.g.loaded_quick_spell = 1

local cmd_name = "QuickSpell"

vim.api.nvim_create_augroup("quick-spell", { clear = true })
vim.api.nvim_create_autocmd("OptionSet", {
    group = "quick-spell",
    pattern = "spell",
    callback = function()
        if vim.wo.spell then
            vim.api.nvim_buf_create_user_command(0, cmd_name,
                function() require("quick-spell").correct_word() end,
                { nargs = 0 })
        elseif vim.api.nvim_buf_get_commands(0, {})[cmd_name] ~= nil then
            vim.api.nvim_buf_del_user_command(0, cmd_name)
        end
    end
})
