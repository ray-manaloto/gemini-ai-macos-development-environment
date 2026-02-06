#!/usr/bin/env python3
"""Generate macOS menu bar tray icon for DevEnvManager-Tauri.

Creates a distinctive terminal/code icon that works as a macOS template icon.
Template icons should be black shapes on transparent background - macOS will
automatically invert them for light/dark mode.
"""

from PIL import Image, ImageDraw
import sys


def create_tray_icon(size: int, output_path: str):
    """Create a terminal prompt icon with chevron/bracket design.

    Args:
        size: Icon size in pixels (22 for 1x, 44 for 2x)
        output_path: Where to save the PNG file
    """
    # Create transparent image
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Calculate dimensions based on size
    padding = size // 8
    line_width = max(2, size // 11)

    # Draw terminal window outline (rounded rectangle)
    outline_rect = [padding, padding, size - padding, size - padding]
    draw.rounded_rectangle(
        outline_rect, radius=size // 8, outline=(0, 0, 0, 255), width=line_width
    )

    # Draw terminal prompt chevron (>)
    chevron_start_x = padding + size // 6
    chevron_y = size // 2
    chevron_size = size // 4

    # Chevron as two lines forming >
    draw.line(
        [
            (chevron_start_x, chevron_y - chevron_size // 2),
            (chevron_start_x + chevron_size, chevron_y),
        ],
        fill=(0, 0, 0, 255),
        width=line_width,
    )
    draw.line(
        [
            (chevron_start_x + chevron_size, chevron_y),
            (chevron_start_x, chevron_y + chevron_size // 2),
        ],
        fill=(0, 0, 0, 255),
        width=line_width,
    )

    # Draw cursor underscore after chevron
    cursor_x = chevron_start_x + chevron_size + size // 12
    cursor_y = chevron_y + chevron_size // 3
    cursor_width = size // 5

    draw.line(
        [(cursor_x, cursor_y), (cursor_x + cursor_width, cursor_y)],
        fill=(0, 0, 0, 255),
        width=line_width,
    )

    # Save with optimization
    img.save(output_path, "PNG", optimize=True)
    print(f"✓ Created {output_path} ({size}x{size})")


def main():
    """Generate both 1x and 2x tray icons."""
    import os

    # Get the icons directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Generate 1x icon (22x22 for macOS menu bar)
    create_tray_icon(22, os.path.join(script_dir, "tray-icon.png"))

    # Generate 2x icon (44x44 for Retina displays)
    create_tray_icon(44, os.path.join(script_dir, "tray-icon@2x.png"))

    print("\n✓ Tray icons generated successfully!")
    print("  These are macOS template icons (black on transparent)")
    print("  macOS will automatically invert them for light/dark mode")


if __name__ == "__main__":
    try:
        main()
    except ImportError as e:
        print(f"Error: {e}", file=sys.stderr)
        print("\nInstall Pillow with: pip install pillow", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
