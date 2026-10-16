# Editing the story from the GitHub website

All dialogue, evidence and answers live in three files:

* `src/server/Cases/Case1.luau`: The Signed Lie
* `src/server/Cases/Case2.luau`: The Stolen Spark
* `src/server/Cases/Case3.luau`: The Midnight File

You can edit them in Safari. Open the file on github.com, tap the ✏️ pencil, make the change, then **Commit changes**. The **Build & Test** check runs automatically and tells you if anything broke. When it's green, run **Publish to Roblox**.

## Changing a line of dialogue

Each line looks like this:

```lua
{ "mara", "First day, first case. Try not to embarrass us." },
```

The first part is **who speaks**. Use a character id from `src/shared/Characters.luau`, `"player"` for you, or `"narrator"`. The second part is **what they say**. Keep the quote marks and the comma at the end.

Lines that start with `(` appear as a quiet aside in italics, for example `"(He does this. Smile.)"`.

## Changing a question

```lua
{
	text = "Brightwell raised their prices.",
	feedback = "Rude, but not illegal. Focus on what proves the contract is fake.",
},
```

The right answer has `correct = true`. Each question needs exactly one; the tests check this. `feedback` is what Mara says when the player picks that option.

## Step types (for bigger changes)

| `type` | What the player sees |
|---|---|
| `scene` | Fade to a location. Places the `cast` on stage marks and sets the camera `shot`. |
| `dialogue` | Conversation lines |
| `interview` | Topics to ask about. All of them must be heard. |
| `evidence_review` | Inspect each listed exhibit |
| `gain` | Exhibits added to the case file |
| `choice` | Multiple choice (scored) |
| `testimony` | Cross-examination: present evidence against a statement (scored) |
| `present` | Present the right exhibit (scored) |
| `combine` | Combine two exhibits into a new one (scored) |
| `order` | Tap exhibits in time order (scored) |
| `verdict` | The court's ruling banner |
| `complete` | The end: score, promotion points, unlocks |

Stage marks (`office_meeting_head`, `court_witness`, …) and camera shots (`court_wide`, …) are listed in `src/shared/StageLayout.luau`.

## Rules the tests enforce

* Every question has exactly one correct option.
* Wrong options have feedback.
* Evidence must be owned before it can be presented.
* The last step is `complete`.
* Answer keys never reach the player's device.
