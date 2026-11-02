# RULE 17: Ink Needs Its Own Material

## Name
Ink Needs Material

## Category
UI Components - Touch Feedback

## Severity Levels
- **Major:** `Ink` / `InkWell` / `InkResponse` has a colored parent between it and the nearest `Material`, so the splash is painted under the color and cannot be seen
- **Minor:** `Ink` / `InkWell` relies on a `Material` from another widget (a page `Scaffold`, a parent component) with nothing colored in between today, but the widget can be placed under a colored parent by its callers
- **Suggestion:** Move a parent's color onto `Ink(decoration:)` so the color and the splash share one `Material`

## Description

`InkWell`, `InkResponse` and `Ink` do not paint the splash themselves. They paint it on the nearest `Material` above them. Every widget between that `Material` and the `InkWell` is painted **on top of** the splash. When one of those widgets paints a color — a `Container(color:)`, a `DecoratedBox`, a `ColoredBox` — the splash is hidden under it. The tap still works, but there is no visual feedback, so the button looks dead to the user.

**Core Principle:** Each `Ink` / `InkWell` needs a `Material` close above it, with nothing colored in between.

## Applicability

Changed files under `**/presentation/` and `lib/app/` that contain `Ink(`, `Ink.image(`, `InkWell(` or `InkResponse(`.

---

## For Coding Agents (Prescriptive)

### Decision Tree

```
Does the widget use Ink / InkWell / InkResponse?
  └─ YES → Walk up the build method from the InkWell.
      ├─ Reach a Material first?                       → OK
      ├─ Reach a colored widget first?                 → Add a Material between them (fix A)
      │                                                   or move the color onto Ink (fix B)
      └─ Reach the top of build with neither?          → Add a Material at the top (fix A),
                                                          the caller may place it on any color
```

### ❌ / ✅

```dart
// ❌ The Container's color is painted over the splash; the tap shows nothing.
Container(
  color: context.colorTheme.pageBackground,
  child: InkWell(
    onTap: onTap,
    child: child,
  ),
)

// ✅ Fix A — a transparent Material right above the InkWell.
Container(
  color: context.colorTheme.pageBackground,
  child: Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: onTap,
      child: child,
    ),
  ),
)

// ✅ Fix B — the color moves onto Ink, which paints on the same Material as the splash.
Material(
  type: MaterialType.transparency,
  child: Ink(
    color: context.colorTheme.pageBackground,
    child: InkWell(
      onTap: onTap,
      child: child,
    ),
  ),
)
```

Use `MaterialType.transparency` unless the `Material` itself should paint the background. Keep any `borderRadius` on the `Material` / `InkWell` the same as the colored shape, so the splash is clipped to it.

### What counts as "colored"

| Colored (blocks the splash) | Not colored (OK between Material and InkWell) |
|---|---|
| `Container(color: …)`, `Container(decoration: BoxDecoration(color:/gradient:/image: …))` | `Container` with only `padding`, `margin`, size or `alignment` |
| `ColoredBox`; `DecoratedBox` / `DecoratedSliver` whose decoration has a color, gradient or image | `Padding`, `SizedBox`, `Align`, `Center`, `Row`, `Column`, `Stack` |
| `Card`, `Chip` and other widgets that paint their own background, unless they are the Material themselves | `ClipRRect`, `Semantics`, `Focus`, `MouseRegion` |
| `Image`, `CoreIconWidget` or any opaque child placed *above* the splash in a `Stack` | `Opacity`, `Transform` |

`Card`, `Dialog`, `Scaffold`, `BottomSheet` and `AppBar` already create a `Material`. An `InkWell` directly inside one of them is fine.

An `InkWell` that draws no ink on purpose — `splashFactory: NoSplash.splashFactory` **and** a transparent `overlayColor` (or `highlightColor` + `hoverColor` + `focusColor` all transparent) — is out of scope: there is nothing to hide. A `BoxDecoration` with only `boxShadow`, `border` or `borderRadius` is not colored either.

---

## For Review Agents (Detective)

### Detection Patterns

```bash
# 1. Candidates: every ink widget in a changed file
git grep -nE '\b(Ink|InkWell|InkResponse)\(|Ink\.image\(' "$PR_BRANCH" -- <changed files>
```

```
For each hit:
  2. Read the file (git show "$PR_BRANCH:<file>") upward from the hit to the
     nearest `Widget build(`. That is the search range.
  3. Inside the range, walk up through each enclosing widget call (each
     child: / children: level). The first Material( or colored widget
     (table above) wins.
     Skip the hit if the InkWell draws no ink on purpose (NoSplash +
     transparent overlay, see above).
  4. Colored widget first                         → Major
     Neither before build(, widget is reusable
     (takes child / onTap from its caller)        → Minor
     Material first, or not reusable              → no finding
```

Only ancestors in the **same build method** count. A `Material` in a parent widget's `build` is not seen by the rule; that is what the Minor case is for.

### Finding shape

- `line`: the line of `InkWell(` / `Ink(` / `InkResponse(`.
- `snippet`: from the colored ancestor down to the ink widget.
- `suggested_fix`: fix A or fix B from above, with the real widget names.

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|---|---|---|
| `Container(color: x, child: InkWell(...))` | `Container(color: x, child: Material(type: MaterialType.transparency, child: InkWell(...)))` | Major |
| `DecoratedBox(decoration: BoxDecoration(color: x, borderRadius: r), child: InkWell(...))` | `Material(color: x, borderRadius: r, child: InkWell(borderRadius: r, ...))` | Major |
| `Stack(children: [InkWell(...), Image(...)])` (image over the splash) | Put the `InkWell` last in the `Stack`, or use `Ink.image` | Major |
| Reusable tile: `build` returns `InkWell(...)` with no `Material` | Wrap in `Material(type: MaterialType.transparency, ...)` | Minor |

### Review Questions

1. Walking up from the `InkWell`, is a `Material` reached before any color? → if no, flag.
2. Can callers place this widget on a colored background? → if yes and there is no own `Material`, flag Minor.
3. Does the splash shape match the colored shape (`borderRadius`)? → if no, suggest matching it.

---

## Summary: Suggested Fixes

1. Put `Material(type: MaterialType.transparency)` right above the `Ink` / `InkWell`.
2. Or move the parent's color onto `Ink(color:/decoration:)` under one `Material`.
3. Match `borderRadius` on the `Material` / `InkWell` to the colored shape.
4. Prove it in a widget test: press the widget inside a colored parent and check the splash in a golden.

## References

- [Flutter `InkWell` docs: "The InkWell widget must have a Material widget as an ancestor"](https://api.flutter.dev/flutter/material/InkWell-class.html)
- [Flutter `Ink` docs: "Drawing ink on Material"](https://api.flutter.dev/flutter/material/Ink-class.html)
- Related: CoreUI Components, Accessibility
