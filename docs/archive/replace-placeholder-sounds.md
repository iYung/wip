# Replace Placeholder Sounds Checklist

- [x] Task A — `scripts/download_sounds.sh` — Create a shell script that downloads all 17 sounds
  from the freesound API (using env var `FREESOUND_TOKEN`), converts each to `.wav` via ffmpeg if
  needed, and writes the result to `assets/sounds/<event_name>.wav`. Use the sound ID → filename
  mapping from the design doc. The script should print each filename as it completes and exit
  non-zero on any curl/ffmpeg failure.
