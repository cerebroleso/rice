# Niri Desktop Environment Configuration with Noctalia

## 1. Underlying Utilities & Background Services

*   **niri**: Core Wayland compositor.
*   **xwayland-satellite**: Rootless X11 compatibility bridge.
*   **hyprpolkitagent**: PolicyKit authentication agent.
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
  hyprland-qt-support-git hyprpolkitagent-git nirimod-git playerctl noctalia-git ly

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
for folder in niri noctalia gtk-3.0 gtk-4.0; do
    if [ -e ~/.config/"$folder" ] && [ ! -L ~/.config/"$folder" ]; then
        echo "Backing up existing ~/.config/$folder to ~/.config/${folder}.bak"
        mv ~/.config/"$folder" ~/.config/"$folder".bak
    elif [ -L ~/.config/"$folder" ]; then
        rm -rf ~/.config/"$folder"
    fi
    ln -sf ~/dotfiles/.config/"$folder" ~/.config/"$folder"
done
```

---

## Configuration Files

Below are the configurations matching the active system settings.

### 1. Main Niri Config (`~/.config/niri/config.kdl`)
```kdl
// ==================================================
// Startup applications (User's configuration)
// ==================================================
spawn-at-startup "xwayland-satellite"
spawn-at-startup "hyprpolkitagent"
spawn-at-startup "nm-applet"
spawn-at-startup "blueman-applet"
spawn-at-startup "noctalia" "--daemon"
spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

// ==================================================
// General (Aesthetic customization)
// ==================================================
config-notification {
    disable-failed
}

prefer-no-csd

// ==================================================
// Input (User's keyboard/touchpad settings)
// ==================================================
input {
    focus-follows-mouse max-scroll-amount="33%"

    keyboard {
        repeat-delay 200
        repeat-rate 50
    }
    touchpad {
        natural-scroll
        tap
        accel-speed 1.0
        accel-profile "flat"
    }
    mouse
}

hotkey-overlay {
    skip-at-startup
    hide-not-bound
}

// ==================================================
// Outputs (Monitors) (User's monitor settings)
// ==================================================
output "eDP-1" {
    mode "1920x1080@144.003"
    scale 1.0
    transform "normal"
    position x=0 y=0
}

// ==================================================
// Layout & Visuals (Aesthetic customization)
// ==================================================
layout {
    gaps 12
    center-focused-column "on-overflow"
    background-color "transparent"
    always-center-single-column
    default-column-width { proportion 0.5; }

    preset-column-widths {
        proportion 0.3
        proportion 0.5
        proportion 0.7
        proportion 1.0
    }
    preset-window-heights {
        proportion 0.34
        proportion 0.5
        proportion 0.67
        proportion 1.0
    }

    focus-ring {
        width 2
        inactive-color "#505050"
        active-gradient from="#6ea1f2" to="#89b4fa" angle=45
    }

    struts {
        left 2
        right 2
        top 2
        bottom 2
    }

    tab-indicator {
        hide-when-single-tab
        place-within-column
        gap 5
        width 4
        length total-proportion=1.0
        position "right"
        gaps-between-tabs 2
        corner-radius 8
        active-color "red"
        inactive-color "gray"
        urgent-color "blue"
    }

    shadow {
        on
        draw-behind-window true
        softness 30
        spread 5
        offset x=0 y=5
        color "#0007"
    }
}

overview {
    workspace-shadow {
        off
    }
}

environment {
    XDG_CURRENT_DESKTOP "niri"
    QT_QPA_PLATFORMTHEME "gtk3"
    QT_QPA_PLATFORMTHEME_QT6 "gtk3"
}

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

animations {
    workspace-switch {
        spring damping-ratio=0.80 stiffness=523 epsilon=0.0001
    }

    window-open {
        duration-ms 150
        curve "ease-out-expo"
    }

    window-close {
        duration-ms 150
        curve "ease-out-quad"
    }

    horizontal-view-movement {
        spring damping-ratio=0.85 stiffness=423 epsilon=0.0001
    }

    window-movement {
        spring damping-ratio=0.75 stiffness=323 epsilon=0.0001
    }

    window-resize {
        spring damping-ratio=0.85 stiffness=423 epsilon=0.0001
    }

    config-notification-open-close {
        spring damping-ratio=0.65 stiffness=923 epsilon=0.001
    }

    screenshot-ui-open {
        duration-ms 200
        curve "ease-out-quad"
    }

    overview-open-close {
        spring damping-ratio=0.85 stiffness=800 epsilon=0.0001
    }
}

// ==================================================
// Window Rules (Aesthetic customization)
// ==================================================
window-rule {
    match app-id="org.gnome.Nautilus"
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 0.9
    }
}

window-rule {
    match app-id="btrfs-assistant"
    open-floating true
    default-column-width { proportion 0.35; }
    default-window-height { fixed 500; }
}

window-rule {
    match app-id="org.quickshell"
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    match app-id="brave-browser"
    default-column-width { proportion 0.7; }
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    match app-id="firefox"
    default-column-width { proportion 0.7; }
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    match app-id="kitty"
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    match app-id="zed"
    default-column-width { proportion 0.7; }
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    match app-id="spotify"
    default-column-width { proportion 0.7; }
    opacity 0.75
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

window-rule {
    geometry-corner-radius 10
    clip-to-geometry true
    opacity 0.85
    draw-border-with-background false
    background-effect {
        xray true
        blur true
    }
    popups {
        opacity 1.0
    }
}

layer-rule {
    match namespace="^launcher$"
    geometry-corner-radius 10
    background-effect {
        xray false
        blur true
    }
}

// ==================================================
// Recent Windows
// ==================================================
recent-windows {
    debounce-ms 500
    open-delay-ms 100

    highlight {
        active-color "#8aadf4ff"
        urgent-color "#ed8796ff"
        padding 8
        corner-radius 4
    }

    previews {
        max-height 500
        max-scale 0.5
    }
}

// ==================================================
// Fixed Workspaces
// ==================================================
workspace "1"
workspace "2"

// ==================================================
// External Includes
// ==================================================
include "dms/binds.kdl"
include "dms/windowrules.kdl"
include "dms/cursor.kdl"
include "dms/outputs.kdl"
include "window_rules.kdl"

include "noctalia.kdl"
```

### 2. Niri Keybindings (`~/.config/niri/dms/binds.kdl`)
```kdl
binds {
    Mod+T { spawn "kitty"; }
    Mod+B { spawn "helium-browser"; }
    Mod+D { spawn "zed"; }
    Mod+E { spawn-sh "kitty yazi"; }
    Mod+Shift+E { spawn "nautilus"; }
    Mod+Shift+R { spawn "bash" "-c" "niri msg action load-config-file && notify-send -e -a 'Niri' -i 'preferences-desktop' 'Niri Configuration' 'Reloaded successfully'"; }

    // Noctalia UI Trigger
    Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
    Mod+V { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
    Mod+N { spawn "noctalia" "msg" "notifications" "toggleHistory"; }

    XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioPause allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
    XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }

    // Volume & Brightness keys routed to Noctalia OSD
    XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }
    XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
    XF86AudioMicMute allow-when-locked=true { spawn "noctalia" "msg" "mic-mute"; }
    XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia" "msg" "brightness-up"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia" "msg" "brightness-down"; }

    Mod+P { spawn "bash" "-c" "grim -g \"$(slurp -c '#00000040')\" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/satty-$(date '+%Y%m%d-%H%M%S').png"; }
    Mod+Ctrl+P { spawn "bash" "-c" "grim -g \"$(slurp -c '#00000040')\" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/satty-$(date '+%Y%m%d-%H%M%S').png"; }

    Mod+Q { close-window; }
    Mod+S { switch-preset-column-width; }
    Mod+M { maximize-column; }
    Mod+F { fullscreen-window; }

    Alt+Tab { focus-window-previous; }

    Mod+Left { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Ctrl+Left { focus-column-left; }
    Mod+Ctrl+Right { focus-column-right; }

    Mod+Shift+Left { move-column-left; }
    Mod+Shift+Right { move-column-right; }

    Mod+Ctrl+Up { focus-workspace-up; }
    Mod+Ctrl+Down { focus-workspace-down; }
    Mod+Shift+Up { move-window-to-workspace-up; }
    Mod+Shift+Down { move-window-to-workspace-down; }
}
```

### 3. Extra Window Rules (`~/.config/niri/window_rules.kdl`)
```kdl
// Layer rules
layer-rule {
  match namespace="ashell-menu-layer"
  background-effect {
    blur true
    xray false
  }
}

// Window rules
window-rule {
  match app-id="Spotify"
  opacity 0.9
  background-effect {
    blur true
  }
}

window-rule {
  match app-id="signal beta"
  default-column-width { proportion 0.25;}
  default-window-height { proportion 0.65;}
  open-floating true
  default-floating-position x=550 y=250 relative-to="top-left"
  opacity 0.9
  background-effect {
    blur true
    xray false
  }
}

window-rule {
  match title="senpai"
  open-floating true
  default-floating-position x=1300 y=250 relative-to="top-left"
  min-height 850
  min-width 750
  opacity 0.9
  background-effect {
    blur true
  }
}

window-rule {
  match app-id="zen"
  open-on-workspace "browsers"
  open-maximized true
}

window-rule {
  match app-id="gimp"
  open-on-workspace "editing"
  open-maximized true
}

window-rule {
  match app-id="foot"
  match app-id="obsidian"
  opacity 0.9
  background-effect {
    blur true
  }
}

window-rule {
  match app-id="positron"
  match app-id="anki"
  draw-border-with-background false
  opacity 0.9
  background-effect {
    blur true
  }
}
```

### 4. Niri Noctalia Styles Override (`~/.config/niri/noctalia.kdl`)
```kdl
layout {
    focus-ring {
        active-color   "#d0c5b2"
        inactive-color "#141312"
        urgent-color   "#ffb4ab"
    }

    border {
        active-color   "#d0c5b2"
        inactive-color "#141312"
        urgent-color   "#ffb4ab"
    }

    shadow {
        color "#00000070"
    }

    tab-indicator {
        active-color   "#d0c5b2"
        inactive-color "#433c2e"
        urgent-color   "#ffb4ab"
    }

    insert-hint {
        color "#d0c5b280"
    }
}

recent-windows {
    highlight {
        active-color "#d0c5b2"
        urgent-color "#ffb4ab"
    }
}
```
