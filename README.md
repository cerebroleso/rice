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
*   **pcmanfm-qt**: Qt-based lightweight file manager (handling desktop icons and files).
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
*   **niri-display-manager**: PySide6/QML graphical monitor layout and settings manager.
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
  ttf-jetbrains-mono-nerd noto-fonts nautilus dolphin pcmanfm-qt file-roller zip unzip p7zip \
  unrar yazi kitty zed helium-browser-bin google-chrome discord pwvucontrol \
  network-manager-applet blueman grim slurp satty hyprutils-git hyprlang-git \
  hyprwayland-scanner-git aquamarine-git hyprgraphics-git hyprtoolkit-git \
  nirimod-git niri-display-manager playerctl noctalia-git ly

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
for folder in niri noctalia gtk-3.0 gtk-4.0 qt5ct qt6ct pcmanfm-qt; do
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

---

## Keyboard Shortcuts (Keybinds)

The following tables document the keyboard shortcuts configured in [binds.kdl](file:///home/chri/dotfiles/stock_niri/dms/binds.kdl).

### Core Applications
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Ctrl+Alt+T` | `spawn "kitty"` | Launch Kitty terminal |
| `Mod+T` | `spawn "kitty"` | Launch Kitty terminal |
| `Mod+B` | `spawn "helium-browser"` | Launch Helium browser |
| `Mod+D` | `spawn "zed"` | Launch Zed code editor |
| `Mod+E` | `spawn "nautilus"` | Launch Nautilus file manager |
| `Mod+Shift+E` | `spawn-sh "kitty yazi"` | Launch Yazi terminal file manager in Kitty |

### Window Management
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Mod+Q` | `close-window` | Close the focused window |
| `Mod+Shift+Q` | `quit skip-confirmation=true` | Exit Niri session |
| `Mod+S` | `switch-preset-column-width` | Cycle column width presets |
| `Mod+M` | `maximize-column` | Toggle maximization of current column |
| `Mod+F` | `fullscreen-window` | Toggle fullscreen on current window |
| `Alt+Tab` | `focus-window-previous` | Focus previous window |
| `Mod+Left` | `move-column-left; set-column-width 50%` | Move column left and set width to 50% |
| `Mod+Right` | `move-column-right; set-column-width 50%` | Move column right and set width to 50% |
| `Mod+Up` | `move-window-up; set-window-height 50%` | Move window up and set height to 50% |
| `Mod+Down` | `move-window-down; set-window-height 50%` | Move window down and set height to 50% |
| `Mod+Ctrl+Left` | `focus-column-left` | Focus column to the left |
| `Mod+Ctrl+Right` | `focus-column-right` | Focus column to the right |
| `Mod+Shift+Left` | `move-column-left` | Move column left |
| `Mod+Shift+Right` | `move-column-right` | Move column right |

### Workspace Navigation
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Mod+Ctrl+Up` | `focus-workspace-up` | Focus adjacent workspace up |
| `Mod+Ctrl+Down` | `focus-workspace-down` | Focus adjacent workspace down |
| `Mod+Shift+Up` | `move-window-to-workspace-up` | Move window to workspace up |
| `Mod+Shift+Down` | `move-window-to-workspace-down` | Move window to workspace down |

### Desktop Shell & System Utilities
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `Mod+Space` | `noctalia msg panel-toggle launcher` | Toggle Noctalia Application Launcher |
| `Mod+V` | `noctalia msg panel-toggle clipboard` | Toggle Noctalia Clipboard History |
| `Mod+N` | `noctalia msg notifications toggleHistory` | Toggle Notification History panel |
| `Mod+Shift+R` | Niri config reload | Reload Niri configuration and notify |
| `Mod+Shift+G` | `toggle-glass.sh` | Toggle Niri Liquid Glass/Refraction mode |
| `Mod+Shift+D` | `toggle-pcmanfm.sh` | Toggle desktop files/icons visibility |
| `Mod+P` / `Mod+Shift+S` / `Mod+Ctrl+P` | Take Screenshot | Capture area/screen and edit in Satty |

### Media & Hardware Controls
| Keybind | Command / Action | Description |
| :--- | :--- | :--- |
| `XF86AudioPlay` / `Pause` | `playerctl play-pause` | Play/Pause media |
| `XF86AudioNext` | `playerctl next` | Next media track |
| `XF86AudioPrev` | `playerctl previous` | Previous media track |
| `XF86AudioRaiseVolume` | `noctalia msg volume-up` | Raise audio volume |
| `XF86AudioLowerVolume` | `noctalia msg volume-down` | Lower audio volume |
| `XF86AudioMute` | `noctalia msg volume-mute` | Mute/unmute audio |
| `XF86AudioMicMute` | `noctalia msg mic-mute` | Mute/unmute microphone |
| `XF86MonBrightnessUp` | `noctalia msg brightness-up` | Increase screen brightness |
| `XF86MonBrightnessDown` | `noctalia msg brightness-down` | Decrease screen brightness |

---

## Memory Footprint & Performance

Below is an analysis of the desktop suite's memory footprint under two setups: the **Full Glass Suite** (Niri Glass + Noctalia + PCManFM-Qt) and the **Minimal Stock Suite** (Niri Stock + Noctalia, without PCManFM-Qt), and how they measure up against other Wayland desktop setups.

### 1. Real-Time Resource Breakdown

These are live metrics showing the resident set size (RSS) memory footprint of the desktop components:

#### Core Components

| Process / Component | Role / Command | RSS Memory (Full Glass) | RSS Memory (Minimal / Stock) |
| :--- | :--- | :--- | :--- |
| **Niri** | Window Manager + Compositor | **175.1 MB** (179,344 KB) | **151.4 MB** (155,044 KB) |
| **Noctalia** | Shell (Bar, Dock, Launcher, Notifier) | **180.3 MB** (184,660 KB) | **180.4 MB** (184,720 KB) |
| **PCManFM-Qt** | Desktop file manager / icons | **118.1 MB** (120,952 KB) | **0.0 MB** *(Disabled)* |
| **XWayland Satellite** | XWayland compatibility layer | **10.6 MB** (10,876 KB) | **10.6 MB** (10,876 KB) |
| **Total Core Components** | **Active base workspace footprint** | **~488.3 MB** | **~342.4 MB** |

### 2. The Cascading Memory Profile (Butterfly Effect)

Toggling off features dynamically slashes memory consumption. Here is the step-by-step modular memory breakdown:

```
[Full Suite: Niri Glass + Noctalia + PCManFM-Qt]  ---> 488.3 MB
                      │
                      ▼
         Disable PCManFM-Qt Desktop
         (Toggled via Mod+Shift+D)              ---> Saves 118.1 MB
                      │
                      ▼
[Subtotal: Niri Glass + Noctalia (No Icons)]     ---> 370.2 MB
                      │
                      ▼
         Disable Liquid Glass (Standard Niri)
         (Toggled via Mod+Shift+G)              ---> Saves 23.7 MB
                      │
                      ▼
[Minimal Suite: Niri Stock + Noctalia]           ---> 342.4 MB (Total Saved: 145.9 MB!)
```

*   **PCManFM-Qt Suspension:** Disabling the desktop icons immediately unloads the Qt6-based manager, recovering **118.1 MB** of RAM.
*   **Compositor Shader Reduction:** Disabling the Liquid Glass refraction shader (switching to standard window borders) drops the compositor footprint by **23.7 MB** by cleaning up the active graphics pipeline, glow/fringing textures, and screen-behind buffers.

### 3. Comparison with Other Environments

Here is how these setups compare to other popular desktop choices on clean boot:

| Environment | Compositor | Panels / Bars | Launcher & Services | Desktop Manager | Total Startup RSS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **The Suite (Minimal / Stock)** | **Niri Stock** (~151MB) | **Noctalia** (~180MB) | Included in Noctalia | None (No icons) | **~342 MB** |
| **The Suite (Full Glass)** | **Niri Glass** (~175MB) | **Noctalia** (~180MB) | Included in Noctalia | **PCManFM-Qt** (~118MB) | **~488 MB** |
| **Sway Minimal** | Sway (~60MB) | Waybar (~55MB) | Fuzzel + Mako (~35MB) | None (No icons) | **~150 MB** |
| **Hyprland Modular** | Hyprland (~90MB) | Waybar (~60MB) | Rofi + Dunst + Swbg (~95MB) | None (No icons) | **~245 MB** |
| **KDE Plasma 6** | KWin (~120MB) | Plasmashell (~300MB) | KRunner + Daemons (~180MB) | Desktop Icons (~100MB) | **~700 MB** |
| **GNOME 46** | Mutter (~150MB) | GNOME Shell (~400MB) | Included in Shell | Extensions (~80MB) | **~630 MB - 900 MB** |

### 4. Design & Performance Insights

#### Why Noctalia is Incredibly Efficient
In a typical modular window manager configuration, multiple separate daemons are executed (e.g. Waybar + SwayNC + Fuzzel + SwayOSD + SWWW + Dock apps). This results in duplicated systemd tasks and repeated copying of Qt/GTK shared libraries in RAM.
By rolling these tools into a single, cohesive binary, **Noctalia** minimizes context switching, shares a single memory pool, and maps standard libraries only once. This saves roughly **80 MB to 150 MB** of system overhead while providing a seamless, unified shell.

#### The Cost of "Glass"
Running **Liquid Glass** in Niri requires real-time computations for background refraction, adaptive dimming, borders, glows, and fringing. These shaders force the compositor to retain additional window-behind texture buffers in GPU/CPU RAM, which is why Niri Glass uses **23.7 MB** more than the stock configuration.


