---
name: plan-implementation
description: |
  Stage 2: Implementation Planning - Decide what to create before writing code.
  Applies RULE_1 (digestible PRs), RULE_2 (naming), checks CoreUI availability.

  Trigger: "plan implementation" (implementation planning intent), "plan this feature" (ticket-to-file planning intent), "what files do we need for implementation"

disable-model-invocation: false
---

# Plan Implementation Skill

**Verb: Decide what to create.**

Agent's blueprint phase before coding. Outputs: file paths, class names, dependencies, CoreUI checks, PR split strategy.

## Input

- **Context from `read-ticket`** (conversation history): layers touched, anticipated classes
- `output_format` (optional): `structured` or `checklist`

## Workflow

1. **Review `read-ticket` context** (from conversation history)
   - If missing: ask user to run `/read-ticket` or describe what they're building

2. **Gather layer-specific inputs** — ask the user only for what the touched layers actually need; skip anything already clear from the ticket

   **Domain layer (entities, use cases, repository interfaces):**
   - Entity fields: ask for each field's name, type, and nullability (e.g. `id: String`, `title: String`, `completedAt: DateTime?`)
   - Any enums or value objects that belong on the entity?

   **Data layer (DataSource, RepositoryImpl, DTO):**
   - Supabase table name(s) for each entity being fetched/mutated
   - Column names + types if they differ from entity fields; otherwise confirm they match
   - Any joins or related table names required for the query?

   **Presentation layer (BLoC, Page):**
   - Entry point: which screen navigates here, and what arguments does it pass?
   - Any form inputs or user-submitted data on this screen?
   - Any non-obvious loading / error / empty state behavior not described in the ticket?

   **Rules:**
   - Ask all relevant questions in one message grouped by layer — never drip-feed one question at a time
   - Do not ask for info that is unambiguous from the ticket context
   - If multiple layers are touched, ask for all their inputs together before proceeding

3. **Apply RULE_2** (naming conventions) → Load `skills/rules/02-naming-conventions.md`
   - Use suffix table + decision tree to name all classes
   - Apply abstraction naming: abstract at UI/domain, explicit at data layer
   - Output: precise class names with responsibilities

4. **Determine file structure** (Flutter conventions)
   ```
   lib/features/{feature}/
     presentation/pages/    → {feature}_page.dart
     presentation/bloc/     → {feature}_bloc|event|state.dart
     domain/usecases/       → {verb}_{noun}_usecase.dart
     domain/repositories/   → {noun}_repository.dart
     data/repositories/     → {noun}_repository_impl.dart
     data/data_source/      → remote|local_{noun}_data_source.dart
   ```

5. **Check CoreUI availability** (if presentation layer touched) → See RULE_4
   - Identify required components from ticket (buttons, inputs, icons, cards, etc.)
   - Check `skills/references/coreui-api.md` (⚠️ may be outdated - use as quick reference only)
   - **Source of truth:** https://github.com/ripplearc/coreui#readme (always check live README)
   - If component missing: flag as blocker with RULE_4-compliant options only:
     1. Use existing CoreUI component with custom layout
     2. Request CoreUI team to add it
     3. Build custom component following CoreUI design patterns
   - ❌ Never suggest "use Material temporarily" (violates RULE_4 Critical severity)

6. **Verify dependencies** (no layer violations)
   - BLoC depends on UseCase (not Repository/DataSource)
   - UseCase depends on Repository interface (not RepositoryImpl/DataSource)
   - RepositoryImpl depends on DataSource
   - Flag violations if found

7. **Apply RULE_1** (digestible PRs) → Load `skills/rules/01-digestible-pr.md`
   - **Estimate production LOC** using this heuristic (before code is written):

     | Class Type | Typical LOC |
     |------------|-------------|
     | Page (simple) | 80-120 |
     | Page (complex) | 150-250 |
     | BLoC (basic CRUD) | 60-100 |
     | BLoC (complex state) | 120-180 |
     | Event class | 10-20 |
     | State class | 20-40 |
     | UseCase (simple) | 20-40 |
     | UseCase (complex) | 50-80 |
     | Repository (interface) | 10-30 |
     | RepositoryImpl | 40-70 |
     | DataSource (remote) | 50-90 |
     | DataSource (local) | 30-60 |
     | DTO/Model | 15-30 |

   - Sum LOC for all classes, exclude tests/generated files
   - If >200 LOC: suggest PR split strategy
     - By layer: Domain → Data → Presentation
     - By dependency: Foundation → Feature → UI
     - By scope: Core feature → Error handling → Polish
   - Output: PR plan with each PR's focus + estimated LOC

8. **Compile plan**
   - Classes + file paths
   - CoreUI check results + blockers
   - Dependencies + violations
   - PR split strategy
   - Next skills to invoke

## Output Format

**Checklist (default):**
```markdown
# Plan: CA-123 - Add estimation screen

## Classes (RULE_2 applied)
- EstimationPage (lib/features/estimation/presentation/pages/estimation_page.dart)
- EstimationBloc/Event/State (lib/features/estimation/presentation/bloc/...)
- GetEstimationsUseCase (lib/features/estimation/domain/usecases/get_estimations_usecase.dart)
- EstimationRepository (interface, lib/features/estimation/domain/repositories/...)
- EstimationRepositoryImpl (lib/features/estimation/data/repositories/...)
- RemoteEstimationDataSource (lib/features/estimation/data/data_source/...)

## CoreUI Check (RULE_4)
✅ CoreButton, CoreTextField, CoreLoadingIndicator
❌ CoreCard (BLOCKER) → Options per RULE_4:
  1. Use existing CoreUI component with custom layout
  2. Request CoreUI team to add CoreCard
  3. Build custom CoreCard following CoreUI patterns

## Dependencies
- EstimationBloc → GetEstimationsUseCase ✅
- GetEstimationsUseCase → EstimationRepository ✅
- EstimationRepositoryImpl → RemoteEstimationDataSource ✅

## PR Strategy (RULE_1)
Estimated: ~420 LOC production code → Split into 2 PRs

PR1 (Domain + Data): ~150 LOC
- GetEstimationsUseCase + EstimationRepository
- EstimationRepositoryImpl + RemoteEstimationDataSource + EstimationDto
- Unit tests for UseCase + Repository

PR2 (Presentation): ~270 LOC
- EstimationPage + EstimationBloc/Event/State
- Widget tests + Golden tests
- Depends on: PR1 merged

→ Next: Resolve CoreCard blocker, then code PR1 with code-domain and code-data skills
```

## References

- **RULE_1:** `skills/rules/01-digestible-pr.md` (PR size + split strategies)
- **RULE_2:** `skills/rules/02-naming-conventions.md` (suffix + abstraction naming)
- **RULE_4:** `skills/rules/04-coreui-components.md` (CoreUI usage + missing component handling)
- **CoreUI API:** `skills/references/coreui-api.md` (quick reference - may be outdated)
- **CoreUI Source of Truth:** https://github.com/ripplearc/coreui#readme (always check live)
- **Next skills:** `code-presentation/`, `code-domain/`, `code-data/` (planned — coming in next PR)
