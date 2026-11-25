# Home Manager module: the tools this Neovim + tmux setup needs, and links
# ~/.config/nvim and ~/.config/tmux to this repo. Used standalone on macOS and
# any Linux (see flake.nix / switch.sh) and as a NixOS module.
{
  config,
  lib,
  pkgs,
  dotfiles, # absolute path of this repo checkout
  genericLinux, # true on Linux distros other than NixOS
  ...
}:
let
  # Live links into the checkout (not copies in /nix/store), so editing the
  # configs, :Lazy updating lazy-lock.json etc. work without a rebuild.
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.packages =
    with pkgs;
    [
      neovim-unwrapped # 0.11.7 from nixos-25.11 (see flake.nix)
      tmux
      terminaltexteffects # `tte`, the animated dashboard banner

      # Neovim plugin installs and builds (lazy.nvim, telescope-fzf-native,
      # treesitter parsers)
      git
      curl
      gnutar
      gzip
      unzip
      gnumake
      ripgrep # telescope live grep
      fd # telescope file search

      # Language servers and formatters (lua/tools.lua). Provided by Nix so
      # they work everywhere, NixOS included, where mason's downloaded
      # binaries can't run. Neovim only asks mason for ones missing from PATH.
      lua-language-server
      pyright
      clang-tools # clangd, clang-format
      stylua
      black
      isort
      rust-analyzer

      # mason's runtimes, for anything it does still install
      nodejs
      python3
    ]
    # C compiler for treesitter parsers and telescope-fzf-native
    ++ lib.optional stdenv.isLinux gcc
    ++ lib.optional stdenv.isDarwin clang;

  xdg.configFile."nvim".source = link "nvim";
  xdg.configFile."tmux".source = link "tmux";

  # Locale archive, XDG data dirs etc. for Nix programs on Ubuntu, Arch, ...
  targets.genericLinux.enable = genericLinux;
  # ...but not its GPU driver setup: nothing here needs it, and it pulls in
  # Intel-only libraries that break the build on ARM Linux.
  targets.genericLinux.gpu.enable = false;

  # Puts the `home-manager` command on PATH (generations, rollback, ...)
  programs.home-manager.enable = true;

  # Home Manager release whose defaults this was written against; leave it
  # as is when upgrading.
  home.stateVersion = "25.11";
}
