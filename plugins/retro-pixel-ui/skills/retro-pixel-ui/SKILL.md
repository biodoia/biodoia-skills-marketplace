---
name: retro-pixel-ui
description: This skill should be used when the user asks about "pixel art UI", "retro design", "8-bit style", "16-bit aesthetic", "cyberpunk UI", "neon glow", "scanlines", "CRT effect", "game UI", "pixel font", "chiptune", or "NES.css". Make sure to use this skill whenever the user wants to design or build retro-styled, pixel art, cyberpunk neon, or nostalgic gaming-inspired user interfaces, needs CSS effects like scanlines, CRT curvature, neon glow, or pixel borders, or wants distinctive non-generic frontend design with a retro aesthetic, even if they just mention wanting a cool or unique UI style.
---

# Retro Pixel UI/UX Design

Expert skill for designing and building retro gaming-inspired, pixel art, 8-bit/16-bit aesthetic, cyberpunk neon user interfaces. This is not a generic frontend skill -- it is a specialized design system rooted in the visual language of classic gaming hardware, arcade cabinets, and the neon-drenched cyberpunk aesthetic.

## Design Philosophy

### Constraints Breed Creativity

The golden era of gaming (1983-1995) produced iconic visual designs not despite hardware limitations but because of them. The NES had 54 colors and 256x240 resolution. The Game Boy had 4 shades of green. These constraints forced extraordinary economy.

Apply the same discipline to modern UI:
- **Limited palettes**: Pick 4-8 core colors. Every color earns its place.
- **Pixel grid thinking**: Design on a grid (8px, 16px, 32px base units). Every element snaps. No fractional pixels.
- **Tile-based composition**: Build screens from reusable tiles, just as hardware sprite engines did. Components tessellate cleanly.
- **Intentional imperfection**: Slight glow bleeds, scanline gaps, and CRT curvature remind users this is a crafted aesthetic.

### Nostalgia as UX Enhancer

Users who grew up with NES, SNES, Genesis, and arcade cabinets have deeply ingrained pattern recognition:
- **RPG dialog boxes** instantly signal "read this text carefully"
- **HP/MP bars** communicate progress more viscerally than generic progress bars
- **Menu cursors** make navigation feel deliberate and satisfying
- **Pixel borders** create visual hierarchy without drop shadows or blur

### Cyberpunk Neon Overlay

The cyberpunk aesthetic extends retro gaming visuals into the future:
- **Dark backgrounds** (#0a0a0a, #1a1a2e) -- the void from which neon emerges
- **Neon glow effects** -- magenta, cyan, and green light bleeding through darkness
- **Terminal aesthetics** -- monospaced fonts, blinking cursors, command-line echoes
- **Scanline overlays** -- the ghost of CRT phosphors, adding texture and depth
- **Information density** -- HUD-style layouts dense with data

### Balance: Retro Aesthetics + Modern Usability

Retro style must never compromise function:
- **Responsive**: Scale pixel art cleanly using `image-rendering: pixelated` and integer scaling
- **Accessible**: Neon-on-dark provides excellent contrast ratios. Add proper ARIA, focus management, and motion preferences
- **Performant**: CSS-based effects over JS. Lightweight pixel fonts. Minimal paint complexity
- **Progressive**: Start with semantic HTML, layer pixel aesthetics on top

## Color Palettes

### Core Cyberpunk Neon Palette (Default)

```css
:root {
  --neon-primary: #ff00ff;       /* Magenta -- main accent, links, active states */
  --neon-secondary: #00ffff;     /* Cyan -- secondary accent, highlights, info */
  --neon-accent: #39ff14;        /* Neon green -- success, terminal, data */
  --neon-hot: #ff1493;           /* Hot pink -- warnings, emphasis, hover */
  --neon-blue: #0066ff;          /* Electric blue -- buttons, interactive */
  --bg-void: #0a0a0a;           /* True dark -- page background */
  --bg-panel: #1a1a2e;          /* Deep navy -- card/panel background */
  --bg-surface: #16213e;        /* Lighter navy -- elevated surfaces */
  --bg-hover: #0f3460;          /* Hover state background */
  --text-primary: #e0e0ff;      /* Soft lavender white -- body text */
  --text-secondary: #8888aa;    /* Muted -- secondary text */
  --scanline-opacity: 0.03;     /* Subtle scanline overlay */
  --glow-spread: 20px;          /* Neon glow radius */
  --pixel-unit: 4px;            /* Base pixel grid unit */
  --color-success: #39ff14;
  --color-warning: #ffaa00;
  --color-danger: #ff0040;
  --color-info: #00ffff;
}
```

### Classic Console Palettes

Use these when targeting a specific retro hardware aesthetic. Full hex tables with RGB values and usage guidelines are in `references/palettes.md`.

- **NES (54 colors)**: The full PPU palette -- iconic and immediately recognizable
- **Game Boy (4 greens)**: #0f380f, #306230, #8bac0f, #9bbc0f
- **CGA (16 colors)**: The original PC palette
- **SNES Warm**: Richer RPG-inspired palette (Chrono Trigger, FF6)
- **Synthwave / Vaporwave**: Sunset pinks, deep purples, chrome blues
- **Amber monochrome**: #ff8800 on #1a0800 -- classic terminal
- **Green monochrome**: #33ff33 on #0a1a0a -- hacker terminal

## Typography

### Pixel Fonts

| Font | Style | Source | Best For |
|------|-------|--------|----------|
| Press Start 2P | 8-bit NES | Google Fonts | Headings, titles, logos |
| VT323 | Terminal CRT | Google Fonts | Body text, monospace content |
| Silkscreen | Clean pixel | Google Fonts | Small UI labels, buttons |
| Pixelify Sans | Modern pixel | Google Fonts | Body text, readable pixel |
| IBM Plex Mono | Terminal | Google Fonts | Code, terminal text |

### Font Rendering

Force sharp, pixel-perfect rendering -- no anti-aliasing:

```css
.pixel-text {
  font-family: 'Press Start 2P', monospace;
  -webkit-font-smoothing: none;
  -moz-osx-font-smoothing: unset;
  font-smooth: never;
  image-rendering: pixelated;
  text-rendering: optimizeSpeed;
}
```

### Size Scale

Maintain pixel-perfect sizing with integer multiples of the base pixel unit:

```css
.text-xs  { font-size: 8px;  line-height: 12px; }
.text-sm  { font-size: 12px; line-height: 16px; }
.text-md  { font-size: 16px; line-height: 24px; }
.text-lg  { font-size: 24px; line-height: 32px; }
.text-xl  { font-size: 32px; line-height: 40px; }
.text-2xl { font-size: 48px; line-height: 56px; }
```

### Neon Glow Text

```css
.neon-text {
  color: var(--neon-primary);
  text-shadow:
    0 0 7px var(--neon-primary),
    0 0 10px var(--neon-primary),
    0 0 21px var(--neon-primary),
    0 0 42px var(--neon-primary);
}
```

## CSS Effects & Techniques

All effects are documented with full copy-paste code in `references/css-effects-library.md`. Summary of available effects:

- **CRT Scanlines** -- `::after` pseudo-element with `repeating-linear-gradient`. Keep opacity at 0.03-0.05.
- **CRT Screen Curvature** -- Barrel distortion using CSS transforms and inset box-shadow.
- **Neon Glow** -- Multi-layer `text-shadow` or `box-shadow` (3-5 shadow layers for depth).
- **Pixel Borders** -- `box-shadow` with zero blur and pixel-unit offsets. Sharp corners only.
- **Screen Noise / Static** -- CSS `@keyframes` cycling opacity on a noise overlay.
- **Chromatic Aberration** -- Offset `text-shadow` in RGB channels.
- **Dithering Patterns** -- `repeating-linear-gradient` at 45 degrees for pixel dithering.
- **Pixelated Image Scaling:**
  ```css
  .pixel-art {
    image-rendering: pixelated;
    image-rendering: crisp-edges;
  }
  ```

## Component Patterns

Complete HTML+CSS templates for all components are in `references/component-templates.md`. Design principles for each:

| Component | Key Design Principle |
|-----------|---------------------|
| Dialog Boxes | RPG-style with double-pixel borders, typewriter text, blinking continue indicator |
| Menus | Pixel arrow cursor (`::before`), glowing highlight bar, arrow key navigation |
| Buttons | No border-radius. Pixel borders via `box-shadow`. Translate down 2px on `:active` |
| HP/Progress Bars | Segmented pixel blocks. Color transitions: green > yellow > red |
| Inventory Grids | Tile-based grid (32/64px cells), dithering on empty cells, hover tooltips |
| Cards / Panels | Pixel corners, 90s-OS-style title bar, consistent padding on pixel grid |
| Forms | Pixel borders, blinking cursor, no rounded corners. Pixel icon validation states |
| Notifications | Pixel slide animation, auto-dismiss with segmented timer bar |
| Loading States | Pixel spinner, segmented progress bar, "NOW LOADING..." with animated dots |

## Animation Patterns

### Sprite Sheets

Use CSS `steps()` timing function with `background-position` to animate frame-by-frame:
```css
.sprite {
  width: 32px; height: 32px;
  background: url('spritesheet.png') 0 0;
  animation: walk 0.6s steps(4) infinite;
}
@keyframes walk {
  to { background-position: -128px 0; }
}
```

### Screen Transitions
- **Fade**: Simple opacity transition
- **Wipe**: CSS clip-path animating from left to right
- **Pixelate dissolve**: Scale down + pixelate filter, then scale up new content
- **Iris**: Circular clip-path expanding from center

## Audio Cues (Optional Enhancement)

### Chiptune SFX

```javascript
const audioCtx = new AudioContext();
function playBeep(freq = 440, duration = 0.1, type = 'square') {
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.type = type;  // 'square' for classic 8-bit
  osc.frequency.value = freq;
  gain.gain.value = 0.1;
  osc.connect(gain).connect(audioCtx.destination);
  osc.start();
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);
  osc.stop(audioCtx.currentTime + duration);
}
```

| Action | Sound | Frequency/Pattern |
|--------|-------|-------------------|
| Menu navigate | Short blip | 440Hz, 50ms, square |
| Confirm/Select | Rising tone | 523-784Hz sweep, 100ms |
| Cancel/Back | Descending tone | 392-262Hz sweep, 100ms |
| Error | Buzz | 150Hz, 200ms, sawtooth |

Libraries: **Howler.js** (audio sprites), **Tone.js** (procedural chiptune), **jsfxr** (retro SFX generator).

## Layout Patterns

### Fixed-Ratio Viewport
```css
.game-viewport {
  aspect-ratio: 4 / 3;
  max-width: 960px;
  margin: 0 auto;
  background: var(--bg-void);
  overflow: hidden;
  image-rendering: pixelated;
}
```

### HUD Overlay
```css
.hud { position: fixed; z-index: 100; pointer-events: none; }
.hud-top-left { top: 8px; left: 8px; }
.hud-top-right { top: 8px; right: 8px; }
.hud-bottom { bottom: 0; left: 0; right: 0; }
```

### Responsive Pixel Scaling
```css
@media (min-width: 768px) {
  .pixel-scale { transform: scale(2); transform-origin: top left; }
}
@media (min-width: 1200px) {
  .pixel-scale { transform: scale(3); transform-origin: top left; }
}
```

## Frameworks & Tools

| Framework | Style | URL | Notes |
|-----------|-------|-----|-------|
| NES.css | NES/Famicom | nostalgic-css.github.io/NES.css | Most popular, solid components |
| RPGUI | RPG themed | ronenness.github.io/RPGUI | Game-like UI elements |
| 98.css | Windows 98 | jdan.github.io/98.css | Classic OS nostalgia |
| XP.css | Windows XP | botoxparty.github.io/XP.css | Luna theme recreation |

Canvas-based options: **PixiJS** (2D WebGL), **Phaser** (full game framework), **Konva** (drag-and-drop).

For most web UIs, a custom CSS approach using the variables and patterns in this skill produces the best results -- no framework dependency, full control, minimal bundle size.

## Integration with Modern Stacks

### HTMX + Retro Templates
Server-rendered HTML with HTMX swaps. Apply retro CSS classes to server templates. SSE for live updates. Ideal for the retro aesthetic because it keeps HTML semantic and adds behavior progressively.

### Tailwind CSS Extension
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: { pixel: ['"Press Start 2P"', 'monospace'] },
      colors: {
        neon: { primary: '#ff00ff', secondary: '#00ffff', accent: '#39ff14' },
        retro: { void: '#0a0a0a', panel: '#1a1a2e', surface: '#16213e' },
      },
      spacing: { 'px-1': '4px', 'px-2': '8px', 'px-4': '16px', 'px-8': '32px' },
    },
  },
}
```

## Accessibility

Retro aesthetics must be inclusive:

- **Font sizing**: Use `rem` for text. The pixel sizes in this skill are guides -- implement as rem equivalents that respect user preferences
- **Motion**: Wrap all animations in `@media (prefers-reduced-motion: no-preference)`. Provide static fallbacks
- **Contrast**: Neon on dark achieves WCAG AAA in most cases. `#00ffff` on `#0a0a0a` = 16.3:1 (AAA). `#ff00ff` on `#0a0a0a` = 6.2:1 (AA)
- **Focus indicators**: Glowing pixel outlines:
  ```css
  :focus-visible {
    outline: 2px solid var(--neon-secondary);
    outline-offset: 2px;
    box-shadow: 0 0 8px var(--neon-secondary);
  }
  ```
- **Semantic HTML**: Under every pixel-art veneer, use proper `<nav>`, `<main>`, `<button>`, `<dialog>` elements
- **Keyboard navigation**: All interactive components must be keyboard-accessible. Tab order is logical

## Performance

- **Pixel fonts**: Subset to needed characters, serve as woff2. Press Start 2P full set is only ~8KB woff2
- **CSS over JS**: All scanline, glow, and noise effects are pure CSS. No JS paint loops
- **`will-change`**: Use sparingly, only on actively animating elements
- **Scanline/noise weight**: Opacity-based overlays on `::after` pseudo-elements have minimal paint cost. Avoid `backdrop-filter`
- **Animation budget**: Keep CSS animations under 16ms frame budget. `steps()` animations are inherently lightweight

## Additional Resources

- **`references/css-effects-library.md`** -- Complete, copy-paste CSS snippets for every retro effect: CRT scanlines (static and animated), screen curvature, neon text glow (5 variants + pulse animation), neon box glow, pixel borders (6 styles including RPG), screen noise/static, chromatic aberration (with animated glitch), typewriter cursor, pixel art scaling, dithering gradients, sprite animation, parallax backgrounds, pixel buttons, RPG dialog box, HP/MP bars, and retro scrollbars. Consult when implementing any visual effect.
- **`references/component-templates.md`** -- Full HTML + CSS + JS component templates ready to drop into any project: RPG dialog box with typewriter JS, pixel menus with keyboard navigation, button variants, health/progress bars, inventory grids, navigation bars, cards/panels, form elements, toast notifications, loading states, and modal windows. Consult when building any UI component.
- **`references/palettes.md`** -- Curated retro gaming color palettes with hex codes, RGB values, and usage guidelines: Cyberpunk Neon, NES (54 colors), Game Boy, SNES Warm, CGA 16-color, Synthwave/Vaporwave, Amber Terminal, and Green Terminal. Includes contrast ratios and palette combination advice. Consult when choosing or customizing a color scheme.
