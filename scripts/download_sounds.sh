#!/usr/bin/env bash
# download_sounds.sh — Fetch all 17 game sounds from freesound.org and write
# them to assets/sounds/<event_name>.wav.
#
# Requirements:
#   - curl
#   - ffmpeg
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
  local tmp_raw
  tmp_raw="$(mktemp)"

  # Download (follow redirects; freesound redirects to the actual audio file)
  if ! curl -sSL \
       -H "Authorization: Token $FREESOUND_TOKEN" \
       -o "$tmp_raw" \
       "https://freesound.org/apiv2/sounds/${sound_id}/download/"; then
    echo "✗ ${event_name} (curl failed for ID ${sound_id})" >&2
    rm -f "$tmp_raw"
    return 1
  fi

  # Verify we got an actual audio file (not an error JSON)
  local mime
  mime="$(file --brief --mime-type "$tmp_raw" 2>/dev/null || true)"
  case "$mime" in
    audio/*|application/octet-stream)
      : # looks like audio — proceed
      ;;
    *)
      # Could be JSON error response from the API
      echo "✗ ${event_name} (unexpected response type '${mime}' for ID ${sound_id})" >&2
      rm -f "$tmp_raw"
      return 1
      ;;
  esac

  # Determine whether conversion is needed.
  # We consider a file already WAV if its MIME type is audio/x-wav or audio/wav,
  # OR if the magic bytes match RIFF....WAVE.
  local needs_conversion=1
  if [[ "$mime" == "audio/x-wav" || "$mime" == "audio/wav" || "$mime" == "audio/wave" ]]; then
    needs_conversion=0
  fi

  if [[ $needs_conversion -eq 0 ]]; then
    mv "$tmp_raw" "$dest"
  else
    local tmp_wav
    tmp_wav="$(mktemp --suffix=.wav)"
    if ! ffmpeg -y -loglevel error -i "$tmp_raw" "$tmp_wav" 2>&1; then
      echo "✗ ${event_name} (ffmpeg conversion failed for ID ${sound_id})" >&2
      rm -f "$tmp_raw" "$tmp_wav"
      return 1
    fi
    mv "$tmp_wav" "$dest"
    rm -f "$tmp_raw"
  fi

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
