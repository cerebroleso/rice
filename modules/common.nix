{ config, pkgs, inputs ? {}, ... }:

let
  # Helper script to configure DualSense triggers with bow profile (1 7 5 8), max vibration, and Lightbar/Player LEDs off (mic LED left alone)
  dualsenseSetup = pkgs.writeShellScriptBin "dualsense-setup" ''
    DEV="''${1:-$DS_DEV}"

    if [ -n "$DEV" ]; then
      # Bow curve: starts at 1, builds to strength 5 at position 7 with heavy snapforce 8
      ${pkgs.dualsensectl}/bin/dualsensectl -d "$DEV" trigger both bow 1 7 5 8 2>/dev/null || true
      # Maximum rumble & trigger vibration power (zero attenuation)
      ${pkgs.dualsensectl}/bin/dualsensectl -d "$DEV" attenuation 0 0 2>/dev/null || true
      # Turn off Lightbar & Player LEDs (leaves microphone LED alone)
      ${pkgs.dualsensectl}/bin/dualsensectl -d "$DEV" lightbar off 2>/dev/null || true
      ${pkgs.dualsensectl}/bin/dualsensectl -d "$DEV" player-leds 0 2>/dev/null || true
    else
      ${pkgs.dualsensectl}/bin/dualsensectl trigger both bow 1 7 5 8 2>/dev/null || true
      ${pkgs.dualsensectl}/bin/dualsensectl attenuation 0 0 2>/dev/null || true
      ${pkgs.dualsensectl}/bin/dualsensectl lightbar off 2>/dev/null || true
      ${pkgs.dualsensectl}/bin/dualsensectl player-leds 0 2>/dev/null || true
    fi
  '';

  # Background daemon: enforces bow 1 7 5 8 triggers, max vibration, and suppresses Lightbar/Player LEDs (leaves mic LED alone)
  dualsenseDaemon = pkgs.writeShellScriptBin "dualsense-daemon" ''
    exec ${pkgs.python3}/bin/python3 - << 'EOF'
import subprocess
import time
import signal

running = True


def stop(sig, frame):
    global running
    running = False


signal.signal(signal.SIGINT, stop)
signal.signal(signal.SIGTERM, stop)

dualsensectl_bin = "${pkgs.dualsensectl}/bin/dualsensectl"


def get_devices():
    try:
        res = subprocess.run(
            [dualsensectl_bin, "-l"],
            capture_output=True,
            text=True,
            timeout=2
        )
        devs = []
        for line in res.stdout.strip().splitlines():
            line = line.strip()
            if line and not line.startswith("Devices:"):
                devs.append(line.split()[0])
        return devs
    except Exception:
        return []


trigger_counter = 0

while running:
    devs = get_devices()
    if devs:
        for dev in devs:
            # Re-assert trigger bow profile and attenuation periodically (every 2s)
            if trigger_counter % 4 == 0:
                subprocess.run(
                    [
                        dualsensectl_bin, "-d", dev,
                        "trigger", "both", "bow",
                        "1", "7", "5", "8"
                    ],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                subprocess.run(
                    [dualsensectl_bin, "-d", dev, "attenuation", "0", "0"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )

            # Continuously suppress Lightbar and Player LEDs (leaves microphone LED untouched)
            subprocess.run(
                [dualsensectl_bin, "-d", dev, "lightbar", "off"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            subprocess.run(
                [dualsensectl_bin, "-d", dev, "player-leds", "0"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

        trigger_counter += 1
        time.sleep(0.5)
    else:
        trigger_counter = 0
        time.sleep(2.0)
EOF
  '';
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.supportedFilesystems = [ "btrfs" "vfat" "ntfs" "exfat" ];

  # In-Memory Compressed Swap (zRAM)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  # Kernel Memory Management Tuning
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
  };

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

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      niri = prev.niri.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          ../experimental/liquid-glass.patch
        ];
      });
      antigravity-ide = prev.antigravity-ide.overrideAttrs (oldAttrs: {
        version = "2.5.5";
        src = prev.fetchurl {
          url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz";
          sha256 = "0c5233b297d2b3aebb61af49f8944012c2953d361a5ebb16978490636917f831";
        };
      });
    })
  ];

  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          if (
            action.id.indexOf("org.freedesktop.NetworkManager.") === 0 ||
            action.id.indexOf("org.freedesktop.udisks2.") === 0 ||
            action.id.indexOf("org.freedesktop.login1.") === 0 ||
            action.id.indexOf("org.freedesktop.upower.") === 0 ||
            action.id.indexOf("org.bluez.") === 0
          ) {
            return polkit.Result.YES;
          }
        }
      });
    '';
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR"
  '';

  environment.homeBinInPath = true;
  environment.variables.EDITOR = "micro";

  programs.niri.enable = true;
  programs.xwayland.enable = true;
  programs.zsh.enable = true;
  programs.steam.enable = true;
  programs.virt-manager.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    glibc
    glib
    openssl
    libxcb
    libX11
    libXext
    libXrender
    libXrandr
    libXinerama
    libXcursor
    libXi
    libXfixes
    tcl
    tk
    libGL
    libglvnd
    freetype
    fontconfig
  ];

  services.tailscale.enable = true;
  services.displayManager.ly.enable = true;

  # Audio (PipeWire & RTKit)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "50-dualsense-audio" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "device.vendor.id" = "0x054c"; "device.product.id" = "0x0ce6"; }
                { "device.vendor.id" = "0x054c"; "device.product.id" = "0x0df2"; }
                { "node.name" = "~alsa_output.*Wireless_Controller*"; }
                { "node.name" = "~alsa_output.*DualSense*"; }
              ];
              actions = {
                update-props = {
                  "node.description" = "Sony DualSense (Audio & Haptics)";
                  "priority.driver" = 400;
                  "priority.session" = 400;
                };
              };
            }
          ];
        };
      };
    };
  };

  # DualSense / DualSense Edge udev rules for hidraw permissions
  services.udev.extraRules = ''
    # PS5 DualSense controller (USB)
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess", GROUP="input"
    # PS5 DualSense controller (Bluetooth)
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess", GROUP="input"
    # PS5 DualSense Edge controller (USB)
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess", GROUP="input"
    # PS5 DualSense Edge controller (Bluetooth)
    KERNEL=="hidraw*", KERNELS=="*054C:0DF2*", MODE="0660", TAG+="uaccess", GROUP="input"
  '';

  # USB Automounting, iOS usbmuxd & Storage Services
  services.usbmuxd.enable = true;
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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu;
      runAsRoot = true;
    };
  };

  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    (if (inputs ? noctalia && inputs.noctalia ? packages && inputs.noctalia.packages ? ${pkgs.system})
     then inputs.noctalia.packages.${pkgs.system}.default
     else (pkgs.writeShellScriptBin "noctalia" ''
       exec noctalia "$@"
     ''))
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
    tree
    file
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    firefox
    chromium
    discord
    qbittorrent
    motrix
    zathura
    kdePackages.ark
    unar
    unrar
    kdePackages.gwenview
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
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
    kdePackages.breeze
    kdePackages.qqc2-desktop-style
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
    micro
    git
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
    python3
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka

    yazi
    btop
    ripgrep
    procps
    gnused
    rsync
    p7zip
    unzip
    ddcutil
    usbmuxd
    libimobiledevice
    ifuse
    appimage-run
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
    # pcsx2
    # moonlight-qt
    mangohud
    vkbasalt
    fastfetch
    dualsensectl
    dualsenseSetup
    dualsenseDaemon
  ];

  # Systemd user service running daemon for gradual trigger stiffness, max vibration & continuous LED suppression
  systemd.user.services.dualsense-monitor = {
    description = "DualSense Controller Daemon (Gradual Triggers, Max Vibration & LED Suppression Loop)";
    wantedBy = [ "graphical-session.target" "default.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${dualsenseDaemon}/bin/dualsense-daemon";
      Restart = "always";
      RestartSec = "3s";
    };
  };

  system.stateVersion = "26.11";
}
