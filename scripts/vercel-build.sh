#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

required_vars=(
  TMDB_API_KEY
  SUPABASE_URL
  SUPABASE_ANON_KEY
)

missing_vars=()
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    missing_vars+=("${var_name}")
  fi
done

if (( ${#missing_vars[@]} > 0 )); then
  echo "Missing required Vercel environment variables: ${missing_vars[*]}"
  echo "Set them in your Vercel project settings and redeploy."
  exit 1
fi

cat > .env <<EOF
TMDB_API_KEY=${TMDB_API_KEY}
TMDB_BASE_URL=${TMDB_BASE_URL:-https://api.themoviedb.org/3}
TMDB_IMAGE_BASE_URL=${TMDB_IMAGE_BASE_URL:-https://image.tmdb.org/t/p}
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_DIR="${ROOT_DIR}/.flutter-sdk"
  if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
  fi

  export PATH="${FLUTTER_DIR}/bin:${PATH}"
fi

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
