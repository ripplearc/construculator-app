# RULE 10: Localization Usage

## Rule ID
RULE_10

## Category
Localization

## Severity Levels
- **Critical:** User-facing strings hardcoded in presentation code
- **Major:** New UI text added without a localization key
- **Minor:** Localized lookups present but inconsistent
- **Suggestion:** Prefer localization for all user-visible text

## Description

All user-facing strings use `AppLocalizations` via the `context.l10n` extension. Hardcoded strings are not localized and break i18n.

## Applicability

All presentation code in `lib/features/**/presentation/` and `lib/app/` that renders user-visible text.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Never hardcode user-facing strings.** Anything the user reads in the UI comes from `context.l10n.<key>`.

### Decision Tree

```
Is this string visible to the user in the UI?
  ├─ YES → Must be localized (Text/labels/hints/tooltips/snackbars/dialogs/errors)
  └─ NO  → May be hardcoded (log messages, route names, internal identifiers, test strings)
```

### Adding a New Localized String

1. **Check `lib/l10n/app_en.arb`** for an existing key. If present, reuse it.
2. **Add a new key** to `app_en.arb` with a `@key` description (and `placeholders` if interpolated).
3. **Run** `flutter gen-l10n` to regenerate `AppLocalizations`.
4. **Use** `context.l10n.<key>` in the widget. The `context.l10n` extension lives in `lib/libraries/extensions/build_context_extensions.dart`. Never use raw `AppLocalizations.of(context)?.key ?? ''` — the extension is the project standard. The former `LocalizationMixin` is retired; do not reintroduce it.

For interpolated strings, declare placeholders in the ARB (`{name}`, `{count, plural, …}`) and call as `context.l10n.welcomeBackUser(userName)` / `context.l10n.estimationCount(items.length)`.

### Key Naming Convention

Pattern: `{context}{ElementType}{Description}` — e.g. `buttonSubmit`, `errorInvalidEmail`, `screenTitleSettings`.

| Context | ❌ Bad | ✅ Good |
|---|---|---|
| Form submit button | `submit` | `buttonSubmit` / `formSubmitButton` |
| Error message | `error` | `errorInvalidEmail` |
| Screen title | `title` | `settingsTitle` / `screenTitleSettings` |
| Empty state | `empty` | `emptyStateNoEstimations` |
| Loading indicator | `loading` | `loadingEstimations` |

### What CAN Be Hardcoded

Non-user-facing strings only:

```dart
AppLogger.debug('User login attempt');       // ✅ log message
const String loginRoute = '/login';          // ✅ internal identifier
expect(find.text('test@example.com'), ...);  // ✅ test code
Text('')                                     // ✅ empty placeholder
```

---

## For Review Agents (Detective)

### Detection Patterns

| # | Indicator | Regex / Grep | Severity | Fix |
|---|---|---|---|---|
| 1 | `Text(...)` with hardcoded string | `Text\s*\(\s*['"]([a-zA-Z][^'"]*)['"]` | Critical | `Text(context.l10n.<key>)` |
| 2 | Hardcoded button / hint / tooltip / title | `(label\|hint\|tooltip\|title\|placeholder\|child:\s*Text)\s*:\s*['"]([a-zA-Z][^'"]*)['"]` | Critical | `label: context.l10n.<key>` |
| 3 | Hardcoded snackbar / dialog / error message | `(showSnackBar\|showDialog\|showToast\|showAlert)\s*\([^)]*['"]([a-zA-Z][^'"]*)['"]` | Critical | Extract key, use `context.l10n.<key>` |
| 4 | File imports `AppLocalizations` but still hardcodes UI strings | — | Major | Apply localization consistently |
| 5 | Mixes `context.l10n.key` with `AppLocalizations.of(context)?.key` | — | Minor | Standardize on `context.l10n.<key>` |
| 6 | Uses retired `LocalizationMixin` | `with\s+LocalizationMixin` | Minor | Remove mixin; use `context.l10n.<key>` |

**Exceptions for Pattern 1:** technical/debug strings, hardcoded IDs (`key:`, `id_…`, URLs), empty strings, single characters.

### Agent Workflow

```
For each presentation file changed:
  1. Find all Text(...), label:/hint:/tooltip:/title:/placeholder:, snackbar/dialog calls.
  2. For each match:
     a. Is the string user-facing? (skip technical/debug)
     b. Is it `context.l10n.<key>`? Pass.
     c. Otherwise flag with Pattern # and severity.
  3. Flag mixed access patterns (Pattern 5) and retired `LocalizationMixin` usage (Pattern 6) as Minor.
  4. Suggest a key name following the {context}{ElementType}{Description} convention.
```

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|---|---|---|
| `Text('Welcome back')` | `Text(context.l10n.welcomeBack)` | Critical |
| `label: 'Login'` | `label: context.l10n.buttonLogin` | Critical |
| `showSnackBar(SnackBar(content: Text('Error')))` | localize error message via `context.l10n.<key>` | Critical |
| `AppLocalizations.of(context)?.key ?? ''` | `context.l10n.key` | Minor |
| `class MyWidget with LocalizationMixin` | Drop the mixin; use `context.l10n.<key>` | Minor |

---

## Summary: Suggested Fixes

1. Identify all hardcoded user-facing strings in the diff.
2. For each: create a key following `{context}{ElementType}{Description}`.
3. Add entry to `lib/l10n/app_en.arb` (with `@key` description and `placeholders` if needed).
4. Run `flutter gen-l10n`.
5. Replace with `Text(context.l10n.<key>)` (or `label: context.l10n.<key>` etc.).

## References

- [Flutter Localization Guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
- ARB file: `lib/l10n/app_en.arb`
- Extension: `lib/libraries/extensions/build_context_extensions.dart`
- Review Script Lines: 408-432 in `scripts/review_pr.sh`
