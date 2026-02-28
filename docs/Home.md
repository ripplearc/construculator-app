# Construculator Documentation

Welcome to the Construculator App documentation wiki. This guide provides comprehensive information for developers working on the project.

## Getting Started

This documentation covers development guidelines, architectural decisions, and best practices.

## Documentation

| Guide | Description |
|-------|-------------|
| [Testing-Directories](Testing/Directories) | Test directory structure, naming conventions, and CI/CD integration |
| [Testing-Fakes](Testing/Fakes) | Faking strategies, real implementations, and testing patterns |
| [Localization](Localization) | How to add and manage translated strings in the app |

## Dashboard Bottom Navigation (HLD)

- Shell ownership: app-level shell lives under `lib/app/shell` and is the authenticated entry point.
- Tabs: `Home`, `Calculations`, `Cost Estimation`, `Members`.
- Tab mapping:
	- `Home` → `DashboardPage`
	- `Calculations` → `CalculationsModule` (placeholder)
	- `Cost Estimation` → existing estimation flow
	- `Members` → `MembersModule` (placeholder)
- State preservation: one `Navigator` per tab with dedicated keys.
- Lazy loading: each tab navigator is initialized on first tab access only.
- AppHeader: persistent header is rendered from shared project UI provider.
- Architecture boundary: features do not call each other directly; shared contracts live in `lib/libraries`.
- Performance constraints: minimal rebuild surface, no eager tab initialization, preserved per-tab stacks.
- UX constraint: bottom navigation only, adaptive sizing by width; no navigation rail.

