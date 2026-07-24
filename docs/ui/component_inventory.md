# Component Inventory

## Shared design-system widgets

| Component | File | Notes |
|-----------|------|-------|
| CRMButton | `widgets/buttons.dart` | Press scale + variants |
| CRMCard / CRMKPICard | `widgets/cards.dart` | Elevated soft cards |
| CRMPropertyCard / CRMRequirementCard | `widgets/crm_entity_cards.dart` | Entity list cards |
| CRMTextField | `widgets/inputs.dart` | Filled grouped inputs |
| CRMDialogs | `widgets/dialogs.dart` | Animated confirmations |
| CRMSnackBar | `widgets/crm_snackbar.dart` | Floating snack helper |
| CRMGlassSurface | `widgets/crm_glass_surface.dart` | Selective glass |
| CRMDataTable | `widgets/data_table.dart` | Active Material table wrapper |
| CRMGenericDataTable | `widgets/crm_data_table.dart` | Generic API (renamed to avoid clash) |
| CRMStatusChip | `widgets/crm_status_chips.dart` | Status pills |
| CRMEmptyState / Error / NoInternet / Permission | `widgets/*_state*.dart` | Empty & error |
| CRMSkeleton* | `widgets/skeletons.dart` | Mode-aware shimmer |
| CRMAppShell | `widgets/app_shell.dart` | Sidebar / drawer / bottom nav / search |
| Filter & property drawers | `crm_filter_drawer.dart`, `drawers.dart` | Overlay chrome |
| Form suite | `widgets/form/*` | Currency, phone, date/time, pickers, etc. |

## Screens (visual pass applied)

Splash, Login, Dashboard, Properties, Property Detail, Recycle Bin, Requirements, Share / Public Property, Clients, Owners, Builders, Users, Settings, Profile, Audit Logs (already tokenized), App Shell chrome.

## Charts

- Dashboard `StatusPieChartPainter` — rounded stroke donut, track, animated progress, chart token colors.

## Legacy (shimmed)

- `AppColors`, `AppSpacing`, `AppBorderRadius`, `AppShadows`, `AppTextStyles`
- `PremiumButton` → `CRMButton`
- `PremiumTextField` → `CRMTextField`
