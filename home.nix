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

  # tte (TerminalTextEffects) for the animated dashboard banner. nixpkgs 25.11
  # has 0.12.1, which lacks --no-eol and --reuse-canvas that
  # nvim/scripts/dashboard-art.sh uses, so build 0.15.0 (same as install.sh).
  tte = pkgs.terminaltexteffects.overridePythonAttrs (old: rec {
    version = "0.15.0";
    src = pkgs.fetchPypi {
      pname = "terminaltexteffects";
      inherit version;
      hash = "sha256-9LMchr+pQ9W/Oyxey/rqDeZe1KlRAoxA+OTLVO/QZDk=";
    };
    build-system = [ pkgs.python3Packages.hatchling ]; # was poetry-core
  });
in
{
  home.packages =
    with pkgs;
    [
      neovim-unwrapped # 0.11.7 from nixos-25.11 (see flake.nix)
      tmux
      tte # animated dashboard banner (see above)

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
