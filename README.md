# Quick-Spell

Correct mistakes quickly and easily without breaking your flow state! Quick Spell offers a simple keybind that automatically checks the nearest words for mistakes, allows you to correct them, and then lets you get back to writing all without having to switch out of insert mode. This package is small and lightweight, simply acting as a small interface over Neovim's default spell-checking functionality.

## Installation

Using **lazy.nvim**:
```lua
{
    "DoozkuV/quick-spell.nvim",
    opts = {},
}
```

With custom configuration:
```lua
{
    "DoozkuV/quick-spell.nvim",
    opts = {
        max_suggestions = 10,
        skip_cursor_word_modes = { "i", "R" },
        notify = true,
    },
}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `max_suggestions` | integer | `10` | Maximum number of spelling suggestions to display |
| `skip_cursor_word_modes` | string[] | `{"i", "R"}` | Vim modes where the word under cursor is skipped (useful for insert mode where you're still typing) |
| `notify` | boolean | `true` | Show notifications for actions like "No misspelled words found" |

## Usage

1. Enable spelling for your buffer (`:set spell`)
2. Run the user command `:QuickSpell`

Alternatively, bind to a keymap:
```lua
vim.keymap.set({"n", "i"}, "<C-;>", function()
    require("quick-spell").correct_word()
end)
```

## Inspirations
- [Jinx](https://github.com/minad/jinx): I basically ripped the workflow for Quick-Spell from this package.
