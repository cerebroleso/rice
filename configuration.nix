# Legacy entry point for nixos-rebuild switch without --flake flag.
# Directs to the laptop host profile by default.
{ config, pkgs, ... }:

{
  imports = [
    ./hosts/laptop/default.nix
  ];
}
