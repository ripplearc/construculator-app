# Construculator App

# Local Development Environment Setup

This guide explains how to set up and run the application locally, including instructions on how to setup the supabase environment locally. The migrations scripts for the supabase backend are located in this repository: https://github.com/ripplearc/construculator-backend and will be referenced through out this doc. This document consists of two sections, the first one will focus on setting up the supabase backend and the second one will provide instructions on how to get the flutter app running.

# Setting up Supabase
## Repository Structure
```
project-root/
│
├── package.json               # Node dependencies (Supabase CLI or scripts)
├── yarn.lock / package-lock.json
│
└── supabase/
    ├── config.toml            # Supabase local environment configuration
    ├── migrations/            # SQL migration scripts (applied in order)
    ├── seeders/               # SQL seed data files
    ├── tests/database/        # Schema and relationship validation tests
    └── .temp/, .branches/     # Internal Supabase CLI files

```

## Prerequisites
Before starting, please ensure you have the following tools installed.

| Tool                                          | Purpose                                 |
| --------------------------------------------- | --------------------------------------- |
| [Docker](https://docs.docker.com/get-docker/) | Runs Postgres, Studio, and APIs locally |
| [Node.js](https://nodejs.org/en/download/)    | For Supabase CLI and package scripts    |
| (Optional) [TablePlus / DBeaver]              | To inspect database directly            |

## Installation
Clone the repository:
```bash
git clone https://github.com/ripplearc/construculator-backend 
cd construculator-backend
```

Install the supabase CLI and its dependencies:
```
npm install
```

Verify the installation:
```
npx supabase --version
```
If you face any issues in this step, please refer to the supabase documentation on setting up a local development environment: https://supabase.com/docs/guides/local-development.

Alternatively, you could also install it globally using:
```
npm install -g supabase
```

## Initialize the Local Supabase Environment
All Supabase configuration files are inside the `/supabase` directory.

To start the supabase instance:
```
npx supabase start
```
This command performs a multitude of actions. It will:
- Start all the local containers
- Apply initial schema and roles defined in your migrations
- Load default configuration from `supabase/config.toml`, more on this later.

Upon successful execution, you will see something like:
```
Starting database...
Applying migration 20250514010114_01_init_types_and_enums.sql
...
Supabase local development setup complete.
```
**Note:** Make sure docker is running locally before you execute the `supabase start` command.

## Active Containers
This section will briefly describe the containers that expose resources that are relevant to the development/debugging process.

| Container Name                            | Exposed Port | Notes                                                                                                                                                                                                   |
| ----------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| supabase_db-construculator-backend        | 54322        | This container hosts the postgres database used in supabase. If you are using a third-party client to view the database, review the section below.                                                      |
| supabase_studio_construculator-backend    | 54323        | This container hosts the dashboard for the locally running instance of supabase.                                                                                                                        |
| supabase_inbucket_construculator-backend  | 54324        | This container hosts a website for the mail pit dashboard. You can use this to obtain OTP codes that are addressed to certain emails. This is very useful for signing up/logging in users using emails. |
| supabase_analytics_construculator-backend | 54327        | This container hosts the website for logflare, which is a log management and querying service that collects, stores and analyzes log data from supabase services.                                       |

## Connecting to third-party DB clients
During development, it is sometimes convenient to quickly view the state of the database after certain actions to debug some issues. Accordingly, it might be smart to have a GUI client to connect to the database and view the entries in each table, like TablePlus for instance.

To connect to the database directly, you can use the following credentials and details:
- Host - `localhost`
- Port - `54322`
- User - `postgres`
- Password - `postgres`
- Database - `postgres`

To connect to the database using `psql`:
```
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

## Working with Migrations
To reapply migrations after a reset manually, you can use:
```
supabase migration up
```

To reset and reinitialize the database:
```
supabase db reset
```
**Note:** This deletes all local data and re-applies the migrations.

## Summary of Common Maintenance Commands
|Action|Command|
|---|---|
|Start Supabase services|`supabase start`|
|Stop Supabase services|`supabase stop`|
|View service logs|`supabase logs`|
|Reset and rebuild the DB|`supabase db reset`|
|Create a new migration|`supabase migration new <migration_name>`|
|Execute a SQL file manually|`supabase db execute <path-to-sql>`|

Add `npx` before each of the following commands if you didn't install `supabase` globally.

## Troubleshooting
|Issue|Cause|Fix|
|---|---|---|
|Tables not visible in TablePlus|Using wrong port or user|Use `54322` and `postgres`|
|Migration errors|SQL syntax or dependency issue|Check `supabase/migrations` for broken references|
|RLS blocking access|Row-Level Security enabled|Disable for local testing: `ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;`|
|CLI fails to start|Old Docker containers|Run `supabase stop && docker system prune -af`|

# Running the Application
This section assumes you have a running working setup with flutter. If not, please refer to the flutter documentation before proceeding: https://docs.flutter.dev/get-started.
## Environment Variables
There is a template environment file in `assets/env`. To create a development environment, duplicate the `.env.template` file and rename it to `.env.dev`. The template file looks as follows:
```
APP_ENV="dev"

APP_NAME=Construculator

API_URL=http://localhost:8000/api

SUPABASE_URL=http://localhost:3000

SUPABASE_ANON_KEY=fake-key

DEBUG_MODE=true

ANALYTICS_ENABLED=false
```

Note: You might face a problem where the application fails to connect to the supabase instance. This happens particularly when you attempt to run the application using an emulator. To resolve this issue, you have to change the `API_URL` and `SUPABASE_URL` variables to use your local IP instead of `localhost`.

To obtain your local IP address, you can run the following command:
```
ipconfig      # Windows
ip            # Linux
```
Copy over your local IP from whichever adapter is active and replace the `localhost` in the aforementioned environment variables.

## Starting the Application
To run the flutter app, use the following command:
```
flutter run --flavor <FLAVOR> -t lib/main.dart
```
And replace `<FLAVOR>` with your preference mode, `dogfood`, `fishfood`, etc...

## Troubleshooting Common Issues
#### Invalid entry when signing up users
> As of the time of writing, there isn't a `country_code` field in the `users` table. This will cause an error to be thrown when attempting to signup as a user. If the migrations haven't been fixed, navigate to the supbase dashboard running locally, go to the table editor and add a text field called `country_code` to the `users` table. Signing up should work as usual following this.

#### Table entries not appearing when fetching using the supabase wrapper
> Among the supabase migrations, there is a file that enables RLS for each table. This essentially creates an authorization check for every entry in each table, but there aren't any rules at the time of writing. This issue can be particularly frustrating because supabase returns an empty array instead of throwing an error. If you are working on the feature itself, please create the RLS rule and add it to the migration scripts. Although it is not recommended, you can also disable RLS when working on a feature initially.

# Generating Screenshots for Golden Tests

Golden tests work by comparing widget screenshots to baseline images. But these screenshots can vary between platforms. To mitigate this problem, there is a docker image and a docker compose file in the root directory of this project. The container produces the environment used in code magic for the CI checks where the screenshots can be generated.

To use this setup for generating screenshots, first make sure to `cd` into the root directory of the project then run:
```
docker-compose up -d 
```
This command starts up the docker container. Note: this pulls the relevant base image and the dependencies so it will take a while for the image to build.

Then run:
```
docker container ps
```
This command retrieves all the running containers in your system. From the output of this command, save EITHER the id or the full name of the running container. The name will most likely resemble: `construculator-app-flutter-1`.

Now that the container is up and running, you'll need to open an interactive shell to interact with the tests:
```
docker exec -it <NAME-OR-ID-OF-DOCKER-CONTAINER> bash    
```
Replace `<NAME-OR-ID-OF-DOCKER-CONTAINER>` with the value you retrieved in the previous step.

You should now have access to a `bash` terminal inside the container. Make sure you are in the `/app` directory and you can now run all the tests and generate screenshots for your golden tests.

Run a single test file (useful for local verification and CI):
```
flutter test <PATH-TO-TEST>
```

Update golden images (only run when a visual change is intended and reviewed):
```
flutter test <PATH-TO-TEST> --update-goldens
```

**Note:** There is a volume binding in the container so all the generated tests should be present in your local repository and there is no need to copy over the screenshot files from the container.

## Troubleshooting

#### Dependency issue when running the `flutter test` command
> If you created the container image in one branch and switch to a different branch that has a different set of dependencies (updated `pubspec.yaml` file), you have to rebuild the docker image and re-run the container. Stop the container that is currently running, then run `docker-compose up -d --build` to rebuild the image. You can then follow the rest of the steps to access a shell in the container and run the tests.