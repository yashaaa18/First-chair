# FIRST CHAIR

*A courtroom drama in three cases. Find the lie. Win the room.*

You're the newest associate at **Valence Legal**, the most expensive law firm in the city of Northbridge. Your mentor, **Mara Quinn**, has one instruction: *"First day, first case. Try not to embarrass us."* Three cases later, you'll find out who has been arranging them all.

| Case | Title | New mechanic | Length |
|---|---|---|---|
| 1 | **The Signed Lie**: a café owner sued over a contract she never signed | Interview, inspect, cross-examine, present | 5–8 min |
| 2 | **The Stolen Spark**: a young inventor accused of copying a rival | **Combine** two pieces of evidence | 6–10 min |
| 3 | **The Midnight File**: a secret file vanishes in a blackout | Present evidence **in order**; spot the liar | 8–10 min |

---

## What's in this repository

```
default.project.json      Rojo project (maps the folders below into Roblox)
build/FirstChair.rbxlx    Ready-made place file (built + world baked in)
src/
  shared/                 ReplicatedStorage.Shared: palette, cast, stage marks, ranks
  server/                 ServerScriptService.Server
    CaseLogic.luau        Rules engine: answers, scoring, retries (pure Luau, tested)
    CaseService.luau      Remotes + server-side validation + unlocks
    DataService.luau      DataStore saving with retries and safe offline mode
    Cases/Case1-3.luau    The three scripts (story, evidence and answer keys)
    World/                Office, courtroom, skyline, lighting, cast models
  client/                 StarterPlayerScripts.Client
    Controllers/          Case runner, cinematic camera, stage (actors), audio
    UI/                   Menu, dialogue, choices, evidence, testimony, results…
tests/run.luau            19 logic tests: every case played start to finish
scripts/
  build.sh                Format check → tests → build → bake → simulate
  bake.luau               Runs the world builders and saves the result into the place
  simulate.luau           Headless robot player: runs real client + server code
.github/workflows/
  ci.yml                  Builds and tests on every push
  publish.yml             One-tap publish to Roblox via Open Cloud
docs/
  PUBLISHING_FROM_IPAD.md Step-by-step publishing guide for iPad
  REPORT.md               What's built, what's tested, what still needs work
  WRITING_CASES.md        How to edit dialogue and cases from the GitHub website
```

## Publish it (from an iPad)

Follow **[docs/PUBLISHING_FROM_IPAD.md](docs/PUBLISHING_FROM_IPAD.md)**. In short: create the experience once, make an Open Cloud API key, paste three secrets into GitHub, then tap **Actions → Publish to Roblox → Run workflow**.

## Build it yourself (any Linux/Mac shell, optional)

```bash
scripts/install-tools.sh .tools    # downloads Rojo, Lune, Luau, StyLua
scripts/build.sh                   # → build/FirstChair.rbxlx
```

With Roblox Studio on a computer you can also live-sync with `rojo serve` and the Rojo Studio plugin.

## Design rules this code follows

* **The server is the judge.** Clients only receive answer-free scripts. Every answer, score, unlock and save is decided on the server.
* **Mistakes never restart a case.** A wrong answer costs points and Mara tells you why. Then you try again.
* **Mobile first.** Everything is tapped. There's no walking or camera control, and every button is at least 54 px tall at reference scale. The UI scales from phones to monitors.
* **Lean visuals.** About 740 parts, 10 non-shadow lights and no external assets. The look comes from a restrained palette (espresso, walnut, navy, ivory, brass), warm lighting and careful composition.
