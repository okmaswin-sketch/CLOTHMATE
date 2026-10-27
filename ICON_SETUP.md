# App Icon Generation Instructions

## Quick Setup

The app icon SVGs have been created at:
- `assets/icon/app_icon.svg` — Full icon with background (512x512)
- `assets/icon/app_icon_foreground.svg` — Hanger only for adaptive icon (512x512)

## Convert SVG to PNG

**Option 1: Online (easiest)**
1. Go to https://cloudconvert.com/svg-to-png or https://convertio.co/svg-png/
2. Upload `assets/icon/app_icon.svg` → Download as `assets/icon/app_icon.png` (512x512)
3. Upload `assets/icon/app_icon_foreground.svg` → Download as `assets/icon/app_icon_foreground.png` (512x512)

**Option 2: ImageMagick (if installed)**
```bash
magick assets/icon/app_icon.svg assets/icon/app_icon.png
magick assets/icon/app_icon_foreground.svg assets/icon/app_icon_foreground.png
```

**Option 3: Inkscape (if installed)**
```bash
inkscape assets/icon/app_icon.svg --export-type=png --export-filename=assets/icon/app_icon.png -w 512 -h 512
inkscape assets/icon/app_icon_foreground.svg --export-type=png --export-filename=assets/icon/app_icon_foreground.png -w 512 -h 512
```

## Generate Platform Icons

After placing the PNG files in `assets/icon/`:

```bash
flutter pub run flutter_launcher_icons:main
```

This will generate:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` + adaptive icon
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`

## Verify

```bash
flutter build apk --release
```

The app will now use your custom ClothMate hanger icon.