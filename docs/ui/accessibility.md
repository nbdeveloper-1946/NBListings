# Accessibility Report

## Maintained / improved

| Area | Status |
|------|--------|
| Contrast | Semantic success/warning/danger/info tuned for light & dark |
| Touch targets | Shell icon buttons and CRMButton default height ≥ 44 |
| Semantics | CRMButton exposes `Semantics(button: …)` |
| Text scaling | Uses TextStyle (scales with MediaQuery textScaler) |
| Charts | Tooltip on pie; legend labels remain visible |
| Forms | Existing validators and labels preserved |
| Keyboard | Material focus traversal unchanged |

## Recommendations for follow-up

- Audit icon-only controls in feature screens for `tooltip` / `semanticsLabel`
- Verify large text (200%) on property/requirement cards for overflow
- Run platform accessibility scanners on web and mobile before release
