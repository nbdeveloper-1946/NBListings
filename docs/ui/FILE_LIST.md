# Modified / New / Deleted Files

## New

- `assets/fonts/Inter-*.ttf` (Regular, Medium, SemiBold, Bold)
- `docs/ui/ROLLBACK.md`
- `docs/ui/design_system.md`
- `docs/ui/component_inventory.md`
- `docs/ui/theme_architecture.md`
- `docs/ui/before_after.md`
- `docs/ui/performance.md`
- `docs/ui/accessibility.md`
- `docs/ui/FILE_LIST.md` (this file)
- `docs/ui/maintenance.md`
- `docs/ui/commit_history.md`
- `docs/ui/validation_checklist.md`
- `lib/core/design_system/tokens/app_blur.dart`
- `lib/core/design_system/tokens/app_motion.dart`
- `lib/core/design_system/tokens/app_gradients.dart`
- `lib/core/theme/crm_theme.dart`
- `lib/core/design_system/widgets/crm_glass_surface.dart`
- `lib/core/design_system/widgets/crm_snackbar.dart`
- `lib/core/design_system/widgets/crm_entity_cards.dart`

## Modified (primary)

- `pubspec.yaml` (fonts)
- `lib/main.dart`
- `lib/core/theme/theme_manager.dart`
- `lib/core/theme/app_theme.dart` (shim)
- `lib/core/design_system/crm_design_system.dart`
- `lib/core/design_system/tokens/app_colors.dart`
- `lib/core/design_system/tokens/app_spacing.dart`
- `lib/core/design_system/tokens/app_typography.dart`
- `lib/core/design_system/tokens/app_shadows.dart`
- `lib/core/design_system/widgets/buttons.dart`
- `lib/core/design_system/widgets/cards.dart`
- `lib/core/design_system/widgets/inputs.dart`
- `lib/core/design_system/widgets/dialogs.dart`
- `lib/core/design_system/widgets/empty_state.dart`
- `lib/core/design_system/widgets/skeletons.dart`
- `lib/core/design_system/widgets/data_table.dart`
- `lib/core/design_system/widgets/crm_data_table.dart` (renamed class)
- `lib/core/design_system/widgets/app_shell.dart`
- `lib/core/design_system/widgets/drawers.dart`
- `lib/core/design_system/widgets/crm_filter_drawer.dart`
- `lib/splash.dart`
- `lib/features/auth/login_screen.dart`
- Feature screens: dashboard, properties, requirements, clients, users, profile, settings, recycle bin, share, public property detail

## Deleted

- None (reversible redesign; no asset deletions)

## Untouched (by design)

- `features/*/bloc`, `repository`, `services`, `models`
- `core/api`, `core/storage`, `core/network`
- Route paths in `app_router.dart`
