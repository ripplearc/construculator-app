# RULE 11: Abstraction-Based Naming (MERGED)

> **⚠️ This rule has been merged into RULE_2: Naming Conventions**
>
> **Location:** `skills/rules/02-naming-conventions.md`
>
> **Section:** "Abstraction Naming (original RULE_11)"

## Rule ID
RULE_11 (Deprecated - use RULE_2)

## Migration Note

RULE_11 (Abstraction-Based Naming) and RULE_2 (Class Naming Conventions) have been merged because they both address naming practices. The combined rule now covers:

1. **Class naming patterns** (original RULE_2) - UseCase, Service, Repository, etc.
2. **Abstraction naming** (original RULE_11) - How abstract or concrete names should be based on layer

## Where to Find This Content Now

All content from RULE_11 is now in:
- **File:** `skills/rules/02-naming-conventions.md`
- **Section:** Lines 200+ under "Abstraction Naming (original RULE_11)"

Key topics covered:
- Abstract names in UI/Domain layers (e.g., `LoginScreen`, not `SupabaseAuthScreen`)
- Concrete names in Data layer (e.g., `RemoteUserDataSource` using Supabase)
- Decision tree for choosing abstraction level
- Examples of abstract vs concrete naming

## Quick Reference

| Layer | Abstraction Level | Example |
|-------|------------------|---------|
| Presentation | Abstract (user-facing) | `LoginScreen` |
| Domain | Abstract (business-focused) | `GetUserUseCase` |
| Data | Concrete (technology-aware) | `RemoteUserDataSource` (Supabase) |

## For Skills Referencing RULE_11

If your skill references `RULE_11`, update to reference `RULE_2` instead:

```bash
# Old reference
cat skills/rules/11-abstraction-naming.md

# New reference
cat skills/rules/02-naming-conventions.md
# Look for section: "Abstraction Naming (original RULE_11)"
```

---

**See:** `skills/rules/02-naming-conventions.md` for the complete merged rule.
