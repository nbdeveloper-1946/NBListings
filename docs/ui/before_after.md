# Before vs After

## Before

- Dual systems: CRM tokens + legacy `AppColors` on splash/login
- Warm cream light palette; incomplete type/shadow/motion tokens
- Inter referenced but not bundled
- Theme preference not persisted
- Thin `ColorScheme.fromSeed` ThemeData
- Duplicate `CRMDataTable` class names
- Hardcoded Colors/TextStyle/radii across large screens
- Pie chart with square stroke ends, no load animation
- Almost no glass/blur chrome

## After

- Single CRM token source of truth; legacy shimmed
- Cooler Apple-style grouped surfaces; brand green kept
- Full type/radius/shadow/blur/motion/gradient tokens
- Inter bundled; SF system on Apple
- Persisted ThemeManager + full `CRMTheme`
- Shared glass surface, snackbar helper, entity cards
- Shell chrome with selective glass + CRMMotion
- Auth restyled onto CRM tokens
- Pie chart: rounded caps, track, animated reveal, RepaintBoundary
- Surgical token pass across list/detail/share screens

## Functional parity

Business logic, APIs, Isar, sync, routes, and feature set are unchanged.
