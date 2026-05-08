# CineFlix UI Motion And Polish Plan

## Skills loaded before planning
- boil-the-ocean-standard
- flutter-expert
- ui-ux-pro-max

## Goal
Deliver a complete UI polish pass that makes CineFlix feel cinematic, responsive, and alive across mobile and web while keeping performance stable and accessibility-safe.

## Current state audit (codebase-specific)
1. Route-level transitions are limited.
   - Shell tabs use NoTransitionPage in lib/main.dart, so tab switches feel abrupt.
   - Detail route uses a simple fade only.
2. Motion exists but is local and inconsistent.
   - Multiple AnimatedContainer and hover states are present across cards and nav.
   - There is no shared motion token system (durations, curves, amplitudes).
3. Loading states are mixed.
   - Home has shimmer skeletons in several sections.
   - Search, watchlist, profile, and detail rely heavily on centered spinners or static state cards.
4. Shared element transitions are missing.
   - Movie posters do not animate into detail view with Hero.
5. Accessibility and reduced-motion handling are not centralized.
   - No single strategy for users with reduced animation preferences.

## Design and motion direction
1. Cinematic, not playful: smooth fades, parallax-lite movement, depth via scale and blur.
2. Tight timing system:
   - Fast: 120ms to 160ms for tap feedback.
   - Standard: 200ms to 260ms for component transitions.
   - Emphasis: 300ms to 420ms for screen entrances and hero moments.
3. Animation primitives:
   - Prefer opacity and transform (translate/scale), avoid layout-thrashing width/height animation.
4. Accessibility:
   - Respect reduced motion by collapsing transitions to near-instant fades.

## Phase plan

### Phase 1 - Motion foundation and tokens
Targets:
- Create centralized motion tokens and reusable wrappers.
Planned files:
- lib/theme/motion_tokens.dart (new)
- lib/widgets/motion/fade_slide_in.dart (new)
- lib/widgets/motion/staggered_reveal.dart (new)
- lib/widgets/motion/pressable_scale.dart (new)

Deliverables:
1. Motion constants (durations, curves, offsets, scale values).
2. Reduced-motion aware helper that reads MediaQuery accessibility settings.
3. Reusable reveal widget for one-off section entrances and list stagger.
4. Reusable press feedback wrapper for cards/buttons.

Acceptance criteria:
- All new motion uses tokenized durations/curves.
- Reduced-motion mode disables non-essential movement.

### Phase 2 - Navigation and route transitions
Targets:
- Replace abrupt tab switches and upgrade detail route transition.
Planned file updates:
- lib/main.dart

Deliverables:
1. Replace NoTransitionPage with subtle fade-through or fade+slide transitions.
2. Keep route identity stable and avoid rebuild flicker.
3. Add consistent transition for modal/push flows.

Acceptance criteria:
- Tab and route changes feel smooth on both mobile and web.
- No navigation regressions.

### Phase 3 - Home screen cinematic choreography
Targets:
- Upgrade first impression and section rhythm.
Planned file updates:
- lib/screens/home/home_screen.dart
- lib/widgets/movie_card.dart
- lib/widgets/movie_card_netflix.dart

Deliverables:
1. Staggered entrance for header, hero, tabs, and rows.
2. Hero animation from poster card to detail header.
3. Smooth pull-to-refresh state handoff (content does not hard-pop).
4. Improve row/grid item loading placeholders with progressive reveal.

Acceptance criteria:
- Home feels alive immediately on entry.
- No frame drops when scrolling horizontally and vertically.

### Phase 4 - Search and discovery transitions
Targets:
- Make query-to-results flow fluid and responsive.
Planned file updates:
- lib/screens/search/search_screen.dart

Deliverables:
1. Animated transition between discovery and result states beyond simple switch.
2. Staggered reveal for suggestion chips and genre chips.
3. Debounce visual feedback (search field active/loading cue).
4. Skeleton grid for results loading.

Acceptance criteria:
- Search feels immediate and smooth under rapid typing.
- State transitions are perceptible but fast.

### Phase 5 - Detail screen storytelling
Targets:
- Increase depth and continuity from list to detail.
Planned file updates:
- lib/screens/detail/detail_screen.dart

Deliverables:
1. Hero transition for poster/backdrop source card to detail media.
2. Section-by-section entrance choreography (overview, actions, cast, providers).
3. Dialog and action button transitions updated to match motion system.

Acceptance criteria:
- Detail opens with cinematic continuity.
- Interactions remain responsive.

### Phase 6 - Watchlist and profile polish
Targets:
- Make account and collection surfaces feel premium and coherent.
Planned file updates:
- lib/screens/watchlist/watchlist_screen.dart
- lib/screens/profile/profile_screen.dart

Deliverables:
1. Tab view transitions and list/grid reveal patterns.
2. Animated empty states with subtle pulse/fade.
3. Smooth auth form mode switching and error presentation.

Acceptance criteria:
- No abrupt state jumps in auth/list flows.

### Phase 7 - Loading, error, and feedback system unification
Targets:
- Replace spinner-heavy UX with skeleton and animated state cards.
Planned files:
- Shared UI components under lib/widgets/loading/ (new)
- Screen-level state blocks in home, search, detail, watchlist, profile

Deliverables:
1. Standardized skeleton components.
2. Animated error and retry cards.
3. Optimistic feedback for watchlist/favorites/ratings actions.

Acceptance criteria:
- Users always see meaningful progress and smooth transitions.

### Phase 8 - Performance and accessibility hardening
Targets:
- Keep motion smooth under real device constraints.
Planned areas:
- All modified screens/widgets

Deliverables:
1. Add RepaintBoundary where beneficial for heavy cards/lists.
2. Reduce unnecessary rebuilds with const and localized state updates.
3. Verify reduced-motion behavior and contrast/focus visibility.

Acceptance criteria:
- Smooth scrolling and transitions on mid-tier devices.
- Accessibility-safe behavior with reduced motion enabled.

### Phase 9 - Testing and quality gates
Targets:
- Prevent regressions while shipping visual improvements.
Planned updates:
- test/widget_test.dart
- Add focused widget tests in test/ for animated state transitions

Deliverables:
1. Smoke test updates for revised route transitions.
2. Widget tests for key animated state swaps (home/search/profile).
3. Ensure flutter analyze and flutter test pass clean.

Acceptance criteria:
- CI-ready with green analyze and test runs.

### Phase 10 - Release readiness
Targets:
- Ship polished UX in a controlled release.

Deliverables:
1. Manual QA checklist for Android, iOS, web.
2. Record before/after captures of key flows.
3. Trigger fresh release with release notes calling out animation and polish upgrades.

Acceptance criteria:
- Users perceive clear smoothness and quality uplift.

## Execution order and risk control
1. Build foundation first (Phase 1).
2. Apply transitions in navigation and home (Phases 2 and 3) before touching all screens.
3. Land in small reviewable commits by phase.
4. Run analyze and tests after each phase, not only at the end.

## Definition of done
1. Every primary screen has cohesive entrance and state transitions.
2. Route navigation is smooth and consistent.
3. Loading and error UX is polished and animated.
4. Reduced-motion users get accessible behavior.
5. Performance stays smooth and test suite is green.
