# HTMX Attributes Reference

Complete reference for every HTMX attribute, its accepted values, defaults, and usage examples.

## Core Request Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-get` | Issue a GET request | URL | — | `hx-get="/api/items"` |
| `hx-post` | Issue a POST request | URL | — | `hx-post="/api/items"` |
| `hx-put` | Issue a PUT request | URL | — | `hx-put="/api/items/1"` |
| `hx-patch` | Issue a PATCH request | URL | — | `hx-patch="/api/items/1"` |
| `hx-delete` | Issue a DELETE request | URL | — | `hx-delete="/api/items/1"` |

## Targeting and Swapping

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-target` | Element to swap response into | CSS selector, `this`, `closest <sel>`, `find <sel>`, `next <sel>`, `previous <sel>`, `body` | The element itself | `hx-target="#result"` |
| `hx-swap` | How to swap the response | `innerHTML`, `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend`, `delete`, `none` | `innerHTML` | `hx-swap="outerHTML"` |
| `hx-select` | Select a fragment from response | CSS selector | Entire response | `hx-select="#content"` |
| `hx-select-oob` | Out-of-band select from response | CSS selector(s), comma-separated | — | `hx-select-oob="#nav,#footer"` |

### hx-swap Modifiers

Append modifiers to the swap value separated by spaces.

| Modifier | Description | Example |
|----------|-------------|---------|
| `transition:true` | Use View Transitions API | `hx-swap="innerHTML transition:true"` |
| `swap:<timing>` | Delay before swap | `hx-swap="innerHTML swap:500ms"` |
| `settle:<timing>` | Delay before settle | `hx-swap="innerHTML settle:300ms"` |
| `scroll:top` | Scroll target to top | `hx-swap="innerHTML scroll:top"` |
| `scroll:bottom` | Scroll target to bottom | `hx-swap="innerHTML scroll:bottom"` |
| `scroll:<selector>:top` | Scroll specific element to top | `hx-swap="innerHTML scroll:#list:top"` |
| `show:top` | Show target at top of viewport | `hx-swap="innerHTML show:top"` |
| `show:bottom` | Show target at bottom of viewport | `hx-swap="innerHTML show:bottom"` |
| `show:<selector>:top` | Show specific element at viewport top | `hx-swap="innerHTML show:#header:top"` |
| `show:window:top` | Scroll window to top | `hx-swap="innerHTML show:window:top"` |
| `focus-scroll:true` | Scroll to focused element | `hx-swap="innerHTML focus-scroll:true"` |
| `focus-scroll:false` | Prevent focus-based scrolling | `hx-swap="innerHTML focus-scroll:false"` |

## Triggering

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-trigger` | Event(s) that trigger request | Event name(s) with optional modifiers | `click` (most), `change` (inputs), `submit` (forms) | `hx-trigger="click"` |

### hx-trigger Events

| Event | Description | Example |
|-------|-------------|---------|
| `click` | Mouse click | `hx-trigger="click"` |
| `change` | Value changed | `hx-trigger="change"` |
| `submit` | Form submit | `hx-trigger="submit"` |
| `keyup` | Key released | `hx-trigger="keyup"` |
| `keydown` | Key pressed | `hx-trigger="keydown"` |
| `mouseenter` | Mouse enters element | `hx-trigger="mouseenter"` |
| `mouseleave` | Mouse leaves element | `hx-trigger="mouseleave"` |
| `focus` | Element focused | `hx-trigger="focus"` |
| `blur` | Element lost focus | `hx-trigger="blur"` |
| `load` | Element loaded | `hx-trigger="load"` |
| `revealed` | Element scrolled into viewport | `hx-trigger="revealed"` |
| `intersect` | IntersectionObserver | `hx-trigger="intersect"` |
| `every <time>` | Polling interval | `hx-trigger="every 2s"` |
| Custom event | Any custom event name | `hx-trigger="myEvent"` |

### hx-trigger Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `once` | Trigger only once | `hx-trigger="click once"` |
| `changed` | Only if value changed | `hx-trigger="keyup changed"` |
| `delay:<time>` | Debounce (wait, reset on re-trigger) | `hx-trigger="keyup delay:300ms"` |
| `throttle:<time>` | Throttle (max once per interval) | `hx-trigger="scroll throttle:200ms"` |
| `from:<selector>` | Listen on another element | `hx-trigger="click from:body"` |
| `from:document` | Listen on document | `hx-trigger="myEvent from:document"` |
| `from:window` | Listen on window | `hx-trigger="resize from:window"` |
| `from:closest <sel>` | Listen on closest ancestor | `hx-trigger="click from:closest .container"` |
| `from:find <sel>` | Listen on descendant | `hx-trigger="change from:find input"` |
| `target:<selector>` | Filter by event target | `hx-trigger="click target:.btn"` |
| `consume` | Prevent event from propagating | `hx-trigger="click consume"` |
| `queue:first` | Queue: keep first, discard rest | `hx-trigger="click queue:first"` |
| `queue:last` | Queue: keep last, discard rest | `hx-trigger="click queue:last"` |
| `queue:all` | Queue: process all | `hx-trigger="click queue:all"` |
| `queue:none` | Queue: discard if busy | `hx-trigger="click queue:none"` |
| `[<condition>]` | JS filter expression | `hx-trigger="keyup[key=='Enter']"` |

### hx-trigger Intersection Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `root:<selector>` | IntersectionObserver root | `hx-trigger="intersect root:#scroll-area"` |
| `threshold:<float>` | Visibility threshold (0.0-1.0) | `hx-trigger="intersect threshold:0.5"` |

## Request Configuration

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-vals` | Add values to request | JSON string or `js:{...}` | — | `hx-vals='{"key":"val"}'` |
| `hx-headers` | Add headers to request | JSON string | — | `hx-headers='{"X-Token":"abc"}'` |
| `hx-include` | Include other elements in request | CSS selector, `this`, `closest <sel>`, `find <sel>`, `next <sel>`, `previous <sel>` | — | `hx-include="[name='csrf']"` |
| `hx-params` | Filter parameters | `*` (all), `none`, `not <list>`, `<list>` | `*` | `hx-params="not secret"` |
| `hx-encoding` | Encoding type | `multipart/form-data` | — | `hx-encoding="multipart/form-data"` |
| `hx-sync` | Synchronize requests | `<selector>:<strategy>` | — | `hx-sync="closest form:abort"` |

### hx-sync Strategies

| Strategy | Description | Example |
|----------|-------------|---------|
| `drop` | Drop this request if another in-flight | `hx-sync="this:drop"` |
| `abort` | Abort previous request | `hx-sync="this:abort"` |
| `replace` | Abort previous, send this one | `hx-sync="this:replace"` |
| `queue first` | Queue, keep first | `hx-sync="this:queue first"` |
| `queue last` | Queue, keep last | `hx-sync="this:queue last"` |
| `queue all` | Queue all | `hx-sync="this:queue all"` |

## UI Feedback

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-indicator` | Element(s) to show during request | CSS selector | Closest parent with `.htmx-indicator` | `hx-indicator="#spinner"` |
| `hx-disabled-elt` | Element(s) to disable during request | CSS selector, `this`, `closest <sel>`, `find <sel>`, `next <sel>`, `previous <sel>` | — | `hx-disabled-elt="this"` |
| `hx-confirm` | Show confirmation dialog | String (message text) | — | `hx-confirm="Delete this?"` |

## Navigation and History

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-boost` | Boost links and forms to AJAX | `true`, `false` | `false` (inherited) | `hx-boost="true"` |
| `hx-push-url` | Push URL to browser history | `true`, `false`, URL string | `false` | `hx-push-url="true"` |
| `hx-replace-url` | Replace current URL in history | `true`, `false`, URL string | `false` | `hx-replace-url="/new-path"` |
| `hx-history` | Control history snapshot caching | `false` | — | `hx-history="false"` |
| `hx-history-elt` | Element to snapshot for history | — | `body` | `hx-history-elt` (on element) |

## Extensions

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-ext` | Enable extensions | Comma-separated extension names, prefix with `ignore:` to exclude inherited | — | `hx-ext="sse,preload"` |

## SSE Extension Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `sse-connect` | Connect to SSE endpoint | URL | — | `sse-connect="/events"` |
| `sse-swap` | Swap on named SSE event | Event name | — | `sse-swap="message"` |
| `sse-close` | Close connection on event | Event name | — | `sse-close="done"` |

## WebSocket Extension Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `ws-connect` | Connect to WebSocket endpoint | URL | — | `ws-connect="/ws/chat"` |
| `ws-send` | Send form data on submit | (no value needed) | — | `<form ws-send>` |

## Response Targets Extension Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-target-*` | Target by HTTP status | CSS selector | — | `hx-target-404="#not-found"` |
| `hx-target-4*` | Target by status class | CSS selector | — | `hx-target-4*="#errors"` |
| `hx-target-5*` | Target 5xx errors | CSS selector | — | `hx-target-5*="#server-error"` |

## Preload Extension Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `preload` | Preload strategy | `mouseover` (default), `mousedown` | `mouseover` | `<a preload="mousedown">` |

## Loading States Extension Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `data-loading` | Show during request | (no value) | — | `<div data-loading>Loading...</div>` |
| `data-loading-class` | Add class during request | Class name | — | `data-loading-class="opacity-50"` |
| `data-loading-class-remove` | Remove class during request | Class name | — | `data-loading-class-remove="hidden"` |
| `data-loading-disable` | Disable during request | (no value) | — | `<button data-loading-disable>` |
| `data-loading-delay` | Delay before showing | Time value | — | `data-loading-delay="200ms"` |
| `data-loading-target` | Target element for loading state | CSS selector | — | `data-loading-target="#spinner"` |
| `data-loading-path` | Only for requests to path | URL path | — | `data-loading-path="/api/save"` |

## Class Tools Extension Attributes

| Attribute | Description | Values | Example |
|-----------|-------------|--------|---------|
| `classes` | Timed class operations | `add <class>:<delay>`, `remove <class>:<delay>`, `toggle <class>:<delay>` | `classes="add fade-in:300ms, remove hidden"` |

## Remove Me Extension Attributes

| Attribute | Description | Values | Example |
|-----------|-------------|--------|---------|
| `remove-me` | Auto-remove element after delay | Time value | `remove-me="3s"` |

## Miscellaneous Attributes

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-disable` | Disable HTMX processing | (no value) | — | `<div hx-disable>No HTMX here</div>` |
| `hx-disinherit` | Disable attribute inheritance | `*` or space-separated attribute names | — | `hx-disinherit="hx-boost hx-target"` |
| `hx-preserve` | Preserve element during swap | `true` | — | `<input hx-preserve="true" id="search">` |
| `hx-prompt` | Show prompt dialog before request | String (prompt message) | — | `hx-prompt="Enter reason:"` |
| `hx-validate` | Force validation before request | `true` | — | `hx-validate="true"` |
| `hx-on` | Inline event handler | Event handler code | — | See below |
| `hx-inherit` | Explicitly inherit attributes | Space-separated attribute names | — | `hx-inherit="hx-target hx-swap"` |

### hx-on Syntax

The `hx-on` attribute allows inline event handling. Use the `hx-on:<event>` syntax:

```html
<!-- HTMX events (use kebab-case after hx-on:) -->
<button hx-get="/data"
        hx-on:htmx:before-request="showSpinner()"
        hx-on:htmx:after-swap="hideSpinner()">
  Load
</button>

<!-- Standard DOM events -->
<button hx-on:click="console.log('clicked')">Click me</button>
<input hx-on:keyup="validate(this)">

<!-- Shorthand without htmx: prefix for htmx events -->
<button hx-on::before-request="showSpinner()">Load</button>
```

## Out-of-Band Swap Attribute

| Attribute | Description | Values | Default | Example |
|-----------|-------------|--------|---------|---------|
| `hx-swap-oob` | Swap this element out-of-band in response | `true`, `innerHTML`, `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend`, `delete`, `none`, or `<strategy>:<selector>` | `true` (outerHTML by ID) | `hx-swap-oob="true"` |

### OOB Swap with Selector

```html
<!-- In server response: swap innerHTML of #count wherever it is in the page -->
<span id="count" hx-swap-oob="innerHTML">#42</span>

<!-- Append to a specific target -->
<div hx-swap-oob="beforeend:#toast-container">
  <div class="toast">Saved!</div>
</div>
```

## Attribute Inheritance

Most `hx-*` attributes are inherited by child elements. This means you can set attributes on a parent and all descendants will use them unless overridden.

**Inherited attributes**: `hx-boost`, `hx-confirm`, `hx-disabled-elt`, `hx-encoding`, `hx-ext`, `hx-headers`, `hx-indicator`, `hx-params`, `hx-select`, `hx-select-oob`, `hx-swap`, `hx-sync`, `hx-target`, `hx-vals`.

**Not inherited**: `hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`, `hx-trigger` (these are element-specific).

Disable inheritance with `hx-disinherit`:

```html
<div hx-boost="true" hx-target="#main">
  <a href="/page">Boosted with target</a>
  <div hx-disinherit="hx-target">
    <a href="/other">Boosted but uses default target</a>
  </div>
</div>
```

## Meta Configuration

Set HTMX configuration via a `<meta>` tag:

```html
<meta name="htmx-config" content='{
  "defaultSwapStyle": "outerHTML",
  "defaultSwapDelay": 0,
  "defaultSettleDelay": 20,
  "includeIndicatorStyles": true,
  "historyCacheSize": 10,
  "useTemplateFragments": false,
  "selfRequestsOnly": true,
  "scrollBehavior": "instant",
  "allowNestedOobSwaps": true,
  "timeout": 0,
  "scrollIntoViewOnBoost": true,
  "triggerSpecsCache": null,
  "allowEval": true,
  "getCacheBusterParam": false,
  "globalViewTransitions": false,
  "methodsThatUseUrlParams": ["get", "delete"],
  "refreshOnHistoryMiss": false,
  "responseHandling": [
    {"code": "204", "swap": false},
    {"code": "[23]..", "swap": true},
    {"code": "[45]..", "swap": false, "error": true},
    {"code": "...", "swap": false}
  ]
}'>
```
