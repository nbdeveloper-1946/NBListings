# NB Listings Design System

Apple-inspired premium UI tokens and components for the NB Listings CRM.
Brand green is preserved as primary; surfaces follow cooler grouped-background patterns.

## Principles

- Visual redesign only — no API, BLoC, or storage changes
- Prefer tokens over hardcoded colors, radii, and durations
- Glass/blur only on chrome (nav, search, sheets, dialogs)
- SF Pro / system font on Apple platforms; bundled **Inter** elsewhere

## Token modules

| Module | Path | Purpose |
|--------|------|---------|
| Colors | `lib/core/design_system/tokens/app_colors.dart` | Surfaces, brand, text, semantic, chart palette |
| Spacing | `lib/core/design_system/tokens/app_spacing.dart` | 4–64 scale + radius tokens |
| Typography | `lib/core/design_system/tokens/app_typography.dart` | Type scale + Material TextTheme |
| Shadows | `lib/core/design_system/tokens/app_shadows.dart` | soft → modal elevations |
| Blur | `lib/core/design_system/tokens/app_blur.dart` | Selective BackdropFilter sigmas |
| Motion | `lib/core/design_system/tokens/app_motion.dart` | Durations + curves + springs |
| Gradients | `lib/core/design_system/tokens/app_gradients.dart` | Soft accent gradients |

## Theme wiring

- Builder: `lib/core/theme/crm_theme.dart` → `CRMTheme.light()` / `CRMTheme.dark()`
- Persistence: `ThemeManager` + SharedPreferences key `crm_theme_is_dark`
- App entry: `lib/main.dart` initializes ThemeManager then applies `CRMTheme`
- Legacy shim: `lib/core/theme/app_theme.dart` maps `AppColors` / `Premium*` → CRM

## Typography scale

Large Display, Large Title, Display, Title, Page Title, Navigation Title, Headline, Section Title/Header, Card Title, Body, Body Medium, Subheadline, Caption, Footnote, Label, Button, Statistics, Chart Labels, Table Headers.

## Spacing & radius

Spacing: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 (`CRMSpacing`).

Radius: `xs`–`huge` plus numeric aliases `r4`…`r40`. Legacy `xl` remains **24** for compatibility.

## Motion

- Fast 150ms · Medium 250ms · Slow 400ms
- Curves: easeIn / easeOut / easeInOut / bounce (easeOutBack)
- Springs: `spring`, `interactiveSpring`

## Blur budget

Use `CRMGlassSurface` / `CRMBlur` only for:

- Navigation chrome
- Search overlay
- Dialogs / bottom sheets
- Floating panels

Do **not** blur every card (web/desktop FPS).

## Import

```dart
import 'package:nblistings/core/design_system/crm_design_system.dart';
```

Or relative imports under `lib/core/design_system/`.
