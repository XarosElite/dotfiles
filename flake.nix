{
  description = "Neovim + tmux dotfiles (Home Manager) and a NixOS config";

  inputs = {
    # 25.11 ships Neovim 0.11.7, the version this config targets (the
    # treesitter `master` branch and rustaceanvim v8 need 0.11, not 0.12).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Standalone Home Manager: one config per platform that fits any machine,
      # by reading the user and paths from the environment. That needs
      # --impure, which ./switch.sh passes.
      getEnv =
        name:
        let
          v = builtins.getEnv name;
        in
        if v == "" then
          throw "${name} is not set: evaluate with --impure (./switch.sh does this for you)."
        else
          v;

      mkHome =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          home = getEnv "HOME";
          dotfiles =
            let
              d = builtins.getEnv "DOTFILES";
            in
            if d == "" then "${home}/dotfiles" else d;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit dotfiles;
            # Non-NixOS Linux needs a few fixes for Nix-built programs (locales etc.)
            genericLinux = pkgs.stdenv.isLinux && !builtins.pathExists "/etc/NIXOS";
          };
          modules = [
            ./home.nix
            {
              home.username = getEnv "USER";
              home.homeDirectory = home;
            }
          ];
        };
    in
    {
      # ./switch.sh picks the one for this machine, e.g. .#aarch64-darwin
      homeConfigurations = forAllSystems mkHome;

      # Exposed so switch.sh can run the matching home-manager without installing it
      packages = forAllSystems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      # NixOS: the same home.nix as a module, applied with the system.
      #   sudo nixos-rebuild switch --flake ~/dotfiles#nixos --impure
      # (--impure: configuration.nix imports /etc/nixos/hardware-configuration.nix)
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                dotfiles = "/home/edger/dotfiles";
                genericLinux = false;
              };
              users.edger = {
                imports = [ ./home.nix ];
                home.username = "edger";
                home.homeDirectory = "/home/edger";
              };
            };
          }
        ];
      };
    };
}
