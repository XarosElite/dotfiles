# Keymaps

Leader is `<Space>`. Press `<leader>?` (or pause after `<leader>`) for which-key.

## Non-Plugin Related

<details/>

<Summary>basic</Summary>

- `<leader>y` - Yank to system clipboard (operator, e.g. `<leader>yiw`; also in visual mode)
- `<leader>Y` - Yank to end of line to system clipboard
- `<leader>t` - Open terminal
- `<Esc>` - Exit terminal mode
- `<leader>d` - Black hole delete, visual mode (vim-visual-multi also uses `<leader>d`)
- `<C-h/j/k/l>` - Move between windows

Every yank already goes to the system clipboard (see `lua/clipboard.lua`; works
locally, over SSH and inside tmux).

</details>

## Plugin Related

<details/>

<Summary>telescope</summary>

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fw` - Grep word under cursor
- `<leader>fb` - Buffers
- `<leader>fh` - Help tags
- `<leader>o` - Document symbols

</details>

<details/>

<Summary>lsp</summary>

Telescope-powered:

- `gd` - Goto definition
- `gr` - References
- `gI` - Implementations
- `gT` - Type definitions

Neovim 0.11 built-in defaults:

- `K` - Hover
- `grn` - Rename
- `gra` - Code action
- `grr` - References (quickfix list)
- `gri` - Implementation
- `gO` - Document symbols
- `<C-s>` - Signature help (insert mode)
- `[d` / `]d` - Previous / next diagnostic
- `<C-w>d` - Diagnostic float

Formatting:

- `<leader>F` - Format buffer (conform.nvim; also runs on save)

</details>

<details/>

<Summary>trouble</summary>

- `<leader>xx` - Diagnostics toggle
- `<leader>xX` - Diagnostics toggle for current buffer
- `<leader>xs` - Symbols toggle
- `<leader>xl` - LSP definitions/references panel (right)
- `<leader>xL` - Location list toggle
- `<leader>xQ` - Quickfix list toggle

</details>

<details/>

<Summary>other</summary>

- `<leader>e` - Oil file explorer
- `<leader>z` - Toggle stay-centered (cursor line kept in the middle of the screen)
- `<C-space>` / `<BS>` - Treesitter: grow / shrink selection
- `<leader>d` - vim-visual-multi: select word under cursor (repeat to add next match)

</details>
