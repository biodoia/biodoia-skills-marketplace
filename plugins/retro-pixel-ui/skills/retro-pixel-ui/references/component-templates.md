# Component Templates

Complete, copy-paste HTML + CSS component templates for retro pixel art UIs. Every component uses the cyberpunk neon palette and is ready to drop into any project.

All components assume the root CSS custom properties from the main skill are loaded.

---

## RPG Dialog Box (with Typewriter JS)

Full dialog box with speaker name, typewriter text reveal, character portrait area, and blinking continue indicator.

```html
<div class="rpg-dialog" id="dialog-box">
  <span class="rpg-dialog__speaker">NPC_UNIT_77</span>
  <div class="rpg-dialog__portrait">
    <div class="rpg-dialog__portrait-frame"></div>
  </div>
  <div class="rpg-dialog__body">
    <span class="rpg-dialog__text" id="dialog-text"></span>
    <span class="rpg-dialog__cursor"></span>
  </div>
  <span class="rpg-dialog__continue" id="dialog-continue">&#9660;</span>
</div>
```

```css
.rpg-dialog {
  position: relative;
  background: rgba(10, 10, 10, 0.95);
  padding: 20px 24px 20px 100px;
  margin: 16px;
  font-family: 'VT323', monospace;
  font-size: 20px;
  color: var(--text-primary);
  line-height: 1.5;
  max-width: 700px;
  min-height: 100px;
  border: 3px solid var(--neon-secondary);
  box-shadow:
    inset 0 0 0 3px var(--bg-void),
    inset 0 0 0 5px var(--neon-primary),
    0 0 20px rgba(0, 255, 255, 0.15),
    0 0 40px rgba(255, 0, 255, 0.08);
}

.rpg-dialog__speaker {
  position: absolute;
  top: -14px;
  left: 20px;
  background: var(--bg-void);
  padding: 2px 14px;
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  color: var(--neon-primary);
  border: 2px solid var(--neon-primary);
  text-transform: uppercase;
  letter-spacing: 2px;
  text-shadow: 0 0 8px var(--neon-primary);
}

.rpg-dialog__portrait {
  position: absolute;
  left: 16px;
  top: 16px;
  width: 64px;
  height: 64px;
}

.rpg-dialog__portrait-frame {
  width: 64px;
  height: 64px;
  background: var(--bg-surface);
  border: 2px solid var(--neon-secondary);
  image-rendering: pixelated;
  /* Replace with: background-image: url('portrait.png'); background-size: cover; */
}

.rpg-dialog__body {
  min-height: 3em;
}

.rpg-dialog__text {
  /* Text appears here character by character */
}

.rpg-dialog__cursor {
  display: inline-block;
  width: 10px;
  height: 18px;
  background: var(--neon-secondary);
  vertical-align: text-bottom;
  animation: cursor-blink 0.6s steps(2) infinite;
}

@keyframes cursor-blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

.rpg-dialog__continue {
  position: absolute;
  bottom: 10px;
  right: 14px;
  font-size: 10px;
  color: var(--neon-secondary);
  opacity: 0;
  animation: bounce-arrow 0.7s steps(2) infinite;
}

.rpg-dialog__continue.visible {
  opacity: 1;
}

@keyframes bounce-arrow {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(4px); }
}
```

```javascript
// Typewriter engine
class TypewriterDialog {
  constructor(textEl, cursorEl, continueEl, speed = 35) {
    this.textEl = document.getElementById(textEl);
    this.cursorEl = cursorEl;
    this.continueEl = document.getElementById(continueEl);
    this.speed = speed;
    this.queue = [];
    this.typing = false;
  }

  say(text) {
    return new Promise((resolve) => {
      this.queue.push({ text, resolve });
      if (!this.typing) this._processQueue();
    });
  }

  async _processQueue() {
    while (this.queue.length > 0) {
      const { text, resolve } = this.queue.shift();
      this.typing = true;
      this.textEl.textContent = '';
      this.continueEl.classList.remove('visible');

      for (let i = 0; i < text.length; i++) {
        this.textEl.textContent += text[i];
        await this._wait(this.speed);
      }

      this.continueEl.classList.add('visible');
      await this._waitForClick();
      resolve();
    }
    this.typing = false;
  }

  _wait(ms) {
    return new Promise(r => setTimeout(r, ms));
  }

  _waitForClick() {
    return new Promise((resolve) => {
      const handler = () => {
        document.removeEventListener('click', handler);
        document.removeEventListener('keydown', handler);
        resolve();
      };
      document.addEventListener('click', handler);
      document.addEventListener('keydown', handler);
    });
  }
}

// Usage:
// const dialog = new TypewriterDialog('dialog-text', null, 'dialog-continue', 30);
// await dialog.say("Welcome, traveler. The neon wastes await...");
// await dialog.say("Choose your path wisely. There is no save point here.");
```

---

## Retro Menu (with Arrow Cursor)

Vertical selection menu with pixel arrow cursor and keyboard navigation.

```html
<nav class="retro-menu" role="menu" id="main-menu">
  <div class="retro-menu__title">MAIN MENU</div>
  <ul class="retro-menu__list">
    <li class="retro-menu__item active" role="menuitem" tabindex="0">New Game</li>
    <li class="retro-menu__item" role="menuitem" tabindex="-1">Continue</li>
    <li class="retro-menu__item" role="menuitem" tabindex="-1">Options</li>
    <li class="retro-menu__item" role="menuitem" tabindex="-1">Achievements</li>
    <li class="retro-menu__item retro-menu__item--disabled" role="menuitem" tabindex="-1" aria-disabled="true">Online Mode</li>
    <li class="retro-menu__item" role="menuitem" tabindex="-1">Quit</li>
  </ul>
</nav>
```

```css
.retro-menu {
  background: var(--bg-panel);
  border: 3px solid var(--neon-secondary);
  padding: 24px 32px;
  min-width: 280px;
  box-shadow:
    inset 0 0 0 2px var(--bg-void),
    inset 0 0 0 4px var(--neon-primary),
    0 0 30px rgba(0, 255, 255, 0.1);
}

.retro-menu__title {
  font-family: 'Press Start 2P', monospace;
  font-size: 14px;
  color: var(--neon-primary);
  text-align: center;
  margin-bottom: 24px;
  text-shadow: 0 0 10px var(--neon-primary);
  letter-spacing: 4px;
}

.retro-menu__list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.retro-menu__item {
  font-family: 'Press Start 2P', monospace;
  font-size: 11px;
  color: var(--text-primary);
  padding: 10px 12px 10px 32px;
  cursor: pointer;
  position: relative;
  transition: none;
  letter-spacing: 1px;
}

.retro-menu__item::before {
  content: '';
  position: absolute;
  left: 8px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0;
}

.retro-menu__item.active {
  color: var(--neon-secondary);
  background: rgba(0, 255, 255, 0.05);
}

.retro-menu__item.active::before {
  content: '\25B8';
  opacity: 1;
  color: var(--neon-secondary);
  text-shadow: 0 0 6px var(--neon-secondary);
  animation: cursor-flicker 1s steps(2) infinite;
}

@keyframes cursor-flicker {
  0%, 80%, 100% { opacity: 1; }
  40% { opacity: 0.6; }
}

.retro-menu__item:hover:not(.retro-menu__item--disabled) {
  color: var(--neon-secondary);
  background: rgba(0, 255, 255, 0.05);
}

.retro-menu__item--disabled {
  color: #444;
  cursor: not-allowed;
}

.retro-menu__item:focus-visible {
  outline: 1px solid var(--neon-secondary);
  outline-offset: 2px;
}
```

```javascript
// Keyboard navigation for retro menu
class RetroMenu {
  constructor(menuId) {
    this.menu = document.getElementById(menuId);
    this.items = [...this.menu.querySelectorAll('.retro-menu__item:not(.retro-menu__item--disabled)')];
    this.currentIndex = 0;
    this._activate(0);
    this.menu.addEventListener('keydown', (e) => this._onKey(e));
    this.items.forEach((item, i) => {
      item.addEventListener('click', () => this._select(i));
      item.addEventListener('mouseenter', () => this._activate(i));
    });
  }

  _onKey(e) {
    switch (e.key) {
      case 'ArrowUp':
      case 'w':
        e.preventDefault();
        this._activate((this.currentIndex - 1 + this.items.length) % this.items.length);
        break;
      case 'ArrowDown':
      case 's':
        e.preventDefault();
        this._activate((this.currentIndex + 1) % this.items.length);
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        this._select(this.currentIndex);
        break;
    }
  }

  _activate(index) {
    this.items.forEach(item => item.classList.remove('active'));
    this.items[index].classList.add('active');
    this.items[index].focus();
    this.currentIndex = index;
  }

  _select(index) {
    this._activate(index);
    const event = new CustomEvent('menu-select', {
      detail: { index, text: this.items[index].textContent }
    });
    this.menu.dispatchEvent(event);
  }
}

// Usage:
// const menu = new RetroMenu('main-menu');
// document.getElementById('main-menu').addEventListener('menu-select', (e) => {
//   console.log('Selected:', e.detail.text);
// });
```

---

## Pixel Button Set (Primary, Secondary, Danger, Disabled)

```html
<div class="pixel-btn-group">
  <button class="pixel-btn pixel-btn--primary">CONFIRM</button>
  <button class="pixel-btn pixel-btn--secondary">OPTIONS</button>
  <button class="pixel-btn pixel-btn--danger">DELETE</button>
  <button class="pixel-btn pixel-btn--ghost">CANCEL</button>
  <button class="pixel-btn pixel-btn--primary" disabled>LOCKED</button>
</div>
```

```css
.pixel-btn-group {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.pixel-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  color: var(--text-primary);
  background: var(--bg-panel);
  border: none;
  padding: 12px 24px;
  cursor: pointer;
  position: relative;
  text-transform: uppercase;
  letter-spacing: 2px;
  -webkit-font-smoothing: none;
  transition: none;
}

/* Primary -- magenta neon */
.pixel-btn--primary {
  color: var(--neon-primary);
  box-shadow:
    0 6px 0 0 #1a001a,
    0 6px 0 2px var(--neon-primary),
    inset 0 0 0 2px var(--neon-primary);
}

.pixel-btn--primary:hover {
  background: rgba(255, 0, 255, 0.1);
  box-shadow:
    0 6px 0 0 #1a001a,
    0 6px 0 2px var(--neon-primary),
    inset 0 0 0 2px var(--neon-primary),
    0 0 20px rgba(255, 0, 255, 0.3);
}

.pixel-btn--primary:active {
  transform: translateY(6px);
  box-shadow:
    0 0 0 0 #1a001a,
    0 0 0 2px var(--neon-primary),
    inset 0 0 0 2px var(--neon-primary);
}

/* Secondary -- cyan neon */
.pixel-btn--secondary {
  color: var(--neon-secondary);
  box-shadow:
    0 6px 0 0 #001a1a,
    0 6px 0 2px var(--neon-secondary),
    inset 0 0 0 2px var(--neon-secondary);
}

.pixel-btn--secondary:hover {
  background: rgba(0, 255, 255, 0.1);
  box-shadow:
    0 6px 0 0 #001a1a,
    0 6px 0 2px var(--neon-secondary),
    inset 0 0 0 2px var(--neon-secondary),
    0 0 20px rgba(0, 255, 255, 0.3);
}

.pixel-btn--secondary:active {
  transform: translateY(6px);
  box-shadow:
    0 0 0 0 #001a1a,
    0 0 0 2px var(--neon-secondary),
    inset 0 0 0 2px var(--neon-secondary);
}

/* Danger -- red neon */
.pixel-btn--danger {
  color: #ff0040;
  box-shadow:
    0 6px 0 0 #1a0008,
    0 6px 0 2px #ff0040,
    inset 0 0 0 2px #ff0040;
}

.pixel-btn--danger:hover {
  background: rgba(255, 0, 64, 0.1);
  box-shadow:
    0 6px 0 0 #1a0008,
    0 6px 0 2px #ff0040,
    inset 0 0 0 2px #ff0040,
    0 0 20px rgba(255, 0, 64, 0.3);
}

.pixel-btn--danger:active {
  transform: translateY(6px);
  box-shadow:
    0 0 0 0 #1a0008,
    0 0 0 2px #ff0040,
    inset 0 0 0 2px #ff0040;
}

/* Ghost -- outline only */
.pixel-btn--ghost {
  color: var(--text-secondary);
  background: transparent;
  box-shadow:
    0 4px 0 0 #111,
    inset 0 0 0 1px var(--text-secondary);
}

.pixel-btn--ghost:hover {
  color: var(--text-primary);
  box-shadow:
    0 4px 0 0 #111,
    inset 0 0 0 1px var(--text-primary);
}

.pixel-btn--ghost:active {
  transform: translateY(4px);
  box-shadow:
    0 0 0 0 #111,
    inset 0 0 0 1px var(--text-primary);
}

/* Disabled -- all variants */
.pixel-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  box-shadow:
    0 4px 0 0 #111,
    inset 0 0 0 1px #333;
  color: #555;
  background: var(--bg-void);
}

.pixel-btn:disabled:hover {
  background: var(--bg-void);
  box-shadow:
    0 4px 0 0 #111,
    inset 0 0 0 1px #333;
}

.pixel-btn:disabled:active {
  transform: none;
}

.pixel-btn:focus-visible {
  outline: 2px solid var(--neon-accent);
  outline-offset: 4px;
}
```

---

## Progress / HP Bar

```html
<div class="pixel-bar-group">
  <div class="pixel-bar-row">
    <span class="pixel-bar-label">HP</span>
    <div class="pixel-bar">
      <div class="pixel-bar__fill pixel-bar__fill--hp" style="width: 75%"></div>
      <span class="pixel-bar__value">186 / 248</span>
    </div>
  </div>
  <div class="pixel-bar-row">
    <span class="pixel-bar-label pixel-bar-label--mp">MP</span>
    <div class="pixel-bar">
      <div class="pixel-bar__fill pixel-bar__fill--mp" style="width: 45%"></div>
      <span class="pixel-bar__value">52 / 115</span>
    </div>
  </div>
  <div class="pixel-bar-row">
    <span class="pixel-bar-label pixel-bar-label--xp">XP</span>
    <div class="pixel-bar pixel-bar--xp">
      <div class="pixel-bar__fill pixel-bar__fill--xp" style="width: 62%"></div>
      <span class="pixel-bar__value">3,100 / 5,000</span>
    </div>
  </div>
</div>
```

```css
.pixel-bar-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  background: var(--bg-panel);
  border: 2px solid var(--neon-secondary);
  max-width: 320px;
}

.pixel-bar-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pixel-bar-label {
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  color: var(--neon-accent);
  width: 24px;
  text-align: right;
  text-shadow: 0 0 4px var(--neon-accent);
}

.pixel-bar-label--mp { color: #0088ff; text-shadow: 0 0 4px #0088ff; }
.pixel-bar-label--xp { color: var(--neon-primary); text-shadow: 0 0 4px var(--neon-primary); }

.pixel-bar {
  flex: 1;
  height: 16px;
  background: #111;
  position: relative;
  border: 2px solid #444;
}

.pixel-bar__fill {
  height: 100%;
  position: relative;
  transition: width 0.4s steps(20);
}

.pixel-bar__fill--hp {
  background: linear-gradient(180deg, #39ff14 0%, #22cc00 40%, #198a00 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.pixel-bar__fill--mp {
  background: linear-gradient(180deg, #00aaff 0%, #0066cc 40%, #003388 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.pixel-bar__fill--xp {
  background: linear-gradient(180deg, #ff44ff 0%, #cc00cc 40%, #880088 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

/* Segmented overlay */
.pixel-bar::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    90deg,
    transparent,
    transparent 7px,
    rgba(0, 0, 0, 0.4) 7px,
    rgba(0, 0, 0, 0.4) 8px
  );
  pointer-events: none;
}

.pixel-bar__value {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Silkscreen', 'Press Start 2P', monospace;
  font-size: 7px;
  color: #fff;
  text-shadow: 1px 1px 0 #000, -1px -1px 0 #000;
  z-index: 1;
  letter-spacing: 1px;
}

/* Low HP warning -- add via JS when HP < 25% */
.pixel-bar__fill--hp.critical {
  background: linear-gradient(180deg, #ff4444 0%, #cc0000 40%, #880000 100%);
  animation: hp-flash 0.5s steps(2) infinite;
}

@keyframes hp-flash {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}
```

---

## Inventory Grid

```html
<div class="inventory-grid" role="grid" aria-label="Inventory">
  <div class="inventory-grid__title">INVENTORY</div>
  <div class="inventory-grid__slots">
    <div class="inventory-slot inventory-slot--filled" role="gridcell" tabindex="0" data-item="Neon Blade" data-qty="1">
      <span class="inventory-slot__icon">&#9876;</span>
      <span class="inventory-slot__qty">1</span>
    </div>
    <div class="inventory-slot inventory-slot--filled" role="gridcell" tabindex="0" data-item="Cyber Potion" data-qty="5">
      <span class="inventory-slot__icon">&#9832;</span>
      <span class="inventory-slot__qty">5</span>
    </div>
    <div class="inventory-slot inventory-slot--filled inventory-slot--rare" role="gridcell" tabindex="0" data-item="Quantum Key" data-qty="1">
      <span class="inventory-slot__icon">&#9883;</span>
      <span class="inventory-slot__qty">1</span>
    </div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
    <div class="inventory-slot" role="gridcell" tabindex="-1"></div>
  </div>
  <div class="inventory-tooltip" id="inv-tooltip" hidden>
    <span class="inventory-tooltip__name"></span>
    <span class="inventory-tooltip__desc"></span>
  </div>
</div>
```

```css
.inventory-grid {
  background: var(--bg-panel);
  border: 3px solid var(--neon-secondary);
  padding: 16px;
  display: inline-block;
  box-shadow:
    inset 0 0 0 2px var(--bg-void),
    inset 0 0 0 4px var(--neon-primary);
}

.inventory-grid__title {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  color: var(--neon-secondary);
  text-align: center;
  margin-bottom: 12px;
  letter-spacing: 3px;
  text-shadow: 0 0 8px var(--neon-secondary);
}

.inventory-grid__slots {
  display: grid;
  grid-template-columns: repeat(4, 48px);
  gap: 4px;
}

.inventory-slot {
  width: 48px;
  height: 48px;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid #333;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: default;
  /* Dithering pattern for empty slots */
  background-image:
    linear-gradient(45deg, #111 25%, transparent 25%),
    linear-gradient(-45deg, #111 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, #111 75%),
    linear-gradient(-45deg, transparent 75%, #111 75%);
  background-size: 4px 4px;
  background-position: 0 0, 0 2px, 2px -2px, -2px 0;
}

.inventory-slot--filled {
  background: rgba(26, 26, 46, 0.8);
  background-image: none;
  border-color: var(--neon-secondary);
  cursor: pointer;
}

.inventory-slot--filled:hover {
  border-color: var(--neon-primary);
  box-shadow: 0 0 10px rgba(255, 0, 255, 0.4);
}

.inventory-slot--rare {
  border-color: var(--neon-primary);
  box-shadow: 0 0 6px rgba(255, 0, 255, 0.3);
  animation: rare-shimmer 2s ease-in-out infinite alternate;
}

@keyframes rare-shimmer {
  from { box-shadow: 0 0 6px rgba(255, 0, 255, 0.3); }
  to { box-shadow: 0 0 14px rgba(255, 0, 255, 0.6); }
}

.inventory-slot__icon {
  font-size: 20px;
  color: var(--text-primary);
  image-rendering: pixelated;
}

.inventory-slot__qty {
  position: absolute;
  bottom: 2px;
  right: 4px;
  font-family: 'Silkscreen', monospace;
  font-size: 8px;
  color: var(--neon-accent);
  text-shadow: 1px 1px 0 #000;
}

.inventory-slot:focus-visible {
  outline: 2px solid var(--neon-accent);
  outline-offset: -2px;
}

/* Tooltip */
.inventory-tooltip {
  position: absolute;
  background: var(--bg-void);
  border: 2px solid var(--neon-primary);
  padding: 8px 12px;
  font-family: 'VT323', monospace;
  z-index: 100;
  pointer-events: none;
  box-shadow: 0 0 12px rgba(255, 0, 255, 0.3);
}

.inventory-tooltip__name {
  display: block;
  font-size: 14px;
  color: var(--neon-primary);
  margin-bottom: 4px;
}

.inventory-tooltip__desc {
  display: block;
  font-size: 12px;
  color: var(--text-secondary);
}
```

---

## Retro Card / Panel

```html
<div class="retro-card">
  <div class="retro-card__titlebar">
    <span class="retro-card__title">SYSTEM STATUS</span>
    <div class="retro-card__controls">
      <button class="retro-card__btn" aria-label="Minimize">_</button>
      <button class="retro-card__btn retro-card__btn--close" aria-label="Close">X</button>
    </div>
  </div>
  <div class="retro-card__body">
    <p>All subsystems operational. Neon core running at 98.7% efficiency.</p>
    <p>Next scheduled maintenance: <span class="retro-card__highlight">CYCLE 2847</span></p>
  </div>
</div>
```

```css
.retro-card {
  background: var(--bg-panel);
  border: 2px solid var(--neon-secondary);
  max-width: 400px;
  box-shadow:
    4px 4px 0 0 rgba(0, 255, 255, 0.1),
    0 0 20px rgba(0, 255, 255, 0.05);
}

.retro-card__titlebar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 10px;
  background: linear-gradient(90deg, var(--neon-primary), var(--neon-secondary));
  border-bottom: 2px solid var(--neon-secondary);
}

.retro-card__title {
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  color: var(--bg-void);
  letter-spacing: 2px;
  text-transform: uppercase;
}

.retro-card__controls {
  display: flex;
  gap: 4px;
}

.retro-card__btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  width: 18px;
  height: 18px;
  background: var(--bg-void);
  color: var(--text-primary);
  border: 1px solid var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.retro-card__btn:hover {
  background: var(--bg-surface);
  border-color: var(--neon-secondary);
}

.retro-card__btn--close:hover {
  background: #ff0040;
  border-color: #ff0040;
  color: #fff;
}

.retro-card__body {
  padding: 16px;
  font-family: 'VT323', monospace;
  font-size: 16px;
  color: var(--text-primary);
  line-height: 1.5;
}

.retro-card__highlight {
  color: var(--neon-accent);
  text-shadow: 0 0 4px var(--neon-accent);
}
```

---

## Notification Toast (Pixel Art)

```html
<div class="pixel-toast pixel-toast--success" role="alert">
  <span class="pixel-toast__icon">&#9733;</span>
  <div class="pixel-toast__content">
    <span class="pixel-toast__title">ACHIEVEMENT UNLOCKED</span>
    <span class="pixel-toast__message">First Blood -- Defeated your first enemy</span>
  </div>
  <button class="pixel-toast__close" aria-label="Dismiss">&times;</button>
  <div class="pixel-toast__timer"></div>
</div>

<div class="pixel-toast pixel-toast--error" role="alert">
  <span class="pixel-toast__icon">&#9888;</span>
  <div class="pixel-toast__content">
    <span class="pixel-toast__title">SYSTEM ERROR</span>
    <span class="pixel-toast__message">Connection to server lost. Retrying...</span>
  </div>
  <button class="pixel-toast__close" aria-label="Dismiss">&times;</button>
  <div class="pixel-toast__timer"></div>
</div>

<div class="pixel-toast pixel-toast--info" role="status">
  <span class="pixel-toast__icon">&#9432;</span>
  <div class="pixel-toast__content">
    <span class="pixel-toast__title">NEW QUEST</span>
    <span class="pixel-toast__message">Explore the abandoned data center</span>
  </div>
  <button class="pixel-toast__close" aria-label="Dismiss">&times;</button>
  <div class="pixel-toast__timer"></div>
</div>
```

```css
.pixel-toast {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  background: var(--bg-panel);
  border: 2px solid var(--neon-secondary);
  padding: 12px 16px;
  min-width: 300px;
  max-width: 420px;
  position: relative;
  overflow: hidden;
  animation: toast-slide-in 0.3s steps(6) forwards;
}

@keyframes toast-slide-in {
  from { transform: translateX(120%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

.pixel-toast__icon {
  font-size: 20px;
  line-height: 1;
  flex-shrink: 0;
}

.pixel-toast--success { border-color: var(--neon-accent); }
.pixel-toast--success .pixel-toast__icon { color: var(--neon-accent); text-shadow: 0 0 6px var(--neon-accent); }
.pixel-toast--success .pixel-toast__title { color: var(--neon-accent); }

.pixel-toast--error { border-color: #ff0040; }
.pixel-toast--error .pixel-toast__icon { color: #ff0040; text-shadow: 0 0 6px #ff0040; }
.pixel-toast--error .pixel-toast__title { color: #ff0040; }

.pixel-toast--info { border-color: var(--neon-secondary); }
.pixel-toast--info .pixel-toast__icon { color: var(--neon-secondary); text-shadow: 0 0 6px var(--neon-secondary); }
.pixel-toast--info .pixel-toast__title { color: var(--neon-secondary); }

.pixel-toast__content {
  flex: 1;
}

.pixel-toast__title {
  display: block;
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  letter-spacing: 2px;
  margin-bottom: 6px;
}

.pixel-toast__message {
  display: block;
  font-family: 'VT323', monospace;
  font-size: 15px;
  color: var(--text-primary);
  line-height: 1.3;
}

.pixel-toast__close {
  background: none;
  border: none;
  color: var(--text-secondary);
  font-size: 18px;
  cursor: pointer;
  padding: 0 4px;
  font-family: 'Press Start 2P', monospace;
  line-height: 1;
}

.pixel-toast__close:hover { color: #ff0040; }

/* Auto-dismiss timer bar */
.pixel-toast__timer {
  position: absolute;
  bottom: 0;
  left: 0;
  height: 3px;
  background: var(--neon-secondary);
  animation: toast-timer 4s linear forwards;
}

.pixel-toast--success .pixel-toast__timer { background: var(--neon-accent); }
.pixel-toast--error .pixel-toast__timer { background: #ff0040; }

@keyframes toast-timer {
  from { width: 100%; }
  to { width: 0%; }
}
```

---

## Retro Form (Input, Select, Checkbox, Radio)

```html
<form class="retro-form">
  <div class="retro-form__group">
    <label class="retro-form__label" for="username">CALLSIGN</label>
    <input class="retro-form__input" type="text" id="username" placeholder="Enter callsign..." autocomplete="off">
  </div>
  <div class="retro-form__group">
    <label class="retro-form__label" for="password">ACCESS CODE</label>
    <input class="retro-form__input" type="password" id="password" placeholder="***********">
  </div>
  <div class="retro-form__group">
    <label class="retro-form__label" for="class-select">CLASS</label>
    <select class="retro-form__select" id="class-select">
      <option value="">-- SELECT --</option>
      <option value="hacker">Hacker</option>
      <option value="runner">Runner</option>
      <option value="fixer">Fixer</option>
      <option value="techie">Techie</option>
    </select>
  </div>
  <div class="retro-form__group">
    <label class="retro-form__checkbox">
      <input type="checkbox" checked>
      <span class="retro-form__checkbox-mark"></span>
      <span class="retro-form__checkbox-label">Enable neon overlay</span>
    </label>
    <label class="retro-form__checkbox">
      <input type="checkbox">
      <span class="retro-form__checkbox-mark"></span>
      <span class="retro-form__checkbox-label">Scanline effects</span>
    </label>
  </div>
  <div class="retro-form__group">
    <span class="retro-form__label">DIFFICULTY</span>
    <div class="retro-form__radios">
      <label class="retro-form__radio">
        <input type="radio" name="difficulty" value="easy">
        <span class="retro-form__radio-mark"></span>
        <span class="retro-form__radio-label">EASY</span>
      </label>
      <label class="retro-form__radio">
        <input type="radio" name="difficulty" value="normal" checked>
        <span class="retro-form__radio-mark"></span>
        <span class="retro-form__radio-label">NORMAL</span>
      </label>
      <label class="retro-form__radio">
        <input type="radio" name="difficulty" value="hard">
        <span class="retro-form__radio-mark"></span>
        <span class="retro-form__radio-label">INSANE</span>
      </label>
    </div>
  </div>
  <div class="retro-form__actions">
    <button type="submit" class="pixel-btn pixel-btn--primary">JACK IN</button>
    <button type="reset" class="pixel-btn pixel-btn--ghost">RESET</button>
  </div>
</form>
```

```css
.retro-form {
  background: var(--bg-panel);
  border: 3px solid var(--neon-secondary);
  padding: 24px;
  max-width: 400px;
  box-shadow:
    inset 0 0 0 2px var(--bg-void),
    inset 0 0 0 4px var(--neon-primary),
    0 0 30px rgba(0, 255, 255, 0.08);
}

.retro-form__group {
  margin-bottom: 20px;
}

.retro-form__label {
  display: block;
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  color: var(--neon-secondary);
  letter-spacing: 2px;
  margin-bottom: 8px;
  text-shadow: 0 0 4px var(--neon-secondary);
}

.retro-form__input {
  width: 100%;
  padding: 10px 14px;
  font-family: 'VT323', monospace;
  font-size: 18px;
  color: var(--neon-accent);
  background: var(--bg-void);
  border: 2px solid #444;
  outline: none;
  caret-color: var(--neon-accent);
  box-sizing: border-box;
}

.retro-form__input::placeholder {
  color: #444;
}

.retro-form__input:focus {
  border-color: var(--neon-secondary);
  box-shadow: 0 0 10px rgba(0, 255, 255, 0.2);
}

.retro-form__input:invalid {
  border-color: #ff0040;
}

.retro-form__select {
  width: 100%;
  padding: 10px 14px;
  font-family: 'VT323', monospace;
  font-size: 18px;
  color: var(--neon-accent);
  background: var(--bg-void);
  border: 2px solid #444;
  outline: none;
  appearance: none;
  cursor: pointer;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath d='M2 4l4 4 4-4' fill='none' stroke='%2300ffff' stroke-width='2'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
}

.retro-form__select:focus {
  border-color: var(--neon-secondary);
  box-shadow: 0 0 10px rgba(0, 255, 255, 0.2);
}

/* Custom checkbox */
.retro-form__checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  margin-bottom: 8px;
}

.retro-form__checkbox input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.retro-form__checkbox-mark {
  width: 16px;
  height: 16px;
  background: var(--bg-void);
  border: 2px solid #444;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.retro-form__checkbox input:checked + .retro-form__checkbox-mark {
  border-color: var(--neon-accent);
  background: var(--bg-void);
}

.retro-form__checkbox input:checked + .retro-form__checkbox-mark::after {
  content: '\2715';
  color: var(--neon-accent);
  font-size: 10px;
  text-shadow: 0 0 4px var(--neon-accent);
}

.retro-form__checkbox input:focus-visible + .retro-form__checkbox-mark {
  outline: 2px solid var(--neon-secondary);
  outline-offset: 2px;
}

.retro-form__checkbox-label {
  font-family: 'VT323', monospace;
  font-size: 16px;
  color: var(--text-primary);
}

/* Custom radio */
.retro-form__radios {
  display: flex;
  gap: 20px;
}

.retro-form__radio {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.retro-form__radio input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.retro-form__radio-mark {
  width: 14px;
  height: 14px;
  background: var(--bg-void);
  border: 2px solid #444;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.retro-form__radio input:checked + .retro-form__radio-mark {
  border-color: var(--neon-primary);
}

.retro-form__radio input:checked + .retro-form__radio-mark::after {
  content: '';
  width: 6px;
  height: 6px;
  background: var(--neon-primary);
  box-shadow: 0 0 4px var(--neon-primary);
}

.retro-form__radio input:focus-visible + .retro-form__radio-mark {
  outline: 2px solid var(--neon-secondary);
  outline-offset: 2px;
}

.retro-form__radio-label {
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  color: var(--text-primary);
  letter-spacing: 1px;
}

.retro-form__actions {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}
```

---

## Pixel Loading Spinner

```html
<div class="pixel-loader">
  <div class="pixel-loader__spinner">
    <div class="pixel-loader__block"></div>
    <div class="pixel-loader__block"></div>
    <div class="pixel-loader__block"></div>
    <div class="pixel-loader__block"></div>
  </div>
  <div class="pixel-loader__text">NOW LOADING<span class="pixel-loader__dots"></span></div>
  <div class="pixel-loader__bar">
    <div class="pixel-loader__bar-fill"></div>
  </div>
</div>
```

```css
.pixel-loader {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 32px;
}

.pixel-loader__spinner {
  width: 32px;
  height: 32px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4px;
}

.pixel-loader__block {
  width: 12px;
  height: 12px;
  background: var(--neon-secondary);
  animation: pixel-spin 1.2s steps(1) infinite;
}

.pixel-loader__block:nth-child(1) { animation-delay: 0s; }
.pixel-loader__block:nth-child(2) { animation-delay: 0.3s; }
.pixel-loader__block:nth-child(3) { animation-delay: 0.9s; }
.pixel-loader__block:nth-child(4) { animation-delay: 0.6s; }

@keyframes pixel-spin {
  0%, 100% { background: var(--neon-secondary); box-shadow: 0 0 6px var(--neon-secondary); }
  50% { background: var(--bg-panel); box-shadow: none; }
}

.pixel-loader__text {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  color: var(--text-primary);
  letter-spacing: 3px;
}

.pixel-loader__dots::after {
  content: '';
  animation: loading-dots 1.5s steps(4) infinite;
}

@keyframes loading-dots {
  0%  { content: ''; }
  25% { content: '.'; }
  50% { content: '..'; }
  75% { content: '...'; }
}

.pixel-loader__bar {
  width: 200px;
  height: 12px;
  background: #111;
  border: 2px solid #444;
  position: relative;
}

.pixel-loader__bar-fill {
  height: 100%;
  background: var(--neon-primary);
  animation: loader-fill 3s steps(20) infinite;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

@keyframes loader-fill {
  from { width: 0%; }
  to { width: 100%; }
}

/* Segmented overlay */
.pixel-loader__bar::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    90deg,
    transparent,
    transparent 8px,
    rgba(0, 0, 0, 0.4) 8px,
    rgba(0, 0, 0, 0.4) 10px
  );
  pointer-events: none;
}
```

---

## Retro Table

```html
<div class="retro-table-container">
  <table class="retro-table">
    <thead>
      <tr>
        <th>RANK</th>
        <th>CALLSIGN</th>
        <th>SCORE</th>
        <th>LEVEL</th>
        <th>STATUS</th>
      </tr>
    </thead>
    <tbody>
      <tr class="retro-table__row--highlight">
        <td>01</td>
        <td>NEON_VIPER</td>
        <td>98,750</td>
        <td>42</td>
        <td><span class="retro-table__status retro-table__status--online">ONLINE</span></td>
      </tr>
      <tr>
        <td>02</td>
        <td>CYBER_WOLF</td>
        <td>87,200</td>
        <td>39</td>
        <td><span class="retro-table__status retro-table__status--offline">OFFLINE</span></td>
      </tr>
      <tr>
        <td>03</td>
        <td>PIXEL_GHOST</td>
        <td>76,450</td>
        <td>35</td>
        <td><span class="retro-table__status retro-table__status--online">ONLINE</span></td>
      </tr>
      <tr>
        <td>04</td>
        <td>VOID_RUNNER</td>
        <td>64,100</td>
        <td>31</td>
        <td><span class="retro-table__status retro-table__status--away">AWAY</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

```css
.retro-table-container {
  overflow-x: auto;
  border: 2px solid var(--neon-secondary);
  box-shadow: 0 0 15px rgba(0, 255, 255, 0.1);
}

.retro-table {
  width: 100%;
  border-collapse: collapse;
  font-family: 'VT323', monospace;
  font-size: 16px;
  color: var(--text-primary);
}

.retro-table thead {
  background: linear-gradient(90deg, rgba(255, 0, 255, 0.15), rgba(0, 255, 255, 0.15));
  border-bottom: 2px solid var(--neon-primary);
}

.retro-table th {
  font-family: 'Press Start 2P', monospace;
  font-size: 8px;
  color: var(--neon-secondary);
  text-align: left;
  padding: 12px 16px;
  letter-spacing: 2px;
  text-shadow: 0 0 4px var(--neon-secondary);
  white-space: nowrap;
}

.retro-table td {
  padding: 10px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.retro-table tbody tr:nth-child(even) {
  background: rgba(255, 255, 255, 0.02);
}

.retro-table tbody tr:hover {
  background: rgba(0, 255, 255, 0.05);
}

.retro-table__row--highlight {
  background: rgba(255, 0, 255, 0.08) !important;
  border-left: 3px solid var(--neon-primary);
}

.retro-table__row--highlight td:first-child {
  color: var(--neon-primary);
  text-shadow: 0 0 6px var(--neon-primary);
}

.retro-table__status {
  font-family: 'Press Start 2P', monospace;
  font-size: 7px;
  padding: 3px 8px;
  letter-spacing: 1px;
}

.retro-table__status--online {
  color: var(--neon-accent);
  text-shadow: 0 0 4px var(--neon-accent);
}

.retro-table__status--offline {
  color: #555;
}

.retro-table__status--away {
  color: #ffaa00;
  text-shadow: 0 0 4px #ffaa00;
}
```

---

## Status Bar (HUD-Style)

```html
<div class="hud-bar">
  <div class="hud-bar__section hud-bar__section--left">
    <span class="hud-bar__label">LVL</span>
    <span class="hud-bar__value hud-bar__value--primary">42</span>
    <div class="hud-bar__divider"></div>
    <span class="hud-bar__label">HP</span>
    <div class="hud-bar__minibar">
      <div class="hud-bar__minibar-fill hud-bar__minibar-fill--hp" style="width: 78%"></div>
    </div>
    <span class="hud-bar__value">186/248</span>
    <div class="hud-bar__divider"></div>
    <span class="hud-bar__label">MP</span>
    <div class="hud-bar__minibar">
      <div class="hud-bar__minibar-fill hud-bar__minibar-fill--mp" style="width: 45%"></div>
    </div>
    <span class="hud-bar__value">52/115</span>
  </div>
  <div class="hud-bar__section hud-bar__section--right">
    <span class="hud-bar__label">CREDITS</span>
    <span class="hud-bar__value hud-bar__value--accent">&#8371; 12,847</span>
    <div class="hud-bar__divider"></div>
    <span class="hud-bar__label">TIME</span>
    <span class="hud-bar__value" id="hud-time">23:47:12</span>
  </div>
</div>
```

```css
.hud-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(10, 10, 10, 0.92);
  border-bottom: 2px solid var(--neon-primary);
  padding: 6px 16px;
  font-family: 'VT323', monospace;
  box-shadow:
    0 2px 10px rgba(255, 0, 255, 0.15),
    inset 0 -1px 0 rgba(255, 0, 255, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
}

.hud-bar__section {
  display: flex;
  align-items: center;
  gap: 8px;
}

.hud-bar__label {
  font-family: 'Press Start 2P', monospace;
  font-size: 7px;
  color: var(--text-secondary);
  letter-spacing: 1px;
}

.hud-bar__value {
  font-size: 16px;
  color: var(--text-primary);
}

.hud-bar__value--primary {
  color: var(--neon-primary);
  text-shadow: 0 0 6px var(--neon-primary);
  font-size: 18px;
}

.hud-bar__value--accent {
  color: var(--neon-accent);
  text-shadow: 0 0 4px var(--neon-accent);
}

.hud-bar__divider {
  width: 1px;
  height: 16px;
  background: linear-gradient(to bottom, transparent, var(--neon-primary), transparent);
  margin: 0 4px;
}

.hud-bar__minibar {
  width: 60px;
  height: 8px;
  background: #111;
  border: 1px solid #333;
  position: relative;
}

.hud-bar__minibar-fill {
  height: 100%;
}

.hud-bar__minibar-fill--hp {
  background: var(--neon-accent);
  box-shadow: 0 0 4px var(--neon-accent);
}

.hud-bar__minibar-fill--mp {
  background: #0088ff;
  box-shadow: 0 0 4px #0088ff;
}
```

---

## Character / Profile Card

```html
<div class="char-card">
  <div class="char-card__portrait">
    <div class="char-card__portrait-frame">
      <!-- Replace with actual sprite/image -->
      <div class="char-card__portrait-placeholder">&#9775;</div>
    </div>
    <div class="char-card__level">LV.42</div>
  </div>
  <div class="char-card__info">
    <h3 class="char-card__name">NEON_VIPER</h3>
    <span class="char-card__class">Netrunner // Elite</span>
    <div class="char-card__stats">
      <div class="char-card__stat">
        <span class="char-card__stat-label">STR</span>
        <div class="char-card__stat-bar"><div class="char-card__stat-fill" style="width: 60%"></div></div>
        <span class="char-card__stat-value">12</span>
      </div>
      <div class="char-card__stat">
        <span class="char-card__stat-label">DEX</span>
        <div class="char-card__stat-bar"><div class="char-card__stat-fill" style="width: 85%"></div></div>
        <span class="char-card__stat-value">17</span>
      </div>
      <div class="char-card__stat">
        <span class="char-card__stat-label">INT</span>
        <div class="char-card__stat-bar"><div class="char-card__stat-fill" style="width: 95%"></div></div>
        <span class="char-card__stat-value">19</span>
      </div>
      <div class="char-card__stat">
        <span class="char-card__stat-label">CHA</span>
        <div class="char-card__stat-bar"><div class="char-card__stat-fill" style="width: 40%"></div></div>
        <span class="char-card__stat-value">8</span>
      </div>
    </div>
  </div>
</div>
```

```css
.char-card {
  display: flex;
  gap: 16px;
  background: var(--bg-panel);
  border: 3px solid var(--neon-secondary);
  padding: 16px;
  max-width: 380px;
  box-shadow:
    inset 0 0 0 2px var(--bg-void),
    inset 0 0 0 4px var(--neon-primary),
    0 0 20px rgba(0, 255, 255, 0.1);
}

.char-card__portrait {
  position: relative;
  flex-shrink: 0;
}

.char-card__portrait-frame {
  width: 80px;
  height: 80px;
  background: var(--bg-void);
  border: 2px solid var(--neon-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  image-rendering: pixelated;
}

.char-card__portrait-placeholder {
  font-size: 36px;
  color: var(--neon-primary);
  text-shadow: 0 0 10px var(--neon-primary);
}

.char-card__level {
  position: absolute;
  bottom: -6px;
  left: 50%;
  transform: translateX(-50%);
  font-family: 'Press Start 2P', monospace;
  font-size: 7px;
  color: var(--bg-void);
  background: var(--neon-primary);
  padding: 2px 8px;
  white-space: nowrap;
}

.char-card__info {
  flex: 1;
  min-width: 0;
}

.char-card__name {
  font-family: 'Press Start 2P', monospace;
  font-size: 11px;
  color: var(--neon-secondary);
  margin: 0 0 4px 0;
  text-shadow: 0 0 8px var(--neon-secondary);
  letter-spacing: 2px;
}

.char-card__class {
  font-family: 'VT323', monospace;
  font-size: 14px;
  color: var(--text-secondary);
  display: block;
  margin-bottom: 12px;
}

.char-card__stats {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.char-card__stat {
  display: flex;
  align-items: center;
  gap: 6px;
}

.char-card__stat-label {
  font-family: 'Press Start 2P', monospace;
  font-size: 6px;
  color: var(--text-secondary);
  width: 24px;
  letter-spacing: 1px;
}

.char-card__stat-bar {
  flex: 1;
  height: 6px;
  background: #111;
  border: 1px solid #333;
}

.char-card__stat-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--neon-primary), var(--neon-secondary));
  box-shadow: 0 0 4px rgba(255, 0, 255, 0.3);
  transition: width 0.3s steps(10);
}

.char-card__stat-value {
  font-family: 'VT323', monospace;
  font-size: 14px;
  color: var(--neon-accent);
  width: 20px;
  text-align: right;
}
```
