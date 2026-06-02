# Web Audio — Known Issue

Audio does not play in the web build. This is a known-unresolved issue.

---

## What was tried

**Silent-buffer unlock** — on the first `touchstart`, a 1-sample silent `AudioBufferSourceNode` was created and played in a new `AudioContext`. This is a standard iOS autoplay unlock technique. It did not fix the issue and was reverted.

---

## What we know about the stack

love.js 11.4.1 compiles LÖVE with Emscripten. Audio goes through:

```
LÖVE  →  OpenAL (emulated)  →  Emscripten AL layer  →  Web Audio API  →  browser
```

love.js registers `autoResumeAudioContext` which listens once for `keydown`, `mousedown`, or `touchstart` on `document` and the canvas, then calls `AudioContext.resume()`. This is intended to satisfy the browser autoplay policy.

---

## Suspected causes (unconfirmed)

1. **Promise timing** — `AudioContext.resume()` returns a Promise. If a sound is triggered on the same tick as the first user gesture, the AudioContext may not be in `running` state yet when `alSourcePlay` is called.

2. **OpenAL context not connected to the unlocked AudioContext** — iOS may create a second suspended AudioContext for OpenAL after the first one was unlocked, meaning the silent-buffer unlock targets the wrong context.

3. **compat build limitation** — the `--compatibility` flag uses `src/compat/love.js` (no web workers). This is a different binary from the release build. It's possible audio is broken or degraded in the compat build specifically. Switching to the release build (removing `--compatibility` from `build_web.sh`) is the next thing to try — but the release build uses `love.worker.js` (pthreads), which needs cross-origin isolation headers (`COOP`/`COEP`) to work, which GitHub Pages does not serve by default.

4. **WAV format** — all sounds are 16-bit PCM WAV. These should decode fine in all browsers, but this has not been confirmed in the web build specifically.

---

## Next steps to try (in order)

1. **Check the browser console** — open the web build in Safari/Chrome with DevTools and look for any AudioContext or OpenAL errors on first interaction.

2. **Switch to the release build** — remove `--compatibility` from `build_web.sh`. The release build uses pthreads and may have better audio support. Note: pthreads require the server to send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers. GitHub Pages does not support custom headers, so this would require a different host (e.g. Netlify with a `_headers` file) or a service worker to inject the headers.

3. **Convert sounds to OGG** — OGG Vorbis is love.js's preferred web audio format and is explicitly listed as an audio suffix in the packager. WAV may have decode issues in the Emscripten OpenAL layer that OGG does not.

4. **Test with a minimal LÖVE web audio example** — strip the game down to `love.audio.newSource` + `love.audio.play` in `love.load` to isolate whether the issue is with love.js audio on this platform at all, or something specific to how `Sound.load`/`Sound.play` is called.
