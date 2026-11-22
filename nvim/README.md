# NeoVim

![Neovim](./Neovim.png)

## Dependencies

- [neovim](https://wiki.archlinux.org/title/Neovim)
- [neovim-older-but-new](https://github.com/neovim/neovim-releases)

## Why?

Jacob is goober

## How To Install

Place the `nvim` folder in the `~/.config` dir

## Mason

[Mason](https://github.com/mason-org/mason.nvim) is a package manager for Neovim. Using the [Masontools](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim) we can auto
install certain languages, linters, and debuggers.

<details/>
    <summary>Auto Installed Packages</summary>

### Packages

Language servers (mason-lspconfig):

- lua_ls
- pyright
- clangd

Formatters (mason-tool-installer, used by conform.nvim):

- stylua
- black
- isort
- clang-format

rust-analyzer is handled by rustaceanvim.

</details>
The Symlink works :)
