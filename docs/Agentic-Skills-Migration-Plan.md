# Agentic Skills Migration Plan

## Executive Summary

We're transforming our 15 Flutter development guidelines into **4 comprehensive agent skills** that actively assist developers during feature development. By grouping related rules that share analysis techniques, we achieve better maintainability with fewer skills while providing the same comprehensive coverage. This initiative will reduce development friction, catch issues earlier, and accelerate feature delivery while maintaining our high code quality standards.

## Overview

This document outlines our plan to transform the 15 Flutter development guidelines into **professional agent skills** that assist developers throughout the development process.

These skills will:
- Provide real-time guidance during coding
- Catch issues early before they reach PR review
- Teach best practices through actionable feedback
- Automate repetitive quality checks
- Work as independent, composable modules

**Impact on Feature Development:**
- **Faster iterations:** Catch violations before committing
- **Learning while coding:** Skills teach patterns, not just flag errors
- **Reduced PR cycles:** Fewer review rounds needed
- **Consistent quality:** Every developer gets the same guidance

## Vision: Skills as Development Assistants

**From:** Manual guideline enforcement during PR review
**To:** Proactive development assistance throughout the coding workflow

### How Skills Help Developers

**During Coding:**
- Suggest CoreUI components while writing UI code
- Detect business logic creeping into widgets
- Recommend proper naming conventions for new classes
- Flag missing localization keys

**Before Committing:**
- Verify test coverage patterns
- Check architectural boundaries
- Validate stream lifecycle management
- Detect AI-generated placeholder comments

**During PR Review:**
- Provide structured, consistent feedback
- Generate actionable remediation guidance
- Track quality trends over time
- Enable automated quality gates

---

## How to Use Skills While Developing

### During Feature Development

**1. Ask for guidance proactively:**
```bash
# Before writing a new widget
"I'm about to create a login screen widget. What should I watch out for?"

# Before creating a new class
"I need to create a class that validates user input. What should I name it?"

# While writing UI code
"Check this widget for CoreUI compliance and business logic separation"
```

**2. Run targeted checks on your changes:**
```bash
# Check a specific file
"Run static analysis on lib/features/auth/presentation/login_screen.dart"

# Check your current branch
"Check my branch for UI/business separation issues"

# Before committing
"Review my changes for common violations"
```

**3. Use skills to learn patterns:**
```bash
# Learn the pattern
"Show me examples of correct BLoC state management"

# Understand why something is wrong
"Why is hardcoded spacing a problem?"

# Get architecture guidance
"Where should this calculation logic live?"
```

### During Code Review

**Run comprehensive checks:**
```bash
# Full PR review
"Review this PR against all applicable rules"

# Specific rule check
"Check this PR for test double violations"

# Compare branches
"Compare feat/user-profile to main"
```

### Tips for Maximum Benefit

**✅ Do:**
- Ask skills questions before writing code
- Run checks frequently on small changes
- Use skills to learn patterns, not just find errors
- Request specific skill checks when you know the area

**❌ Don't:**
- Wait until PR review to run checks
- Ignore skill suggestions (they're based on team standards)
- Disable skills without understanding why they flagged something
- Use skills as a replacement for understanding the guidelines

---

## How to Add a New Rule

### Decision: Add to Existing Skill or Create New Group?

**First, determine where your rule belongs:**

1. **Does it fit an existing group?**
   - Static pattern matching → Add to `static-analysis` skill
   - Layer boundaries/state → Add to `architectural-check` skill
   - Test patterns → Add to `test-quality` skill
   - Code cleanliness → Add to `code-health` skill

2. **Does it require unique analysis?**
   - Different file types than existing groups
   - New analysis technique (e.g., performance profiling)
   - Different execution characteristics
   → Consider creating a new skill group

### Adding a Rule to an Existing Skill

**Step 1: Identify the target skill**

```bash
# Example: Adding a rule about forbidden imports
"This checks for import patterns" → Goes in `static-analysis` skill
```

**Step 2: Add rule definition**

Create `skills/{skill-name}/rules/{new-rule-id}.md`:
```markdown
# RULE_16: Forbidden Import Detection

## Detection Patterns
- Pattern: `import.*package:flutter/material.dart` in CoreUI files
- Severity: major
- Message: "Material import in CoreUI component"
- Fix: "Use CoreUI components instead"

## Examples
...
```

**Step 3: Update skill's detection logic**

Edit `skills/{skill-name}/SKILL.md` to include the new rule in the workflow.

**Step 4: Test with existing skill**

```bash
"Run static-analysis skill with new RULE_16 on sample code"
```

### Creating a New Skill Group (Rare)

Only create a new skill when you have multiple related rules that:
- Share unique analysis techniques
- Target different file types than existing groups
- Have distinct performance characteristics

**Example:** If adding performance profiling rules:
```
skills/performance-analysis/
├── SKILL.md
├── rules/
│   ├── RULE_X-memory-leaks.md
│   ├── RULE_Y-render-performance.md
│   └── RULE_Z-build-optimization.md
└── schemas/
```

### Validation Checklist

Before considering a skill complete:

- [ ] Skill has clear trigger conditions
- [ ] Detection patterns are well-defined
- [ ] Output matches standard schema
- [ ] Tested on real code samples
- [ ] False positive rate is acceptable (<10%)
- [ ] Remediation guidance is actionable
- [ ] Added to file routing matrix
- [ ] Examples include violations and corrections

---

## Skill Groups

We organize the 15 guidelines into **4 skill groups** based on analysis complexity:

### 🔍 Group 1: Static Analysis Skills
*Fast, pattern-based checks*

**Skills:**
- **RULE_2**: Class Naming Convention
- **RULE_4**: CoreUI Components Usage
- **RULE_10**: Localization Usage
- **RULE_11**: Precision vs. Abstraction (Level-Based Naming)

**What they do:**
- Verify naming conventions (UseCase, Service, Repository suffixes)
- Detect hardcoded spacing, colors, and Material components
- Find missing localization for user-facing strings
- Check abstraction-appropriate naming (abstract at UI, explicit at data layer)

**Trigger:** Any `.dart` file in `lib/`
**Speed:** Very fast (<1s per file), parallelizable

---

### 🏗️ Group 2: Architectural Analysis Skills
*Context-aware checks for layer boundaries*

**Skills:**
- **RULE_5**: UI & Business Logic Separation
- **RULE_12**: Clean Presentation & State Derivation
- **RULE_6**: Stream-Based Performance & Lifecycle

**What they do:**
- Detect business logic leaking into widgets (guard checks, state derivation)
- Flag UI performing calculations or cross-state coordination
- Verify StreamControllers have proper lifecycle management
- Ensure streams use `distinct()` and proper cancellation

**Trigger:** Presentation layer files (`lib/features/**/presentation/**`, `lib/app/presentation/**`)
**Speed:** Moderate (2-5s per file), may need AST parsing

---

### 🧪 Group 3: Testing Pattern Skills
*Test quality and coverage verification*

**Skills:**
- **RULE_3**: Test Double Pattern (Real vs. Fake)
- **RULE_8**: Widget Test Behavior & Robust Finders
- **RULE_9**: Unit Test Behavior over Implementation
- **RULE_13**: Mutation Testing
- **RULE_14**: Accessibility Testing

**What they do:**
- Detect "fake everything" anti-pattern and mock/stub usage
- Find fragile widget finders (byType, findsNWidgets)
- Check tests focus on behavior vs implementation details
- Run mutation testing on logic-heavy changes
- Verify critical user flows have a11y tests

**Trigger:** Test files (`test/**/*_test.dart`)
**Speed:** Fast for most (1-3s), slow for mutation testing (minutes)

---

### 🛡️ Group 4: Quality & Monitoring Skills
*Code health and observability*

**Skills:**
- **RULE_7**: Self-Documenting & Clean Code
- **RULE_15**: Judicious Sentry Error Reporting

**What they do:**
- Detect AI-generated placeholder comments
- Flag comments explaining "how" instead of "why"
- Find errors logged multiple times in call stack
- Identify expected errors incorrectly logged as critical

**Trigger:** All Dart files
**Speed:** Very fast (<1s per file)

---

## Migration Approach: 4 Skills, Not 15

**Key Insight:** Create one skill per group, not per rule. Rules within a group share analysis techniques and can be checked together.

**Current State:** POC `skills/pr-review/` already handles multiple rules (RULE_4, RULE_5, RULE_10)

**Target Architecture:**

```
skills/
├── static-analysis/        # Group 1: RULE_2, 4, 10, 11
├── architectural-check/    # Group 2: RULE_5, 6, 12
├── test-quality/           # Group 3: RULE_3, 8, 9, 13, 14
└── code-health/            # Group 4: RULE_7, 15
```

**Benefits of Group-Level Skills:**
- **Fewer skills to maintain** (4 instead of 15)
- **Shared analysis infrastructure** within each group
- **Single invocation** checks multiple related rules
- **Natural modularity** based on analysis type

**Next Steps:**

1. **Refactor POC** into `static-analysis` skill
   - Already handles RULE_4, RULE_10
   - Add RULE_2 (Class Naming) and RULE_11 (Precision)

2. **Extract `architectural-check`** from POC
   - Move RULE_5 to new architectural skill
   - Add RULE_6 and RULE_12 with AST parsing

3. **Create `test-quality`** skill
   - Combine all testing rules (RULE_3, 8, 9, 13, 14)
   - Share test file detection and analysis logic

4. **Create `code-health`** skill
   - Combine RULE_7 and RULE_15
   - Focus on comments and logging patterns

---

## Standard Skill Structure

Every skill follows this structure:

```
skills/{skill-name}/
├── SKILL.md                    # Agent execution instructions
├── schemas/
│   ├── input.schema.json       # Input contract
│   └── output.schema.json      # Output contract (structured findings)
├── rules/
│   └── {rule-id}-{name}.md     # Detection patterns & remediation
├── scripts/                    # Helper scripts for analysis
└── references/                 # Examples & documentation
```

**Key Components:**
- **SKILL.md**: Instructs the agent on when/how to run the skill
- **Schemas**: Define structured input/output (enables composition)
- **Rules**: Detection patterns and fix guidance
- **Scripts**: Reusable analysis utilities

---

## File Routing Matrix

This matrix determines which skills run on which files:

| File Pattern | Group 1 | Group 2 | Group 3 | Group 4 |
|-------------|---------|---------|---------|---------|
| `lib/features/**/presentation/*.dart` | ✅ All | ✅ All | ❌ | ✅ All |
| `lib/features/**/domain/*.dart` | RULE_2, RULE_11 | ❌ | ❌ | ✅ All |
| `lib/features/**/data/*.dart` | RULE_2, RULE_11 | ❌ | ❌ | ✅ All |
| `test/**/*_test.dart` | ❌ | ❌ | ✅ All | ✅ RULE_7 |
| `test/**/*_a11y_test.dart` | ❌ | ❌ | ✅ RULE_14 | ❌ |
| `**/*.g.dart`, `**/*.freezed.dart` | ❌ | ❌ | ❌ | ❌ |

**Rules:**
- Generated files (`*.g.dart`, `*.freezed.dart`) are always skipped
- Presentation files trigger the most rules (UI-focused)
- Test files only trigger testing rules (Group 3) + clean code (RULE_7)
- Domain/data files trigger naming + quality rules

---

## Summary

This plan transforms our 15 development guidelines into **4 comprehensive agent skills** that assist developers throughout the coding workflow.

**Key Principles:**
- **Group-based skills**: 4 skills covering 15 rules (not 15 individual skills)
- **Development-focused**: Help developers during coding, not just in PR review
- **Shared infrastructure**: Rules in same group share analysis techniques
- **Progressive expansion**: Build on existing POC, add rules to groups
- **Modular design**: Skills are independent, reusable, and composable

**Final Architecture:**
- `static-analysis` → RULE_2, 4, 10, 11
- `architectural-check` → RULE_5, 6, 12
- `test-quality` → RULE_3, 8, 9, 13, 14
- `code-health` → RULE_7, 15
