# Store art for FIRST CHAIR

Everything here is generated from `src/*.html` by `render.mjs` (Chromium + ffmpeg), so the
art stays on-brand with the game's palette and fonts and can be re-rendered after any change.

| File | Use in Creator Hub |
|---|---|
| `out/icon-512.png` | **Basic Info → Icon** (512×512) |
| `out/thumbnail-title-1920x1080.png` | **Basic Info → Thumbnails** (first image) |
| `out/thumbnail-cases-1920x1080.png` | second thumbnail |
| `out/teaser-1920x1080.mp4` | 22-second cinematic teaser, 1080p30, H.264 + AAC |

## About the video

Roblox requires uploaded experience videos to show **authentic in-game content**, and uploads are
capped at 3 per month. This teaser is motion graphics (title, cases, objection stamp) and contains no
gameplay footage, because the game hasn't been captured on a real device yet. Use it for social media,
YouTube or a Discord, and for the Roblox store page cut a version with real footage:

1. On the iPad, screen-record 30–60 seconds of play (Control Centre → Screen Recording).
2. Add the clips to this folder (or share them) and ask Claude to cut a trailer: the teaser's title,
   case cards and end card become the bookends around the real footage.

## Re-render

```bash
node marketing/render.mjs            # icon + thumbnails + video (~5 minutes)
node marketing/render.mjs --stills   # images only (~5 seconds)
```
