#!/usr/bin/env python3
"""Sync theme colors from noctalia.colors to kdeglobals and dynamically recolor GTK folder icons."""

import configparser
import os
import re
import sys
import time
from pathlib import Path
from subprocess import run

def update_icon_theme(accent_rgb_str):
    try:
        # Parse RGB and convert to Hex
        rgb = [int(x.strip()) for x in accent_rgb_str.split(',')]
        accent_hex = '#{:02x}{:02x}{:02x}'.format(*rgb)
    except Exception as e:
        print(f"Error parsing accent RGB string '{accent_rgb_str}': {e}", file=sys.stderr)
        return

    src_base = Path('/usr/share/icons/breeze')
    dst_base = Path('~/.local/share/icons/breeze-noctalia').expanduser()

    # 1. Create index.theme
    dst_base.mkdir(parents=True, exist_ok=True)
    index_path = dst_base / 'index.theme'
    index_content = """[Icon Theme]
Name=Breeze Noctalia
Comment=Dynamic Breeze folders for Noctalia
Inherits=breeze,breeze-dark,hicolor
Directories=places/16,places/22,places/32,places/48,places/64,places/128,places/scalable

[places/16]
Size=16
Context=Places
Type=Fixed

[places/22]
Size=22
Context=Places
Type=Fixed

[places/32]
Size=32
Context=Places
Type=Fixed

[places/48]
Size=48
Context=Places
Type=Fixed

[places/64]
Size=64
Context=Places
Type=Fixed

[places/128]
Size=128
Context=Places
Type=Fixed

[places/scalable]
Size=256
MinSize=16
MaxSize=512
Context=Places
Type=Scalable
"""
    with open(index_path, 'w') as f:
        f.write(index_content)

    places_src = src_base / 'places'
    places_dst = dst_base / 'places'

    if not places_src.exists():
        print(f"Warning: {places_src} does not exist. Cannot recolor folders.", file=sys.stderr)
        return

    # Regex to find/replace .ColorScheme-Accent { color: #xxxxxx; }
    accent_regex = re.compile(r'ColorScheme-Accent\s*\{\s*color:\s*#[0-9a-fA-F]{6};?\s*\}')
    new_style_block = f'ColorScheme-Accent {{\n        color:{accent_hex};\n      }}'

    count = 0
    for root, dirs, files in os.walk(places_src):
        rel_path = Path(root).relative_to(places_src)
        for file in files:
            if not file.startswith('folder') or not file.endswith('.svg'):
                continue

            src_file = Path(root) / file
            dst_dir = places_dst / rel_path
            dst_dir.mkdir(parents=True, exist_ok=True)
            dst_file = dst_dir / file

            if src_file.is_symlink():
                target = os.readlink(src_file)
                if dst_file.exists() or dst_file.is_symlink():
                    dst_file.unlink()
                os.symlink(target, dst_file)
            else:
                with open(src_file, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                modified = accent_regex.sub(new_style_block, content)
                with open(dst_file, 'w', encoding='utf-8') as f:
                    f.write(modified)
                count += 1

    # Update GTK icon cache
    run(['gtk-update-icon-cache', '-q', '-f', str(dst_base)], capture_output=True)
    print(f"Successfully generated {count} custom folder icons at {dst_base} with accent {accent_hex}")

def main():
    # Sleep to ensure Noctalia has finished writing templates to disk
    time.sleep(1.0)
    scheme_path = Path('~/.local/share/color-schemes/noctalia.colors').expanduser()
    kglobals_path = Path('~/.config/kdeglobals').expanduser()

    if not scheme_path.exists():
        print(f"Error: {scheme_path} does not exist", file=sys.stderr)
        sys.exit(1)

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
