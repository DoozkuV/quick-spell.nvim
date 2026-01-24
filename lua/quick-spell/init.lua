local config = require("quick-spell.config")
local logger = require("quick-spell.logger")
local finder = require("quick-spell.finder")
local replacer = require("quick-spell.replacer")


local M = {}

M.setup = config.setup

---The main function to be bound by the plugin user
function M.correct_word()
    if not vim.wo.spell then
        logger.log("Spell checking is not enabled", vim.log.levels.WARN)
        return
    end

    local initial_pos = vim.api.nvim_win_get_cursor(0)

    local mode = vim.api.nvim_get_mode().mode
    local skip_cursor_word = vim.tbl_contains(config.options.skip_cursor_word_modes, mode)
    local match = finder.find_nearest(skip_cursor_word)

    if not match then
        logger.log("No misspelled words found", vim.log.levels.INFO)
        return
    end

    local suggestions = vim.fn.spellsuggest(match.word, config.options.max_suggestions)
    if #suggestions == 0 then
        logger.log("No suggestions for: " .. match.word, vim.log.levels.WARN)
        return
    end

    local choices = { "Add to dictionary" }
    vim.list_extend(choices, suggestions)

    vim.ui.select(choices, { prompt = "Correct '" .. match.word .. "':" }, function(item)
        if not item then return end

        if item == "Add to dictionary" then
            vim.api.nvim_win_set_cursor(0, match.pos)
            vim.cmd("spellgood " .. vim.fn.fnameescape(match.word))
            logger.log("Added '" .. match.word .. "' to dictionary", vim.log.levels.INFO)
        else
            replacer.replace_word(match.pos, match.word, item)
        end

        vim.api.nvim_win_set_cursor(0, initial_pos)
    end)
end

return M
