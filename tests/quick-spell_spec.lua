local quick_spell = require("quick-spell")
local config = require("quick-spell.config")

describe("quick-spell", function()
    before_each(function()
        -- Reset config to defaults
        config.setup({})
        -- Create a fresh buffer for each test
        vim.cmd("enew!")
        vim.wo.spell = true
        vim.bo.spelllang = "en"
    end)

    after_each(function()
        vim.cmd("bwipeout!")
    end)

    describe("setup", function()
        it("accepts minimal config", function()
            quick_spell.setup({ keymap = "<C-;>" })
            assert.equals("<C-;>", config.options.keymap)
            assert.equals(10, config.options.max_suggestions)
        end)

        it("merges with defaults", function()
            quick_spell.setup({ max_suggestions = 5 })
            assert.equals(5, config.options.max_suggestions)
            assert.equals(true, config.options.notify)
        end)
    end)

    describe("find_nearest_misspelled", function()
        it("returns nil when no misspellings exist", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local notified = false
            local orig_notify = vim.notify
            vim.notify = function(msg)
                if msg:match("No misspelled") then notified = true end
            end

            quick_spell.correct_word()

            vim.notify = orig_notify
            assert.is_true(notified)
        end)

        it("finds misspelled word at cursor", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local prompted = false
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                if opts.prompt:match("helo") then prompted = true end
                on_choice(nil) -- cancel
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            assert.is_true(prompted)
        end)

        it("finds nearest misspelled word when cursor is between two", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "wrld hello wrld" })
            -- Cursor on "hello" (correct word), between two misspelled "wrld"
            vim.api.nvim_win_set_cursor(0, { 1, 6 })

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            assert.equals("wrld", found_word)
        end)
    end)

    describe("correct_word", function()
        it("warns when spell is disabled", function()
            vim.wo.spell = false

            local warned = false
            local orig_notify = vim.notify
            vim.notify = function(msg, level)
                if level == vim.log.levels.WARN and msg:match("not enabled") then
                    warned = true
                end
            end

            quick_spell.correct_word()

            vim.notify = orig_notify
            assert.is_true(warned)
        end)

        it("restores cursor position after correction", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world test" })
            vim.api.nvim_win_set_cursor(0, { 1, 11 }) -- on "test"

            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                on_choice(items[2], 2) -- select first suggestion
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            local pos = vim.api.nvim_win_get_cursor(0)
            assert.equals(1, pos[1])
            assert.equals(11, pos[2])
        end)

        it("respects max_suggestions config", function()
            config.setup({ max_suggestions = 3 })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local suggestion_count = 0
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                -- First item is "Add to dictionary", rest are suggestions
                suggestion_count = #items - 1
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            assert.is_true(suggestion_count <= 3)
        end)

        it("corrects misspelled word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                on_choice("hello")
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("hello world", line)
        end)

        it("replaces with longer word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "wrld test" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                on_choice("worldwide")
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("worldwide test", line)
        end)

        it("replaces with shorter word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "accross the street" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                on_choice("across")
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("across the street", line)
        end)

        it("handles word not at start of line", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Good bda input" })
            vim.api.nvim_win_set_cursor(0, { 1, 5 })

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice("bad")
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            assert.equals("bda", found_word)
            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("Good bad input", line)
        end)

        it("handles cursor at end of misspelled word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Good bda input" })
            vim.api.nvim_win_set_cursor(0, { 1, 7 }) -- on 'a' at end of "bda"

            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                on_choice("bad")
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("Good bad input", line)
        end)
    end)

    describe("skip_cursor_word option", function()
        it("skips cursor word when mode is in skip_cursor_word_modes", function()
            config.setup({ skip_cursor_word_modes = { "n" } }) -- include normal mode
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo wrld" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- on "helo"

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            -- Should find "wrld" not "helo" since normal mode skips cursor word
            assert.equals("wrld", found_word)
        end)

        it("returns no misspellings when only cursor word is misspelled and skipping", function()
            config.setup({ skip_cursor_word_modes = { "n" } }) -- include normal mode
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- on "helo"

            local notified = false
            local orig_notify = vim.notify
            vim.notify = function(msg)
                if msg:match("No misspelled") then notified = true end
            end

            quick_spell.correct_word()

            vim.notify = orig_notify
            assert.is_true(notified)
        end)

        it("finds cursor word when mode is not in skip_cursor_word_modes", function()
            config.setup({ skip_cursor_word_modes = {} }) -- empty, don't skip any mode
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- on "helo"

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            -- Should find "helo" since normal mode is not in skip list
            assert.equals("helo", found_word)
        end)

        it("finds cursor word in normal mode by default", function()
            -- Default skip_cursor_word_modes is {"i", "R"}, not "n"
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- on "helo"

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            -- Should find "helo" since default doesn't skip normal mode
            assert.equals("helo", found_word)
        end)

        it("skips cursor word even when cursor is at end of word", function()
            config.setup({ skip_cursor_word_modes = { "n" } })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo wrld" })
            vim.api.nvim_win_set_cursor(0, { 1, 3 }) -- at end of "helo" (on 'o')

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            -- Should find "wrld" not "helo" even though cursor is at end of "helo"
            assert.equals("wrld", found_word)
        end)

        it("skips cursor word when cursor is immediately after word (insert mode)", function()
            config.setup({ skip_cursor_word_modes = { "n" } })
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helo wrld" })
            vim.api.nvim_win_set_cursor(0, { 1, 4 }) -- after "helo" (insert mode position)

            local found_word = nil
            local orig_select = vim.ui.select
            vim.ui.select = function(items, opts, on_choice)
                found_word = opts.prompt:match("'([^']+)'")
                on_choice(nil)
            end

            quick_spell.correct_word()

            vim.ui.select = orig_select
            -- Should find "wrld" not "helo" when cursor is right after "helo"
            assert.equals("wrld", found_word)
        end)
    end)
end)
