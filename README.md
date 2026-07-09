# Niri Desktop Environment Configuration with Noctalia

![Desktop Preview](desktop.png)

## 1. Underlying Utilities & Background Services

*   **niri**: Core Wayland compositor.
*   **xwayland-satellite**: Rootless X11 compatibility bridge.
*   **wl-clipboard**: Native Wayland clipboard protocol interface.
*   **cliphist**: Background daemon for clipboard history persistence.
*   **xdg-desktop-portal**: Core IPC router for sandbox bridging.
*   **xdg-desktop-portal-gnome**: Portal backend required for screen captures.
*   **xdg-desktop-portal-gtk**: Fallback portal for GTK file pickers.
*   **hypridle**: DPMS state manager.
*   **hyprlock**: GPU-accelerated screen locker.
*   **ly**: TUI display manager (login manager) supporting X11 and Wayland.
*   **noctalia-git**: Monolithic Wayland desktop shell (providing status bar, dock, application launcher, notifications, OSD, and wallpaper manager).
*   **pipewire**: Low-latency multimedia routing daemon.
*   **wireplumber**: Session and policy manager for PipeWire.
*   **brightnessctl**: Interface for sysfs backlight manipulation.
*   **networkmanager**: System daemon for network states.
*   **bluez**: Core Bluetooth protocol stack.
*   **bluez-utils**: CLI utilities for Bluetooth management.
*   **nwg-look**: GTK visual settings injector.
*   **qt5ct**: Qt5 environment variable injector.
*   **qt6ct**: Qt6 environment variable injector.
*   **ttf-jetbrains-mono-nerd**: Base typography and icon glyphs.
*   **noto-fonts**: System UI fallback typography.
*   **playerctl**: MPRIS command-line controller for media keys.

---

## 2. User-Facing GUI & TUI Applications

*   **nautilus**: Graphical file manager.
*   **dolphin**: Qt-based graphical file manager.
*   **file-roller**: Graphical archive manager.
*   **zip, unzip, p7zip, unrar**: Compression algorithms.
*   **yazi**: Asynchronous terminal file manager.
*   **kitty**: GPU-accelerated Wayland terminal emulator.
*   **zed**: Vulkan-rendered code editor.
*   **helium-browser-bin**: Minimal web browser.
*   **google-chrome**: Monolithic web browser.
*   **discord**: Electron-based communication client.
*   **pwvucontrol**: Graphical PipeWire audio router.
*   **network-manager-applet**: System tray interface for Wi-Fi.
*   **blueman**: System tray interface for Bluetooth.
*   **nirimod-git**: GTK4 graphical settings application for Niri.
*   **grim**: Frame grabber for the Wayland buffer.
*   **slurp**: Coordinate mapping utility for screen captures.
*   **satty**: Wayland screenshot annotation GUI.

---

## The Master Deployment Pipeline

Execute these steps to bootstrap the system, clone the dotfiles repository, install packages, configure user groups, and enable essential services.

### Step 1: System Bootstrapping (Run this first on a clean TTY system)
```bash
# Install git and base-devel (needed for AUR compiling)
sudo pacman -S --needed base-devel git

# Bootstrap paru (AUR helper)
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin && makepkg -si --noconfirm
cd .. && rm -rf paru-bin

# Clone your dotfiles repository to your home folder
git clone https://github.com/cerebroleso/rice.git ~/dotfiles
```

### Step 2: Install Packages & Configure Services
```bash
# Update system and install Niri, Ly, and Noctalia Environment packages
paru -S niri xwayland-satellite wl-clipboard cliphist xdg-desktop-portal \
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk hypridle hyprlock pipewire \
  wireplumber brightnessctl networkmanager bluez bluez-utils nwg-look qt5ct qt6ct \
  ttf-jetbrains-mono-nerd noto-fonts nautilus dolphin file-roller zip unzip p7zip \
  unrar yazi kitty zed helium-browser-bin google-chrome discord pwvucontrol \
  network-manager-applet blueman grim slurp satty hyprutils-git hyprlang-git \
  hyprwayland-scanner-git aquamarine-git hyprgraphics-git hyprtoolkit-git \
  nirimod-git playerctl noctalia-git ly

# Enable the Ly TUI display manager for system startup login
sudo systemctl enable ly.service

# Add current user to video and input groups to allow Wayland/compositor seat control
sudo usermod -aG video,input $USER

# Enable user services for multimedia routing
systemctl --user enable wireplumber.service
systemctl --user enable pipewire.service

# Ensure Wayland session entries directory exists
sudo mkdir -p /usr/share/wayland-sessions

# Inject desktop entry for Niri (so Ly can detect it)
cat << 'EOF' | sudo tee /usr/share/wayland-sessions/niri.desktop
[Desktop Entry]
Name=Niri
Exec=niri-session
Type=Application
EOF

# Scaffold configurations directories
mkdir -p ~/.config/niri/dms
```

### Step 3: Starting the Session

You can launch your desktop environment in one of two ways:

1. **Via the Ly Display Manager (Recommended):**
   Simply reboot your system:
   ```bash
   sudo reboot
   ```
   Upon boot, the Ly TUI login manager will appear. Enter your credentials, select **Niri** as the session (use the arrow keys to navigate), and login.

2. **Manual Launch from TTY (Alternative):**
   If you want to launch Niri directly from your current terminal session without rebooting:
   ```bash
   niri-session
   ```

---

## Dotfiles Symlinking

Run this block to link the non-legacy configurations from your repository to your `~/.config` directory. It safely handles pre-existing files by backing them up to `<folder>.bak` before creating the symlinks.

```bash
# Ensure ~/.config exists
mkdir -p ~/.config

# Symlink active configuration folders from the repository (excluding legacy fuzzel, waybar, vicinae)
for folder in niri noctalia gtk-3.0 gtk-4.0 qt5ct qt6ct; do
    if [ -e ~/.config/"$folder" ] && [ ! -L ~/.config/"$folder" ]; then
        echo "Backing up existing ~/.config/$folder to ~/.config/${folder}.bak"
        mv ~/.config/"$folder" ~/.config/"$folder".bak
    elif [ -L ~/.config/"$folder" ]; then
        rm -rf ~/.config/"$folder"
    fi
    ln -sf ~/dotfiles/.config/"$folder" ~/.config/"$folder"
done

# Ensure local state directory for Noctalia overrides exists
mkdir -p ~/.local/state/noctalia

# Symlink Noctalia GUI override settings to keep them synced in the repo
if [ -e ~/.local/state/noctalia/settings.toml ] && [ ! -L ~/.local/state/noctalia/settings.toml ]; then
    echo "Backing up existing ~/.local/state/noctalia/settings.toml to ~/.local/state/noctalia/settings.toml.bak"
    mv ~/.local/state/noctalia/settings.toml ~/.local/state/noctalia/settings.toml.bak
elif [ -L ~/.local/state/noctalia/settings.toml ]; then
    rm -f ~/.local/state/noctalia/settings.toml
fi
ln -sf ~/dotfiles/.config/noctalia/settings.toml ~/.local/state/noctalia/settings.toml

# Install WhiteSur icon theme locally if not already present (needed for macOS folders & extensions)
if [ ! -d ~/.local/share/icons/WhiteSur ]; then
    echo "Installing WhiteSur icon theme..."
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
    /tmp/WhiteSur-icon-theme/install.sh
    rm -rf /tmp/WhiteSur-icon-theme
fi

# Set GTK icon theme to breeze-noctalia (so Nautilus uses our dynamic folders & extensions)
gsettings set org.gnome.desktop.interface icon-theme 'breeze-noctalia'

# Make hook script executable and initialize the dynamic folder icons theme
chmod +x ~/dotfiles/.config/noctalia/colors_changed.sh
~/dotfiles/.config/noctalia/colors_changed.sh
```

---

## Building Patched Niri with Liquid Glass/Refraction Effects

This setup supports a custom patch that ports the Liquid Glass / Refraction effects to the Niri window manager (specifically tested on commit `0777769e719b7c9b7c980d4ea66288bfbb4da5b3`).

### Option 1: Automatic Arch Linux Package (Recommended)

To compile and package it into an installable `.pkg.tar.zst` package replacing the standard `niri` repository package:

```bash
# Go to the package directory
cd ~/dotfiles/experimental/niri-glass-pkgbuild

# Compile, package and install
makepkg -si
```

---

### Option 2: Manual Clone, Patch, and Build

If you want to manually set up the source tree and apply the patch:

1. **Clone Niri and checkout the target commit**:
   ```bash
   git clone https://github.com/niri-wm/niri.git
   cd niri
   git checkout 0777769e719b7c9b7c980d4ea66288bfbb4da5b3
   ```

2. **Apply the patch**:
   ```bash
   git apply ~/dotfiles/experimental/liquid-glass.patch
   ```

3. **Build the release binary**:
   ```bash
   cargo build --release
   ```

---

## Toggling Liquid Glass Configuration

You can easily switch between standard rendering (stock Niri) and the Liquid Glass effect.

The active configuration remains at `~/.config/niri/` (symlinked from `~/dotfiles/.config/niri/`). The repository contains two reference configurations:
- `~/dotfiles/stock_niri/`: Duplicate copy of original configuration files.
- `~/dotfiles/glass_niri/`: Modified version containing the `liquid-glass` refraction blocks.

To toggle back and forth between standard and glass modes, run:

```bash
~/dotfiles/toggle-glass.sh
```

This will copy the files from the selected mode into your active `~/.config/niri` folder and trigger an automatic configuration reload.
