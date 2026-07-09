#!/usr/bin/env python3
"""Sync theme colors from noctalia.colors to kdeglobals and dynamically recolor GTK folder icons."""

import configparser
import os
import re
import sys
import time
import shutil
from pathlib import Path
from subprocess import run

def adjust_brightness(hex_color, factor):
    hex_color = hex_color.lstrip('#')
    rgb = [int(hex_color[i:i+2], 16) for i in (0, 2, 4)]
    new_rgb = [max(0, min(255, int(c * factor))) for c in rgb]
    return '#{:02x}{:02x}{:02x}'.format(*new_rgb)

def update_icon_theme(accent_rgb_str):
    try:
        # Parse RGB and convert to Hex
        rgb = [int(x.strip()) for x in accent_rgb_str.split(',')]
        accent_hex = '#{:02x}{:02x}{:02x}'.format(*rgb)
    except Exception as e:
        print(f"Error parsing accent RGB string '{accent_rgb_str}': {e}", file=sys.stderr)
        return

    src_base = Path('~/.local/share/icons/WhiteSur').expanduser()
    dst_base = Path('~/.local/share/icons/breeze-noctalia').expanduser()

    # 1. Create index.theme
    dst_base.mkdir(parents=True, exist_ok=True)
    index_path = dst_base / 'index.theme'
    
    # We list both mimes and mimetypes in directories to ensure maximum compatibility
    index_content = """[Icon Theme]
Name=Breeze Noctalia
Comment=Dynamic macOS folders & extensions for Noctalia with Breeze fallbacks
Inherits=breeze,breeze-dark,hicolor
Directories=places/16,places/22,places/24,places/scalable,places/symbolic,mimes/16,mimes/22,mimes/scalable,mimes/symbolic,mimetypes/16,mimetypes/22,mimetypes/scalable,mimetypes/symbolic

[places/16]
Size=16
Context=Places
Type=Fixed

[places/22]
Size=22
Context=Places
Type=Fixed

[places/24]
Size=24
Context=Places
Type=Fixed

[places/scalable]
Size=256
MinSize=16
MaxSize=512
Context=Places
Type=Scalable

[places/symbolic]
Size=16
Context=Places
MinSize=16
MaxSize=512
Type=Scalable

[mimes/16]
Size=16
Context=Mimetypes
Type=Fixed

[mimes/22]
Size=22
Context=Mimetypes
Type=Fixed

[mimes/scalable]
Size=256
MinSize=16
MaxSize=512
Context=Mimetypes
Type=Scalable

[mimes/symbolic]
Size=16
Context=Mimetypes
MinSize=16
MaxSize=512
Type=Scalable

[mimetypes/16]
Size=16
Context=Mimetypes
Type=Fixed

[mimetypes/22]
Size=22
Context=Mimetypes
Type=Fixed

[mimetypes/scalable]
Size=256
MinSize=16
MaxSize=512
Context=Mimetypes
Type=Scalable

[mimetypes/symbolic]
Size=16
Context=Mimetypes
MinSize=16
MaxSize=512
Type=Scalable
"""
    with open(index_path, 'w') as f:
        f.write(index_content)

    # 2. Copy and recolor places folders
    places_src = src_base / 'places'
    places_dst = dst_base / 'places'

    # Clear existing places directory to prevent stale links
    if places_dst.exists():
        shutil.rmtree(places_dst)

    if not places_src.exists():
        print(f"Warning: {places_src} does not exist. Cannot recolor folders.", file=sys.stderr)
        return

    # Dynamic variations of the accent color for macOS styled folder gradients
    c_base = accent_hex
    c_grad_start = adjust_brightness(accent_hex, 1.1)
    c_grad_end = adjust_brightness(accent_hex, 1.25)
    c_shadow = adjust_brightness(accent_hex, 0.6)

    # Compile replacement regexes
    replacements = {
        r'#46a2d7': c_base,
        r'#60c0f0': c_grad_start,
        r'#83d4fb': c_grad_end,
        r'#008ea2': c_shadow
    }

    def replace_colors(text):
        for orig, new in replacements.items():
            text = re.sub(orig, new, text, flags=re.IGNORECASE)
        return text

    places_count = 0
    for root, dirs, files in os.walk(places_src):
        rel_path = Path(root).relative_to(places_src)
        for file in files:
            src_file = Path(root) / file
            dst_dir = places_dst / rel_path
            dst_dir.mkdir(parents=True, exist_ok=True)
            dst_file = dst_dir / file

            # If it's a symlink
            if src_file.is_symlink():
                target = os.readlink(src_file)
                if dst_file.exists() or dst_file.is_symlink():
                    dst_file.unlink()
                os.symlink(target, dst_file)
            else:
                if file.endswith('.svg') and file.startswith('folder'):
                    with open(src_file, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                    modified = replace_colors(content)
                    if dst_file.exists() or dst_file.is_symlink():
                        dst_file.unlink()
                    with open(dst_file, 'w', encoding='utf-8') as f:
                        f.write(modified)
                else:
                    if dst_file.exists() or dst_file.is_symlink():
                        dst_file.unlink()
                    shutil.copy2(src_file, dst_file)
                places_count += 1

    # 3. Copy mimes (mimetypes) to both mimes and mimetypes directories
    mimes_src = src_base / 'mimes'
    mimes_dst = dst_base / 'mimes'
    mimetypes_dst = dst_base / 'mimetypes'

    if mimes_src.exists():
        # Clear existing mimes/mimetypes directories to avoid stale icons
        if mimes_dst.exists():
            shutil.rmtree(mimes_dst)
        if mimetypes_dst.exists():
            shutil.rmtree(mimetypes_dst)

        # Copy directory tree
        shutil.copytree(mimes_src, mimes_dst, symlinks=True)
        # Duplicate to mimetypes to ensure compatibility with GTK's fallback lookups
        shutil.copytree(mimes_src, mimetypes_dst, symlinks=True)

    # 4. Update GTK icon cache
    run(['gtk-update-icon-cache', '-q', '-f', str(dst_base)], capture_output=True)
    print(f"Successfully generated {places_count} macOS folder icons with accent {accent_hex}")

    # 5. Force running GTK applications (like Nautilus) to reload the icon theme
    try:
        res = run(['gsettings', 'get', 'org.gnome.desktop.interface', 'icon-theme'], capture_output=True, text=True)
        current_theme = res.stdout.strip().strip("'")
        if current_theme:
            temp_theme = 'Adwaita' if current_theme != 'Adwaita' else 'hicolor'
            run(['gsettings', 'set', 'org.gnome.desktop.interface', 'icon-theme', temp_theme], capture_output=True)
            time.sleep(0.1)
            run(['gsettings', 'set', 'org.gnome.desktop.interface', 'icon-theme', current_theme], capture_output=True)
    except Exception as e:
        print(f"Warning: Failed to toggle icon-theme to reload cache: {e}", file=sys.stderr)

def main():
    # Sleep to ensure Noctalia has finished writing templates to disk
    time.sleep(1.0)
    scheme_path = Path('~/.local/share/color-schemes/noctalia.colors').expanduser()
    kglobals_path = Path('~/.config/kdeglobals').expanduser()

    if not scheme_path.exists():
        print("Noctalia color scheme not generated yet. Dynamic folders will be initialized on first startup.")
        sys.exit(0)

    # Read the generated color scheme
    scheme = configparser.RawConfigParser()
    scheme.optionxform = lambda option: option
    scheme.read(scheme_path)

    if not scheme.has_section('Colors:Selection') or not scheme.has_option('Colors:Selection', 'BackgroundNormal'):
        print("Error: Could not find Selection BackgroundNormal in color scheme", file=sys.stderr)
        sys.exit(1)

    accent_color = scheme.get('Colors:Selection', 'BackgroundNormal')

    # Read and update kdeglobals
    kglobals = configparser.RawConfigParser()
    kglobals.optionxform = lambda option: option
    if kglobals_path.exists():
        kglobals.read(kglobals_path)

    if not kglobals.has_section('General'):
        kglobals.add_section('General')

    kglobals.set('General', 'AccentColor', accent_color)
    kglobals.set('General', 'accentColorFromWallpaper', 'false')

    with open(kglobals_path, 'w') as f:
        kglobals.write(f, space_around_delimiters=False)

    print(f"Successfully updated kdeglobals AccentColor to {accent_color}")

    # Generate custom icons theme for GTK / Nautilus
    update_icon_theme(accent_color)

    # Notify running applications if dbus is available
    try:
        run((
            'dbus-send',
            '/KGlobalSettings',
            'org.kde.KGlobalSettings.notifyChange',
            'int32:0',
            'int32:0',
        ), start_new_session=True, capture_output=True)
    except Exception:
        pass

if __name__ == '__main__':
    main()
