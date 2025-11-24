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
- [Backend Setup (Supabase)](#backend-setup-supabase)
- [Frontend Setup (Flutter)](#frontend-setup-flutter)
- [Testing](#testing)
- [Scripts & Automation](#scripts--automation)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)

---

## Overview

Construculator is a mobile application designed for construction professionals to:
- Perform construction-related calculations using an intuitive interface featuring suggestion chips.
- Create quick cost estimates (materials, labor, equipment)
- Collaborate with team members on cost estimation.
- Track calculations and project data
- Export estimates to cloud storage (Google Drive, OneDrive, Dropbox)

### Tech Stack

- **Flutter 3.32.0** (managed via FVM)
- **Supabase** - Backend as a Service (PostgreSQL + Auth + API)
- **BLoC Pattern** - State management with flutter_bloc
- **Clean Architecture** - Feature-based modules with clear layer separation
- **Freezed** - Immutable data classes with code generation
- **Modular** - Dependency injection and routing

### Documentation

- **Backend Architecture:** [Google Doc - Database Schema](https://docs.google.com/document/d/144-j6mZluSGtFXZdF23cVf9hbVWt4vb-wA3eq02Au4M)
- **Backend Repository:** [construculator-backend](https://github.com/ripplearc/construculator-backend)

---

## Architecture

**Design Documentation:** [RippleArc Engineering Best Practice](https://docs.google.com/document/d/1gJKQ_9kEZaQfbFBDHxrS7zQct9ubsc37EcdqPpsXURk/edit?tab=t.cftu3k9in6u#heading=h.sxep7l3m4lxv)

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
| **Node.js** (v16+) | Supabase CLI | [Get Node.js](https://nodejs.org/) |
| **FVM** | Flutter Version Manager | `dart pub global activate fvm` |
| **Flutter 3.32.0** | Via FVM | `fvm install 3.32.0` |

**Optional:**
- **TablePlus** or **DBeaver** - Database GUI clients for inspection
- **Postman** - API testing (though Supabase Studio handles most use cases)

---

## Backend Setup (Supabase)

The backend is a separate repository that contains all database migrations, seeders, and configuration.

### 1. Clone the Backend Repository

```bash
git clone https://github.com/ripplearc/construculator-backend
cd construculator-backend
```

### 2. Install Supabase CLI

```bash
# Install via npm (local to project)
npm install

# Verify installation
npx supabase --version

# Or install globally (optional)
npm install -g supabase
```

If you encounter issues, refer to the [Supabase Local Development Guide](https://supabase.com/docs/guides/local-development).

### 3. Start Supabase Services

```bash
npx supabase start
```

**Important:** Ensure Docker is running before executing this command.

This command will:
1. Start Docker containers for Postgres, PostgREST, Auth, Studio, and other services
2. Apply all database migrations from `supabase/migrations/`
3. Seed the database with test data from `supabase/seeders/`
4. Display connection details and API keys

**Expected Output:**
```
Started supabase local development setup.

         API URL: http://127.0.0.1:54321
     GraphQL URL: http://127.0.0.1:54321/graphql/v1
  S3 Storage URL: http://127.0.0.1:54321/storage/v1/s3
         MCP URL: http://127.0.0.1:54321/mcp
    Database URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
     Mailpit URL: http://127.0.0.1:54324
 Publishable key: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
      Secret key: 
   S3 Access Key: 625729a08b95bf1b7ff351a663f3a23c
   S3 Secret Key: 850181e4652dd023b7a98c58ae0d2d34bd487ee0cc3254aed6eda37307425907
       S3 Region: local
```

### 4. Understanding Supabase Ports

When Supabase starts, the following services become available:

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **API (PostgREST)** | 54321 | `http://localhost:54321` | REST API for all database operations |
| **Database (Postgres)** | 54322 | `postgresql://postgres:postgres@localhost:54322/postgres` | Direct database connection |
| **Studio** | 54323 | `http://localhost:54323` | Web UI to browse data, run queries, manage auth |
| **Inbucket (Email)** | 54324 | `http://localhost:54324` | View test emails (OTPs, password reset, signup confirmation) |
| **Analytics (Logflare)** | 54327 | `http://localhost:54327` | Log management and querying |

**Most Important for Development:**
- **Port 54321** - API endpoint (use this in your Flutter app)
- **Port 54323** - Supabase Studio for debugging and data inspection
- **Port 54324** - Inbucket for viewing OTP codes and test emails

### 5. Viewing OTP Codes for Authentication

When testing user signup or password reset, the app sends OTP codes via email. Since these are test emails, they're caught by **Inbucket**.

**To view OTPs:**

1. Open your browser and go to: `http://localhost:54324`
2. You'll see the Inbucket interface with all test emails
3. Click on the email addressed to your test user
4. The OTP code will be in the email body

**Example:** If you sign up with `john@example.com`, you'll see an email in Inbucket with the subject "Confirm your signup" containing a 6-digit OTP code.

### 6. Browsing Database with Supabase Studio

**Supabase Studio** is the web interface for managing your local database:

1. Open: `http://localhost:54323`
2. Navigate to:
   - **Table Editor** - View and edit data in tables
   - **SQL Editor** - Run custom queries
   - **Authentication** - Manage users

### 7. Understanding Seeded Data

When you run `supabase start` or `supabase db reset`, the database is seeded with test data. Here's what's pre-populated:

#### Professional Roles (5 roles)

| ID | Name |
|----|------|
| `550e8400-e29b-41d4-a716-446655440001` | Project Manager |
| `550e8400-e29b-41d4-a716-446655440002` | Cost Estimator |
| `550e8400-e29b-41d4-a716-446655440003` | Construction Manager |
| `550e8400-e29b-41d4-a716-446655440004` | Architect |
| `550e8400-e29b-41d4-a716-446655440005` | Engineer |

#### Project Roles (4 roles)

| Role | Level | Permissions |
|------|-------|-------------|
| Admin | 4 | Full control: view + create estimates |
| Manager | 3 | View + create estimates |
| Collaborator | 2 | View + create estimates |
| Viewer | 2 | View estimates only |

#### Permissions (2 permissions)

| Permission Key | Description |
|----------------|-------------|
| `get_cost_estimations` | View cost estimates |
| `add_cost_estimation` | Create cost estimates |

#### Test User

- **Email:** `seeder@example.com`
- **Name:** Seeder User
- **Professional Role:** Project Manager
- **Credential ID:** `850e8400-e29b-41d4-a716-446655440000` (hardcoded - **needs to be updated**)

**⚠️ Important:** The test user currently uses a hardcoded `credential_id`. After signing up a new user through the app, you must update this credential ID to match the authenticated user's ID from Supabase Auth.

**Steps to Update credential_id:**

1. **Sign up a new user through the studio:**
   - Open Supabase Studio
   - Navigate to **Authentication** → **Users** in the left sidebar 
   - Then `Add User -> Create new user`
   - Enter email `seeder@example.com`
   - Enter password 


2. **Copy the User UID**
   - Copy the **User UID** (this is a UUID like `a1b2c3d4-...`)

3. **Update the credential_id in the users table:**
   - In Supabase Studio, go to **Table Editor** → **users** table
   - Find the row where `email = 'seeder@example.com'`
   - Click on the `credential_id` field for that row
   - Paste the **User UID** you copied from step 2
   - Press Enter or click outside the field to save

4. **Verify the update:**
   - Try to log in through the app with `seeder@example.com`
   - You should now be able to access user-specific data
   - If RLS policies are enabled, they should work correctly now

**Why This Is Needed:**

The `credential_id` field links the `users` table record to the Supabase Auth user. When a user signs up:
- Supabase Auth creates an auth user with a unique UID
- The app creates a record in the `users` table
- The `credential_id` should match the auth UID for proper authentication and RLS policies

The seeded data uses a placeholder UUID that doesn't match any real auth user, which can cause authentication and permission issues.

#### Sample Projects (4 projects)

| Project Name | Description | Storage Provider |
|--------------|-------------|------------------|
| Downtown Office Complex | 15-story office building | Google Drive |
| Residential Housing Development | 50 single-family homes | OneDrive |
| Shopping Mall Renovation | Complete mall renovation | Dropbox |
| Industrial Warehouse | 100,000 sq ft warehouse | Google Drive |

**Note:** All sample data uses fixed UUIDs for consistency across local environments. In production, these will be dynamically generated.

### 8. Understanding Row Level Security (RLS)

**⚠️ CRITICAL CONCEPT:** By default, all tables in Supabase have **Row Level Security (RLS)** enabled. This is the **most common issue** developers face.

#### What is RLS?

Row Level Security is PostgreSQL's built-in security feature that controls which rows users can access in a table. Think of it as fine-grained permissions at the row level.

**Key Points:**
- **Without RLS policies:** Tables appear empty even though data exists
- **With RLS policies:** Users only see data they're authorized to access
- **Purpose:** Security and multi-tenancy support
- **Behavior:** Supabase returns `[]` (empty array) instead of an error when RLS blocks access

#### Why Are My Tables Empty?

**Symptom:** You query a table from your Flutter app and get an empty array `[]`, but when you check Supabase Studio, the data is there.

**Cause:**
1. RLS is enabled on that table (default behavior)
2. No RLS policy exists that allows the current authenticated user to read that data
3. The migration files enable RLS but don't create policies yet

**This is EXTREMELY frustrating because:**
- Supabase returns `[]` instead of throwing an error
- The data exists in the database (you can see it in Studio)
- Your code looks correct but doesn't work
- It's hard to debug without knowing about RLS

#### Checking RLS Status

**Via Supabase Studio:**
1. Go to **Table Editor**
2. Select a table
3. Look for the shield icon 🛡️ next to the table name
4. If it's enabled, you'll see "RLS enabled"

**Via SQL:**
```sql
-- Check RLS status for all tables
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- rowsecurity = true means RLS is enabled
```

#### Solution Options

You have three options when RLS blocks your access:

##### Option 1: Disable RLS for Local Development (Quick Fix)

**⚠️ WARNING:** Only use this for local development. **NEVER** disable RLS in production.

**Via Supabase Studio:**
1. Go to **Authentication** → **Policies**
2. Select the table (e.g., `users`)
3. Click **"Disable RLS"** button

**Via SQL:**
```sql
-- Disable RLS for specific table
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Disable for multiple tables
ALTER TABLE public.projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_estimates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_items DISABLE ROW LEVEL SECURITY;
```

**When to use this:**
- Quick local testing
- Prototyping features
- When you don't need security yet

##### Option 2: Implement Proper RLS Policies (Production-Ready)

Create proper security policies based on business logic:

```sql
-- Users can only read their own profile
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = credential_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = credential_id)
WITH CHECK (auth.uid() = credential_id);

-- Project members can view projects they're assigned to
CREATE POLICY "Members can view their projects" ON public.projects
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = (
      SELECT id FROM public.users WHERE credential_id = auth.uid()
    )
  )
);
```

**When to use this:**
- For production code
- When implementing actual features
- When security matters
- **Important:** Add these policies to migration files in the backend repo

#### Important Notes on RLS

1. **Service Role Bypasses RLS:** When you use the `service_role` key instead of `anon` key, RLS is bypassed. This is useful for admin operations but dangerous if exposed.

2. **Studio Uses Service Role:** Supabase Studio uses the service role key, which is why you see all data there even when RLS blocks your app.

3. **Migration Files:** When working on a feature that requires creating or modifying RLS policies directly related to that feature, add those policy changes to the migration files in the [construculator-backend](https://github.com/ripplearc/construculator-backend) repo so other developers get them.

4. **Policy Names Must Be Unique:** Each policy needs a unique name per table, or you'll get errors when applying migrations.

### 9. Resetting the Database

If you need to start fresh or apply new migrations:

```bash
npx supabase db reset
```

**This command will:**
- Drop all tables and data
- Reapply all migrations from `supabase/migrations/` in order
- Re-seed the database with test data
- Reset auth users

**Use this when:**
- Migrations are updated in the backend repo
- Database is in an inconsistent state
- You need fresh test data
- After pulling new migration files from the backend repo

### 10. Common Supabase Commands

| Action | Command |
|--------|---------|
| Start Supabase | `npx supabase start` |
| Stop Supabase | `npx supabase stop` |
| View service status | `npx supabase status` |
| View logs | `npx supabase logs` |
| Reset database | `npx supabase db reset` |
| Apply migrations | `npx supabase migration up` |
| Create new migration | `npx supabase migration new <name>` |
| Execute SQL file | `npx supabase db execute <file.sql>` |

**Tip:** Omit `npx` if you installed Supabase CLI globally.

---

## Frontend Setup (Flutter)

### 1. Clone the Flutter Repository

```bash
git clone https://github.com/ripplearc/construculator-app
cd construculator-app
```

### 2. Install FVM and Flutter

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

#### Edit .env.dev

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

**Problem:** Emulators cannot access `localhost` on the host machine.

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
- `fishfood` - Beta testing environment
- `prod` - Production environment

The app will load the corresponding environment file (`assets/env/.env.<flavor>`).

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
├── units/              # Unit tests (business logic)
├── widgets/            # Widget tests (UI components)
├── screenshots/        # Golden tests (visual regression)
└── mutations/          # Mutation test configurations
```

### Running Tests Locally

```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test test/units/libraries/auth/auth_notifier_test.dart

# Run tests with coverage
fvm flutter test --coverage

# Run golden tests (inside the docker container)
fvm flutter test < PATH-SCREENSHOT-FEATURE > --update-goldens
```

### Coverage Requirements

- **Target:** 95% code coverage (enforced by CI)
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
   Look for `construculator-app-flutter-1` or similar.

3. **Open shell in container:**
   ```bash
   docker exec -it <NAME-OR-ID-OF-DOCKER-CONTAINER> bash
   ```

4. **Run golden tests inside container:**
   ```bash
   # Verify golden tests
   flutter test test/screenshots

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
./scripts/run_check.sh --pre --target main

# Comprehensive check (full codebase)
./scripts/run_check.sh --comp --target main

# Both pre-check and comprehensive
./scripts/run_check.sh --all --target main

# Mutation tests only
./scripts/run_check.sh --mutations --target main
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
- **Time:** ~15-30 minutes
- **Artifacts:** APK, coverage reports, mutation reports

#### Mutation Tests (`--mutations`)
- **Purpose:** Validate test effectiveness
- **Checks:**
  - Runs mutation tests for changed config files (`test/mutations/*.xml`)
  - Introduces code mutations to verify tests catch them
- **Time:** Varies (can be slow)

**Dependencies:**

The script requires:
- FVM with Flutter 3.32.0
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
./scripts/review_pr.sh feature/new-auth main
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
3. Paste into Claude/Cursor for AI-assisted code review
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

### Supabase Issues

#### ⚠️ Tables Appear Empty (MOST COMMON ISSUE)

**Symptom:** Querying tables from your Flutter app returns `[]` (empty array) even though data exists in Supabase Studio.

**Cause:** **Row Level Security (RLS)** is enabled on the table, and no policy allows the current user to access the data. This is the default behavior for all tables.

**Why This Happens:**
- All tables have RLS enabled by default in the migrations
- RLS policies haven't been created yet (or are incomplete)
- Supabase returns `[]` instead of throwing an error (confusing!)
- Studio shows data because it uses the service_role key which bypasses RLS

**How to Identify RLS Issues:**
1. Data exists in Supabase Studio but not in your app → RLS is blocking
2. Queries return `[]` with no errors → RLS is blocking
3. Same query works in Studio's SQL editor → RLS is the culprit

**Quick Fix (Local Development Only):**

```sql
-- Disable RLS for the table (DO NOT USE IN PRODUCTION)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_estimates DISABLE ROW LEVEL SECURITY;
```

**Via Supabase Studio:**
1. Open `http://localhost:54323`
2. Go to **Authentication** → **Policies**
3. Select the table
4. Click **"Disable RLS"**

**Production Fix (Create Policies):**

If you're implementing the feature for real, create proper RLS policies:

```sql
-- Example: Allow users to read their own data
CREATE POLICY "Users can view own data" ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = credential_id);
```

**Important:** Add policies to migration files in the [construculator-backend](https://github.com/ripplearc/construculator-backend) repo.

**See Section 8** for detailed RLS documentation.

---

#### ⚠️ User Signup Fails - Missing country_code Field

**Symptom:** User signup through the app fails with an error about `country_code` field being missing or invalid.

**Cause:** The `users` table is missing the `country_code` column that the app expects to send during registration.

**Quick Fix:**

1. Open Supabase Studio: `http://localhost:54323`
2. Go to **Table Editor** → `users` table
3. Click **"New Column"**
4. Add column:
   - **Name:** `country_code`
   - **Type:** `text`
   - **Nullable:** Yes (check the box)
5. Click **"Save"**

**Production Fix:**

Create a migration in the backend repo:

```bash
cd construculator-backend
npx supabase migration new add_country_code_to_users
```

Edit the migration file:

```sql
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS country_code TEXT;
```

Apply the migration:

```bash
npx supabase db reset
```

Commit and push the migration to the backend repo.

---
#### OTP Code Not Received

**Symptom:** User signup/login requires OTP but email is never received.

**Fix:**
1. Open Inbucket: `http://localhost:54324`
2. Look for emails addressed to your test user
3. Open the email to see the OTP code
4. Remember: These are test emails, they don't go to real inboxes

#### Not able to initiate Supabase

**Symptom:** App repeatedly crashes after ```supabase start```.

**Emulator workaround:**
1. Reset and reseed local Supabase (no backup):
```bash
npx supabase stop --no-backup
```

#### Seeded Data Not Visible

**Symptom:** After `supabase start`, expected seeded data doesn't appear in tables.

**Possible Causes:**
1. **RLS is blocking access** - Most common (see above)
2. Seeder files weren't applied
3. Migration errors occurred during startup

**Fix:**
```bash
# Reset database completely
npx supabase db reset

# Check for errors in output
# If seeder errors occur, check supabase/seeders/ in backend repo
```

#### Migration Errors

**Symptom:** `supabase start` fails with migration errors.

**Fix:**
1. Check migration files in `supabase/migrations/`
2. Look for syntax errors or broken references
3. Reset database:
   ```bash
   npx supabase db reset
   ```
4. If problem persists, check the [construculator-backend](https://github.com/ripplearc/construculator-backend) repo for updates

### Flutter Issues

#### Build Runner Conflicts

**Symptom:** `build_runner` fails with conflicts.

**Fix:**
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

#### Golden Test Failures

**Symptom:** Golden tests fail with "pixel mismatch" errors.

**Fix:**
1. Use Docker container to generate platform-consistent screenshots:
   ```bash
   docker-compose up -d
   docker exec -it construculator-app-flutter-1 bash
   flutter test test/screenshots --update-goldens
   exit
   ```
2. Commit the updated golden files

### Coverage Issues

#### Coverage Below 95%

**Symptom:** `run_check.sh --pre` fails with "Low coverage" error.

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

- **Backend Database Schema:** [Google Doc](https://docs.google.com/document/d/144-j6mZluSGtFXZdF23cVf9hbVWt4vb-wA3eq02Au4M)
- **Backend Repository:** [construculator-backend](https://github.com/ripplearc/construculator-backend)
- **Supabase Documentation:** [https://supabase.com/docs](https://supabase.com/docs)
- **Flutter Documentation:** [https://docs.flutter.dev](https://docs.flutter.dev)
- **BLoC Pattern:** [https://bloclibrary.dev](https://bloclibrary.dev)

---

## Contributing

1. Create a feature branch with naming convention: `MM-DD-[feat|chore|docs|refactor]_descriptive_name`
2. Make your changes with atomic commits
3. Run `./scripts/run_check.sh --pre` before pushing
4. Create a PR with descriptive title and summary
5. Generate PR review: `./scripts/review_pr.sh <branch> main`
6. Request code review from team
7. Address feedback and ensure CI passes


---

## Team

**Repository:** [construculator-app](https://github.com/ripplearc/construculator-app)
