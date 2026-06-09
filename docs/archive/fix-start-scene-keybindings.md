# Checklist: Fix Start Scene Ignoring Saved Keybindings

- [x] `main.lua`: after line 90 where `ss` is assigned, add `input._map = ss:key_map()` to sync the input map with loaded settings before the first scene starts
