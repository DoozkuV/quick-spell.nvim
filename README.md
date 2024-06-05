# Spellchecker

A simpler and ears to use set of keybinds for interfacing with Neovim's spell-checker based on Emacs's spellchecker as well as projects like [Jinx](https://github.com/minad/jinx) which provide good bindings for spell-checking.

Neovim's default spell-checking functionality but has clunky binds - you have to first go out of insert mode and into normal mode, and then you have to manually navigate to that mode, then run the correction command, and then go back to what you were doing. 

This package hopes to solve that problem, by providing a single keybind that can find and correct the nearest word without altering the position of the cursor. 

# TODO
- [ ] Add ability to mark words as good.
- [ ] Smarter checking: Right now it always checks lines from start to end - it should always just pick the closest word to the cursor.
- [ ] Telescope integration? This should already work theoretically.
- [ ] Checking to see if "spell" is enabled before package can work. 
    - [ ] Consider having the package set it's own binds that are only set when spell is set. 

