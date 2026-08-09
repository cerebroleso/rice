# Niri Desktop Environment Configuration with Noctalia (NixOS Edition)

### Frost Mode
![Desktop Preview (frost)](desktop-frost.png)

### Liquid Glass Mode
![Desktop Preview (glass)](desktop-glass.png)

---

## 1. Core Environment Architecture

*   **niri**: Scrollable-tiling Wayland compositor.
*   **noctalia**: Monolithic Wayland desktop shell (providing status bar, dock, launcher, notifications, wallpaper manager, and OSD).
*   **ly**: TUI display manager for console login and Wayland session selection.
*   **kitty**: GPU-accelerated Wayland terminal emulator.
*   **zsh & zsh-powerlevel10k**: Interactive shell with Powerlevel10k prompt engine and autosuggestions.
*   **nautilus**: GNOME file manager with dynamic macOS styled accent folders.
*   **pipewire & wireplumber**: Low-latency multimedia audio & video routing.
*   **nirimon & nirius**: Niri monitor layout manager & IPC command suite (`niri-mod` helper tools).
*   **udiskie & udisks2**: Automatic USB drive & removable storage automounter with system tray status.
*   **tuxedo-drivers & tuxedo-rs**: Laptop hardware drivers & GUI daemon (`tailord`/`tailor-gui`) for dynamic RGB keyboard LED sync.
*   **rose-pine-cursor**: Rosé Pine BreezeX cursor theme (`BreezeX-RosePine-Linux`).

---

## 2. Master NixOS Deployment Guide

Follow these exact steps to deploy this complete desktop environment on a fresh NixOS system.

### Step 1: Generate NixOS System Configuration (`/etc/nixos/configuration.nix`)

Copy the master NixOS system configuration file provided in your dotfiles repository:

```bash
# Symlink configuration to /etc/nixos
sudo ln -sf ~/dotfiles/configuration.nix /etc/nixos/configuration.nix
ln -sf /etc/nixos/hardware-configuration.nix ~/dotfiles/hardware-configuration.nix

# Apply system rebuild
sudo nixos-rebuild switch
```

#### Master Configuration Reference (`configuration.nix`):
```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

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

  # User tsui configuration with Wayland hardware permissions
  users.users.tsui = {
    isNormalUser = true;
    description = "tsui";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "libvirtd" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  # Core Programs & Services
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

  # Tuxedo Hardware & Control Center Module (tailord daemon & tailor-gui)
  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # USB Automounting & Storage Services
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.upower.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;
  services.upower.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  hardware.bluetooth.enable = true;

  # Virtualization Stack
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu;
      runAsRoot = true;
    };
  };

  # Graphics & NVIDIA Drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
  ];

  # System Packages
  environment.systemPackages = with pkgs; [
    niri nirimon nirius kitty waybar nwg-look satty grim slurp swayosd playerctl brightnessctl cliphist
    wl-clipboard libnotify udiskie ntfs3g exfat exfatprogs qt5ct qt6ct firefox chromium discord qbittorrent zathura file-roller
    loupe meld qdirstat gparted nautilus tuxedo tuxedo-rs rose-pine-cursor xhost pavucontrol
    dbeaver-bin tailscale nmap lshw pciutils usbutils vscode antigravity-ide zed-editor
    neovim git zsh zsh-powerlevel10k zsh-autosuggestions zsh-syntax-highlighting python3
    nerd-fonts.jetbrains-mono yazi btop ripgrep procps gnused rsync p7zip unzip ddcutil
    (bottles.override { removeWarningPopup = true; }) wineWow64Packages.stable scx.full virt-manager qemu libvirt ebtables dnsmasq OVMF steam ryubing rpcs3 pcsx2
    moonlight-qt mangohud vkbasalt
  ];

  system.stateVersion = "26.11";
}
```

---

### Step 2: Dotfiles Symlinking & Path Configuration

Run this command block to link your repository directly to `~/.config/` and fix user path references:

```bash
# 1. Scaffold directories
mkdir -p ~/.config ~/.local/bin ~/.local/state/noctalia ~/.config/"Antigravity IDE"/User ~/.config/"Code - OSS"/User

# 2. Symlink configuration folders (Strategy 2 Live Editable Symlinks)
for folder in niri noctalia kitty gtk-3.0 gtk-4.0 qt5ct qt6ct pcmanfm-qt; do
    rm -rf ~/.config/"$folder"
    ln -snf ~/dotfiles/.config/"$folder" ~/.config/"$folder"
done

# 3. Symlink shell and state files
rm -f ~/.zshrc ~/.p10k.zsh
ln -snf ~/dotfiles/.zshrc ~/.zshrc
ln -snf ~/dotfiles/.p10k.zsh ~/.p10k.zsh

rm -f ~/.local/state/noctalia/settings.toml
ln -snf ~/dotfiles/.config/noctalia/settings.toml ~/.local/state/noctalia/settings.toml

rm -f ~/.config/"Antigravity IDE"/User/settings.json ~/.config/"Code - OSS"/User/settings.json
ln -snf ~/dotfiles/.config/"Antigravity IDE"/User/settings.json ~/.config/"Antigravity IDE"/User/settings.json
ln -snf ~/dotfiles/.config/"Code - OSS"/User/settings.json ~/.config/"Code - OSS"/User/settings.json
```

---

### Step 3: Build & Install Noctalia Desktop Shell

Build **Noctalia** from source Flake and link it to your local binary path:

```bash
# Compile Noctalia via Nix Flake
nix --extra-experimental-features 'nix-command flakes' build github:noctalia-dev/noctalia --out-link /tmp/noctalia-result

# Link binaries to user PATH
ln -sf /tmp/noctalia-result/bin/noctalia ~/.local/bin/noctalia
ln -sf /tmp/noctalia-result/bin/.noctalia-wrapped ~/.local/bin/.noctalia-wrapped
```

---

### Step 4: Install WhiteSur Base Icons & Generate Dynamic macOS Folders

Install `WhiteSur-icon-theme` and initialize the dynamic color hook:

```bash
# Install WhiteSur base icons
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
/tmp/WhiteSur-icon-theme/install.sh -d ~/.local/share/icons
rm -rf /tmp/WhiteSur-icon-theme

# Set GTK cursor theme
gsettings set org.gnome.desktop.interface cursor-theme 'BreezeX-RosePine-Linux'

# Run colors hook to generate 596 macOS styled folder icons
chmod +x ~/dotfiles/.config/noctalia/colors_changed.sh
~/dotfiles/.config/noctalia/colors_changed.sh
```

---

## 3. Keyboard Shortcuts (Keybinds)

Keybindings are configured in [binds.kdl](file:///home/tsui/dotfiles/.config/niri/dms/binds.kdl).

### Core Applications
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Ctrl+Alt+T` / `Mod+T` | `spawn "kitty"` | Launch Kitty terminal |
| `Mod+W` | `spawn "firefox"` | Launch Firefox browser |
| `Mod+D` | `spawn "zed-editor"` | Launch Zed code editor |
| `Mod+E` | `spawn "nautilus"` | Launch Nautilus file manager |
| `Mod+Shift+E` | `spawn-sh "kitty yazi"` | Launch Yazi file manager in Kitty |

### Window Management
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Mod+Q` | `close-window` | Close focused window |
| `Mod+Shift+Q` | `quit skip-confirmation=true` | Exit Niri session |
| `Mod+S` | `switch-preset-column-width` | Cycle column width presets |
| `Mod+M` | `maximize-column` | Toggle column maximization |
| `Mod+F` | `fullscreen-window` | Toggle fullscreen |
| `Alt+Tab` | `focus-window-previous` | Focus previous window |
| `Mod+Left` / `Mod+Right` | `move-column-left / right` | Move column left or right |
| `Mod+Ctrl+Left` / `Right` | `focus-column-left / right` | Focus adjacent column |
| `Mod+Shift+Space` | `toggle-window-floating` | Toggle window floating mode |

### Desktop Shell & Noctalia Controls
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Mod+Space` | `noctalia msg panel-toggle launcher` | Toggle Noctalia Application Launcher |
| `Mod+V` | `noctalia msg panel-toggle clipboard` | Toggle Noctalia Clipboard History |
| `Mod+N` | `noctalia msg notifications toggleHistory` | Toggle Notification History panel |
| `Mod+P` / `Mod+Shift+S` | `noctalia msg screenshot-region` | Interactive region screenshot |
| `Mod+Shift+R` | Niri config reload | Reload Niri configuration |
| `Mod+Shift+G` | `toggle-glass.sh` | Toggle Niri Liquid Glass refraction mode |
| `Mod+Shift+D` | `toggle-pcmanfm.sh` | Toggle desktop icons visibility |

---

## 4. Toggling Liquid Glass vs Stock Render Mode

Switch between standard rendering and Liquid Glass refraction effects:

```bash
~/dotfiles/scripts/toggle-glass.sh
```

---

## 5. NixOS Troubleshooting & FAQ

### A. How to open Noctalia Settings GUI?
Run the IPC command in terminal or via keybind:
```bash
noctalia msg settings-open
```

### B. Keyboard RGB Backlight does not sync with wallpaper?
Ensure `tuxedo` and `hardware.tuxedo-drivers.enable = true;` are present in `/etc/nixos/configuration.nix`. The script `colors_changed.sh` automatically updates Tuxedo LED colors via D-Bus (`com.tuxedocomputers.tccd`).

### C. Zsh prompt missing Powerlevel10k icons?
Ensure `zsh-powerlevel10k` and `nerd-fonts.jetbrains-mono` are installed in your NixOS system packages. `~/.zshrc` automatically loads the theme from `/run/current-system/sw/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme`.

### D. Re-building system after configuration changes?
Run:
```bash
sudo nixos-rebuild switch
```

### E. VS Code / Antigravity IDE "Failed to save: User did not grant permission"?
* **Cause**: `vscode-fhs` / `antigravity-ide-fhs` use Bubblewrap (`bwrap`) to create an FHS sandbox. Inside this sandbox, `/run/wrappers` is mounted with `nosuid` and `PR_SET_NO_NEW_PRIVS` is set, blocking `pkexec` and `sudo` at the kernel level.
* **Fix**: Use non-FHS packages (`vscode`, `antigravity-ide`) in `configuration.nix` along with `programs.nix-ld.enable = true;`. This allows `pkexec` to execute properly and prompt via Noctalia's built-in Polkit agent.

### F. Running GParted or GUI apps as root ("cannot open display")?
* **Cause**: `pkexec` cleans environment variables when running commands as root, stripping `$DISPLAY` and `$WAYLAND_DISPLAY`.
* **Fix**:
  1. Ensure `xhost +local:root` is enabled (automatically run via `glass_niri/config.kdl`).
  2. Launch GParted using `sudo -E gparted` or `sudo gparted`. `configuration.nix` configures `security.sudo.extraConfig` to preserve `DISPLAY` and `WAYLAND_DISPLAY`.

### G. FitGirl Repacks & Wine / Bottles Installer Freeze at 0.2%?
* **Cause**: FitGirl Repack setup wizards use 32-bit `unarc.dll` / `cls-*.dll` decompression algorithms. On 64-bit Wine, unconstrained decompression threads rapidly exceed the 2 GB 32-bit virtual memory address space, triggering Linux Out-Of-Memory (OOM) killer (exit code 137).
* **Fix**:
  1. On the **first screen of the FitGirl setup wizard** (before clicking *Next* to install), check the box: **"Limit installer to 2 GB of RAM usage"**.
  2. Ensure `(bottles.override { removeWarningPopup = true; })` and `wineWow64Packages.stable` are present in `/etc/nixos/configuration.nix` for native 32-bit/64-bit Wine support.


