# Validation Checklist

Post-implementation verification (manual QA recommended before merge):

- [x] No intentional business logic / API / backend changes in redesign commits
- [x] Navigation routes preserved
- [x] Design tokens expanded and wired through ThemeData
- [x] Inter bundled; ThemeManager persists preference
- [x] Shared components + shell restyled
- [x] Splash/login on CRM tokens (legacy shimmed)
- [x] Feature screens token pass + entity cards
- [x] Dashboard pie chart restyled + animated
- [x] Rollback docs + baseline tag available
- [ ] Manual: no overflow on phone / tablet / desktop
- [ ] Manual: light + dark mode visual QA
- [ ] Manual: web + mobile + desktop smoke
- [ ] Manual: no animation jank on search overlay / sheets
- [ ] Manual: accessibility pass (large text, screen reader spot-check)
- [ ] Manual: performance spot-check with blur on web

Stop and report if any functional regression appears; revert to `ui-baseline-pre-redesign` if needed.
