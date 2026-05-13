---
name: read-ticket
description: |
  Stage 1: Ticket Intake - Understand what to build before coding begins.
  Identifies architecture layers, anticipates classes, determines test types, flags ambiguities.

  Trigger: "read ticket CA-123", "analyze ticket", "what does CA-456 require"

disable-model-invocation: false
---

# Read Ticket Skill

**Verb: Understand what to build.**

Agent's first action when assigned a story. Output primes `plan-implementation` and subsequent coding skills.

## Input

- `ticket_id`: YouTrack ID (e.g., "CA-123")
- `output_format` (optional): `structured` or `conversational`

## Workflow

1. **Fetch ticket** via `mcp__youtrack__get_issue(issueId: ticket_id)`
   - Extract: summary, description, custom fields, comments
   - Handle errors: ticket not found, missing description
   - **Fallback:** If YouTrack MCP unavailable, ask user to paste ticket content directly

2. **Identify layers touched** (presentation, domain, data, integration)
   - UI changes/screens → presentation
   - Business logic/rules → domain
   - API/DB/cache → data
   - New SDK → integration (ask user to confirm)

3. **Anticipate classes** (rough scope, not final naming)
   - Presentation: {Feature}Page, {Feature}Bloc/Event/State
   - Domain: {Verb}{Noun}UseCase, {Noun}Repository (interface)
   - Data: Remote/Local{Noun}DataSource, {Noun}RepositoryImpl

4. **Determine test types**
   - Unit tests: always
   - Widget tests: if presentation touched
   - Golden tests: if layout-sensitive UI
   - Mutation tests: if 4+ conditional branches (per RULE_13: `skills/rules/13-mutation-testing.md`)
   - Accessibility tests: if critical flow

5. **Flag ambiguities**
   - Missing: user flow, edge cases, data source, design refs
   - Unclear: acceptance criteria, conflicting requirements
   - Surface to developer before `plan-implementation`

6. **Output analysis**
   - Layers touched + next skills needed
   - Anticipated classes
   - Required test types
   - Ambiguities + clarifying questions
   - Estimated complexity

## Output Format

**Conversational (default):**
```
📋 Ticket CA-123: Add project estimation page

Layers: Presentation + Domain
Classes: EstimationPage, EstimationBloc, GetEstimationsUseCase
Tests: Unit + Widget + Golden

⚠️ Ambiguities:
- No API endpoint specified
- No error handling mentioned

**Next:** Clarify ambiguities, then plan the implementation using the plan-implementation skill
```

## References

- Next skill: `skills/plan-implementation/SKILL.md`
