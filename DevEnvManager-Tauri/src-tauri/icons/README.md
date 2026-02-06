# DevEnvManager-Tauri Icons

## Tray Icon

The menu bar tray icon (`tray-icon.png` and `tray-icon@2x.png`) is a **macOS template icon** featuring a terminal prompt design with a chevron (`>`) and cursor.

### Design Specifications

- **Size**: 22x22 pixels (1x), 44x44 pixels (2x for Retina)
- **Format**: PNG with transparency
- **Color**: Black shapes on transparent background
- **Style**: Terminal window outline with prompt chevron and cursor

### macOS Template Icon Behavior

Template icons are automatically inverted by macOS:
- **Light mode**: Black icon appears dark
- **Dark mode**: Icon is inverted to white

This is controlled by the `icon_as_template(true)` setting in `src/tray.rs`.

### Regenerating Icons

To regenerate the tray icons:

```bash
cd DevEnvManager-Tauri/src-tauri/icons
python3 -m pip install pillow
python3 generate_tray_icon.py
```

This will create:
- `tray-icon.png` (22x22)
- `tray-icon@2x.png` (44x44)

### Design Rationale

The terminal prompt icon was chosen because:
1. **Distinctive**: Stands out in the menu bar
2. **Recognizable**: Immediately conveys "development/terminal" concept
3. **Scalable**: Works well at small menu bar sizes (22x22)
4. **Professional**: Clean, geometric design

### Other Icons

- `icon.png` / `icon@2x.png` - App icon (legacy, not used for tray)
- `icon.icns` - macOS app bundle icon

## Modifying the Icon

To change the tray icon design:

1. Edit `generate_tray_icon.py` to modify the drawing code
2. Run the script to regenerate PNGs
3. The Rust code in `src/tray.rs` will automatically use the new icon

Key design constraints:
- Keep shapes bold and simple (works better at small sizes)
- Use solid black (#000000) for all shapes
- Maintain transparency for background
- Test in both light and dark mode
