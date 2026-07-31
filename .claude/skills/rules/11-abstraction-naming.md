# Abstraction Naming (MERGED)

> **⚠️ This rule has been merged into `Naming & Abstraction`**
>
> **Location:** `skills/rules/02-naming-conventions.md`
>
> **Section:** "Part 2: Abstraction-Level Naming"

## Name
Abstraction Naming (Deprecated - use Naming & Abstraction)

## Migration Note

`Abstraction Naming` and `Naming & Abstraction` (formerly Class Naming Conventions) have been merged because they both address naming practices. The combined rule now covers:

1. **Class naming patterns** - UseCase, Service, Repository, etc.
2. **Abstraction naming** - How abstract or concrete names should be based on layer

## Where to Find This Content Now

All content from `Abstraction Naming` is now in:
- **File:** `skills/rules/02-naming-conventions.md`
- **Section:** "Part 2: Abstraction-Level Naming"

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

## For Skills Referencing Abstraction Naming

If your skill references `Abstraction Naming`, update to reference
`Naming & Abstraction` instead:

```bash
# Old reference
cat skills/rules/11-abstraction-naming.md

# New reference
cat skills/rules/02-naming-conventions.md
# Look for section: "Part 2: Abstraction-Level Naming"
```

---

**See:** `skills/rules/02-naming-conventions.md` for the complete merged rule.
