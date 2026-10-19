# Status Report: FIRST CHAIR prototype v0.1

## Summary

All three cases are implemented and can be played start to finish in code. Case 1 got the most polish. Every system is wired up end to end: menu → case → verdict → results → unlock → save.

**This build has not been run inside Roblox itself yet.** Nothing here has been playtested in Roblox Studio or the Roblox app. Everything below was checked with real tools outside Roblox. Some things can only be confirmed by playing it on Roblox (see "Not yet verified").

---

## What's implemented

### Story and content
* **Case 1, The Signed Lie** (6 scored decisions): reception welcome, Mara's briefing ("First day, first case. Try not to embarrass us."), client interview (4 topics), 3 evidence items plus the contract, the key contradiction, court opening, cross-examination of Nadia Price (4 statements with Press), presenting the strongest evidence, a 3-part closing, verdict, and the Crestline reveal.
* **Case 2, The Stolen Spark** (7 decisions): the new **Combine** mechanic, used twice (notebook + receipt → *Verified Design Date*; design file + internship record → *Impossible Theft*), plus the KM-7 deduction, Gregory Lusk's testimony and a second Crestline link.
* **Case 3, The Midnight File** (6 decisions): two interviews (Nora and Rosa), 5 security records, Combine to expose the blackout, identifying the liar, Martin Cole's testimony, **Order** the night's timeline, the visitor-register reveal (Adrian Voss), and the final twist on Mara's signature with a *Chapter Two* teaser.
* An original cast of 13 characters (Mara Quinn, Judge Rowan, Adrian Voss, Theo Marsh, June Park, Nadia Price, Dale Kerrigan, Kai Mercer, Gregory Lusk, Nora Lindqvist, Martin Cole, Rosa Delgado, plus your avatar).

### Gameplay systems
* **Case engine** (`CaseLogic`): 12 step types. Answers are checked on the server. Wrong answers give coaching feedback and a retry, never a restart. "Good instinct, wrong moment" hints cost no points.
* **Scoring:** 100 / 60 / 35 / 20 points by attempt. Grades S/A/B/C. Promotion points per case (best result counts). Career titles: Junior Associate → Associate → Senior Associate → First Chair.
* **Progression:** each case unlocks the next. Unlocks are always worked out on the server from saved results, never from what the client says.
* **Saving:** DataStore with retries and merge-on-save (a lagging server can't overwrite a better grade). Autosave and save-on-leave/shutdown. If DataStores are down, the player can still play and is told progress won't be saved.
* **Security:** clients receive case scripts with the answer keys removed (a test checks this). The server rejects out-of-order steps, evidence the player doesn't own, and malformed answers, and rate-limits remote calls.
* **Skip** button for dialogue you've already seen (remembered in your save).

### Social and engagement (added in v0.2)
* **Shared lobby:** "Explore the Office" lets you walk around Valence Legal with Roblox's normal camera and chat. Other players are drawn nearest-first up to `Config.Lobby.visiblePlayers` (16) with a name + career title tag, so a 100-player server stays light on an iPad. Tapping the **Active Matters** board (ProximityPrompt) opens the case files.
* **Private cases:** the instant a case starts, other players are hidden and the cinematic camera takes over, exactly as before.
* **Server size:** 100 per server via `Players.MaxPlayersInternal` in the project file (verify in Creator Hub → Places).
* **Leaderstats + titles:** the Roblox player list shows Title and Points; titles replicate as player attributes for the nametags.
* **Top Associates board:** OrderedDataStore of promotion points, refreshed every 90 s, rendered on a brass-framed board in the lobby.
* **Daily bonus + streak:** the first case won each day adds 10 promotion points and extends the streak; shown on the results screen and the title screen.
* **Badges:** First Verdict, Clean Sweep, First Chair (IDs in `Config.Badges`; skipped until set).
* **Announcements:** "X just won The Signed Lie · Grade S" toasts to the whole server.
* **Music:** four original tracks (title/lobby, investigation, courtroom, verdict stinger) composed in `marketing/music/compose.py`; cross-faded per scene by `Controllers/Music.luau`; mute toggle on the title screen and pause menu. Asset IDs go in `Config.Music` after upload.
* **Robustness:** every social call (badges, leaderboard, broadcast) is isolated so an outage can never block a verdict.

### Presentation
* **Valence Legal lobby:** marble floor with walnut inlay, navy feature wall with brass "VALENCE LEGAL" signage, fluted walnut reception counter, brass pendants, a lounge with sofa, armchairs and lamp, the **Active Matters** case board, glass-walled **Conference Room B**, and a golden-hour Northbridge skyline.
* **Northbridge Civil Court:** raised judge's bench with nameplate and a tall leather chair, a navy dossal with the city seal, fluted pilasters, tall windows with brass mullions, a coffered ceiling, witness stand, counsel tables, the bar rail, six rows of gallery pews, law-library shelves and brass pendants.
* **Performance budget:** 737 parts, 10 lights (none casting shadows), 11 text signs. ShadowMap lighting with subtle atmosphere, colour grading and bloom. No external assets.
* **Cinematic camera:** fixed shots per scene, automatic three-quarter close-ups on whoever is speaking, a slow push-in, and a shake on objections.
* **UI:** premium main menu with career progress, three case cards (locked, grade badges), dialogue panel with typewriter text and name tabs, choice cards, illustrated evidence cards and an inspector with a highlighted key detail, a one-statement-at-a-time testimony view with Press and Present, an animated **OBJECTION!** stamp, verdict banner, results screen with animated score and an unlock ribbon, toasts, pause menu, and a Case File you can open any time.
* **Mobile-first:** the whole UI scales from a 960×560 reference to fit phones, iPads and monitors. It respects safe areas (notches), touch targets are 54 px or more, and there's no joystick (movement controls are turned off). Other players are hidden, so each player gets a private story.

---

## What was tested, and how

| Check | Tool | Result |
|---|---|---|
| Code formatting | StyLua 0.20 | ✅ clean |
| Type check against the real Roblox API | luau-lsp 1.62 + Roblox definitions | ✅ 0 errors |
| Logic tests: data validity, no answer leaks, perfect run = S, a mistake on every question still completes, forged/out-of-order submissions rejected, free hints cost nothing | Luau 0.640 (`tests/run.luau`) | ✅ 19/19 |
| Place file builds | Rojo 7.4.4 | ✅ `build/FirstChair.rbxlx` |
| World builders run without errors; every property name and type valid; part and light budgets | Lune 0.8.9 (`scripts/bake.luau`) | ✅ 737 parts, 10 lights |
| **Headless full playthrough:** the real client and server scripts run together; a robot taps the actual UI through all 3 cases, deliberately answers 13 questions wrong first, and checks results, unlocks and career points | Lune (`scripts/simulate.luau`) | ✅ all 3 cases completed, 0 invalid UI properties, 375 dialogue taps |
| Lobby walking, nametags, chat, leaderboard store, badges | — | ⚠️ not covered by the simulation (needs Roblox); code paths are isolated with pcall |
| Fresh-machine tool install + full pipeline | `scripts/install-tools.sh` + `scripts/build.sh` | ✅ |

The simulation stands in for the Roblox engine with a fake network, fake tweens and a fake camera. It proves the logic and flow work and that every UI property set is valid. It can't show how anything looks.

## Not yet verified (needs Roblox itself)

These are the things to check on your first iPad playtest:

1. **Visual framing:** whether close-ups frame faces well and never clip into furniture. All marks and shots are in `src/shared/StageLayout.luau` and easy to nudge.
2. **NPC appearance:** characters are built as R15 rigs from a HumanoidDescription with body colours as clothing, plus welded parts for hair, collars and ties. This is a deliberately stylised "mannequin" look with no external assets. Hair offsets may need small tweaks.
3. **Animations:** idle and point use Roblox's own default R15 animation IDs.
4. **Sounds:** they use sound files bundled with the Roblox client. Some may be quiet or plain. Swapping in Creator Store audio IDs is a one-line change each in `Controllers/Audio.luau`, and there's a slot for background music.
5. **Fonts and glyphs:** Merriweather and Montserrat, plus a few symbols (› ✓ “ ”). Roblox normally falls back for missing glyphs.
6. **Real performance on an iPad:** the budget is small, but frame rate hasn't been measured on a device.
7. **Live DataStores:** the save code follows Roblox's recommended pattern but has only run in simulation.

## Known limitations and next steps

* **Avatars:** your own avatar stands at the defence table. Very large or tiny avatar scales may look odd beside the NPCs.
* **Store page:** there's no music, icon or thumbnails yet. Add them via Creator Hub.
* **Polish ideas (if time allows):** short NPC gesture animations per emotion, a camera dolly on verdicts, ambient courtroom murmur, and a "Chapter Two" placeholder card in the menu.
* **Studio editing:** the world is generated from code (`src/server/World/*.luau`). Hand edits made in Studio are replaced by the next build, so make lasting changes in the builder code.
