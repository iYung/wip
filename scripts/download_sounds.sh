#!/usr/bin/env bash
# download_sounds.sh — Fetch all 17 game sounds from freesound.org and write
# them to assets/sounds/<event_name>.wav.
#
# Strategy: The /download/ endpoint requires OAuth2. Instead, we call the
# info endpoint (token auth) to get the public HQ-preview URL, download that
# (no auth needed), and convert to WAV via ffmpeg.
#
# Requirements:
#   - curl
#   - ffmpeg
#   - jq
#   - FREESOUND_TOKEN env var set to a valid personal API token

set -euo pipefail

# ---------------------------------------------------------------------------
# Guard: FREESOUND_TOKEN must be set
# ---------------------------------------------------------------------------
if [[ -z "${FREESOUND_TOKEN:-}" ]]; then
  echo "Error: FREESOUND_TOKEN environment variable is not set." >&2
  echo "Obtain a personal API token from https://freesound.org/apiv2/apply/ and export it:" >&2
  echo "  export FREESOUND_TOKEN=your_token_here" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not found. Install it:" >&2
  echo "  brew install jq" >&2
  exit 1
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "Error: ffmpeg is required but not found. Install it:" >&2
  echo "  brew install ffmpeg" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SOUNDS_DIR="$REPO_ROOT/assets/sounds"

mkdir -p "$SOUNDS_DIR"

# ---------------------------------------------------------------------------
# Sound mapping: "FREESOUND_ID:event_name"
# ---------------------------------------------------------------------------
SOUNDS=(
  "483212:pick_up"
  "481855:put_down"
  "480840:water_plant"
  "675866:plant_ready"
  "480686:clone_success"
  "675921:clone_fail"
  "481835:sell_plant"
  "675869:dismiss_customer"
  "675772:dialogue_skip"
  "481825:dialogue_advance"
  "483238:discard_plant"
  "675881:open_shop"
  "480663:shop_navigate"
  "676000:shop_buy"
  "483202:shop_close"
  "480663:menu_navigate"
  "675695:menu_confirm"
)

# ---------------------------------------------------------------------------
# Download + convert one sound
# Returns 0 on success, 1 on failure.
# ---------------------------------------------------------------------------
download_sound() {
  local sound_id="$1"
  local event_name="$2"
  local dest="$SOUNDS_DIR/${event_name}.wav"
  local tmp_json tmp_audio tmp_wav
  tmp_json="$(mktemp)"

  # Step 1: fetch sound metadata (token auth is fine for the info endpoint)
  if ! curl -sSf \
       "https://freesound.org/apiv2/sounds/${sound_id}/?token=${FREESOUND_TOKEN}" \
       -o "$tmp_json"; then
    echo "✗ ${event_name} (info request failed for ID ${sound_id})" >&2
    rm -f "$tmp_json"
    return 1
  fi

  # Step 2: extract the HQ preview URL (public — no auth required to download)
  local preview_url
  preview_url="$(jq -r '.previews["preview-hq-mp3"] // .previews["preview-hq-ogg"] // empty' "$tmp_json")"
  rm -f "$tmp_json"

  if [[ -z "$preview_url" ]]; then
    echo "✗ ${event_name} (no preview URL in API response for ID ${sound_id})" >&2
    return 1
  fi

  # Step 3: download the preview
  tmp_audio="$(mktemp)"
  if ! curl -sSfL -o "$tmp_audio" "$preview_url"; then
    echo "✗ ${event_name} (preview download failed for ID ${sound_id})" >&2
    rm -f "$tmp_audio"
    return 1
  fi

  # Step 4: convert to WAV (preview is MP3 or OGG)
  tmp_wav="$(mktemp /tmp/sound_XXXXXX.wav)"
  if ! ffmpeg -y -loglevel error -i "$tmp_audio" "$tmp_wav"; then
    echo "✗ ${event_name} (ffmpeg conversion failed for ID ${sound_id})" >&2
    rm -f "$tmp_audio" "$tmp_wav"
    return 1
  fi
  rm -f "$tmp_audio"

  mv "$tmp_wav" "$dest"
  echo "✓ ${event_name}"
  return 0
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
any_failure=0

for entry in "${SOUNDS[@]}"; do
  sound_id="${entry%%:*}"
  event_name="${entry##*:}"
  if ! download_sound "$sound_id" "$event_name"; then
    any_failure=1
  fi
done

if [[ $any_failure -ne 0 ]]; then
  echo "" >&2
  echo "One or more sounds failed to download. See errors above." >&2
  exit 1
fi

echo ""
echo "All sounds downloaded successfully to ${SOUNDS_DIR}/"
