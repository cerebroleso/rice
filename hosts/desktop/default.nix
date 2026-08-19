{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  # Desktop Kernel & Performance Profile
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # (Optional) Desktop-specific settings can be added here
}
