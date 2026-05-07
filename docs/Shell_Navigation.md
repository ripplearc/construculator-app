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
- State preservation: `Offstage` keeps all tab widget trees mounted across tab switches. `TabNavigator` provides a per-tab `GlobalKey<NavigatorState>` used by `AppShellPage` for system back-button handling — it is not the mechanism that preserves state.
- Lazy loading: each tab navigator is initialized on first tab access only.
- App bar: one persistent app bar owned exclusively by `AppShellPage`. Feature pages (`DashboardPage`, `CostEstimationLandingPage`, etc.) are pure content bodies — no `Scaffold`, no `appBar`, no `CurrentProjectNotifier` subscription of their own.
- Architecture boundary: features do not call each other directly; shared contracts live in `lib/libraries`.
- Performance constraints: minimal rebuild surface, no eager tab initialization, preserved per-tab stacks.
- UX constraint: bottom navigation only, adaptive sizing by width; no navigation rail.

### Two-Tier Navigation Model

The shell enforces a strict boundary between two kinds of navigation:

**Tier 1 — Shell-level navigation (`Modular.to` / `AppRouter`)**
For pages that appear full-screen above the shell (details pages, auth flows). Targets the root navigator. The tab bar is hidden while the destination is shown. Tab state is preserved underneath via `Offstage` and reappears on back.

**Tier 2 — In-tab navigation (`Navigator.of(context)`)**
For drill-downs where the tab bar must remain visible. Targets the `TabNavigator`'s local navigator. `Modular.to` / `AppRouter` must never be called for these flows — doing so targets the root navigator and hides the tab bar.

**Decision rule:** if the destination should appear full-screen (tab bar hidden) → Tier 1. If the tab bar must stay visible during the drill-down → Tier 2.

> **Note:** for `ShellModule` to resolve Tier 1 routes called from within a tab, feature modules must be registered as children of the shell route — see the architecture discussion in PR #217.
