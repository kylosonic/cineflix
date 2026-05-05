# CineFlix

CineFlix is a cross-platform Flutter movie discovery app for web, Android, and iOS.

## UI Revitalization Plan

This repository now follows a cinematic UI plan to make the product feel alive and intuitive on both mobile and web.

1. Build one visual language for all screens:
	- Shared design tokens in `lib/theme/cine_theme.dart`.
	- Reusable cinematic gradient background and glass panels.
	- Consistent spacing, typography, and button behavior.
2. Make discovery engaging:
	- Home now uses a featured hero, richer section hierarchy, and responsive web grids.
	- Search now supports guided discovery, quick vibe prompts, and genre-first exploration.
3. Improve user ownership flows:
	- Watchlist and Profile now surface clear actions, better empty states, and stronger account context.
4. Improve detail storytelling:
	- Movie detail now uses immersive hero presentation, clearer metadata, and polished action blocks.

## UX Principles

- Always show users what to do next.
- Replace blank states with informative, actionable states.
- Keep interactions responsive with clear hover/press feedback.
- Ensure the same quality bar across web and mobile layouts.

## Local Development

1. Install Flutter SDK.
2. Create a `.env` file with TMDB and Supabase credentials.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

5. Run tests and static analysis:

```bash
flutter test
flutter analyze
```
