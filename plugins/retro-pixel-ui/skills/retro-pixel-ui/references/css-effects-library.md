# CSS Effects Library

Complete, copy-paste CSS snippets for every retro pixel art effect. Each snippet is self-contained and uses the cyberpunk neon CSS custom properties defined in the main skill.

## Prerequisites

Include these custom properties at the root of your stylesheet:

```css
:root {
  --neon-primary: #ff00ff;
  --neon-secondary: #00ffff;
  --neon-accent: #39ff14;
  --neon-hot: #ff1493;
  --neon-blue: #0066ff;
  --bg-void: #0a0a0a;
  --bg-panel: #1a1a2e;
  --bg-surface: #16213e;
  --text-primary: #e0e0ff;
  --text-secondary: #8888aa;
  --scanline-opacity: 0.03;
  --glow-spread: 20px;
  --pixel-unit: 4px;
}
```

---

## CRT Scanlines Overlay

Horizontal lines across the entire screen simulating CRT phosphor rows. Apply to `body` or a container element.

```css
.crt-scanlines {
  position: relative;
}

.crt-scanlines::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 1px,
    rgba(0, 0, 0, var(--scanline-opacity)) 1px,
    rgba(0, 0, 0, var(--scanline-opacity)) 2px
  );
  pointer-events: none;
  z-index: 9999;
}

/* Animated variant -- scanlines slowly drift downward */
.crt-scanlines-animated::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 1px,
    rgba(0, 0, 0, 0.04) 1px,
    rgba(0, 0, 0, 0.04) 2px
  );
  pointer-events: none;
  z-index: 9999;
  animation: scanline-drift 8s linear infinite;
}

@keyframes scanline-drift {
  from { background-position: 0 0; }
  to { background-position: 0 4px; }
}
```

---

## CRT Screen Curvature

Simulates the barrel distortion of a curved CRT monitor. Apply to the main content container.

```css
.crt-screen {
  border-radius: 16px;
  overflow: hidden;
  position: relative;
  box-shadow:
    inset 0 0 60px rgba(0, 0, 0, 0.6),
    inset 0 0 120px rgba(0, 0, 0, 0.3);
}

/* Full CRT with vignette and slight curvature illusion */
.crt-monitor {
  border-radius: 20px;
  overflow: hidden;
  position: relative;
  background: var(--bg-void);
  border: 3px solid #333;
  box-shadow:
    0 0 20px rgba(0, 0, 0, 0.8),
    inset 0 0 80px rgba(0, 0, 0, 0.5),
    inset 0 0 4px rgba(255, 255, 255, 0.05);
}

/* Vignette overlay for CRT edge darkening */
.crt-monitor::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse at center,
    transparent 60%,
    rgba(0, 0, 0, 0.4) 100%
  );
  pointer-events: none;
  z-index: 9998;
}
```

---

## Neon Text Glow

Multiple intensity levels for text glow. Use with pixel fonts for maximum effect.

```css
/* Subtle glow -- for body text accents */
.neon-glow-subtle {
  color: var(--neon-primary);
  text-shadow: 0 0 4px var(--neon-primary);
}

/* Medium glow -- for headings and labels */
.neon-glow-medium {
  color: var(--neon-primary);
  text-shadow:
    0 0 7px var(--neon-primary),
    0 0 10px var(--neon-primary),
    0 0 21px var(--neon-primary);
}

/* Intense glow -- for titles and hero text */
.neon-glow-intense {
  color: #fff;
  text-shadow:
    0 0 4px #fff,
    0 0 11px var(--neon-primary),
    0 0 19px var(--neon-primary),
    0 0 40px var(--neon-primary),
    0 0 80px var(--neon-primary);
}

/* Cyan variant */
.neon-glow-cyan {
  color: var(--neon-secondary);
  text-shadow:
    0 0 7px var(--neon-secondary),
    0 0 10px var(--neon-secondary),
    0 0 21px var(--neon-secondary),
    0 0 42px var(--neon-secondary);
}

/* Green terminal variant */
.neon-glow-terminal {
  color: var(--neon-accent);
  text-shadow:
    0 0 5px var(--neon-accent),
    0 0 10px var(--neon-accent),
    0 0 20px var(--neon-accent);
}

/* Pulsing glow animation */
.neon-glow-pulse {
  color: var(--neon-primary);
  animation: neon-pulse 2s ease-in-out infinite alternate;
}

@keyframes neon-pulse {
  from {
    text-shadow:
      0 0 4px var(--neon-primary),
      0 0 11px var(--neon-primary),
      0 0 19px var(--neon-primary);
  }
  to {
    text-shadow:
      0 0 4px var(--neon-primary),
      0 0 11px var(--neon-primary),
      0 0 19px var(--neon-primary),
      0 0 40px var(--neon-primary),
      0 0 80px var(--neon-primary);
  }
}
```

---

## Neon Box Glow

Glowing borders and outlines for containers, cards, and panels.

```css
/* Subtle box glow */
.neon-box-subtle {
  border: 1px solid var(--neon-primary);
  box-shadow: 0 0 5px rgba(255, 0, 255, 0.3);
}

/* Medium box glow */
.neon-box-medium {
  border: 1px solid var(--neon-primary);
  box-shadow:
    0 0 5px rgba(255, 0, 255, 0.3),
    0 0 10px rgba(255, 0, 255, 0.2),
    0 0 20px rgba(255, 0, 255, 0.1),
    inset 0 0 5px rgba(255, 0, 255, 0.1);
}

/* Intense box glow */
.neon-box-intense {
  border: 2px solid var(--neon-primary);
  box-shadow:
    0 0 5px var(--neon-primary),
    0 0 10px var(--neon-primary),
    0 0 20px var(--neon-primary),
    0 0 40px var(--neon-primary),
    inset 0 0 10px rgba(255, 0, 255, 0.15);
}

/* Cyan box variant */
.neon-box-cyan {
  border: 1px solid var(--neon-secondary);
  box-shadow:
    0 0 5px rgba(0, 255, 255, 0.3),
    0 0 15px rgba(0, 255, 255, 0.15),
    inset 0 0 5px rgba(0, 255, 255, 0.1);
}

/* Double-border neon box (classic RPG feel) */
.neon-box-double {
  border: 2px solid var(--neon-secondary);
  outline: 2px solid var(--neon-primary);
  outline-offset: 2px;
  box-shadow:
    0 0 10px rgba(255, 0, 255, 0.3),
    0 0 10px rgba(0, 255, 255, 0.3);
}
```

---

## Pixel Borders

Stepped, pixelated borders using `box-shadow` for that authentic 8-bit look. No blur, sharp edges only.

```css
/* 1px pixel border -- minimal */
.pixel-border-1 {
  box-shadow:
    -1px 0 0 0 var(--neon-secondary),
     1px 0 0 0 var(--neon-secondary),
     0 -1px 0 0 var(--neon-secondary),
     0  1px 0 0 var(--neon-secondary);
}

/* 2px pixel border -- standard */
.pixel-border-2 {
  box-shadow:
    -2px 0 0 0 var(--neon-secondary),
     2px 0 0 0 var(--neon-secondary),
     0 -2px 0 0 var(--neon-secondary),
     0  2px 0 0 var(--neon-secondary),
    -2px -2px 0 0 var(--neon-secondary),
     2px -2px 0 0 var(--neon-secondary),
    -2px  2px 0 0 var(--neon-secondary),
     2px  2px 0 0 var(--neon-secondary);
}

/* 3px pixel border -- bold, RPG dialog style */
.pixel-border-3 {
  border: 3px solid var(--neon-secondary);
  outline: 3px solid var(--neon-primary);
  outline-offset: 3px;
}

/* Inset pixel border -- pressed/sunken look */
.pixel-border-inset {
  box-shadow:
    inset -2px -2px 0 0 #555,
    inset  2px  2px 0 0 #222,
    inset -1px -1px 0 0 #444,
    inset  1px  1px 0 0 #111;
}

/* 3D pixel border -- raised button look */
.pixel-border-raised {
  box-shadow:
    -2px -2px 0 0 #555,
     2px  2px 0 0 #111,
    -1px -1px 0 0 #444,
     1px  1px 0 0 #222;
}

/* Double pixel border with gap -- classic RPG window */
.pixel-border-rpg {
  border: 4px solid var(--neon-secondary);
  box-shadow:
    inset 0 0 0 2px var(--bg-void),
    inset 0 0 0 4px var(--neon-primary),
    0 0 0 2px var(--bg-void),
    0 0 0 4px var(--neon-primary);
}
```

---

## Screen Noise / Static

Animated visual noise simulating CRT static. Very lightweight, opacity-based.

```css
.screen-noise {
  position: relative;
}

.screen-noise::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.4'/%3E%3C/svg%3E");
  opacity: 0.04;
  pointer-events: none;
  z-index: 9997;
  animation: noise-shift 0.2s steps(3) infinite;
}

@keyframes noise-shift {
  0% { transform: translate(0, 0); }
  33% { transform: translate(-1px, 1px); }
  66% { transform: translate(1px, -1px); }
  100% { transform: translate(0, 0); }
}

/* Heavier static -- for loading screens or glitch moments */
.screen-static::before {
  content: '';
  position: absolute;
  inset: -50%;
  width: 200%;
  height: 200%;
  background: repeating-radial-gradient(
    circle at 17% 32%,
    transparent 0,
    transparent 1px,
    rgba(255, 255, 255, 0.01) 1px,
    rgba(255, 255, 255, 0.01) 2px
  );
  opacity: 0.08;
  pointer-events: none;
  z-index: 9997;
  animation: static-jitter 0.15s steps(4) infinite;
}

@keyframes static-jitter {
  0%   { transform: translate(0, 0) rotate(0deg); }
  25%  { transform: translate(-2px, 1px) rotate(0.5deg); }
  50%  { transform: translate(1px, -1px) rotate(-0.5deg); }
  75%  { transform: translate(-1px, -2px) rotate(0.2deg); }
  100% { transform: translate(2px, 1px) rotate(-0.2deg); }
}
```

---

## Chromatic Aberration

RGB channel splitting that mimics the color fringing of old CRT monitors and VHS artifacts.

```css
/* Subtle chromatic aberration -- for headings */
.chromatic-subtle {
  text-shadow:
    -1px 0 rgba(255, 0, 0, 0.4),
     1px 0 rgba(0, 255, 255, 0.4);
}

/* Medium chromatic aberration -- for titles */
.chromatic-medium {
  text-shadow:
    -2px 0 rgba(255, 0, 0, 0.5),
     2px 0 rgba(0, 255, 255, 0.5),
     0 1px rgba(0, 255, 0, 0.3);
}

/* Heavy chromatic aberration -- for glitch effects */
.chromatic-heavy {
  text-shadow:
    -3px -1px rgba(255, 0, 0, 0.6),
     3px  1px rgba(0, 255, 255, 0.6),
     1px -2px rgba(0, 255, 0, 0.3);
}

/* Animated chromatic glitch */
.chromatic-glitch {
  animation: chromatic-shift 3s ease-in-out infinite;
}

@keyframes chromatic-shift {
  0%, 90%, 100% {
    text-shadow:
      -1px 0 rgba(255, 0, 0, 0.4),
       1px 0 rgba(0, 255, 255, 0.4);
  }
  92% {
    text-shadow:
      -4px -1px rgba(255, 0, 0, 0.8),
       4px  1px rgba(0, 255, 255, 0.8),
       2px -3px rgba(0, 255, 0, 0.5);
  }
  94% {
    text-shadow:
       3px  2px rgba(255, 0, 0, 0.6),
      -3px -2px rgba(0, 255, 255, 0.6);
  }
  96% {
    text-shadow:
      -2px 0 rgba(255, 0, 0, 0.4),
       2px 0 rgba(0, 255, 255, 0.4);
  }
}
```

---

## Typewriter Text Effect

CSS for the typewriter container; requires a small JS driver (see component-templates.md for the full implementation).

```css
.typewriter-container {
  font-family: 'VT323', 'Press Start 2P', monospace;
  color: var(--text-primary);
  font-size: 16px;
  line-height: 1.6;
  min-height: 1.6em;
}

.typewriter-cursor {
  display: inline-block;
  width: 8px;
  height: 1.1em;
  background: var(--neon-secondary);
  margin-left: 2px;
  vertical-align: text-bottom;
  animation: cursor-blink 0.6s steps(2) infinite;
}

@keyframes cursor-blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

/* Variant: green terminal cursor */
.typewriter-cursor--terminal {
  background: var(--neon-accent);
  width: 10px;
  height: 1.2em;
}

/* Variant: underscore cursor */
.typewriter-cursor--underscore {
  width: 10px;
  height: 3px;
  background: var(--neon-secondary);
  vertical-align: baseline;
}
```

---

## Pixel Art Scaling

Ensure pixel art images and sprites scale up crisply without anti-aliasing blur.

```css
.pixel-art {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  -ms-interpolation-mode: nearest-neighbor;
}

/* Pixel art container -- scales content by integer factor */
.pixel-scale-2x { transform: scale(2); transform-origin: top left; }
.pixel-scale-3x { transform: scale(3); transform-origin: top left; }
.pixel-scale-4x { transform: scale(4); transform-origin: top left; }

/* Pixel art canvas -- for rendering crisp pixel content */
.pixel-canvas {
  image-rendering: pixelated;
  width: 100%;
  height: auto;
  display: block;
}
```

---

## Dithering Gradients

CSS-based patterns that mimic pixel dithering -- the technique retro hardware used to simulate more colors than the palette allowed.

```css
/* Checkerboard dither -- simulates 50% transparency */
.dither-checker {
  background-image:
    linear-gradient(45deg, var(--bg-void) 25%, transparent 25%),
    linear-gradient(-45deg, var(--bg-void) 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, var(--bg-void) 75%),
    linear-gradient(-45deg, transparent 75%, var(--bg-void) 75%);
  background-size: 4px 4px;
  background-position: 0 0, 0 2px, 2px -2px, -2px 0;
}

/* Horizontal line dither */
.dither-lines {
  background-image: repeating-linear-gradient(
    0deg,
    var(--bg-panel),
    var(--bg-panel) 2px,
    var(--bg-void) 2px,
    var(--bg-void) 4px
  );
}

/* Diagonal dither */
.dither-diagonal {
  background-image: repeating-linear-gradient(
    45deg,
    var(--bg-panel),
    var(--bg-panel) 2px,
    var(--bg-void) 2px,
    var(--bg-void) 4px
  );
}

/* Gradient dither -- fades from solid to dithered */
.dither-fade {
  background:
    repeating-linear-gradient(
      0deg,
      transparent,
      transparent 1px,
      rgba(0, 0, 0, 0.15) 1px,
      rgba(0, 0, 0, 0.15) 2px
    ),
    linear-gradient(
      to bottom,
      var(--bg-panel),
      var(--bg-void)
    );
}
```

---

## Sprite Animation with steps()

Frame-by-frame sprite sheet animation using pure CSS.

```css
/* 4-frame sprite animation (32x32 sprites in a horizontal strip) */
.sprite-4frame {
  width: 32px;
  height: 32px;
  background: url('spritesheet.png') 0 0 no-repeat;
  image-rendering: pixelated;
  animation: sprite-walk 0.5s steps(4) infinite;
}

@keyframes sprite-walk {
  from { background-position: 0 0; }
  to { background-position: -128px 0; }  /* 4 frames * 32px */
}

/* 8-frame sprite animation (64x64 sprites) */
.sprite-8frame {
  width: 64px;
  height: 64px;
  background: url('spritesheet-large.png') 0 0 no-repeat;
  image-rendering: pixelated;
  animation: sprite-run 0.8s steps(8) infinite;
}

@keyframes sprite-run {
  from { background-position: 0 0; }
  to { background-position: -512px 0; }  /* 8 frames * 64px */
}

/* Direction rows (row 0=down, 1=left, 2=right, 3=up) */
.sprite-down  { background-position-y: 0; }
.sprite-left  { background-position-y: -32px; }
.sprite-right { background-position-y: -64px; }
.sprite-up    { background-position-y: -96px; }

/* Idle bobbing animation */
.sprite-idle {
  animation: sprite-bob 1.2s ease-in-out infinite;
}

@keyframes sprite-bob {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}
```

---

## Parallax Background Layers

Multi-layer scrolling backgrounds for side-scroller or depth effects.

```css
.parallax-container {
  position: relative;
  height: 100vh;
  overflow-x: hidden;
  overflow-y: auto;
  perspective: 1px;
}

.parallax-layer {
  position: absolute;
  inset: 0;
  background-repeat: repeat-x;
  background-size: auto 100%;
  image-rendering: pixelated;
}

/* Far background -- moves slowest */
.parallax-sky {
  background-image: url('bg-sky.png');
  transform: translateZ(-3px) scale(4);
  z-index: 1;
}

/* Mid background -- medium speed */
.parallax-mountains {
  background-image: url('bg-mountains.png');
  transform: translateZ(-2px) scale(3);
  z-index: 2;
}

/* Near background -- moves faster */
.parallax-trees {
  background-image: url('bg-trees.png');
  transform: translateZ(-1px) scale(2);
  z-index: 3;
}

/* Foreground -- normal scroll speed */
.parallax-content {
  position: relative;
  z-index: 4;
  transform: translateZ(0);
}

/* CSS-only horizontal auto-scroll parallax */
.auto-scroll-bg {
  background: url('tileable-bg.png') repeat-x;
  image-rendering: pixelated;
  animation: scroll-bg 20s linear infinite;
}

@keyframes scroll-bg {
  from { background-position: 0 0; }
  to { background-position: -512px 0; }
}
```

---

## Pixel Button (with Press State)

Complete button with 3D pixel shadow, press animation, and neon accents.

```css
.pixel-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 12px;
  color: var(--text-primary);
  background: var(--bg-panel);
  border: none;
  padding: 12px 24px;
  cursor: pointer;
  position: relative;
  text-transform: uppercase;
  letter-spacing: 1px;
  -webkit-font-smoothing: none;
  transition: none; /* No smooth transitions -- pixel-perfect snapping */

  /* 3D pixel shadow */
  box-shadow:
    0 4px 0 0 #111,
    0 4px 0 1px var(--neon-primary),
    inset 0 0 0 1px var(--neon-primary);
}

.pixel-btn:hover {
  background: var(--bg-surface);
  color: var(--neon-primary);
  box-shadow:
    0 4px 0 0 #111,
    0 4px 0 1px var(--neon-primary),
    inset 0 0 0 1px var(--neon-primary),
    0 0 12px rgba(255, 0, 255, 0.3);
}

.pixel-btn:active {
  transform: translateY(4px);
  box-shadow:
    0 0 0 0 #111,
    0 0 0 1px var(--neon-primary),
    inset 0 0 0 1px var(--neon-primary);
}

.pixel-btn:focus-visible {
  outline: 2px solid var(--neon-secondary);
  outline-offset: 4px;
  box-shadow:
    0 4px 0 0 #111,
    0 4px 0 1px var(--neon-primary),
    inset 0 0 0 1px var(--neon-primary),
    0 0 12px rgba(0, 255, 255, 0.4);
}

.pixel-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  box-shadow:
    0 4px 0 0 #111,
    inset 0 0 0 1px #555;
  color: #555;
}
```

---

## RPG Dialog Box

Complete dialog box with double pixel border and neon accent.

```css
.rpg-dialog {
  position: relative;
  background: rgba(10, 10, 10, 0.95);
  padding: 20px 24px;
  margin: 16px;
  font-family: 'VT323', monospace;
  font-size: 18px;
  color: var(--text-primary);
  line-height: 1.6;
  max-width: 640px;

  /* Double pixel border */
  border: 3px solid var(--neon-secondary);
  box-shadow:
    inset 0 0 0 3px var(--bg-void),
    inset 0 0 0 5px var(--neon-primary),
    0 0 15px rgba(0, 255, 255, 0.2),
    0 0 30px rgba(255, 0, 255, 0.1);
}

/* Speaker name label */
.rpg-dialog__speaker {
  position: absolute;
  top: -14px;
  left: 16px;
  background: var(--bg-void);
  padding: 2px 12px;
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  color: var(--neon-primary);
  border: 2px solid var(--neon-primary);
  text-transform: uppercase;
  letter-spacing: 1px;
}

/* Continue indicator -- blinking triangle */
.rpg-dialog__continue {
  position: absolute;
  bottom: 8px;
  right: 12px;
  font-size: 12px;
  color: var(--neon-secondary);
  animation: dialog-bounce 0.8s steps(2) infinite;
}

@keyframes dialog-bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(4px); }
}
```

---

## HP / MP Bar Component

Segmented health and mana bars with color transitions.

```css
.pixel-bar {
  width: 200px;
  height: 16px;
  background: #111;
  position: relative;
  border: 2px solid #555;
  box-shadow: inset 0 0 0 1px #222;
}

.pixel-bar__fill {
  height: 100%;
  transition: width 0.3s steps(10);
  position: relative;
}

/* HP bar -- green to yellow to red */
.pixel-bar__fill--hp {
  background: linear-gradient(to right, #00cc00, #39ff14);
  box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.3);
}

.pixel-bar__fill--hp.low {
  background: linear-gradient(to right, #cc0000, #ff4444);
}

.pixel-bar__fill--hp.medium {
  background: linear-gradient(to right, #ccaa00, #ffdd00);
}

/* MP bar -- blue gradient */
.pixel-bar__fill--mp {
  background: linear-gradient(to right, #0044cc, #0088ff);
  box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.3);
}

/* XP bar -- purple/magenta */
.pixel-bar__fill--xp {
  background: linear-gradient(to right, #8800cc, #ff00ff);
  box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.3);
}

/* Segmented overlay -- creates pixel segments */
.pixel-bar::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    90deg,
    transparent,
    transparent 8px,
    rgba(0, 0, 0, 0.3) 8px,
    rgba(0, 0, 0, 0.3) 10px
  );
  pointer-events: none;
}

/* Bar label */
.pixel-bar__label {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-family: 'Silkscreen', monospace;
  font-size: 8px;
  color: #fff;
  text-shadow: 1px 1px 0 #000;
  z-index: 1;
  white-space: nowrap;
}
```

---

## Retro Scrollbar Styling

Custom scrollbars that match the pixel art aesthetic. Webkit/Blink and Firefox support.

```css
/* Webkit/Blink (Chrome, Edge, Safari) */
.retro-scroll::-webkit-scrollbar {
  width: 12px;
  background: var(--bg-void);
}

.retro-scroll::-webkit-scrollbar-track {
  background: var(--bg-void);
  border-left: 2px solid var(--neon-primary);
}

.retro-scroll::-webkit-scrollbar-thumb {
  background: var(--bg-panel);
  border: 2px solid var(--neon-secondary);
}

.retro-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--bg-surface);
  box-shadow: 0 0 8px rgba(0, 255, 255, 0.3);
}

.retro-scroll::-webkit-scrollbar-corner {
  background: var(--bg-void);
}

/* Firefox */
.retro-scroll {
  scrollbar-width: thin;
  scrollbar-color: var(--neon-secondary) var(--bg-void);
}
```
