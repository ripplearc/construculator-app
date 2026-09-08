# RULE 4: CoreUI Components Usage

## Name
CoreUI Components

## Category
UI Components

## Severity Levels
- **Critical:** Material components used directly in new UI code
- **Major:** Hardcoded spacing, colors, or typography appear instead of CoreUI tokens
- **Minor:** CoreUI imports missing where they should be present
- **Suggestion:** Prefer CoreUI components for new work

## Description

All UI components, styling, and design tokens use CoreUI rather than ad-hoc Material.

## Applicability

All presentation code under `lib/features/**/presentation/` and `lib/app/`.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Never use Material components or hardcoded design tokens directly.** Use CoreUI's design system for consistency.

### Decision Tree

```
What do I need?

├─ Spacing/padding?  → CoreSpacing.space{4|8|12|16|20|24|32|40|48|64}
├─ Icon?             → CoreIconWidget(icon: CoreIcons.<name>, size: CoreIconSize.<size>)
├─ Typography?       → context.textTheme.<variant>  (e.g. bodyMediumRegular, headlineLargeBold)
├─ Color?            → context.colorTheme.<variant> (e.g. primary, pageBackground, textHeadline)
└─ UI component?     → See component reference below
```

Complete token tables (spacing values, typography variants, color names) live in **`skills/references/coreui-api.md`** — consult it before writing UI code.

### Component Reference

| Need | ❌ Don't Use | ✅ Use Instead |
|---|---|---|
| **Buttons** | `ElevatedButton`, `TextButton`, `OutlinedButton` | `CoreButton` |
| **Text Input** | `TextField`, `TextFormField` | `CoreTextField` |
| **App Bar** | `AppBar` | `CoreAppBar` |
| **Icons** | `Icon(Icons.*)` | `CoreIconWidget(icon: CoreIcons.*)` |
| **Loading** | `CircularProgressIndicator` | `CoreLoadingIndicator` |
| **Progress** | `LinearProgressIndicator` | `CoreProgressBar` |
| **Dialogs** | `Dialog`, `AlertDialog` | `CoreDialog` |
| **Bottom Sheet** | `ModalBottomSheet` | `CoreBottomSheet` |
| **Snackbar** | `SnackBar` | `CoreSnackBar` |
| **Checkbox** | `Checkbox` | `CoreCheckbox` |
| **Switch** | `Switch` | `CoreSwitch` |
| **Slider** | `Slider` | `CoreSlider` |
| **FAB** | `FloatingActionButton` | `CoreFAB` |

### What If CoreUI Doesn't Have It?

**Never silently substitute Material components.** Surface to the developer:

> CoreUI doesn't have `{ComponentName}`. Options: (1) compose existing CoreUI components, (2) request CoreUI team to add it, (3) build a custom component following CoreUI patterns. Which do you want?

---

## For Review Agents (Detective)

### Detection Patterns

| # | Indicator | Regex | Severity | Fix |
|---|---|---|---|---|
| 1 | Hardcoded spacing in `EdgeInsets`/`SizedBox`/`Padding` | `(EdgeInsets\|SizedBox\|Padding).*\(\s*[0-9]+(\.[0-9]+)?\s*\)` | Major | `CoreSpacing.space<N>` |
| 2 | Material icons | `Icons\.[a-zA-Z_]+` | Critical | `CoreIconWidget(icon: CoreIcons.<name>)` |
| 3 | Hardcoded `TextStyle(...)` | `TextStyle\s*\(` | Major | `context.textTheme.<variant>` |
| 4 | Material colors / theme lookups / hex | `Colors\.[a-zA-Z_]+\|Theme\.of\(context\)\.\w*[Cc]olor\|Color\(0x[0-9A-Fa-f]{8}\)` | Major | `context.colorTheme.<variant>` |
| 5 | Material components | `(ElevatedButton\|TextFormField\|TextField\|AppBar\|BottomNavigationBar\|FloatingActionButton\|Checkbox\|Switch\|Slider\|LinearProgressIndicator\|CircularProgressIndicator\|Dialog\|ModalBottomSheet\|SnackBar)\s*\(` | Critical | Use the CoreUI equivalent from the component table |

### Agent Workflow

```
For each applicable file:
  1. Grep each pattern above.
  2. For each match: capture line, surrounding context, severity.
  3. Suggest the CoreUI replacement from the tables above (or coreui-api.md).
  4. Return issues with (id, severity, file:line, snippet, suggested fix, reference).
```

---

## Summary: Suggested Fixes

Replace all literal styling and Material components with CoreUI design tokens and widgets. If a needed component doesn't exist in CoreUI, surface to the developer rather than substituting Material.

## References

- [CoreUI GitHub README](https://github.com/ripplearc/coreui#readme) — latest design system docs
- **Token tables:** `skills/references/coreui-api.md` (spacing, typography, colors, icons)
- Extension: `lib/libraries/extensions/build_context_extensions.dart` (defines `context.textTheme`, `context.colorTheme`)
- Review Script Lines: 273-294 in `scripts/review_pr.sh`
