# Performance Notes

## Blur budget

- BackdropFilter limited to search overlay, glass nav surfaces, and similar chrome
- Cards and lists use solid elevated surfaces + soft shadows (cheaper)

## Charts

- Dashboard pie wrapped in `RepaintBoundary`
- Animation via `TweenAnimationBuilder` (no continuous ticker after settle)

## Lists

- Existing lazy builders preserved
- Skeleton shimmer uses a repeating controller only while visible

## Motion

- Prefer `CRMMotion.fast/medium` for press/chrome
- Avoid stacking multiple full-screen blurs

## Target

- 60 FPS baseline; 120 FPS where the platform supports it
- If FPS drops on web after adding blur, disable `enableBlur` on `CRMGlassSurface` for that surface
