# Character Chapter 4 Checklist

- [x] Task A — `lua/game/data/customer_scripts.lua` — Append 8 new ch4 entries (one per character below). Each entry follows the existing table structure: id, chapter=4, accessory, trigger, name, voice_pitch, primary_color, secondary_color, plant_type, messages, after_messages. Insert each block immediately after that character's ch3 entry so the file stays grouped by character.

  **romeo ch4** — trigger `{ plant_type = 5, count = 8 }` — plant_type 3 (rose)
  - messages: "Mon ami! One last time, you must help me!", "The relationship, she has lasted six months!", "I am going to propose! Tonight! Under the moon!", "She loves roses. I need the most beautiful rose you have."
  - after_messages: "Merci! I will come back to tell you how it goes!"

  **agent_frogsby ch4** — trigger `{ plant_type = 5, count = 12 }` — plant_type 5 (daisy)
  - messages: "Don't react to seeing me.", "Going undercover. High-end garden society. Suspicious connections.", "I need to blend in. A flower. Nothing too flashy.", "Something ordinary. Unassuming."
  - after_messages: "This conversation never happened."

  **mayor_bloom ch4** — trigger `{ plant_type = 5, count = 16 }` — plant_type 6 (golden lotus)
  - messages: "Hellooo! Mayor Bloom to you now!", "We won! Thanks in part to our many campaigns, we pulled it off!", "I wanted to decorate the mayor's office with something special.", "Something that says power. Prestige. But still approachable.", "Do you have a Golden Lotus? I think it says all of that."
  - after_messages: "Thank you! I promise this lotus and I are headed for great things!"

  **dottie ch4** — trigger `{ plant_type = 5, count = 20 }` — plant_type 4 (tulip)
  - messages: "Hey, it's Dottie! I have huge news!", "Mayor Bloom personally hired me to perform at the inauguration! Big stage!", "There's a love scene in my act. A romantic clown thing.", "My prop needs to be a tulip. Don't ask why, it's comedy, it just works."
  - after_messages: "The crowd is going to love it, I just know it!"

  **glen ch4** — trigger `{ plant_type = 5, count = 24 }` — plant_type 2 (cactus)
  - messages: "Yo man. Guess what.", "I started listening to Joe Froggan again. But I'm critical now. I really am.", "Anyway he released a new episode: 'The Cactus Return. Why I Was Right All Along.'", "I mean... he makes good points. I need to start on cactus again."
  - after_messages: "I'm just open-minded, you know?"

  **wallace ch4** — trigger `{ plant_type = 6, count = 1 }` — plant_type 6 (golden lotus)
  - messages: "Hey man. It's me again.", "The raccoon count is now three. My wife moved out.", "She said she'll come back if I do something truly extraordinary.", "I heard golden lotuses are really expensive. She likes fancy things. Please."
  - after_messages: "She came back. The raccoons are still here. We didn't discuss that part."

  **chef_brio ch4** — trigger `{ plant_type = 6, count = 3 }` — plant_type 6 (golden lotus)
  - messages: "Hello sir! Big news! I've been nominated for the Frog Chef Awards!", "Best Floral Dish! Can you believe it? Me!", "The judges want a final dish. I need the rarest ingredient.", "A Golden Lotus. To win, I have to go all in."
  - after_messages: "I will make you proud. Lotus bread. It's happening."

  **mechafrog ch4** — trigger `{ plant_type = 6, count = 5 }` — plant_type 1 (grass)
  - messages: "TITLE CHANGE: MASTER GARDENER.", "GARDEN WON AWARD: MOST SCENIC IN FROGTOWN.", "REQUIRED: ONE GRASS. FOR CEREMONY.", "CEREMONIAL PURPOSE. GRASS IS WHERE THIS UNIT STARTED."
  - after_messages: "THIS UNIT THANKS YOU. OPERATION PEACEFUL: SUCCESS."

- [x] Task B — `tests/test_quest_timing.lua` — Update the inline comment on the daisy schedule line to include the 5 new daisy-triggered chapters, and update the `--` comment to note the two lotus-triggered ones. No logic changes, comment-only. The schedule line for Daisy currently reads:
  `-- Daisy  >= 32  → mechafrog:1 (>=5), dottie:3 (>=7), glen:3 (>=14), collector:1 (>=32)`
  Update to:
  `-- Daisy  >= 32  → mechafrog:1 (>=5), dottie:3 (>=7), glen:3 (>=14), romeo:4 (>=8), frogsby:4 (>=12), bloom:4 (>=16), dottie:4 (>=20), glen:4 (>=24), collector:1 (>=32)`
  And update the Lotus line from:
  `-- Lotus  >= 5   → collector:2 (>=5)`
  to:
  `-- Lotus  >= 5   → wallace:4 (>=1), chef_brio:4 (>=3), mechafrog:4 (>=5), collector:2 (>=5)`

- [x] Task C — Verify: run `love . --headless tests/test_quest_timing.lua` and confirm all 8 new chapters appear in the timeline output and the test prints `PASS`. Also run `love . --headless tests/test_customer_scripts.lua` to confirm no regressions. Both must exit 0.
