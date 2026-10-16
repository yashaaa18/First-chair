# Publishing FIRST CHAIR from an iPad

This guide gets the game from this GitHub repository onto Roblox using only Safari and the Roblox app. GitHub builds the game for you, and Roblox's **Open Cloud** API receives it.

> **Never paste your API key anywhere except GitHub's "Secrets" page.** Don't put it in a file, an issue, a chat or a commit. If it ever leaks, delete it on the Roblox site and make a new one.

---

## What you need

* A Roblox account (13+ for publishing; ID verification isn't needed to publish).
* This GitHub repository, open in Safari on your iPad.
* About 20 minutes the first time. After that, each update takes one tap.

## Which steps might need a computer

| Step | iPad only? |
|---|---|
| Create an empty experience on Roblox | **Maybe.** See Step 1. If the website won't create one, you need any computer with Roblox Studio **once**: a friend's, a school or library PC, or a cloud PC. |
| Create an API key, get IDs | Yes (Creator Hub in Safari) |
| Add GitHub secrets, run the publish | Yes (GitHub in Safari) |
| Play and test the game | Yes (Roblox app) |
| Open the place in Studio, move things by hand, record trailers | No. That needs Roblox Studio on Windows or Mac. Nothing in this guide requires it. |

---

## Step 1: Create the experience (one time)

1. In Safari, open **create.roblox.com** and sign in.
2. Go to **Creations → Experiences**.
3. Tap **Create Experience**.
   * If it creates an experience in the browser, you're done. Continue to Step 2.
   * If it says to open Roblox Studio, you need a computer once. In Studio, choose **New → Baseplate**, then **File → Publish to Roblox**, give it a name ("First Chair") and publish. You won't need the computer again.

## Step 2: Check the two ID numbers

The workflow already knows which experience to publish to. The IDs are written at the top of `.github/workflows/publish.yml`:

```
UNIVERSE_ID: "10771328364"
PLACE_ID: "125527667705419"
```

These aren't secrets: they appear in your Creator Hub URLs. If you ever publish to a different experience, edit those two lines on github.com (tap the ✏️ pencil on the file). To find an experience's IDs: in **Creations**, tap the **⋯** menu on its card → **Copy Universe ID** / **Copy Start Place ID**.

## Step 3: Create an Open Cloud API key

1. In Creator Hub, open **Open Cloud → API Keys** (left menu), then **Create API Key**.
2. **Name:** `first-chair-publish`.
3. Under **Access Permissions**, choose the API system **universe-places** (Place Publishing). Select **your experience** and tick the **write** operation.
4. Under **Security → Accepted IP Addresses**, add `0.0.0.0/0`. GitHub's build servers change IP addresses, so this is required.
5. Optional: set an expiration date.
6. Tap **Save & Generate Key**, then **Copy Key to Clipboard**. Roblox shows the key only once.

## Step 4: Give the key to GitHub

1. In Safari, open this repository on github.com.
2. Go to **Settings → Secrets and variables → Actions → New repository secret**. On a phone-sized view, Settings may be under the **⋯** menu.
3. Add one secret with this exact name:

| Name | Value |
|---|---|
| `ROBLOX_API_KEY` | the key you copied in Step 3 |

Afterwards, delete the key from anywhere else you pasted it.

## Step 5: Put the workflow on your main branch (one time)

GitHub only shows the **Run workflow** button for workflows that are on the repository's default branch (`main`).

1. On github.com, open **Pull requests → New pull request**.
2. Set **base: main** and **compare: claude/first-chair-roblox-mt805b**.
3. Tap **Create pull request**, then **Merge pull request**.

(You can also ask Claude to open the pull request for you.)

## Step 6: Publish

1. Open the **Actions** tab.
2. Choose **Publish to Roblox** on the left.
3. Tap **Run workflow**, keep **Published**, and tap the green **Run workflow** button.
4. Wait about 2 minutes. A green tick means the game is on Roblox. The log ends with `Published! New place version: …`.

Every later change follows the same flow: update the code, then run **Publish to Roblox** again.

> **Saved vs Published:** *Saved* uploads a new version without showing it to players. *Published* makes it live.

## Step 7: Experience settings (one time, in Creator Hub)

Open your experience, then **Configure** (or the experience's dashboard page):

* **Basic Info:** name it *First Chair*, add a description, and upload an icon and thumbnails. You can make these on the iPad. A courtroom screenshot works well.
* **Avatar:** set **Avatar Type → R15**. The gesture animations are R15. R6 avatars still work but won't point.
* **Questionnaire / Maturity:** fill in the content questionnaire. It's required before the experience can be public. The game has no violence, gore or romance.
* **Server size (optional):** the game already hides other players, so each player gets a private story. A small server size like 6 keeps servers light.
* **Privacy:** keep it **Private** while you test. You, the owner, can still play a private experience. Switch to **Public** when you're happy.

## Step 8: Play it on your iPad

Open the Roblox app → **Creations** or your profile → **First Chair** → **Play**.

Things to check on your first play:

1. The title screen appears over the moving lobby view, and **Start Game → Case 1 → Begin** works.
2. Dialogue is readable, and tapping advances it.
3. The **Case File** and **II** (pause) buttons respond during dialogue.
4. Finishing Case 1 shows the results screen and unlocks Case 2.
5. Leave and rejoin: Case 2 should still be unlocked. This is the save system.

If something looks wrong, describe it or attach a screenshot when you talk to Claude. Changes can be made, tested and republished without a computer.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Publish fails with **HTTP 401** | The API key is wrong, expired, or missing `0.0.0.0/0` in Accepted IP Addresses. Make a new key and update the `ROBLOX_API_KEY` secret. |
| Publish fails with **HTTP 403** | The key lacks **universe-places → write** for *this* experience. Edit the key's permissions. |
| Publish fails with **HTTP 404** | The Universe ID or Place ID at the top of `.github/workflows/publish.yml` is wrong. Compare with Creator Hub (Step 2). |
| "Missing secret" error | The secret must be named exactly `ROBLOX_API_KEY` (capital letters, underscores). |
| No **Run workflow** button | The workflow isn't on `main` yet. Do Step 5. |
| Build step fails before upload | A test caught a problem. Open the failed step's log and share it with Claude. |
| In game: "Progress can't be saved right now" | Roblox DataStores were briefly unavailable. Play continues, but that session isn't saved. In Studio this is normal unless *Game Settings → Security → Enable Studio Access to API Services* is on. |
