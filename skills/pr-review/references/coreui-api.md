# CoreUI API Reference

> **Note:** This file is a local quick-reference summary. Always check the live README for the latest tokens:
> https://github.com/ripplearc/coreui#readme

---

## Spacing — `CoreSpacing`

| Constant | Value |
|---|---|
| `CoreSpacing.space2` | 2.0 |
| `CoreSpacing.space4` | 4.0 |
| `CoreSpacing.space8` | 8.0 |
| `CoreSpacing.space12` | 12.0 |
| `CoreSpacing.space16` | 16.0 |
| `CoreSpacing.space20` | 20.0 |
| `CoreSpacing.space24` | 24.0 |
| `CoreSpacing.space32` | 32.0 |
| `CoreSpacing.space40` | 40.0 |
| `CoreSpacing.space48` | 48.0 |
| `CoreSpacing.space64` | 64.0 |

---

## Typography — `CoreTypography`

| Method | Usage |
|---|---|
| `CoreTypography.displayLarge()` | Hero headings |
| `CoreTypography.displayMedium()` | Section headings |
| `CoreTypography.headlineLarge()` | Screen titles |
| `CoreTypography.headlineMedium()` | Card titles |
| `CoreTypography.titleLarge()` | List item titles |
| `CoreTypography.titleMedium()` | Subtitles |
| `CoreTypography.bodyLargeRegular()` | Body copy |
| `CoreTypography.bodyMediumRegular()` | Default body |
| `CoreTypography.bodySmallRegular()` | Captions |
| `CoreTypography.labelLarge()` | Button labels |
| `CoreTypography.labelMedium()` | Tags / chips |

---

## Colors

### Text — `CoreTextColors`
- `CoreTextColors.primary`
- `CoreTextColors.secondary`
- `CoreTextColors.disabled`
- `CoreTextColors.inverse`
- `CoreTextColors.error`

### Background — `CoreBackgroundColors`
- `CoreBackgroundColors.surface`
- `CoreBackgroundColors.surfaceVariant`
- `CoreBackgroundColors.surfaceContainer`
- `CoreBackgroundColors.inverse`

### Brand — `CoreTheme.colorScheme`
- `CoreTheme.colorScheme.primary`
- `CoreTheme.colorScheme.secondary`
- `CoreTheme.colorScheme.error`

---

## Icons — `CoreIcons`

Use `CoreIconWidget(icon: CoreIcons.<name>)` to render an icon.

Common icons:
`search`, `close`, `back`, `forward`, `menu`, `home`, `settings`, `user`, `email`, `lock`, `eye`, `eyeOff`, `check`, `error`, `info`, `warning`, `add`, `remove`, `edit`, `delete`, `share`, `download`, `upload`, `camera`, `photo`, `calendar`, `clock`, `location`, `phone`, `notification`

---

## Components

| Component | Import |
|---|---|
| `CoreButton` | `package:coreui/components/core_button.dart` |
| `CoreTextField` | `package:coreui/components/core_text_field.dart` |
| `CoreAppBar` | `package:coreui/components/core_app_bar.dart` |
| `CoreBottomNavBar` | `package:coreui/components/core_bottom_nav_bar.dart` |
| `CoreFAB` | `package:coreui/components/core_fab.dart` |
| `CoreCheckbox` | `package:coreui/components/core_checkbox.dart` |
| `CoreSwitch` | `package:coreui/components/core_switch.dart` |
| `CoreSlider` | `package:coreui/components/core_slider.dart` |
| `CoreLoadingIndicator` | `package:coreui/components/core_loading_indicator.dart` |
| `CoreProgressBar` | `package:coreui/components/core_progress_bar.dart` |
| `CoreDialog` | `package:coreui/components/core_dialog.dart` |
| `CoreBottomSheet` | `package:coreui/components/core_bottom_sheet.dart` |
| `CoreSnackBar` | `package:coreui/components/core_snack_bar.dart` |
| `CoreIconWidget` | `package:coreui/components/core_icon_widget.dart` |
