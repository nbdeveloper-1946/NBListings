# UI Redesign Rollback Instructions

## Baseline

- **Branch:** `ui/apple-inspired-redesign`
- **Tag:** `ui-baseline-pre-redesign` (pre-redesign state on `Main`)

## Restore old UI within minutes

### Option A — Leave the redesign branch

```bash
git checkout Main
```

### Option B — Hard-reset the redesign branch to baseline

```bash
git checkout ui/apple-inspired-redesign
git reset --hard ui-baseline-pre-redesign
```

### Option C — Check out the tag in detached HEAD (read-only restore)

```bash
git checkout ui-baseline-pre-redesign
```

## Rules

- Prefer reverting commits or switching branches over deleting files by hand.
- Never force-push `Main`.
- Design-system and theme files are the primary UI surface; business logic under `features/*/bloc`, `repository`, `services`, `models`, and `core/api|storage|network` must stay untouched.