{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  # Laptop-specific Kernel & Performance Profile
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Laptop Battery & Power Management
  services.upower.enable = true;

  # Tuxedo Keyboard RGB & Control Daemon (Laptop Hardware)
  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # Laptop Dedicated Graphics (NVIDIA Hybrid)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };
}
