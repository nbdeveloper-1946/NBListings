# Theme Architecture

```
ThemeManager (persisted preference)
        │
        ├─► CRMColors / CRMShadows / CRMGradients (mode-aware getters)
        │
        └─► MaterialApp.themeMode
                 ├─ CRMTheme.light()
                 └─ CRMTheme.dark()
                        │
                        ├─ ColorScheme (brand green primary)
                        ├─ TextTheme (CRMTypography)
                        ├─ Component themes (AppBar, Card, Dialog, Input, NavBar, SnackBar…)
                        └─ CRMSemanticColors extension
```

## Light mode

- Background `#F2F2F7` (grouped)
- Surfaces white / elevated white
- Soft shadows, minimal 0.5 borders
- Primary `#688A75`

## Dark mode

- Background `#0B0B0D` (deep, not flat card black)
- Surfaces `#1C1C1E` / elevated `#2C2C2E`
- Glass translucency on chrome
- Primary `#5CA380`
- Soft highlights via borders/shadows — no flat black cards

## Fonts

| Platform | Font |
|----------|------|
| iOS / macOS | System (SF Pro) |
| Android / Windows / Linux / Web | Bundled Inter (`assets/fonts/`) |
