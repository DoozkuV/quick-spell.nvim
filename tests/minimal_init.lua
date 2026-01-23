-- Minimal init for testing
vim.cmd([[set runtimepath+=.]])

-- Try common plenary paths
local plenary_paths = {
    vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"),
    vim.fn.expand("~/.local/share/nvim/site/pack/packer/start/plenary.nvim"),
    vim.fn.expand("~/.local/share/nvim/site/pack/*/start/plenary.nvim"),
    vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
    vim.fn.stdpath("data") .. "/site/pack/packer/start/plenary.nvim",
}

for _, path in ipairs(plenary_paths) do
    if vim.fn.isdirectory(path) == 1 then
        vim.cmd([[set runtimepath+=]] .. path)
        break
    end
end

vim.cmd([[runtime plugin/plenary.vim]])
