local quick_spell = require("quick-spell")

describe("quick-spell", function()
    before_each(function()
        -- Create a fresh buffer for each test
        vim.cmd("enew!")
        vim.wo.spell = true
        vim.bo.spelllang = "en"
    end)

    after_each(function()
        vim.cmd("bwipeout!")
    end)

    describe("find_nearest_misspelled", function()
        it("returns nil when no misspellings exist", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world" })
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            -- We need to expose find_nearest_misspelled for testing
            -- or test via correct_word behavior
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
    end)

    describe("replace_word_at", function()
        it("replaces word at the start of line", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "foo bar baz" })

            quick_spell.replace_word_at({ 1, 0 }, "foo", "hello")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("hello bar baz", line)
        end)

        it("replaces word in the middle of line", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "foo bar baz" })

            quick_spell.replace_word_at({ 1, 4 }, "bar", "world")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("foo world baz", line)
        end)

        it("replaces word at the end of line", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "foo bar baz" })

            quick_spell.replace_word_at({ 1, 8 }, "baz", "qux")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("foo bar qux", line)
        end)

        it("replaces with longer word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a b c" })

            quick_spell.replace_word_at({ 1, 2 }, "b", "longer")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("a longer c", line)
        end)

        it("replaces with shorter word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world test" })

            quick_spell.replace_word_at({ 1, 6 }, "world", "x")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("hello x test", line)
        end)

        it("handles word on different line", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first line", "second line", "third line" })

            quick_spell.replace_word_at({ 2, 7 }, "line", "row")

            local lines = vim.api.nvim_buf_get_lines(0, 0, 3, false)
            assert.equals("first line", lines[1])
            assert.equals("second row", lines[2])
            assert.equals("third line", lines[3])
        end)

        it("replaces first part of hyphenated word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "self-aware robot" })

            quick_spell.replace_word_at({ 1, 0 }, "self", "fully")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("fully-aware robot", line)
        end)

        it("replaces second part of hyphenated word", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "self-aware robot" })

            quick_spell.replace_word_at({ 1, 5 }, "aware", "conscious")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("self-conscious robot", line)
        end)

        it("replaces word with apostrophe", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "I don't know" })

            quick_spell.replace_word_at({ 1, 2 }, "don't", "do")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("I do know", line)
        end)

        it("replaces word containing numbers", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "test123 value" })

            quick_spell.replace_word_at({ 1, 0 }, "test123", "example456")

            local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            assert.equals("example456 value", line)
        end)
    end)
end)
