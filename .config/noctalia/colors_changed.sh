#!/usr/bin/env python3
"""Sync theme colors from noctalia.colors to kdeglobals."""

import configparser
import os
import sys
import time
from pathlib import Path

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

    # Notify running KDE applications if dbus is available
    try:
        from subprocess import run
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
