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

## Deploying To Vercel

This project uses a custom Vercel build step in `scripts/vercel-build.sh`.
The script installs Flutter in CI, creates a `.env` file from Vercel environment variables, and runs `flutter build web --release`.

Set these environment variables in Vercel before deploying:

- `TMDB_API_KEY` (required)
- `SUPABASE_URL` (required)
- `SUPABASE_ANON_KEY` (required)
- `TMDB_BASE_URL` (optional, default: `https://api.themoviedb.org/3`)
- `TMDB_IMAGE_BASE_URL` (optional, default: `https://image.tmdb.org/t/p`)

### GitHub Actions Prebuilt Deploy (Recommended)

Use `.github/workflows/deploy-web-vercel-prebuilt.yml` to build Flutter web on GitHub and deploy prebuilt output to Vercel.
This avoids running Flutter builds inside Vercel for each deployment.

Add these GitHub repository secrets:

- `VERCEL_TOKEN` (required)
- `VERCEL_ORG_ID` (required)
- `VERCEL_PROJECT_ID` (required)
- `TMDB_API_KEY` (required)
- `SUPABASE_URL` (required)
- `SUPABASE_ANON_KEY` (required)
- `TMDB_BASE_URL` (optional, default: `https://api.themoviedb.org/3`)
- `TMDB_IMAGE_BASE_URL` (optional, default: `https://image.tmdb.org/t/p`)

If your Vercel project is connected to GitHub auto-deploy, disable automatic Git deployments to avoid duplicate production deployments from both Vercel and GitHub Actions.

## Mobile Release Automation (Unsigned APK + IPA)

Use `.github/workflows/release-mobile-artifacts.yml` to build and publish mobile artifacts to GitHub Releases.

- Trigger automatically on tags matching `v*`.
- Can also be triggered manually from GitHub Actions (`workflow_dispatch`).
- Publishes these release assets:
	- `CineFlix-android-unsigned.apk`
	- `CineFlix-ios-unsigned.ipa`

### Required GitHub Secrets

- `TMDB_API_KEY` (required)
- `SUPABASE_URL` (required)
- `SUPABASE_ANON_KEY` (required)
- `TMDB_BASE_URL` (optional)
- `TMDB_IMAGE_BASE_URL` (optional)

### Website Download Targets

The web app download buttons point to:

- `https://github.com/kylosonic/cineflix/releases/latest/download/CineFlix-android-unsigned.apk`
- `https://github.com/kylosonic/cineflix/releases/latest/download/CineFlix-ios-unsigned.ipa`
