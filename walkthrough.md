# Walkthrough — Premium Cinematic PropKart Brand Evolution Announcement

We have successfully rebuilt the brand migration experience as a high-fidelity, timeline-driven cinematic movie intro using the actual application logo assets.

## Key Changes Made

### 1. Fixed Gold Plate Bug via Custom ShaderMask Sweep
* **Root Cause**: The `shimmer` package was compiling a solid shader mask over the entire bounding rectangle of the transparent `splash.png` image on Flutter Web (CanvasKit/HTML renderer), creating a solid gold square box instead of drawing over the logo.
* **Resolution**: Replaced `Shimmer.fromColors` with a custom `_MetallicLogoSweep` widget that uses a native `ShaderMask` and `BlendMode.srcATop`.
* This ensures that the metallic light sweep reflection is drawn *only* over the non-transparent pixels of the `splash.png` logo image, making the actual logo fully visible with a premium golden shine passing over it.

### 2. Elongated 7-Second Cinematic Timeline Sequence
* Driven by a 7-second chronological timeline using a single `AnimationController` and tick triggers:
  * **Phase 1: Initial State (0.0s - 1.2s)**:
    * Background starts as solid `Colors.white`.
    * Green Logo (`assets/images/launcher.png`) fades in and remains centered.
    * A green glow backplate (`Color(0xFF5CA380)`) behind the logo animates up in blur radius and opacity, creating an "emitting light" effect.
    * Haptics: Triggers `HapticFeedback.lightImpact()` at 1.0s.
  * **Phase 2: Blueprint Dissolve (1.2s - 2.8s)**:
    * Green logo shatters and dissolves into 280 glowing green particles.
    * The particles morph to align along thin, technical cyan-green vector lines, forming the architectural blueprint wireframes of a house.
    * Haptics: Triggers `HapticFeedback.mediumImpact()` at 1.2s.
  * **Phase 3: Skyline Assembly & Dark Mode Shift (2.8s - 4.6s)**:
    * Background smoothly interpolates from `Colors.white` to deep charcoal (`#090909`).
    * Blueprint lines expand and assemble into a golden, illuminated skyline of houses, apartment skyscrapers, and commercial buildings.
  * **Phase 4: Molten Gold Convergence (4.6s - 5.8s)**:
    * Skyline folds inward and collapses toward the center, morphing into streams of molten gold particles.
    * The new gold logo (`splash.png`) begins to zoom out from scale `0.8` to `1.0` using a smooth `Curves.easeOutCubic` curve.
    * Haptics: Triggers `HapticFeedback.vibrate()` (Heavy reveal) at 4.6s.
  * **Phase 5: PropKart Settle & Metallic Shimmer (5.8s - 7.0s)**:
    * The new logo settles.
    * A horizontal metallic white-gold sweep gradient travels across the logo image to create a realistic light reflection.
    * The tagline **"BUY  •  SELL  •  RENT  •  CONNECT"** slides up and fades in below.

### 3. Post-Cinematic Glassmorphic CTA Panel
* Once the timeline finishes playing (t >= 7.0s), the screen transitions to the final glassmorphic details card and auto-redirect countdown.
* Skip/Close controls are anchored to the top-right to preserve developer overrides.

---

## Verification Results
* **Compilation**: Analyzed with `flutter analyze`, yielding zero type warnings or syntax issues.
* **Layout Integrity**: verified that the actual transparent logo `splash.png` is fully visible and the shine sweeps correctly across the logo contours.
