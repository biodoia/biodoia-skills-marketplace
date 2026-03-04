---
name: htmx-expert
description: This skill should be used when the user asks about "htmx", "hx-get", "hx-post", "hx-swap", "hx-trigger", "hypermedia", "HATEOAS", "html over the wire", "server-sent events", "hyperscript", or "htmx extensions". Make sure to use this skill whenever the user mentions building hypermedia-driven web apps, server-side rendering with partial HTML responses, SSE or WebSocket integration with HTMX, htmx attributes or patterns, Go/Python/Node templating for HTMX, or out-of-band swaps, even if they just mention server-rendered HTML without explicitly saying HTMX.
---

# HTMX Expert

Complete reference for building hypermedia-driven applications with HTMX. Covers philosophy, every attribute, events, server integration, SSE, WebSocket, extensions, patterns, and backend templating for Go, Python, and Node.

## Philosophy

### Hypermedia as the Engine of Application State (HATEOAS)

HTMX returns HTML to the original vision of the web: the server sends hypermedia (HTML with links and forms) and the client renders it. Application state lives in the HTML itself, not in client-side JavaScript objects. The server drives transitions by returning new HTML fragments containing the next set of available actions.

### HTML Over the Wire vs JSON APIs

Traditional SPAs fetch JSON from an API, then reconstruct HTML in the browser using a JavaScript framework. HTMX inverts this: the server renders HTML fragments and sends them directly. The browser simply swaps the new HTML into the DOM. Benefits: no client-side state management, no serialization/deserialization mismatch, no JavaScript build pipeline, smaller payload for most UIs, and the server remains the single source of truth.

### Locality of Behaviour

HTMX attributes are placed directly on the HTML elements they affect. Behaviour is local to the element, not split across separate JS files. Reading `<button hx-delete="/item/5" hx-target="closest tr" hx-swap="outerHTML" hx-confirm="Delete?">` reveals the full interaction without looking elsewhere.

### Why HTMX

- No build step, no bundler, no node_modules.
- Progressive enhancement: works with standard HTML forms, HTMX enhances them.
- Server-driven UI: any backend language can serve HTML.
- Small footprint: ~14KB min+gzip.
- Plays well with existing server-rendered applications (Django, Rails, Go templates, PHP).

## Core Attributes

### AJAX Request Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-get` | Issue GET request | `hx-get="/api/users"` |
| `hx-post` | Issue POST request | `hx-post="/api/users"` |
| `hx-put` | Issue PUT request | `hx-put="/api/users/1"` |
| `hx-patch` | Issue PATCH request | `hx-patch="/api/users/1"` |
| `hx-delete` | Issue DELETE request | `hx-delete="/api/users/1"` |

These can be placed on any element. HTMX issues the request when the element's natural event fires (click for buttons, submit for forms, change for inputs/selects).

### hx-trigger

Controls when the request fires. Default triggers: `click` for most elements, `change` for inputs/selects/textareas, `submit` for forms.

```html
<div hx-get="/news" hx-trigger="click">Click for news</div>
<div hx-get="/stats" hx-trigger="load">Loading stats...</div>
<div hx-get="/lazy" hx-trigger="revealed">Lazy content</div>
<div hx-get="/live" hx-trigger="every 2s">Live data</div>
<div hx-get="/more" hx-trigger="intersect once">Load when visible</div>
<input hx-get="/search" hx-trigger="keyup changed delay:300ms" name="q">
<button hx-get="/data" hx-trigger="click throttle:1s">Rate limited</button>
<div hx-get="/data" hx-trigger="load, click, every 30s">Multi-trigger</div>
<input hx-get="/search" hx-trigger="keyup[target.value.length > 2]">
```

### hx-target

Specifies where to place the response. Default: the element that made the request.

```html
<button hx-get="/content" hx-target="#result">Load</button>
<button hx-target="this">Replace self</button>
<button hx-target="closest div">Closest ancestor div</button>
<button hx-target="find .content">First descendant with .content</button>
<button hx-target="next .panel">Next sibling matching .panel</button>
```

### hx-swap

Controls how the response is inserted into the target. Default: `innerHTML`.

| Value | Effect |
|-------|--------|
| `innerHTML` | Replace inner content of target |
| `outerHTML` | Replace the entire target element |
| `beforebegin` | Insert before the target |
| `afterbegin` | Insert at start inside the target |
| `beforeend` | Insert at end inside the target (append) |
| `afterend` | Insert after the target |
| `delete` | Delete the target element |
| `none` | Do not swap (useful for side-effect requests) |

**Swap modifiers** (append to swap value):
```html
<div hx-swap="innerHTML transition:true">
<div hx-swap="innerHTML swap:500ms settle:300ms">
<div hx-swap="innerHTML scroll:top">
<div hx-swap="innerHTML focus-scroll:false">
```

### Other Important Attributes

```html
<div hx-get="/page" hx-select="#content">Only swap #content from response</div>
<button hx-post="/action" hx-vals='{"key": "value"}'>Submit</button>
<button hx-post="/save" hx-include="closest form">Include form</button>
<button hx-get="/slow" hx-indicator="#spinner">Load</button>
<button hx-delete="/item/5" hx-confirm="Are you sure?">Delete</button>
<button hx-get="/data" hx-disabled-elt="this">Disables self during request</button>
<nav hx-boost="true"><a href="/about">About</a></nav>
<a hx-get="/page" hx-push-url="true">Navigate</a>
<div hx-ext="sse">SSE enabled</div>
```

For the complete attribute reference table with all accepted values and defaults, see `references/attributes-reference.md`.

## Out-of-Band Swaps (OOB)

OOB swaps allow a single response to update multiple parts of the page. The server returns additional elements with `hx-swap-oob` that get swapped into matching elements by ID.

```html
<!-- Server response -->
<div id="main-content">...primary content...</div>
<span id="notification-count" hx-swap-oob="true">5</span>
<div id="toast-container" hx-swap-oob="beforeend">
  <div class="toast">Item saved!</div>
</div>
<nav id="breadcrumb" hx-swap-oob="innerHTML">Home > Products > Edit</nav>
```

**Common OOB patterns:** update navbar counters, append toast messages, update breadcrumbs, refresh sidebar stats, synchronize multiple views.

## Events

### Client-Side Events

```javascript
document.body.addEventListener('htmx:configRequest', function(evt) {
    evt.detail.headers['X-CSRF-Token'] = getCsrfToken();
});

document.body.addEventListener('htmx:beforeSwap', function(evt) {
    if (evt.detail.xhr.status === 422) {
        evt.detail.shouldSwap = true;  // swap even on 4xx
        evt.detail.isError = false;
    }
});

document.body.addEventListener('htmx:afterSwap', function(evt) { /* reinit plugins */ });
document.body.addEventListener('htmx:load', function(evt) { /* new element: evt.detail.elt */ });
```

### Server-Triggered Events (HX-Trigger Header)

The server can trigger client-side events via response headers:

```
HX-Trigger: {"showToast": {"message": "Saved!", "level": "success"}}
HX-Trigger-After-Swap: refreshSidebar
```

Listen on the client:
```javascript
document.body.addEventListener('showToast', function(evt) {
    showToast(evt.detail.message, evt.detail.level);
});
```

## Server Integration

### Response Headers (server sends)

| Header | Purpose |
|--------|---------|
| `HX-Trigger` | Trigger client events |
| `HX-Redirect` | Client-side redirect |
| `HX-Refresh` | Full page refresh (`true`) |
| `HX-Retarget` | Change the target (CSS selector) |
| `HX-Reswap` | Change the swap strategy |
| `HX-Push-Url` | Push URL to history |
| `HX-Replace-Url` | Replace current URL in history |

### Request Headers (HTMX sends)

| Header | Purpose |
|--------|---------|
| `HX-Request` | Always `true` for HTMX requests |
| `HX-Target` | ID of the target element |
| `HX-Trigger` | ID of the triggered element |
| `HX-Current-URL` | Current URL of the browser |
| `HX-Boosted` | `true` if from a boosted element |

### Detecting HTMX Requests on the Server

```go
// Go
func handler(w http.ResponseWriter, r *http.Request) {
    if r.Header.Get("HX-Request") == "true" {
        tmpl.ExecuteTemplate(w, "fragment.html", data)
    } else {
        tmpl.ExecuteTemplate(w, "layout.html", data)
    }
}
```

```python
# Django with django-htmx
def view(request):
    if request.htmx:
        return render(request, "partials/fragment.html", ctx)
    return render(request, "full_page.html", ctx)
```

### Special Response Codes

- **204 No Content**: HTMX does nothing (no swap).
- **286**: Stop polling (for `hx-trigger="every Ns"`).

## SSE (Server-Sent Events)

```html
<div hx-ext="sse" sse-connect="/events" sse-swap="message">
  <!-- Content replaced on each "message" event -->
</div>

<div hx-ext="sse" sse-connect="/events">
  <div sse-swap="notifications">Notifications here</div>
  <div sse-swap="stats">Stats here</div>
</div>

<!-- Use SSE as trigger for other requests -->
<div hx-ext="sse" sse-connect="/events">
  <div hx-get="/data" hx-trigger="sse:update">Refreshed on SSE event</div>
</div>
```

**Go SSE server:**

```go
func sseHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    w.Header().Set("Connection", "keep-alive")
    flusher, _ := w.(http.Flusher)

    for {
        select {
        case msg := <-messageChan:
            fmt.Fprintf(w, "event: notifications\ndata: <div>%s</div>\n\n", msg)
            flusher.Flush()
        case <-r.Context().Done():
            return
        }
    }
}
```

## WebSocket

```html
<div hx-ext="ws" ws-connect="/ws/chat">
  <div id="messages"></div>
  <form ws-send>
    <input name="message">
    <button>Send</button>
  </form>
</div>
```

The server receives form data as JSON and should respond with HTML fragments.

## Extensions

### Key Built-in Extensions

| Extension | Purpose | Usage |
|-----------|---------|-------|
| `sse` | Server-Sent Events | `hx-ext="sse"` |
| `ws` | WebSocket | `hx-ext="ws"` |
| `json-enc` | JSON-encode request body | `hx-ext="json-enc"` |
| `preload` | Preload on mouseover | `hx-ext="preload"` |
| `head-support` | Merge `<head>` from responses | `hx-ext="head-support"` |
| `response-targets` | Target by response code | `hx-target-4*="#errors"` |
| `class-tools` | Timed class toggling | `classes="add fade-in:1s"` |
| `remove-me` | Auto-remove after delay | `remove-me="2s"` |
| `loading-states` | Scoped loading classes | `data-loading` |

### Loading Extensions (HTMX 2.x)

```html
<script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>
<script src="https://unpkg.com/htmx-ext-ws@2.2.1/ws.js"></script>
<script src="https://unpkg.com/htmx-ext-response-targets@2.0.2/response-targets.js"></script>
```

## Go + HTMX (Primary Stack)

### html/template with Partials

```go
// templates/partials/user-row.html
// {{define "user-row"}}
// <tr id="user-{{.ID}}">
//   <td>{{.Name}}</td>
//   <td><button hx-delete="/users/{{.ID}}" hx-target="closest tr" hx-swap="outerHTML">Delete</button></td>
// </tr>
// {{end}}
```

### templ (Type-Safe Templates)

```go
templ SearchResults(users []User) {
    for _, u := range users {
        <tr><td>{ u.Name }</td><td>{ u.Email }</td></tr>
    }
}

templ SearchBox() {
    <input type="search" name="q"
        hx-get="/search"
        hx-trigger="keyup changed delay:300ms"
        hx-target="#results"
        hx-indicator="#spinner"/>
}
```

### framegotui pkg/web Integration

The framegotui framework uses HTMX natively for its WebUI frontend. The `pkg/web` package renders templates with HTMX attributes and serves SSE for real-time updates from the backend event bus. Use `web.NewFromManager(cfg, mgr)` to create the web server, which automatically supports HTMX partial responses.

## Python + HTMX

### Django + django-htmx

```python
# pip install django-htmx
MIDDLEWARE = ["django_htmx.middleware.HtmxMiddleware", ...]

def search(request):
    q = request.GET.get("q", "")
    results = Item.objects.filter(name__icontains=q)
    if request.htmx:
        return render(request, "partials/results.html", {"results": results})
    return render(request, "search.html", {"results": results})
```

### FastAPI + Jinja2

```python
@app.get("/items")
async def items(request: Request, q: str = ""):
    items = get_items(q)
    if request.headers.get("HX-Request"):
        return templates.TemplateResponse("partials/items.html",
            {"request": request, "items": items})
    return templates.TemplateResponse("items.html",
        {"request": request, "items": items})
```

## Patterns and Best Practices

For ready-to-use code patterns with full HTML and Go server examples, see `references/patterns-cookbook.md`. Key patterns covered:

- **Active Search**: search-as-type with debounce
- **Infinite Scroll**: load more on scroll with `revealed` trigger
- **Click to Edit**: inline editing with save/cancel
- **Bulk Update**: checkbox selection with batch operations
- **Modal Dialogs**: server-rendered modals
- **Tabs**: lazy-loaded tab content
- **Toast Notifications**: OOB appended toasts
- **File Upload with Progress**: multipart upload with SSE progress
- **Live Notifications via SSE**: real-time notification feed
- **Sortable Tables**: sort/filter via header clicks

## _hyperscript

A companion scripting language for HTMX for small inline behaviours:

```html
<button _="on click toggle .active on me">Toggle</button>
<div _="on click add .fade-out then wait 300ms then remove me">Dismissible</div>
```

Use _hyperscript for simple UI interactions (toggle, show/hide, transitions). Use JavaScript for complex logic. Do not use _hyperscript for anything that touches server data; use HTMX for that.

## CSS Integration

HTMX adds CSS classes during the request lifecycle:

| Class | When Applied |
|-------|-------------|
| `htmx-request` | On the element (or indicator) during the request |
| `htmx-settling` | On the target during the settle phase |
| `htmx-swapping` | On the target during the swap phase |
| `htmx-added` | On newly added elements |

```css
.htmx-indicator { opacity: 0; transition: opacity 200ms; }
.htmx-request .htmx-indicator { opacity: 1; }
.htmx-request.htmx-indicator { opacity: 1; }
.htmx-added { opacity: 0; }
.htmx-settling .htmx-added { opacity: 1; transition: opacity 300ms; }
```

## Troubleshooting

### Debugging

```javascript
htmx.logAll();  // Log all HTMX events to console
```

Check the Network tab: HTMX requests include `HX-Request: true` header. Responses should be HTML fragments, not JSON.

### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Response is full HTML page, not fragment | Check `HX-Request` header and return partial |
| Content disappears on swap | Use `outerHTML` to replace element, `innerHTML` for children |
| Target not found | Verify CSS selector, check element exists in DOM |
| Polling never stops | Return 286 status code to stop |
| OOB swap not working | Ensure `hx-swap-oob` and matching `id` in DOM |
| Double requests firing | Check for duplicate `hx-trigger` or bubbling events |

### Performance

- **Debounce** search inputs: `hx-trigger="keyup changed delay:300ms"`
- **Throttle** scroll handlers: `hx-trigger="scroll throttle:200ms"`
- **Preload** on hover: use the `preload` extension
- **`hx-sync`** to coalesce or cancel in-flight requests: `hx-sync="closest form:abort"`

## Additional Resources

- **`references/attributes-reference.md`** -- Complete reference for every HTMX attribute, accepted values, defaults, and examples. Includes all hx-swap modifiers, hx-trigger events and modifiers, hx-sync strategies, SSE/WebSocket/extension attributes, OOB swap syntax, attribute inheritance rules, and meta configuration options. Consult for any attribute lookup or configuration detail.
- **`references/patterns-cookbook.md`** -- Ready-to-use HTML + Go server handler patterns for 10+ common HTMX interactions: active search with debounce, infinite scroll, click-to-edit, bulk operations, live SSE notifications, modal dialogs, lazy-loaded tabs, file upload with progress, toast notifications via OOB, sortable/filterable tables, inline validation, delete with fade-out, cascading selects, and progress bar polling. Consult when implementing any standard HTMX interaction pattern.
