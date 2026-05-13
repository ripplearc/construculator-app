# RULE 4: CoreUI Components Usage

## Rule ID
RULE_4

## Category
UI Components

## Severity Levels
- Critical: Material components are used directly in new UI code.
- Major: Hardcoded spacing, colors, or typography appear instead of CoreUI tokens.
- Minor: CoreUI imports are missing where they should be present.
- Suggestion: Prefer CoreUI components for new work.

## Description

All UI components, styling, and design tokens should use CoreUI rather than ad hoc Material usage.

## Applicability

This rule applies to all presentation code under `lib/features/**/presentation/` and `lib/app/`.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Never use Material components or hardcoded design tokens directly.** Always use CoreUI's design system for consistency and maintainability.

### When Writing UI Code

Before writing any UI code, consult the CoreUI design system:
- **Reference:** https://github.com/ripplearc/coreui#readme
- **API Docs:** Check `skills/references/coreui-api.md` for available components

### Decision Tree: What Should I Use?

```
Need spacing/padding?
  └─ Use: CoreSpacing.space{4|8|12|16|20|24|32|40|48|64}
     Example: EdgeInsets.all(CoreSpacing.space16)

Need an icon?
  └─ Use: CoreIconWidget(icon: CoreIcons.{name})
     Example: CoreIconWidget(icon: CoreIcons.search)

Need typography/text style?
  └─ Use: context.textTheme.{variant}
     Example: context.textTheme.bodyMediumRegular

Need colors?
  └─ Use: context.colorTheme.{variant}
     Example: context.colorTheme.primary, context.colorTheme.pageBackground

Need a UI component?
  └─ Check CoreUI equivalents below
```

### CoreUI Component Reference

| Need | ❌ Don't Use | ✅ Use Instead |
|------|-------------|---------------|
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

### Common Patterns

#### ✅ Spacing

```dart
// Good: Using CoreSpacing
Padding(
  padding: EdgeInsets.all(CoreSpacing.space16),
  child: Column(
    spacing: CoreSpacing.space12,  // ✅ Column spacing
    children: [
      Text('Title'),
      SizedBox(height: CoreSpacing.space8),  // ✅ Explicit gap
      Text('Subtitle'),
    ],
  ),
)

// Bad: Hardcoded values
Padding(
  padding: EdgeInsets.all(16.0),  // ❌ Magic number
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: 8),  // ❌ Magic number
      Text('Subtitle'),
    ],
  ),
)
```

**Available Spacing:**
- `CoreSpacing.space4` → 4.0
- `CoreSpacing.space8` → 8.0
- `CoreSpacing.space12` → 12.0
- `CoreSpacing.space16` → 16.0
- `CoreSpacing.space20` → 20.0
- `CoreSpacing.space24` → 24.0
- `CoreSpacing.space32` → 32.0
- `CoreSpacing.space40` → 40.0
- `CoreSpacing.space48` → 48.0
- `CoreSpacing.space64` → 64.0

#### ✅ Icons

```dart
// Good: Using CoreIcons
CoreIconWidget(
  icon: CoreIcons.search,
  size: CoreIconSize.medium,
  color: context.colorTheme.primary,
)

// Bad: Material icons
Icon(Icons.search)  // ❌ Material icon
```

#### ✅ Typography

```dart
// Good: Using CoreTypography
Text(
  'Welcome',
  style: context.textTheme.headlineLargeBold,
)

Text(
  'Description text',
  style: context.textTheme.bodyMediumRegular,
)

// Bad: Hardcoded TextStyle
Text(
  'Welcome',
  style: TextStyle(  // ❌ Hardcoded
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
)
```

**Available Typography Properties (via `context.textTheme`):**
- `context.textTheme.displayLargeBold` - Large display text
- `context.textTheme.headlineLargeBold` - Page titles
- `context.textTheme.headlineMediumBold` - Section headers
- `context.textTheme.bodyLargeRegular` - Large body text
- `context.textTheme.bodyMediumRegular` - Standard body text
- `context.textTheme.bodySmallRegular` - Small body text
- `context.textTheme.labelLargeBold` - Button labels
- `context.textTheme.labelMediumBold` - Small labels

#### ✅ Colors

```dart
// Good: Using CoreUI colors via extension
Container(
  color: context.colorTheme.pageBackground,
  child: Text(
    'Hello',
    style: context.textTheme.bodyMediumRegular.copyWith(
      color: context.colorTheme.primary,  // ✅ CoreUI color via extension
    ),
  ),
)

// Bad: Material colors
Container(
  color: Colors.white,  // ❌ Material color
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),  // ❌ Material color
  ),
)

// Bad: Theme lookup
Container(
  color: Theme.of(context).primaryColor,  // ❌ Theme lookup
)

// Bad: Hex colors
Container(
  color: Color(0xFFFFFFFF),  // ❌ Hardcoded hex
)
```

**Available Color Properties (via `context.colorTheme`):**

Access colors through the extension pattern:
- `context.colorTheme.pageBackground` - Page background color
- `context.colorTheme.textHeadline` - Headline text color
- `context.colorTheme.primary` - Primary brand color
- `context.colorTheme.orientMid` - Mid-tone color

> **Note:** See `lib/libraries/extensions/build_context_extensions.dart` and CoreUI's `AppColorsExtension` for the complete list of available color properties.

#### ✅ Buttons

```dart
// Good: Using CoreButton
CoreButton(
  label: 'Continue',
  onPressed: () => handlePress(),
  variant: CoreButtonVariant.primary,
)

// Bad: Material button
ElevatedButton(  // ❌ Material component
  onPressed: () => handlePress(),
  child: Text('Continue'),
)
```

### What If CoreUI Doesn't Have What I Need?

**Decision Gate:**

```
Does the component I need exist in CoreUI?
  ├─ YES → Use it
  │
  └─ NO → STOP and ask the developer
           "CoreUI doesn't have {ComponentName}. Options:
           1. Use existing CoreUI component with custom layout
           2. Request CoreUI team to add it
           3. Build custom component following CoreUI patterns

           What would you like to do?"
```

**Never substitute silently with Material components.** Always surface missing components to the developer.

---

## For Review Agents (Detective)

### Detection Patterns

Search for violations using these grep patterns:

### Pattern 1: Hardcoded Spacing

**Regex:** `(EdgeInsets|SizedBox|Padding).*\((([0-9]+\.[0-9]*)|([0-9]+))\)`

**Examples to catch:**
- `EdgeInsets.all(24.0)` → should be `EdgeInsets.all(CoreSpacing.space24)`
- `SizedBox(height: 16)` → should be `SizedBox(height: CoreSpacing.space16)`
- `Padding(padding: EdgeInsets.symmetric(horizontal: 20))` → should use `CoreSpacing.space20`

**Severity:** Major

**Fix:** Replace literal values with `CoreSpacing.space*` constants per [CoreUI API Reference](../references/coreui-api.md#spacing)

---

### Pattern 2: Material Icons

**Regex:** `Icons\.[a-zA-Z_]+`

**Examples to catch:**
- `Icon(Icons.search)`
- `IconButton(icon: Icon(Icons.close))`
- `leading: Icon(Icons.menu)`

**Severity:** Critical

**Fix:** Replace with `CoreIconWidget(icon: CoreIcons.<name>)`. Reference available icons: [CoreUI API Reference](../references/coreui-api.md#icons)

---

### Pattern 3: Hardcoded Typography

**Regex:** `TextStyle\s*\(`

**Examples to catch:**
- `TextStyle(fontSize: 16, fontWeight: FontWeight.bold)`
- `Text('Hello', style: TextStyle(color: Colors.black))`
- `TextStyle(fontSize: 14, height: 1.5)`

**Severity:** Major

**Fix:** Use `context.textTheme.<property>` instead. Example: `context.textTheme.bodyMediumRegular` for body text

---

### Pattern 4: Material Colors

**Regex:** `(Colors\.[a-zA-Z_]+|Theme\.of\(context\)\.\w*[Cc]olor|Color\(0x[0-9A-Fa-f]{8}\))`

**Examples to catch:**
- `Colors.blue`, `Colors.black`, `Colors.white`
- `Theme.of(context).primaryColor`
- `Color(0xFF000000)`

**Severity:** Major

**Fix:** Use `context.colorTheme.<property>` for colors. Examples:
- `context.colorTheme.primary` - Primary brand color
- `context.colorTheme.pageBackground` - Page background
- `context.colorTheme.textHeadline` - Headline text color

---

### Pattern 5: Material Components

**Regex:** `(ElevatedButton|TextFormField|TextField|AppBar|BottomNavigationBar|FloatingActionButton|Checkbox|Switch|Slider|LinearProgressIndicator|CircularProgressIndicator|Dialog|ModalBottomSheet|SnackBar)\s*\(`

**Examples to catch:**
- `ElevatedButton(onPressed: () {}, child: Text('Click'))`
- `TextFormField(decoration: InputDecoration(...))`
- `AppBar(title: Text('Title'))`
- `FloatingActionButton(onPressed: () {})`

**Severity:** Critical

**Fix:** Replace with CoreUI equivalents:
- `ElevatedButton` → `CoreButton`
- `TextFormField` / `TextField` → `CoreTextField`
- `AppBar` → `CoreAppBar`
- `FloatingActionButton` → `CoreFAB`
- `Checkbox` → `CoreCheckbox`
- `Switch` → `CoreSwitch`
- `Slider` → `CoreSlider`
- `CircularProgressIndicator` → `CoreLoadingIndicator`
- `LinearProgressIndicator` → `CoreProgressBar`
- `Dialog` → `CoreDialog`
- `ModalBottomSheet` → `CoreBottomSheet`
- `SnackBar` → `CoreSnackBar`

---

**Agent Workflow:**

```
For each applicable file:
  1. Read file content
  2. For each pattern above:
     a. Search using grep with provided regex
     b. Extract line numbers and surrounding context
     c. Determine severity based on pattern
     d. Create issue object with (id, name, description, severity, file, line, snippet, suggested_fix, references)
  3. Compile all issues and return
```

## Summary: Suggested Fixes

Replace all literal styling and Material components with CoreUI design tokens and widgets. If a needed component doesn't exist in CoreUI, surface this to the developer rather than substituting with Material.

## References

- [CoreUI GitHub README](https://github.com/ripplearc/coreui#readme) - Latest design system documentation
- [CoreUI API Reference](../references/coreui-api.md) - Local API reference
- Review Script Lines: 273-294 in `scripts/review_pr.sh`
