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

This rule applies to all presentation code in `lib/features/**/presentation/` and `lib/app/` that renders user-visible text.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Never hardcode user-facing strings.** All text visible to users must be localized using `AppLocalizations` to support internationalization.

### Decision Tree: Should This String Be Localized?

```
Is this string visible to the user in the UI?
  ├─ YES → Must be localized
  │        Examples: Button labels, titles, error messages, descriptions
  │
  └─ NO → Can be hardcoded (but consider logging)
           Examples: Log messages, debug strings, internal identifiers
```

### When Writing UI Code

**Before adding ANY user-visible text:**

1. **Check if localization key exists** in `lib/l10n/app_en.arb`
   - If YES → Use existing key
   - If NO → Create new key (see steps below)

2. **Use localization consistently**
   - ✅ Use extension: `context.l10n.key` (throws StateError if not configured)
   - ❌ Never: Hardcoded strings
   - ❌ Never: Direct `AppLocalizations.of(context)?.key ?? ''` (use extension instead)

### How to Add New Localized Strings

**Step 1: Create Localization Key**

```dart
// Bad: Hardcoded string
Text('Welcome back')  // ❌

// Good: Use localization key via extension
Text(context.l10n.welcomeBack)  // ✅
```

**Step 2: Add Entry to ARB File**

Add to `lib/l10n/app_en.arb`:

```json
{
  "welcomeBack": "Welcome back",
  "@welcomeBack": {
    "description": "Greeting shown to returning users on login screen"
  }
}
```

**Step 3: Run Code Generation**

```bash
flutter gen-l10n
```

This generates the `AppLocalizations` class with your new key.

### Naming Conventions for Localization Keys

Use descriptive, context-aware key names:

| Context | ❌ Bad Key | ✅ Good Key |
|---------|-----------|------------|
| Button to submit form | `submit` | `buttonSubmit` or `formSubmitButton` |
| Error message | `error` | `errorInvalidEmail` |
| Screen title | `title` | `screenTitleSettings` or `settingsTitle` |
| Empty state message | `empty` | `emptyStateNoEstimations` |
| Loading indicator | `loading` | `loadingEstimations` |

**Pattern:** `{context}{ElementType}{Description}`
- `context`: Where it appears (button, screen, error, etc.)
- `ElementType`: What it is (Title, Label, Message, etc.)
- `Description`: What it says/does

### Common Patterns

#### ✅ Using LocalizationMixin (Preferred)

```dart
class LoginScreen extends StatelessWidget with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.screenTitleLogin ?? ''),  // ✅
      ),
      body: Column(
        children: [
          Text(l10n?.loginWelcomeMessage ?? ''),  // ✅
          CoreButton(
            label: l10n?.buttonLogin ?? '',  // ✅
            onPressed: () => _handleLogin(),
          ),
          if (state.hasError)
            Text(
              l10n?.errorInvalidCredentials ?? '',  // ✅
              style: CoreTypography.bodySmallRegular().copyWith(
                color: CoreTextColors.error,
              ),
            ),
        ],
      ),
    );
  }
}
```

#### ✅ Using Localization Extension

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.screenTitleSettings),  // ✅ Extension
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.l10n.settingsLanguage),  // ✅ Extension
            subtitle: Text(context.l10n.settingsLanguageDescription),  // ✅ Extension
          ),
        ],
      ),
    );
  }
}
```

#### ❌ Wrong: Hardcoded Strings

```dart
// Bad: All hardcoded
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),  // ❌ Hardcoded
      ),
      body: Column(
        children: [
          Text('Welcome back'),  // ❌ Hardcoded
          CoreButton(
            label: 'Login',  // ❌ Hardcoded
            onPressed: () => _handleLogin(),
          ),
          if (state.hasError)
            Text('Invalid credentials'),  // ❌ Hardcoded
        ],
      ),
    );
  }
}
```

### What CAN Be Hardcoded

✅ **Allowed (Technical/Debug Strings):**
```dart
// Log messages
AppLogger.debug('User login attempt');  // ✅ Not user-facing

// Internal identifiers
const String loginRoute = '/login';  // ✅ Technical

// Test strings
expect(find.text('test@example.com'), findsOneWidget);  // ✅ Test code

// Empty strings
Text('')  // ✅ Placeholder
```

### Interpolation and Dynamic Values

**For strings with dynamic values:**

ARB file:
```json
{
  "welcomeBackUser": "Welcome back, {name}!",
  "@welcomeBackUser": {
    "description": "Personalized greeting",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "John"
      }
    }
  }
}
```

Usage:
```dart
Text(l10n?.welcomeBackUser(userName) ?? '')  // ✅
```

### Pluralization

**For strings that need plural forms:**

ARB file:
```json
{
  "estimationCount": "{count, plural, =0{No estimations} =1{1 estimation} other{{count} estimations}}",
  "@estimationCount": {
    "description": "Count of estimations",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

Usage:
```dart
Text(l10n?.estimationCount(estimations.length) ?? '')  // ✅
```

---

## For Review Agents (Detective)

### Detection Patterns

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

**Fix:** Replace with `Text(context.l10n.yourStringKey)` using the BuildContext extension

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

**Fix:** Create localization key and use: `label: context.l10n.buttonSubmit`

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

**Fix:** Extract to localization and reference via `context.l10n.errorMessageKey`

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
- Some text uses `context.l10n.key`
- Other text uses hardcoded strings
- Mixed patterns (old `AppLocalizations.of(context)?.key` with new extension)

**Severity:** Minor (code smell, not breaking)

**Fix:** Standardize on extension pattern: use `context.l10n.key` for all localized strings.

---

**Agent Workflow:**

```
For each applicable file:
  1. Check if file uses BuildContext (needed for context.l10n extension)
  2. Search file for all Text() and widget label definitions
  3. For each match:
     a. Determine if string is user-facing (not technical/debug)
     b. Check if already using localization (context.l10n.key)
     c. If not localized: flag as violation
     d. Extract context and line number
  4. Check for mixed patterns (old AppLocalizations vs extension)
  5. Create issue objects with severity
  6. Return all issues with suggested fix (which localization key to use)
```

## Summary: Suggested Fixes

Replace hardcoded strings with localized keys and add the missing entry to the ARB files.

**Steps to fix:**
1. Identify all hardcoded user-facing strings in the changed file
2. For each string, create a unique localization key following the naming pattern: `{context}{ElementType}{Description}`
   - Examples: `buttonSubmit`, `errorInvalidEmail`, `screenTitleSettings`
3. Add entry to `lib/l10n/app_en.arb` with the English text and description
4. Run `flutter gen-l10n` to regenerate AppLocalizations class
5. Replace hardcoded string with:
   - Using extension: `Text(context.l10n.buttonSubmit)` ✅ Preferred
   - See: `lib/libraries/extensions/build_context_extensions.dart` for extension implementation

## References

- [Flutter Localization Guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
- ARB files location: `lib/l10n/app_en.arb`
- AppLocalizations class: Generated from ARB files in `lib/l10n/`
- Review Script Lines: 408-432 in `scripts/review_pr.sh`
