---
name: retro-pixel-ui
description: Use when designing or building retro-styled, pixel art, 8-bit, 16-bit, cyberpunk neon, or nostalgic gaming-inspired user interfaces and web applications. Also use when mentioning 'pixel art UI', 'retro design', '8-bit style', '16-bit aesthetic', 'cyberpunk UI', 'neon glow', 'scanlines', 'CRT effect', 'game UI', 'pixel font', 'chiptune aesthetic', or wanting distinctive non-generic frontend design.
---

# Retro Pixel UI/UX Design

Expert skill for designing and building retro gaming-inspired, pixel art, 8-bit/16-bit aesthetic, cyberpunk neon user interfaces. This is not a generic frontend skill -- it is a specialized design system rooted in the visual language of classic gaming hardware, arcade cabinets, and the neon-drenched cyberpunk aesthetic.

## Design Philosophy

### Constraints Breed Creativity

The golden era of gaming (1983-1995) produced some of the most iconic visual designs in history, not despite hardware limitations but because of them. The NES had 54 colors and 256x240 resolution. The Game Boy had 4 shades of green. These constraints forced designers to communicate with extraordinary economy.

Apply the same discipline to modern UI:
- **Limited palettes**: Pick 4-8 core colors and stick to them. Every color earns its place.
- **Pixel grid thinking**: Design on a grid (8px, 16px, 32px base units). Every element snaps to the grid. No fractional pixels, no arbitrary spacing.
- **Tile-based composition**: Build screens from reusable tiles, just as hardware sprite engines did. Components are modular squares and rectangles that tessellate cleanly.
- **Intentional imperfection**: Slight glow bleeds, scanline gaps, and CRT curvature remind users this is a crafted aesthetic, not a bug.

### Nostalgia as UX Enhancer

Nostalgia is a powerful UX tool. Users who grew up with NES, SNES, Genesis, Game Boy, and arcade cabinets have deeply ingrained pattern recognition for these visual languages:
- **RPG dialog boxes** instantly signal "read this text carefully"
- **HP/MP bars** communicate progress more viscerally than generic progress bars
- **Menu cursors (arrow pointers)** make navigation feel deliberate and satisfying
- **Pixel borders** create visual hierarchy without needing drop shadows or blur

Even users without direct nostalgia recognize these patterns as intentional, distinctive, and characterful -- the opposite of yet another flat Material Design clone.

### Cyberpunk Neon Overlay

The cyberpunk aesthetic extends retro gaming visuals into the future:
- **Dark backgrounds** (#0a0a0a, #1a1a2e) -- the void from which neon emerges
- **Neon glow effects** -- magenta, cyan, and green light bleeding through darkness
- **Terminal aesthetics** -- monospaced fonts, blinking cursors, command-line echoes
- **Scanline overlays** -- the ghost of CRT phosphors, adding texture and depth
- **Information density** -- HUD-style layouts dense with data, like a hacker's terminal

### Balance: Retro Aesthetics + Modern Usability

Retro style must never compromise function:
- **Responsive**: Scale pixel art cleanly using `image-rendering: pixelated` and integer scaling
- **Accessible**: Neon-on-dark already provides excellent contrast ratios. Add proper ARIA, focus management, and motion preferences
- **Performant**: CSS-based effects over JS. Lightweight pixel fonts. Minimal paint complexity
- **Progressive**: Start with semantic HTML, layer pixel aesthetics on top. Works without CSS, looks extraordinary with it

## Color Palettes

### Core Cyberpunk Neon Palette (Default)

The recommended palette for all retro pixel UIs:

```css
:root {
  /* Primary neons */
  --neon-primary: #ff00ff;       /* Magenta -- main accent, links, active states */
  --neon-secondary: #00ffff;     /* Cyan -- secondary accent, highlights, info */
  --neon-accent: #39ff14;        /* Neon green -- success, terminal, data */
  --neon-hot: #ff1493;           /* Hot pink -- warnings, emphasis, hover */
  --neon-blue: #0066ff;          /* Electric blue -- buttons, interactive */

  /* Backgrounds */
  --bg-void: #0a0a0a;           /* True dark -- page background */
  --bg-panel: #1a1a2e;          /* Deep navy -- card/panel background */
  --bg-surface: #16213e;        /* Lighter navy -- elevated surfaces */
  --bg-hover: #0f3460;          /* Hover state background */

  /* Text */
  --text-primary: #e0e0ff;      /* Soft lavender white -- body text */
  --text-secondary: #8888aa;    /* Muted -- secondary text */
  --text-glow: #ffffff;         /* Pure white -- for glow effect source */

  /* Effects */
  --scanline-opacity: 0.03;     /* Subtle scanline overlay */
  --glow-spread: 20px;          /* Neon glow radius */
  --pixel-unit: 4px;            /* Base pixel grid unit */

  /* Semantic */
  --color-success: #39ff14;     /* Neon green */
  --color-warning: #ffaa00;     /* Amber */
  --color-danger: #ff0040;      /* Red neon */
  --color-info: #00ffff;        /* Cyan */
}
```

### Classic Console Palettes

Use these when targeting a specific retro hardware aesthetic:

- **NES (54 colors)**: See `references/palettes.md` for full hex table
- **Game Boy (4 greens)**: #0f380f, #306230, #8bac0f, #9bbc0f
- **CGA (16 colors)**: The original PC palette, iconic and limited
- **SNES**: Richer palette, up to 256 on-screen from 32768 possible
- **Amber monochrome**: #ff8800 on #1a0800 -- classic terminal
- **Green monochrome**: #33ff33 on #0a1a0a -- hacker terminal

### Palette Generators

- **Lospec** (lospec.com/palette-list): Curated retro palettes, filter by color count
- **Coolors** (coolors.co): Generate palettes, lock retro anchor colors
- **Color Hunt**: Search "retro", "neon", "cyberpunk" for curated sets

## Typography

### Pixel Fonts

| Font | Style | Source | Best For |
|------|-------|--------|----------|
| Press Start 2P | 8-bit NES | Google Fonts | Headings, titles, logos |
| VT323 | Terminal CRT | Google Fonts | Body text, monospace content |
| Silkscreen | Clean pixel | Google Fonts | Small UI labels, buttons |
| Pixelify Sans | Modern pixel | Google Fonts | Body text, readable pixel |
| DotGothic16 | Japanese pixel | Google Fonts | Japanese-style retro |
| IBM Plex Mono | Terminal | Google Fonts | Code, terminal text |
| Kongtext | Chunky 8-bit | Free | Large display headings |
| Upheaval | Bold 16-bit | Free | Impact headings |

### Font Loading

```html
<!-- Google Fonts -- fast and reliable -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=VT323&family=Silkscreen&display=swap" rel="stylesheet">
```

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
.text-xs  { font-size: 8px;  line-height: 12px; }  /* Tiny labels */
.text-sm  { font-size: 12px; line-height: 16px; }  /* Small UI text */
.text-md  { font-size: 16px; line-height: 24px; }  /* Body text */
.text-lg  { font-size: 24px; line-height: 32px; }  /* Subheadings */
.text-xl  { font-size: 32px; line-height: 40px; }  /* Headings */
.text-2xl { font-size: 48px; line-height: 56px; }  /* Display titles */
```

### Text Effects

**Neon glow text:**
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

**Typewriter effect** requires JS -- see `references/component-templates.md` for the full implementation.

## CSS Effects & Techniques

All effects are documented with copy-paste code in `references/css-effects-library.md`. Summary:

### CRT Scanlines
A `::after` pseudo-element with `repeating-linear-gradient` creates horizontal lines across the screen. Keep opacity at 0.03-0.05 for subtlety.

### CRT Screen Curvature
Apply slight barrel distortion using CSS transforms to simulate a curved CRT monitor.

### Neon Glow
Multi-layer `text-shadow` or `box-shadow` with increasing blur radius and decreasing opacity. Stack 3-5 shadows for rich glow depth.

### Pixel Borders
Use `box-shadow` with zero blur and pixel-unit offsets to create stepped, pixelated borders. No border-radius -- sharp corners only.

### Screen Noise / Static
CSS `@keyframes` animation cycling opacity on a high-frequency noise overlay. Keep lightweight.

### Chromatic Aberration
Offset `text-shadow` in red, green, and blue channels with slight horizontal displacement.

### Dithering Patterns
CSS `background-image` with `repeating-linear-gradient` at 45 degrees to simulate pixel dithering.

### Pixelated Image Scaling
```css
.pixel-art {
  image-rendering: pixelated;           /* Chrome, Firefox */
  image-rendering: -moz-crisp-edges;    /* Firefox fallback */
  image-rendering: crisp-edges;         /* Standard */
  -ms-interpolation-mode: nearest-neighbor; /* IE */
}
```

## Component Patterns

Complete HTML+CSS templates for all components are in `references/component-templates.md`. Design principles for each:

### Dialog Boxes
RPG-style text boxes with double-pixel borders, dark semi-transparent backgrounds, character portrait on the left, text appearing with typewriter effect. The blinking triangle at the bottom-right signals "press to continue."

### Menus
Vertical lists with a pixel arrow cursor (using `::before` content: "\\25B8"). Active item has a glowing highlight bar. Arrow keys navigate, Enter selects. Add subtle SFX on selection change.

### Buttons
No border-radius. Pixel borders via `box-shadow`. On `:active`, translate down 2px and remove bottom shadow to simulate physical press. Three variants: primary (magenta), secondary (cyan), danger (red neon).

### Health / Progress Bars
Segmented bars with individual pixel blocks that fill or drain. Color transitions: green > yellow > red as value decreases. Label text outside or inside the bar.

### Inventory Grids
Tile-based grid (32px or 64px cells) with pixel borders. Hover shows item tooltip. Empty cells have subtle dithering pattern. Drag-and-drop for reordering.

### Navigation
Top bar or sidebar with pixel icons. Active state uses neon underline glow. Mobile: hamburger menu slides in with pixel animation.

### Cards / Panels
Bordered panels with pixel corners and a title bar reminiscent of 90s OS windows. Optional close button (X) in title bar. Content area with consistent padding on pixel grid.

### Forms
Input fields with pixel borders, blinking cursor, no rounded corners. Validation states use pixel icons: green checkmark, red X, yellow warning triangle.

### Notifications / Toasts
Pop-up from screen edge with pixel slide animation. Pixel art icons for message type. Auto-dismiss with segmented timer bar.

### Loading States
Pixel spinner (rotating pixel square), segmented progress bar filling left to right, "NOW LOADING..." text with animated dots.

## Animation Patterns

### Sprite Sheets
Use CSS `steps()` timing function with `background-position` to animate sprite sheets frame-by-frame:
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

### Parallax Scrolling
Multi-layer backgrounds scrolling at different speeds, like classic side-scrollers. Use `background-attachment: fixed` with different `background-position` rates, or CSS `transform: translateZ()` with `perspective`.

### Screen Transitions
- **Fade**: Simple opacity transition
- **Wipe**: CSS clip-path animating from left to right
- **Pixelate dissolve**: Scale down + pixelate filter, then scale up new content
- **Iris**: Circular clip-path expanding from center

### Text Reveal
Character-by-character typewriter using JS `setInterval` with a cursor element that blinks independently.

## Audio Cues (Optional Enhancement)

### Chiptune SFX
Add 8-bit sound effects to UI interactions for full immersion:

```javascript
// Lightweight approach with Web Audio API
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

### UI Sound Mapping
| Action | Sound | Frequency/Pattern |
|--------|-------|-------------------|
| Menu navigate | Short blip | 440Hz, 50ms, square |
| Confirm/Select | Rising tone | 523-784Hz sweep, 100ms |
| Cancel/Back | Descending tone | 392-262Hz sweep, 100ms |
| Error | Buzz | 150Hz, 200ms, sawtooth |
| Notification | Two-tone | 660-880Hz, 80ms each |

### Libraries
- **Howler.js**: Lightweight audio sprite management
- **Tone.js**: Synthesizer for procedural chiptune
- **jsfxr**: Browser-based SFX generator (retro sound effects)

## Layout Patterns

### Fixed-Ratio Viewport
Maintain classic aspect ratios with letterboxing:
```css
.game-viewport {
  aspect-ratio: 4 / 3;       /* Classic CRT ratio */
  max-width: 960px;
  max-height: 720px;
  margin: 0 auto;
  background: var(--bg-void);
  overflow: hidden;
  image-rendering: pixelated;
}
```

### Tile Grid
Base all spacing on pixel grid multiples:
```css
.tile-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(32px, 1fr));
  gap: 0;  /* Tiles touch -- no gaps in pixel grids */
}
```

### HUD Overlay
Fixed-position status elements overlaying the main content:
```css
.hud { position: fixed; z-index: 100; pointer-events: none; }
.hud-top-left { top: 8px; left: 8px; }      /* HP, level */
.hud-top-right { top: 8px; right: 8px; }     /* Score, time */
.hud-bottom { bottom: 0; left: 0; right: 0; } /* Dialog, menu */
```

### RPG Split Layout
Classic RPG: large viewport on top, dialog/menu panel on bottom:
```css
.rpg-layout {
  display: grid;
  grid-template-rows: 1fr auto;
  height: 100vh;
}
.rpg-viewport { min-height: 60vh; }
.rpg-dialog { max-height: 40vh; padding: 16px; }
```

### Responsive Pixel Scaling
Scale pixel art UIs to larger screens while maintaining crispness:
```css
@media (min-width: 768px) {
  .pixel-scale { transform: scale(2); transform-origin: top left; }
}
@media (min-width: 1200px) {
  .pixel-scale { transform: scale(3); transform-origin: top left; }
}
```

## Frameworks & Tools

### CSS Frameworks
| Framework | Style | URL | Notes |
|-----------|-------|-----|-------|
| NES.css | NES/Famicom | nostalgic-css.github.io/NES.css | Most popular, solid components |
| RPGUI | RPG themed | ronenness.github.io/RPGUI | Game-like UI elements |
| PaperCSS | Hand-drawn | getpapercss.com | Sketch aesthetic (not pixel, but retro) |
| 98.css | Windows 98 | jdan.github.io/98.css | Classic OS nostalgia |
| XP.css | Windows XP | botoxparty.github.io/XP.css | Luna theme recreation |
| 7.css | Windows 7 | khang-nd.github.io/7.css | Aero glass aesthetic |

### Canvas-Based (For Game-Like UIs)
- **PixiJS**: 2D WebGL renderer, excellent for sprite-heavy UIs
- **Phaser**: Full game framework, overkill for UI but powerful
- **Konva**: Canvas library good for drag-and-drop inventory systems

### Custom Approach (Recommended)
For most web UIs, a custom CSS approach using the variables and patterns in this skill produces the best results. Use CSS custom properties for theming, CSS Grid for layout, and CSS animations for effects. No framework dependency, full control, minimal bundle size.

## Integration with Modern Stacks

### HTMX + Retro Templates
Server-rendered HTML with HTMX swaps. Apply retro CSS classes to server templates. SSE for live updates (score tickers, notifications). Ideal stack for the retro aesthetic because it keeps HTML semantic and adds behavior progressively.

### React / Vue / Svelte
Create a retro component library wrapping the component templates from `references/component-templates.md`. Use CSS Modules or styled-components for scoped retro styles. Maintain the CSS custom properties at the root for theming.

### Tailwind CSS
Extend Tailwind config with pixel utilities:
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

- **Font sizing**: Use `rem` for text, not `px`. The pixel sizes in this skill are guides -- implement as rem equivalents that respect user preferences
- **Motion**: Wrap all animations in `@media (prefers-reduced-motion: no-preference)`. Provide a static fallback for scanlines, flicker, and noise effects
- **Contrast**: Neon on dark already achieves WCAG AAA in most cases. Verify with contrast checkers. `#ff00ff` on `#0a0a0a` = 6.2:1 (AA pass). `#00ffff` on `#0a0a0a` = 16.3:1 (AAA pass)
- **Focus indicators**: Use glowing pixel outlines instead of default browser outlines:
  ```css
  :focus-visible {
    outline: 2px solid var(--neon-secondary);
    outline-offset: 2px;
    box-shadow: 0 0 8px var(--neon-secondary);
  }
  ```
- **Semantic HTML**: Under every pixel-art veneer, use proper `<nav>`, `<main>`, `<button>`, `<dialog>`, `<table>` elements. Screen readers see semantics, sighted users see pixels
- **Keyboard navigation**: All interactive components must be keyboard-accessible. Menu cursor follows arrow key input. Tab order is logical

## Performance

- **Pixel fonts**: Subset to needed characters, serve as woff2. Press Start 2P full set is only ~8KB woff2
- **CSS over JS**: All scanline, glow, and noise effects are pure CSS. No JS paint loops
- **`will-change`**: Use sparingly and only on actively animating elements. Remove after animation completes
- **Lazy decorative assets**: Sprite sheets, background tiles, and noise textures are decorative -- lazy load them
- **Scanline/noise weight**: Opacity-based overlays on `::after` pseudo-elements have minimal paint cost. Avoid filters like `backdrop-filter` which trigger expensive compositing
- **Animation budget**: Keep CSS animations under 16ms frame budget. `steps()` animations are inherently lightweight since they skip interpolation
