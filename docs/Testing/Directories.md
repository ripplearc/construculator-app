# Testing Guidelines

This document outlines our testing structure and conventions. Following these guidelines ensures your tests are picked up by CI/CD pipelines and local scripts.

## Directory Structure

All tests must be placed under either `test/features/` or `test/libraries/` following this structure:

```
test/
├── features/
│   └── <feature_name>/
│       ├── units/          # Unit tests (blocs, providers, etc.)
│       ├── widgets/        # Widget tests
│       ├── screenshots/    # Golden/screenshot tests
│       └── mutations/      # Mutation test configs (.xml)
└── libraries/
    └── <library_name>/
        ├── units/          # Unit tests
        └── mutations/      # Mutation test configs (.xml)
```

### Real Examples

```
test/features/auth/widgets/widgets/auth_footer_test.dart
test/features/auth/screenshots/auth_header_screenshot_test.dart
test/features/auth/mutations/create_account_bloc.xml
test/libraries/config/units/app_config_test.dart
test/libraries/supabase/mutations/fake_supabase_wrapper.xml
```

## Detailed Subfolder Organization

### Units Tests (`units/`)

**Rule**: Mirror your implementation structure as much as possible. If your feature has `data/`, `domain/`, and `presentation/` layers, your tests should follow the same structure.

#### Common Subfolders in `units/`:

```
units/
├── data/
│   ├── data_source/      # Remote/local data source tests
│   ├── models/           # DTO/model tests
│   └── repositories/     # Repository implementation tests
├── domain/
│   ├── entities/         # Entity tests
│   ├── usecases/         # Use case tests
│   └── validation/       # Domain validation logic tests
├── presentation/         # Non-widget presentation logic
├── blocs/                # Bloc/Cubit tests
|__ fakes/                # Fake implementations for testing
```

#### Real-World Examples:

**Estimations Feature** (Clean Architecture):
```
test/features/estimations/units/
├── blocs/
│   ├── add_cost_estimation_bloc_test.dart
│   ├── cost_estimation_list_bloc_test.dart
│   └── delete_cost_estimation_bloc_test.dart
├── data/
│   ├── data_source/
│   │   └── remote_cost_estimation_data_source_test.dart
│   ├── models/
│   │   └── cost_estimate_dto_test.dart
│   └── repositories/
│       └── cost_estimation_repository_impl_test.dart
├── domain/
│   ├── entities/
│   └── usecases/
│       └── add_cost_estimation_usecase_test.dart
└── fakes/
    └── fake_cost_estimation_repository_test.dart
```

This mirrors:
```
lib/features/estimation/
├── data/
│   ├── data_source/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── usecases/
└── presentation/
    └── bloc/
```

**Project Feature** (presentation layer):
```
test/features/project/units/
├── blocs/
│   └── get_project_bloc_test.dart
└── presentation/
    └── project_ui_provider_impl_test.dart
```

**Auth Library** (library example):
```
test/libraries/auth/units/
├── data/
│   └── models/
│       ├── auth_user_test.dart
│       └── auth_credential_test.dart
├── domain/
│   └── validation/
│       └── auth_validation_test.dart
├── repositories/
│   └── supabase_auth_repository_test.dart
├── fakes/
│   ├── fake_auth_manager_test.dart
│   ├── fake_auth_repository_test.dart
│   └── fake_auth_notifier_test.dart
├── auth_manager_test.dart
└── auth_notifier_test.dart
```

**Key Principle**: If you're testing `lib/features/estimation/data/repositories/foo.dart`, the test goes in `test/features/estimations/units/data/repositories/foo_test.dart`.

### Widget Tests (`widgets/`)

Widget tests are organized by widget type.

#### Common Subfolders in `widgets/`:

```
widgets/
├── pages/       # Full page widgets
└── widgets/     # Reusable component widgets
```

#### Real-World Examples:

**Auth Feature**:
```
test/features/auth/widgets/
├── pages/
│   ├── create_account_page_test.dart
│   ├── enter_password_page_test.dart
│   ├── forgot_password_page_test.dart
│   ├── login_with_email_page_test.dart
│   ├── register_with_email_page_test.dart
│   └── set_new_password_page_test.dart
└── widgets/
    ├── auth_footer_test.dart
    ├── auth_header_test.dart
    ├── auth_provider_buttons_test.dart
    ├── error_widget_builder_test.dart
    ├── otp_verification_sheet_test.dart
    └── terms_and_conditions_section_test.dart
```

This tests widgets in:
```
lib/features/auth/presentation/
├── pages/          # Page-level widgets
└── widgets/        # Smaller reusable widgets
```

### Screenshot Tests (`screenshots/`)

Screenshot tests are **flat** - no subfolders. All golden tests for a feature live directly in the screenshots directory.

```
test/features/auth/screenshots/
├── auth_footer_screenshot_test.dart
├── auth_header_screenshot_test.dart
├── auth_provider_buttons_screenshot_test.dart
├── error_widget_builder_screenshot_test.dart
├── forgot_password_header_screenshot_test.dart
├── otp_verification_sheet_screenshot_test.dart
└── terms_and_conditions_section_screenshot_test.dart
```

Golden files are stored alongside tests:
```
test/features/project/screenshots/
├── goldens/
│   └── project_header_app_bar/
│       └── 390.0x56.0/
│           ├── project_header_app_bar_long_name.png
│           ├── project_header_app_bar_no_avatar.png
│           └── project_header_app_bar_normal.png
└── project_header_app_bar_screenshot_test.dart
```

### Mutation Tests (`mutations/`)

Mutation configs are **flat** - no subfolders. All `.xml` configs live directly in the mutations directory.

```
test/features/auth/mutations/
├── create_account_bloc.xml
├── create_account_page_mutations.xml
├── enter_password_bloc.xml
├── enter_password_page_mutations.xml
├── forgot_password_bloc.xml
├── login_with_email_bloc.xml
└── ...
```

**Why flat?** Mutation testing runs on specific files, and we don't need complex organization since configs are named descriptively.

## Naming Conventions

**Note**: Test files usually shoulld follow Flutter conventions:

- Units and widgets: Test file name = source file name + `_test.dart`
- Example: `auth_footer.dart` → `auth_footer_test.dart`
- Screenshots: Test file name = source file name + `_screenshot_test.dart`
- Example: `auth_footer.dart` → `auth_footer_screenshot_test.dart`
- Mutation configs: Test file name = source file name + `_mutations.xml`
- Example: `auth_footer.dart` → `auth_footer_mutations.xml`

## Why This Structure Matters

Our scripts and CI/CD (`scripts/run_check.sh` and `codemagic.yaml`) are configured to find tests in these specific locations:

```bash
# Pre-check runs only changed tests
test/features/**/units/*.dart
test/features/**/widgets/*.dart
test/libraries/**/units/*.dart

# Comprehensive check runs all tests
test/features/**/screenshots/*.dart
test/features/**/mutations/*.xml
test/libraries/**/mutations/*.xml
```

**⚠️ If you place tests outside these paths, they might not run in CI/CD and will be skipped in coverage.**

## Test Types Summary

### Unit Tests (`units/`)
- Business logic and state management
- Pure Dart logic tests
- Common subfolders: data/, domain/, presentation/, blocs/, fakes/, helpers/
- Key Principle: Mirror your implementation structure


### Widget Tests (`widgets/`)
- Widget behavior and interaction
- Widget state changes
- Basic UI logic without golden comparison
- Subfolders: pages/ and widgets/

### Screenshot Tests (`screenshots/`)
- Golden file comparisons
- Visual regression testing
- Use `--update-goldens` flag to update reference images
- Flat structure (no subfolders)
- Shows golden file organization

**Important Notes:**
- Screenshot tests do **not** contribute to code coverage metrics
- Test specific UI states and variations (e.g., loading, error, empty states)
- Avoid full-page screenshots—isolate the critical user journey (CUJ) of individual widgets
- Don't overtest, one screenshot per widget state + some edge cases is sufficient (no need for multiple redundant tests)


### Mutation Tests (`mutations/`)
- XML config files for mutation testing
- Tests run only when mutation configs change
- Validates test suite quality
- Flat structure with descriptive names


## Coverage Requirements

- Target: 95% code coverage (`ARC_CODE_COVERAGE_TARGET=95`)
- Excludes generated files (`*.g.dart`, `*.freezed.dart`, `l10n/**`)
- Both pre-check and comprehensive-check enforce this threshold
- Calculated based on unit and widget tests

## Running Tests Locally

```bash
# Pre-check (changed files only)
./scripts/run_check.sh --pre

# Comprehensive check (all tests + builds)
./scripts/run_check.sh --comp

# Both checks
./scripts/run_check.sh --all

# Mutation tests only
./scripts/run_check.sh --mutations

# Specify target branch
./scripts/run_check.sh --pre --target develop
```
