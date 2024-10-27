# Quick-Spell 

Correct mistakes quickly and easily without breaking your flow state! Quick Spell offers a simple keybind that automatically checks the nearest words for mistakes, allows you to correct them, and then lets you get back to writing all without having to switch out of insert mode. This package is small and lightweight, simply acting as a small interface over Neovim's default spell-checking functionality. 

## Installation 
Using *Lazy.nvim*:
```lua
return {
    "DoozkuV/quick-spell.nvim",
    lazy = false, 
}
```
Note that this package is *automatically* lazy-loaded. *Lazy loading this package may interfere with the creation of the User Command.*

## Usage 
1. Enable spelling for your buffer
2. Enter the user command `QuickSpell`

Alternatively, bind `QuickSpell` or `require("quick-spell").correct_word() `
```lua
vim.keymap.set({'n', 'i'}, '<C-;>', function()
    require("quick-spell").correct_word() 
end)
```
## Inspirations
- [Jinx](https://github.com/minad/jinx) I basically ripped the work flow for Quick-Spell from this package. 

