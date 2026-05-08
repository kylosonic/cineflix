# Mobile Dock Liquid Glass Overhaul

## Objective
Redesign the mobile bottom dock so it feels premium, adaptive, and unmistakably high-end while staying performant and accessible.

## Research summary

### Apple HIG: Materials (2025/2026 Liquid Glass updates)
Source: https://developer.apple.com/design/human-interface-guidelines/materials

Key guidance extracted:
1. Navigation controls should float in a distinct functional layer above content.
2. Liquid Glass should let content peek through while preserving legibility.
3. Prefer regular glass when text/labels need reliable readability.
4. Use color sparingly on glass; over-coloring many controls harms clarity.
5. Adapt for accessibility settings that reduce transparency and increase contrast.

### Apple HIG: Tab bars
Source: https://developer.apple.com/design/human-interface-guidelines/tab-bars

Key guidance extracted:
1. iOS tab bars are floating and translucent above content.
2. Keep tab bars consistently visible for orientation.
3. Labels should be clear and stable; tabs are for navigation, not actions.
4. Selected state should be obvious without overwhelming unselected tabs.

### Apple HIG: Color + Liquid Glass color
Source: https://developer.apple.com/design/human-interface-guidelines/color#Liquid-Glass-color

Key guidance extracted:
1. By default, glass should inherit color from background content.
2. Monochrome labels/icons generally improve readability over rich backgrounds.
3. Accent color should be concentrated in selected/priority state, not all items.
4. Contrast must remain strong in dark/light and increased-contrast contexts.

### Accessibility and standards
Sources:
- https://developer.apple.com/design/human-interface-guidelines/accessibility
- https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- https://www.w3.org/WAI/WCAG21/Understanding/target-size.html

Key guidance extracted:
1. Minimum control size around 44x44 pt for touch interactions.
2. Strong text/icon contrast on translucent backgrounds.
3. Respect reduced-motion and reduced-transparency expectations.
4. Avoid over-animated depth transitions for sensitive users.

## Design decisions for CineFlix dock

1. Layered glass architecture (3 layers)
- Layer A: blur substrate for background separation.
- Layer B: subtle top specular reflection for premium finish.
- Layer C: lower shadow/vignette for floating depth.

2. Active state system
- A moving, softly glowing active capsule behind selected tab.
- Monochrome unselected icons/labels.
- Accent-led selected item only (single emphasis point).

3. Structural refinement
- Wider corner radius for modern floating-dock geometry.
- Controlled vertical padding to increase visual breathing room.
- Equal-width tab slots with stable alignment.

4. Interaction/motion
- Pressable scale on tap.
- Smooth active-capsule travel (eased animation, no bounce).
- Short icon/label transitions for snappy but polished feel.

5. Accessibility guardrails
- 44+ logical touch target.
- Color/contrast tuned for dark cinematic background.
- Animation durations reduced in reduced-motion contexts.

## Implementation scope

Primary file:
- lib/main.dart

Changes:
1. Replace current _MobileShell dock container with new _LiquidGlassDock widget.
2. Replace old _MobileNavItem with _LiquidDockItem for premium states.
3. Add helper _MobileNavDestination model and path-index mapping.
4. Keep route behavior unchanged (Home, Search, Saved, Profile).

## Acceptance criteria
1. Dock appearance clearly differs from previous version at first glance.
2. Selected tab visibility is immediate and premium.
3. Dock still feels readable over busy scrolling content.
4. Touch interactions remain reliable and comfortable.
5. flutter analyze and flutter test pass.

## Non-goals
1. Replacing the web sidebar in this task.
2. Overhauling all app colors/typography in this pass.
3. Introducing external heavy animation dependencies.
