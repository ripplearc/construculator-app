# RULE 10: Localization Usage

## Rule ID
RULE_10

## Category
Localization

## Severity Levels
- Critical: User-facing strings are hardcoded in presentation code.
- Major: New UI text is added without a localization key.
- Minor: Localized lookups are present but inconsistent.
- Suggestion: Prefer localization for all user-visible text.

## Description

All user-facing strings should use `AppLocalizations` or the project localization mixins.

## Applicability

This rule applies to widgets and presentation code that render visible text.

## Detection Patterns

- Hardcoded `Text('...')` strings.
- Button labels, titles, and error messages in plain English.
- Missing `AppLocalizations` lookups in new UI code.

## Implementation Guide

**For Agent Execution:**

Search for violations in presentation code using these patterns:

### Pattern 1: Hardcoded Text Strings

**Indicator:** `Text()` widget with a hardcoded string literal (not from localization)

**Examples to catch:**
- `Text('Welcome back')`
- `Text('Click here')`
- `Text('Loading...')`
- `Text('Error occurred')`

**Regex:** `Text\s*\(\s*['\"]([a-zA-Z][^'\"]*)['\"]`

**Severity:** Critical

**Exceptions:**
- Technical/debug strings (allowed but not recommended)
- Hardcoded IDs or identifiers (technical strings)
- Empty strings or single characters
- Strings matching known technical patterns (e.g., `key:`, `id_`, URLs)

**Fix:** Replace with `Text(AppLocalizations.of(context)?.yourStringKey ?? '')` or use `LocalizationMixin` pattern: `Text(l10n?.yourStringKey ?? '')`

---

### Pattern 2: Hardcoded Button/Label Text

**Indicator:** Button labels, field labels, or tooltip text without localization

**Examples to catch:**
- `label: 'Logout'`
- `hint: 'Enter email'`
- `tooltip: 'Save changes'`
- `title: 'Settings'`
- `ElevatedButton(onPressed: ..., child: Text('Submit'))`

**Regex:** `(label|hint|tooltip|title|placeholder|child:\s*Text)\s*:\s*['\"]([a-zA-Z][^'\"]*)['\"]`

**Severity:** Critical

**Fix:** Create localization key and use: `label: AppLocalizations.of(context)?.buttonSubmit`

---

### Pattern 3: Hardcoded Error Messages

**Indicator:** Error or validation messages shown to users without localization

**Examples to catch:**
- `showSnackBar('Invalid email')`
- `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error')))`
- `throw Exception('User not found')`
- `showDialog(title: 'Alert', content: Text('Something went wrong'))`

**Regex:** `(showSnackBar|showDialog|showToast|showAlert)\s*\([^)]*['\"]([a-zA-Z][^'\"]*)['\"]`

**Severity:** Critical

**Fix:** Extract to localization and reference via `AppLocalizations.of(context)?.errorMessageKey`

---

### Pattern 4: Missing AppLocalizations Usage

**Indicator:** Localization functions/mixins available but not used in new code

**Detection approach:**
- File imports `AppLocalizations` or `LocalizationMixin`
- But contains Pattern 1, 2, or 3 violations
- Indicates inconsistent adoption

**Severity:** Major

**Fix:** Use imported localization consistently throughout file

---

### Pattern 5: Inconsistent Localization Access

**Indicator:** Widget mixes different localization patterns in same file

**Examples:**
- Some text uses `AppLocalizations.of(context)?.key`
- Other text uses hardcoded strings
- Some use `l10n?.key`, others use `AppLocalizations.of(context)?.key`

**Severity:** Minor (code smell, not breaking)

**Fix:** Standardize on one pattern per file. Preferred: use `LocalizationMixin` with `l10n?.key` for consistency.

---

**Agent Workflow:**

```
For each applicable file:
  1. Check if file imports AppLocalizations or LocalizationMixin
  2. Search file for all Text() and widget label definitions
  3. For each match:
     a. Determine if string is user-facing (not technical/debug)
     b. Check if already using localization (AppLocalizations or l10n)
     c. If not localized: flag as violation
     d. Extract context and line number
  4. Check for mixed patterns (inconsistency)
  5. Create issue objects with severity
  6. Return all issues with suggested fix (which localization key to use)
```

## Suggested Fix

Replace hardcoded strings with localized keys and add the missing entry to the ARB files.

**Steps to fix:**
1. Identify all hardcoded user-facing strings in the changed file
2. For each string, create a unique localization key (e.g., `buttonSubmit`, `errorInvalidEmail`)
3. Add entry to `lib/l10n/app_en.arb` with the English text
4. Replace hardcoded string with: `Text(AppLocalizations.of(context)?.buttonSubmit ?? '')`
5. If using `LocalizationMixin`, use: `Text(l10n?.buttonSubmit ?? '')`

## References

- [Architecture Layers Reference](../references/architecture-layers.md)
- [Flutter Localization Guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
- AppLocalizations class: Generated from ARB files in `lib/l10n/`
