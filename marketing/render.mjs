// Renders the store art (icon + thumbnails) and the teaser video from the HTML in ./src.
//   node marketing/render.mjs            -> marketing/out/*.png, marketing/out/teaser.mp4
//   node marketing/render.mjs --stills   -> images only
// Needs: Chromium via Playwright (pre-installed here), ffmpeg.

import { chromium } from 'playwright';
import { spawnSync } from 'node:child_process';
import { mkdirSync, rmSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const src = (f) => 'file://' + path.join(here, 'src', f);
const out = path.join(here, 'out');
mkdirSync(out, { recursive: true });
const stillsOnly = process.argv.includes('--stills');
const FPS = 30;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });

async function ready() {
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(200);
}

// ---- stills
await page.goto(src('thumbnail.html'), { waitUntil: 'networkidle' });
await ready();
await page.locator('#wide').screenshot({ path: path.join(out, 'thumbnail-title-1920x1080.png') });
await page.locator('#cases').screenshot({ path: path.join(out, 'thumbnail-cases-1920x1080.png') });
await page.locator('#icon').screenshot({ path: path.join(out, 'icon-512.png') });
console.log('stills written');

if (!stillsOnly) {
  // ---- teaser frames
  const frames = path.join(out, 'frames');
  rmSync(frames, { recursive: true, force: true });
  mkdirSync(frames);
  await page.goto(src('teaser.html'), { waitUntil: 'networkidle' });
  await ready();
  const duration = await page.evaluate(() => window.__duration);
  const total = Math.round(duration * FPS);
  for (let i = 0; i < total; i++) {
    await page.evaluate((t) => window.seek(t), i / FPS);
    await page.screenshot({ path: path.join(frames, `f${String(i).padStart(4, '0')}.png`), type: 'png' });
    if (i % 60 === 0) console.log(`frame ${i}/${total}`);
  }

  // ---- soundtrack: a low warm drone, a swell, and a gavel strike at the title and the objection.
  // All synthesised by ffmpeg, so no downloaded audio and nothing to license.
  const audio = path.join(out, 'teaser-audio.wav');
  const af = [
    `sine=frequency=55:duration=${duration},volume=0.10,lowpass=f=160[drone]`,
    `sine=frequency=110.3:duration=${duration},volume=0.045,tremolo=f=0.25:d=0.6[fifth]`,
    `anoisesrc=color=brown:duration=${duration}:amplitude=0.05,lowpass=f=400,highpass=f=40,volume=0.5[room]`,
    // gavel at 3.2s and 17.25s: short bursts of lowpassed noise shaped by an envelope
    `anoisesrc=color=pink:duration=0.35:amplitude=1,lowpass=f=900,afade=t=out:st=0.02:d=0.33,volume=1.4,adelay=3200|3200[g1]`,
    `anoisesrc=color=pink:duration=0.4:amplitude=1,lowpass=f=700,afade=t=out:st=0.02:d=0.38,volume=1.8,adelay=17250|17250[g2]`,
    `[drone][fifth][room][g1][g2]amix=inputs=5:duration=longest:normalize=0,afade=t=in:st=0:d=1.5,afade=t=out:st=${duration - 1.5}:d=1.5,volume=1.6[a]`,
  ].join(';');
  let r = spawnSync('ffmpeg', ['-y', '-filter_complex', af, '-map', '[a]', '-ac', '2', '-ar', '48000', audio], { stdio: 'inherit' });
  if (r.status !== 0) throw new Error('audio synth failed');

  // ---- encode H.264 (yuv420p so phones, YouTube and Roblox all accept it)
  const mp4 = path.join(out, 'teaser-1920x1080.mp4');
  r = spawnSync('ffmpeg', [
    '-y', '-framerate', String(FPS), '-i', path.join(frames, 'f%04d.png'), '-i', audio,
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
    '-c:a', 'aac', '-b:a', '160k', '-shortest', mp4,
  ], { stdio: 'inherit' });
  if (r.status !== 0) throw new Error('video encode failed');
  rmSync(frames, { recursive: true, force: true });
  rmSync(audio, { force: true });
  console.log('video written:', mp4);
}

await browser.close();
