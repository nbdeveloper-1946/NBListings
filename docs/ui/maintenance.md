# Maintenance Guidelines

1. **Style with tokens only** — new UI should use `CRMColors`, `CRMSpacing`, `CRMBorderRadius`, `CRMTypography`, `CRMShadows`, `CRMMotion`. Avoid raw `Color(0x…)` and magic paddings.
2. **Extend tokens, don’t fork** — add members to existing CRM classes rather than creating a parallel theme.
3. **Glass sparingly** — use `CRMGlassSurface` for chrome only.
4. **Keep logic separate** — design-system PRs must not change BLoC/API/Isar.
5. **Deprecate before delete** — shim legacy APIs for one release cycle (see `app_theme.dart`).
6. **Commit checkpoints** — UI phases should land as discrete commits for easy revert.
7. **Fonts** — update Inter files under `assets/fonts/` and `pubspec.yaml` together.
8. **Dark mode** — verify both modes when adding surfaces; never use flat black cards.
9. **Tables** — prefer `data_table.dart` (`CRMDataTable`); use `CRMGenericDataTable` for the generic API.
10. **Rollback** — see `docs/ui/ROLLBACK.md` (`ui-baseline-pre-redesign` tag).
