## Store-to-Start Music Bug Checklist

- [x] Fix wrong bg track name in `_on_leave` — `main.lua:98` — replace `Sound.fade_music("bg", 0, 1)` with a loop fading `"bg1"` through `"bg4"` to 0 over 1 second
