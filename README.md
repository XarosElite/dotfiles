# Dotfiles Home

## Nvim Instructions
- Symbolic link Nvim to your .config directory
```
git clone git@github.com:XarosElite/dotfiles.git 
ln -s ~/dotfiles/nvim/ ~/.config/nvim
```

## NixOS Setup
```
git clone git@github.com:XarosElite/dotfiles.git 
sudo nixos-rebuild switch -I nixos-config=/home/$USER/dotfiles/nixos/configuration.nix
```

