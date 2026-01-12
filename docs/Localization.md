# Localization Guide

This guide explains how to use the localization system in Construculator. The project uses Flutter's built-in localization generation (gen-l10n) to provide internationalization support.

The localization system is configured to automatically generate type-safe Dart code from ARB (Application Resource Bundle) files. The current implementation supports English (en) and can be extended to support additional languages.

## Key Components

- **ARB Files**: Source files containing localized strings in JSON format (`lib/l10n/app_*.arb`)
  ```json
  {
    "@@locale": "en",
    "welcomeText": "Welcome to Construculator",
    "@welcomeText": {
      "description": "Welcome message on home screen"
    }
  }
  ```

- **Generated Code**: Type-safe Dart classes automatically generated from ARB files (`lib/l10n/generated/`)
  ```dart
  // Auto-generated - DO NOT EDIT
  class AppLocalizations {
    String get welcomeText => 'Welcome to Construculator';

    static AppLocalizations? of(BuildContext context) {
      return Localizations.of<AppLocalizations>(context, AppLocalizations);
    }
  }
  ```

- **Configuration**: Settings for code generation (`l10n.yaml`)
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-dir: lib/l10n/generated
  ```

- **App Integration**: Localization delegates configured in MaterialApp (`lib/app/app.dart`)
  ```dart
  MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // ... rest of the app
  )
  ```

> **Note:** The `locale` parameter is optional. If omitted, Flutter uses the device's locale (if supported). Specify it when you want to override the device locale or implement language switching.

### Configuration

The `l10n.yaml` file in the project root configures the generation process:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
synthetic-package: false
output-dir: lib/l10n/generated
```

> **Note**: Do not modify files in the `generated/` directory manually. They are automatically generated and will be overwritten.

## Adding New Localized Text

### Step 1: Add the Key to English ARB File

Edit `lib/l10n/app_en.arb` and add your new translation key with metadata:

```json
{
  "@@locale": "en",
  "myNewButtonLabel": "Click Me",
  "@myNewButtonLabel": {
    "description": "Label for the click me button",
    "context": "https://www.figma.com/design/..."
  }
}
```

**Things to note:**
- Always include the `@keyName` metadata entry with at least a `description` field
- The `context` field is optional but recommended for design references
- Use camelCase for key names (e.g., `myNewButtonLabel`, not `my_new_button_label`)

### Step 2: Generate Localization Files

After adding new keys, run the generation command:

```bash
flutter gen-l10n
```

Some IDEs automatically re-generate the files after editing the ARB files.

### Step 3: Use in Code

Once generated, access the new string:

```dart
AppLocalizations.of(context).myNewButtonLabel
```

### Step 4: Add Translations for Other Languages

If there are other language files in the code, add the same key with the translation:

```json
{
  "@@locale": "es",
  "myNewButtonLabel": "Haz Clic",
  "@myNewButtonLabel": {
    "description": "Etiqueta para el botón haz clic",
    "context": "https://www.figma.com/design/..."
  }
}
```

Then regenerate the files using `flutter gen-l10n`.

## Using Localized Text in Code

<!-- TODO: https://ripplearc.youtrack.cloud/issue/CA-460/UI-refactorCreate-BuildContext-Extensions-for-UI-Shortcuts -->
### Using LocalizationMixin (Recommended)

The recommended way to access localized strings is using the `LocalizationMixin`. This approach eliminates the need for null checks and provides cleaner code:

```dart
import 'package:construculator/libraries/mixins/localization_mixin.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    return Text(l10n.agreeAndContinueButton);
  }
}
```

The mixin is defined as:

```dart
mixin LocalizationMixin<T extends StatefulWidget> on State<T> {
  /// Holds the current localization instance for the widget.
  ///
  /// This is updated automatically in `didChangeDependencies`.
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      throw StateError(
        'AppLocalizations not found in the widget tree. '
        'Ensure that your MaterialApp has localizationsDelegates configured '
        'and that you are accessing this from a descendant widget.',
      );
    }
    l10n = localizations;
  }
}
```

**Benefits:**
- No null checks required (`l10n.key` instead of `l10n?.key ?? ''`)
- Automatic updates when locale changes
- Clear error messages if localization is not properly configured


### Standard Approach

The most common way to access localized strings:

```dart
import 'package:construculator/l10n/generated/app_localizations.dart';

// In your widget's build method
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Text(l10n.agreeAndContinueButton);
}
```

## Adding New Languages

### Step 1: Create Language ARB File

Create a new file `lib/l10n/app_<language_code>.arb` where `<language_code>` is the ISO 639-1 language code (e.g., `es` for Spanish).

```json
{
  "@@locale": "es",
  "agreeAndContinueButton": "Aceptar y continuar",
  "@agreeAndContinueButton": {
    "description": "Etiqueta para el botón aceptar y continuar",
    "context": "https://www.figma.com/design/..."
  },
  "alreadyHaveAccount": "¿Ya tienes una cuenta?",
  "@alreadyHaveAccount": {
    "description": "Texto para ya tienes una cuenta",
    "context": "https://www.figma.com/design/..."
  }
}
```

**Things to note:**
- The file must include `"@@locale": "<language_code>"` at the top
- All keys from `app_en.arb` should be included with appropriate translations
- Maintain the same metadata structure (`@keyName` entries)

### Step 2: Generate Files

Run the generation command:

```bash
flutter gen-l10n
```

This will create `app_localizations_<language_code>.dart` in the `generated/` directory and update `app_localizations.dart` to include the new language in `supportedLocales`.

## Additional Features

### Using Parameters

To pass dynamic values in translations, define placeholders in your ARB file and pass them when using the localization.

#### Simple String Parameter

**ARB file:**
```json
{
  "greeting": "Hello {name}!",
  "@greeting": {
    "description": "Greeting with a name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**Code usage:**
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.greeting('Alice'))  // Output: "Hello Alice!"
```

#### Multiple Parameters

**ARB file:**
```json
{
  "welcomeMessage": "Welcome {firstName} {lastName}, you have {count} new messages",
  "@welcomeMessage": {
    "description": "Welcome message with name and message count",
    "placeholders": {
      "firstName": {
        "type": "String"
      },
      "lastName": {
        "type": "String"
      },
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Code usage:**
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.welcomeMessage('John', 'Doe', 5))
// Output: "Welcome John Doe, you have 5 new messages"
```

#### Number and Date Parameters

**ARB file:**
```json
{
  "priceDisplay": "Price: ${price}",
  "@priceDisplay": {
    "description": "Display price with currency formatting",
    "placeholders": {
      "price": {
        "type": "double",
        "format": "currency",
        "optionalParameters": {
          "symbol": "$"
        }
      }
    }
  },
  "lastUpdated": "Last updated: {date}",
  "@lastUpdated": {
    "description": "Display last update date",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  }
}
```

**Code usage:**
```dart
final l10n = AppLocalizations.of(context)!;

// Price formatting
Text(l10n.priceDisplay(99.99))  // Output: "Price: $99.99"

// Date formatting
Text(l10n.lastUpdated(clock.now()))  // Output: "Last updated: 1/1/2026"
```

### Pluralization

Define pluralization rules in the ARB file:

**ARB file:**
```json
{
  "itemsCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemsCount": {
    "description": "Number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Code usage:**
```dart
final l10n = AppLocalizations.of(context)!;

Text(l10n.itemsCount(0))  // Output: "No items"
Text(l10n.itemsCount(1))  // Output: "1 item"
Text(l10n.itemsCount(5))  // Output: "5 items"
```

#### More Complex Pluralization

**ARB file:**
```json
{
  "daysRemaining": "{count, plural, =0{Due today} =1{1 day remaining} other{{count} days remaining}}",
  "@daysRemaining": {
    "description": "Days remaining until deadline",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Code usage:**
```dart
final l10n = AppLocalizations.of(context)!;

Text(l10n.daysRemaining(0))  // Output: "Due today"
Text(l10n.daysRemaining(1))  // Output: "1 day remaining"
Text(l10n.daysRemaining(3))  // Output: "3 days remaining"
```

## Testing

Widget tests must include the localization delegates to access translated strings. Use this helper setup:

```dart
import 'package:construculator/l10n/generated/app_localizations.dart';

BuildContext? buildContext;

Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        buildContext = context;
        return child;
      },
    ),
  );
}

/// Convenient accessor for localized strings within tests
AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;
```

Now you can access localized strings in your tests:

```dart
expect(find.text(l10n().agreeAndContinueButton), findsOneWidget);
```


## Best Practices

### Key Naming

- Use descriptive, domain-oriented names: `estimationStartButton` instead of `button`
- Follow camelCase convention
- Be consistent with existing patterns (e.g., `Button`, `Label`, `Error`)
- Avoid abbreviations unless widely understood

### Metadata

- Always include `description` in `@keyName` metadata
- Include `context` field with Figma links or design references when available
- For parameterized strings, always define `placeholders` with correct types

### Translation Maintenance

- When adding new features, update all language ARB files, not just English
- Test all languages to ensure parameters work correctly across translations
