# Launcher Icons Configuration Guide

## Overview

This guide explains how to properly configure and generate launcher icons for all three flavor variants (Fishfood, Dogfood, and Production).

---

## Prerequisites

- Flutter SDK installed
- `flutter_launcher_icons` package (already in `pubspec.yaml`)
- Source icon images in `assets/icons/` directory:
  - `app_icon_fishfood.png`
  - `app_icon_dogfood.png`
  - `app_icon.png` (production)

**Recommended icon size:** 1024x1024px PNG with transparency

---

## File Structure

```
main/
├── flutter_launcher_icons-fishfood.yaml
├── flutter_launcher_icons-dogfood.yaml
├── flutter_launcher_icons-prod.yaml
├── assets/icons/
│   ├── app_icon_fishfood.png
│   ├── app_icon_dogfood.png
│   └── app_icon.png
└── android/app/src/
    ├── fishfood/res/mipmap-*/
    ├── dogfood/res/mipmap-*/
    └── prod/res/mipmap-*/
```

---

## Configuration Files

### Fishfood (`flutter_launcher_icons-fishfood.yaml`)
```yaml
flutter_launcher_icons:
  image_path: "assets/icons/app_icon_fishfood.png"
  android: true
  ios: true
  remove_alpha_channel_ios: true
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon_fishfood.png"
```

### Dogfood (`flutter_launcher_icons-dogfood.yaml`)
```yaml
flutter_launcher_icons:
  image_path: "assets/icons/app_icon_dogfood.png"
  android: true
  ios: true
  remove_alpha_channel_ios: true
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon_dogfood.png"
```

### Production (`flutter_launcher_icons-prod.yaml`)
```yaml
flutter_launcher_icons:
  image_path: "assets/icons/app_icon.png"
  android: true
  ios: true
  remove_alpha_channel_ios: true
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
```

---

## Step-by-Step Generation

### 1. Ensure Source Images Exist
```bash
ls -la assets/icons/app_icon*.png
```

### 2. Generate Icons for Each Flavor

**Fishfood:**
```bash
dart run flutter_launcher_icons -f flutter_launcher_icons-fishfood.yaml
```

**Dogfood:**
```bash
dart run flutter_launcher_icons -f flutter_launcher_icons-dogfood.yaml
```

**Production:**
```bash
dart run flutter_launcher_icons -f flutter_launcher_icons-prod.yaml
```

**Generate All at Once:**
```bash
dart run flutter_launcher_icons -f flutter_launcher_icons-fishfood.yaml && \
dart run flutter_launcher_icons -f flutter_launcher_icons-dogfood.yaml && \
dart run flutter_launcher_icons -f flutter_launcher_icons-prod.yaml
```

### 3. Optional: Add Custom Inset (Padding)

After generation, if you want to add padding around the icon:

**Edit adaptive icon XML files:**
- `android/app/src/fishfood/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/dogfood/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/prod/res/mipmap-anydpi-v26/ic_launcher.xml`

**Change from:**
```xml
<foreground android:drawable="@drawable/ic_launcher_foreground" />
```

**To (for 4% padding):**
```xml
<foreground>
    <inset
        android:drawable="@drawable/ic_launcher_foreground"
        android:inset="4%" />
</foreground>
```

**Recommended inset range:** 0-8% (higher values make icons appear small)

### 4. Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
```

### 5. Build Release APKs

**Fishfood:**
```bash
flutter build apk --release --flavor fishfood
```

**Dogfood:**
```bash
flutter build apk --release --flavor dogfood
```

**Production:**
```bash
flutter build apk --release --flavor prod
```

---

## Verification Checklist

- [ ] All three config files point to correct source images
- [ ] Source images exist in `assets/icons/`
- [ ] Icons generated successfully (no errors)
- [ ] All density folders populated (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] Adaptive icon XML files exist for Android 8.0+
- [ ] Custom inset applied (if desired)
- [ ] Test builds complete without errors
- [ ] Icons display correctly on test devices/emulators

---

## Generated Files Per Flavor

Each flavor generates the following Android resources:

```
android/app/src/{flavor}/res/
├── drawable-mdpi/ic_launcher_foreground.png
├── drawable-hdpi/ic_launcher_foreground.png
├── drawable-xhdpi/ic_launcher_foreground.png
├── drawable-xxhdpi/ic_launcher_foreground.png
├── drawable-xxxhdpi/ic_launcher_foreground.png
├── mipmap-mdpi/ic_launcher.png
├── mipmap-hdpi/ic_launcher.png
├── mipmap-xhdpi/ic_launcher.png
├── mipmap-xxhdpi/ic_launcher.png
├── mipmap-xxxhdpi/ic_launcher.png
├── mipmap-anydpi-v26/ic_launcher.xml
└── values/colors.xml (ic_launcher_background)
```

---

## Troubleshooting

### Issue: Icons appear too small
**Cause:** Excessive inset value in adaptive icon XML  
**Solution:** Reduce `android:inset` to 0-8% or remove entirely


### Issue: Icons not updating after generation
**Cause:** Build cache  
**Solution:**
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter build apk --release --flavor <flavor>
```
---

## Best Practices

1. **Icon Design:** Use 1024x1024px source images with transparency
2. **Safe Zone:** Design foreground graphics within the center 66% for adaptive icons
3. **Inset Usage:** Keep inset values minimal (0-8%) for proper visual prominence
4. **Version Control:** Commit generated icons to ensure consistency across team
5. **Testing:** Verify icons on multiple device sizes and Android versions (8.0+)
6. **Regeneration:** Always regenerate all flavors when changing source images
7. **Background Color:** Use brand-appropriate colors (current: `#FFFFFF`)

---

## Related Configuration

- **Package:** `flutter_launcher_icons: 0.14.3` (in `pubspec.yaml`)
- **Min Android SDK:** 21
- **Adaptive Icons:** Supported on Android 8.0+ (API 26+)
- **iOS Icons:** Generated automatically for all required sizes

---

## References

- [flutter_launcher_icons package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons Guide](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Material Design Icon Guidelines](https://m3.material.io/styles/icons/overview)

---

