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

This rule applies to presentation code under `lib/features/**/presentation/` and `lib/app/presentation/`.

## Detection Patterns

- Hardcoded spacing with `EdgeInsets`, `SizedBox`, or `Padding` literals.
- Material icon usage such as `Icons.*`.
- Hardcoded typography with `TextStyle` literals.
- Material colors such as `Colors.*`.
- Material widgets such as `ElevatedButton`, `TextFormField`, and `AppBar`.

## Implementation Guide

**For Agent Execution:**

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

**Fix:** Use `CoreTypography.<method>()` instead. Example: `CoreTypography.bodyMediumRegular()` for body text

---

### Pattern 4: Material Colors

**Regex:** `(Colors\.[a-zA-Z_]+|Theme\.of\(context\)\.\w*[Cc]olor|Color\(0x[0-9A-Fa-f]{8}\))`

**Examples to catch:**
- `Colors.blue`, `Colors.black`, `Colors.white`
- `Theme.of(context).primaryColor`
- `Color(0xFF000000)`

**Severity:** Major

**Fix:** Use CoreUI color classes:
- Text: `CoreTextColors.primary`, `CoreTextColors.secondary`, etc.
- Background: `CoreBackgroundColors.surface`, `CoreBackgroundColors.surfaceVariant`, etc.
- Theme: `CoreTheme.colorScheme.primary`

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

## Suggested Fix

Replace literal styling and Material components with CoreUI tokens and widgets.

## References

- [CoreUI API Reference](../references/coreui-api.md)
- [CoreUI GitHub](https://github.com/ripplearc/coreui#readme)
