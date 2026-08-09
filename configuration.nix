{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.supportedFilesystems = [ "btrfs" "vfat" "ntfs" "exfat" ];
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };

  console.keyMap = "it";

  users.users.tsui = {
    isNormalUser = true;
    description = "tsui";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "libvirtd" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.udisks2.") === 0 && subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
        if (subject.isInGroup("wheel")) {
          return polkit.Result.AUTH_ADMIN_KEEP;
        }
      });
    '';
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR"
  '';

  environment.sessionVariables = {
    PATH = [ "/run/wrappers/bin" ];
  };

  programs.niri.enable = true;
  programs.xwayland.enable = true;
  programs.zsh.enable = true;
  programs.steam.enable = true;
  programs.virt-manager.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
  ];

  services.tailscale.enable = true;
  services.upower.enable = true;
  services.displayManager.ly.enable = true;

  # USB Automounting & Storage Services
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

  # Bluetooth Hardware & Blueman Services
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };

  services.blueman.enable = true;

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu;
      runAsRoot = true;
    };
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  environment.systemPackages = with pkgs; [
    niri
    nirimon
    nirius
    xwayland-satellite
    kitty
    waybar
    nwg-look
    satty
    grim
    slurp
    swayosd
    playerctl
    brightnessctl
    bluez
    bluez-tools
    blueman
    cliphist
    wl-clipboard
    libnotify
    udiskie
    ntfs3g
    exfat
    exfatprogs
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    firefox
    chromium
    discord
    qbittorrent
    zathura
    file-roller
    loupe
    meld
    qdirstat
    (pkgs.symlinkJoin {
      name = "gparted";
      paths = [ pkgs.gparted ];
      postBuild = ''
        rm $out/bin/gparted
        cat << 'EOF' > $out/bin/gparted
#!/usr/bin/env bash
export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
${pkgs.xhost}/bin/xhost +local:root >/dev/null 2>&1 || true
exec /run/wrappers/bin/pkexec --disable-internal-agent env DISPLAY="$DISPLAY" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" ${pkgs.gparted}/libexec/gpartedbin "$@"
EOF
        chmod +x $out/bin/gparted

        rm $out/share/applications/gparted.desktop
        ${pkgs.gnused}/bin/sed 's|Exec=.*gparted|Exec=gparted|g' ${pkgs.gparted}/share/applications/gparted.desktop > $out/share/applications/gparted.desktop
      '';
    })
    nautilus
    rose-pine-cursor
    xhost
    pavucontrol
    dbeaver-bin
    tailscale
    nmap
    lshw
    pciutils
    usbutils
    vscode
    antigravity-ide
    zed-editor
    neovim
    git
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
    python3
    nerd-fonts.jetbrains-mono
    yazi
    btop
    ripgrep
    procps
    gnused
    rsync
    p7zip
    unzip
    ddcutil
    (bottles.override { removeWarningPopup = true; })
    wineWow64Packages.stable
    scx.full
    virt-manager
    qemu
    libvirt
    ebtables
    dnsmasq
    OVMF
    steam
    ryubing
    rpcs3
    pcsx2
    moonlight-qt
    mangohud
    vkbasalt
    fastfetch
  ];

  system.stateVersion = "26.11";
}
