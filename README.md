# Construculator App

> A construction cost estimation and collaboration platform built with Flutter and Supabase

**Version:** 1.0.0+1
**Flutter:** 3.32.0 (via FVM)
**Platform:** iOS & Android

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Backend Setup](#backend-setup)
- [Frontend Setup (Flutter)](#frontend-setup-flutter)
- [Testing](#testing)
- [Scripts & Automation](#scripts--automation)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)

---

## Overview

Construculator is a mobile application designed for construction professionals to:
- Create quick cost estimates (materials, labor, equipment)
- Collaborate with team members on cost estimation.
- Track calculations and project data
- Export estimates to cloud storage (Google Drive, OneDrive, Dropbox)

### Tech Stack

- **Flutter 3.32.0** (managed via FVM)
- **Supabase** - Backend as a Service (PostgreSQL + Auth + API)
- **BLoC Pattern** - State management with flutter_bloc
- **Clean Architecture** - Feature-based modules with clear layer separation
- **flutter_modular** - Dependency Injection and Routing


## Architecture

**Design Documentation:** [RippleArc Engineering Best Practice](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.cftu3k9in6u#heading=h.sxep7l3m4lxv)

**Wiki Documentation:** [construculator-app Wiki](https://github.com/ripplearc/construculator-app/wiki)

### Project Structure

```
lib/
├── app/                    # Application bootstrap & module setup
├── features/               # Feature modules (auth, dashboard, estimation)
│   ├── {feature}/
│   │   ├── domain/        # Business logic & use cases
│   │   ├── data/          # Data sources, repositories, models
│   │   ├── presentation/  # BLoC, pages, widgets
│   │   └── testing/       # Test doubles (fakes, no mocks)
└── libraries/             # Shared infrastructure
    ├── auth/             # Authentication management
    ├── config/           # Environment configuration
    ├── router/           # Navigation
    ├── supabase/         # Supabase client wrapper
    └── ...               # Other shared utilities
```

### Architecture Patterns

**Clean Architecture + BLoC:**
```
Presentation (BLoC, Widgets)
        ↓
Domain (Use Cases, Entities)
        ↓
Data (Repositories, Data Sources)
        ↓
External (Supabase, Storage)
```

**Key Principles:**
- [Feature-based modules with clear boundaries](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.cftu3k9in6u#heading=h.n6s05wrc5vaw)
- [BLoC for state management](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.twe1ifcyor7p) (flutter_bloc 9.1.0)
- [Use Case pattern for business operations](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.avq0hrlnmvs5#bookmark=id.9zm4c91a7nf1)
- [Repository pattern for data abstraction](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.avq0hrlnmvs5#bookmark=id.9zv9ppub7lzj)
- [Test Double pattern](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.781ppv45x6si) (real implementations, fake externals only - no mocks)

---

## Prerequisites

Before starting, ensure you have the following installed:

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Docker** | Runs Supabase local services | [Get Docker](https://docs.docker.com/get-docker/) |
| **FVM** | Flutter Version Manager | `dart pub global activate fvm` |
| **Flutter 3.32.0** | Via FVM | `fvm install 3.32.0` |

---

## Backend Setup

Before running the application, you must set up the local backend services:

1.  **Clone the Backend Repository:**
    ```bash
    git clone https://github.com/ripplearc/construculator-backend
    ```
2.  **Start the Services:** Follow the instructions in the [construculator-backend README](https://github.com/ripplearc/construculator-backend) to run the server locally using Docker.
3.  **Verify Services:** Ensure Supabase and the API are running before proceeding to the frontend setup.

---

## Frontend Setup (Flutter)

### 1. Clone the Flutter Repository

```bash
git clone https://github.com/ripplearc/construculator-app
cd construculator-app
```

### 2. Install FVM and Flutter

Refer to the [Prerequisites](#prerequisites) section to install **FVM** and the correct **Flutter version**.

```bash
# Install FVM globally (if not already installed)
dart pub global activate fvm

# Install Flutter 3.32.0 via FVM
fvm install 3.32.0

# Set as global default (optional)
fvm global 3.32.0

# Verify installation
fvm flutter --version
```

### 3. Configure Environment Variables

The app uses environment-specific configuration files located in `assets/env/`.

#### Create .env.dev

```bash
# Copy the template
cp assets/env/.env.template assets/env/.env.dev
```

#### Edit .env.dev (Values obtained from running supabase start)

```env
APP_ENV="dev"
APP_NAME=Construculator
API_URL=http://localhost:8000/api
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
DEBUG_MODE=true
ANALYTICS_ENABLED=false
```

**Environment Variable Details:**

| Variable | Description | How to Get It |
|----------|-------------|---------------|
| `APP_ENV` | Environment name | `dev` for local development |
| `APP_NAME` | App display name | `Construculator` |
| `API_URL` | Backend API endpoint | Use `http://localhost:8000/api` or your backend URL |
| `SUPABASE_URL` | Supabase API URL | `http://localhost:54321` (from `supabase start` output) |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | Copy the ` Publishable key` from `supabase start` output |
| `DEBUG_MODE` | Enable debug logging | `true` for development, `false` for production |
| `ANALYTICS_ENABLED` | Enable analytics | `false` for local development |

#### Important: Emulator Network Configuration

**Problem:** Emulators may not be able to access `localhost` on the host machine.

**Solution:** Replace `localhost` with your local IP address:

**Find your local IP:**

```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig
```

**Example IP:** `192.168.1.10`

**Updated .env.dev:**
```env
API_URL=http://192.168.1.10:8000/api
SUPABASE_URL=http://192.168.1.10:54321
```

### 4. Install Dependencies

```bash
# Install Flutter dependencies
fvm flutter pub get

# Generate code (Freezed, JSON serialization)
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Generate Localization Files
fvm flutter gen-l10n
```

### 5. Run the Application

```bash
# Run with a specific flavor
fvm flutter run --flavor dogfood -t lib/main.dart

# Or use fishfood flavor
fvm flutter run --flavor fishfood -t lib/main.dart
```

**Available Flavors:**
- `dogfood` - Internal testing environment
- `fishfood` - QA (Quality Assurance) environment
- `prod` - Production environment


### 6. Verify Setup

1. **Check Supabase connection:**
   - Open the app
   - Try to sign up with a new user
   - Check Inbucket (`http://localhost:54324`) for the OTP email
   - Complete signup with the OTP code

2. **Check database connection:**
   - After signup, open Supabase Studio (`http://localhost:54323`)
   - Navigate to **Table Editor** → `users` table
   - Verify your new user appears in the table

3. **Check authentication:**
   - Try to log in with your credentials
   - You should see the dashboard

---

## Testing

### Test Structure

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

You can read further from our [Directories Wiki](https://github.com/ripplearc/construculator-app/wiki/Directories)

### Running Tests Locally

```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test test/libraries/auth/units/auth_notifier_test.dart

# Run tests with coverage
fvm flutter test --coverage

# Run golden tests (inside the docker container)
# Example: fvm flutter test test/features/auth/screenshots --update-goldens
fvm flutter test [PATH-TO-SCREENSHOTS] --update-goldens
```

### Coverage Requirements

- **Target:** 94% code coverage (enforced by CI)
- **Exclusions:** Generated files (`*.g.dart`, `*.freezed.dart`, `l10n/**`)
- **Tool:** lcov

**Generate coverage report:**
```bash
# Run tests with coverage
fvm flutter test --coverage

# Remove generated files from coverage
lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' '**/l10n/**' -o coverage/lcov.info

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open coverage report (OS-specific), or open the file in any browser manually
# macOS:
open coverage/html/index.html
# Linux:
xdg-open coverage/html/index.html
# Windows:
start coverage/html/index.html
```

**Or we can see the coverage report after running script/run_check.sh :**

```bash
genhtml coverage/lcov.info -o coverage/html

# Open coverage report (OS-specific), or open the file in any browser manually
# macOS:
open coverage/html/index.html
# Linux:
xdg-open coverage/html/index.html
# Windows:
start coverage/html/index.html
```

### Golden Tests with Docker

**Why Docker?** Golden test screenshots vary between platforms (macOS, Linux, Windows). The Docker container matches the CI environment (Linux) to ensure consistent screenshots.

#### Setup

1. **Start Docker container:**
   ```bash
   docker-compose up -d
   ```

2. **Get container name:**
   ```bash
   docker container ps
   ```
   Look for `construculator-app-flutter-1` or similar ID.

3. **Open shell in container:**
   ```bash
   docker exec -it [CONTAINER-ID] bash
   ```

4. **Run golden tests inside container:**
   ```bash
   # Verify golden tests
   flutter test test/features/**/screenshots

   # Update golden images ( Only run when a visual change is intended in a specific directory )
   flutter test <PATH-TO-TEST> --update-goldens
   ```

5. **Exit container:**
   ```bash
   exit
   ```

**Note:** The `test/` and `lib/` directories are volume-mounted, so updated golden files automatically sync to your host machine. No need to copy files manually.

#### Rebuilding Docker Image

Rebuild the Docker image only when switching to a branch that changes underlying dependencies (for example when pubspec.yaml or pubspec.lock — or any other dependency files — differ). If those files did not change, you can skip the rebuild and just restart the containers.

```bash
# Stop container
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

---

## Scripts & Automation

The project includes automated scripts for quality assurance and code review.

### run_check.sh

Comprehensive quality assurance script that runs analysis, tests, and builds. Scripts require FVM to be installed and configured.

**Location:** `scripts/run_check.sh`

**Usage:**

```bash
# Pre-check (fast, changed files only)
./scripts/run_check.sh --pre

# Comprehensive check (full codebase)
./scripts/run_check.sh --comp

# Both pre-check and comprehensive
./scripts/run_check.sh --all

# Mutation tests only
./scripts/run_check.sh --mutations
```

**What Each Mode Does:**

#### Pre-check (`--pre`)
- **Purpose:** Fast feedback for PRs
- **Checks:**
  - Validates no `[skip ci]` in commit messages
  - Analyzes changed Dart files only
  - Runs tests for changed files
  - Enforces 95% code coverage
  - Excludes generated files from coverage
- **Time:** ~5-10 minutes

#### Comprehensive Check (`--comp`)
- **Purpose:** Full validation before merge
- **Checks:**
  - Full codebase analysis (`flutter analyze --fatal-infos --fatal-warnings`)
  - All unit + widget tests with coverage
  - Screenshot/golden tests with `--update-goldens`
  - Android APK build (fishfood flavor)
  - Mutation testing (if configs changed)
- **Time:** ~5-15 minutes
- **Artifacts:** APK, coverage reports, mutation reports

#### Mutation Tests (`--mutations`)
- **Purpose:** Validate test effectiveness
- **Checks:**
  - Runs mutation tests for changed config files (`test/mutations/*.xml`)
  - Introduces code mutations to verify tests catch them
- **Time:** Varies (can be slow)

**Dependencies:**

The script requires:
- FVM and Flutter (See [Prerequisites](#prerequisites))
- `git`, `flutter`, `dart` (via FVM)
- `lcov`
- `bc` (calculator - usually pre-installed on Unix systems)

**Coverage Configuration:**

```bash
# Set custom coverage target (default: 95%)
export ARC_CODE_COVERAGE_TARGET=90

# Run pre-check with custom target
./scripts/run_check.sh --pre
```

### review_pr.sh

Generates AI-friendly code review documents for use with Claude/Cursor.

**Location:** `scripts/review_pr.sh`

**Usage:**

```bash
./scripts/review_pr.sh <pr_branch> <base_branch> [output_file]

# Example
./scripts/review_pr.sh feat/auth main
```

**Output:** `reviews/pr_review_for_cursor.txt`

**Generated Review Includes:**
- Change statistics table (files modified, lines added/removed)
- GitHub-style diffs with 3 lines of context
- Filters out generated files and binaries
- Review instructions based on 4 coding standards (This can change overtime)

**Workflow:**
1. Run the script to generate review document
2. Copy the content from `reviews/pr_review_for_cursor.txt`
3. Paste into Claude/Cursor/Antigravity for AI-assisted code review
4. Address feedback and update PR

---

## CI/CD

The project uses **CodeMagic** for continuous integration and deployment.

### Workflows

#### 1. pre-check (Pull Request Validation)

**Trigger:** Pull requests
**Instance:** linux_x2
**Purpose:** Fast feedback for PRs

**Checks:**
- Block `[skip ci]` commits
- Analyze changed Dart files
- Run changed tests with 95% coverage
- Fast feedback (~5-10 min)

**Notifications:** Email + Slack (#build-notifications)

#### 2. comprehensive-check (Full Validation)

**Trigger:** Manual via `#RunCheck` comment or merge to main
**Instance:** linux_x2
**Purpose:** Full validation before merge

**Checks:**
- Full codebase analysis
- All unit + widget tests with coverage
- Screenshot tests
- Mutation testing (changed configs only)
- Android APK build (fishfood flavor)

**Artifacts:** APK, coverage reports, test results, mutation reports
**Notifications:** Email + Slack

#### 3. ios-debug-build

**Trigger:** Manual via `#RunCheck` comment
**Instance:** mac_mini_m2
**Purpose:** iOS build validation

**Checks:**
- iOS pod installation
- iOS debug build (no codesign)

**Artifacts:** .app file

### Triggering Manual Checks

To manually trigger CI checks on a PR, add a comment with:

```
#runcheck
```

This will trigger all workflows (pre-check, comprehensive-check, ios-debug-build).

---

## Troubleshooting

### Golden Test Failures

**Symptom:** Golden tests fail with "pixel mismatch" errors.

**Fix:**
1. Use Docker container to generate platform-consistent screenshots:
   ```bash
   docker-compose up -d
   docker exec -it construculator-app-flutter-1 bash
   flutter test test/features/**/screenshots --update-goldens
   exit
   ```
2. Commit the updated golden files

### Coverage Issues

#### Coverage Below 95%

**Symptom:** `run_check.sh --comp` fails with "Low coverage" error.

**Fix:**
1. Identify untested code:
   ```bash
   fvm flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```
2. Add tests for uncovered code
3. Rerun: `./scripts/run_check.sh --pre`

**Alternative (Must get the approval of the code owner):** If coverage is temporarily low and intentional:
- Add `#DeltaCoverageLow` or `DCL` to commit message
- This lowers the coverage requirement for that commit

---

## Additional Resources

- **Flutter Documentation:** [https://docs.flutter.dev](https://docs.flutter.dev)
- **BLoC Pattern:** [https://bloclibrary.dev](https://bloclibrary.dev)
- **Jujutsu (jj):** [Migration from Graphite to Jujutsu (jj)](https://docs.google.com/document/d/1apOp9YNEAWjBPE1pFRu5chM96A9j_jZS0cm1yvdAG6g/edit?tab=t.0)
- **Flutter Modular:** [https://modular.flutterando.com.br/docs/flutter_modular/start](https://modular.flutterando.com.br/docs/flutter_modular/start)
- **Backend Repository:** [construculator-backend](https://github.com/ripplearc/construculator-backend)

---

## Contributing

1. Create a feature branch with naming convention: `[feat|chore|docs|refactor]_descriptive_name`
2. Keep PRs small; use stacked PRs via [Jujutsu (jj)](https://docs.jj-vcs.dev/latest/) 
3. Run `./scripts/run_check.sh --pre` before pushing
4. Run `./scripts/run_check.sh --comp` after pushing
5. Create a PR with descriptive title and summary
6. Generate PR review: `./scripts/review_pr.sh <branch> main`
7. Request code review from team
8. Address feedback and ensure CI passes

---

## Team

**Repository:** [construculator-app](https://github.com/ripplearc/construculator-app)
