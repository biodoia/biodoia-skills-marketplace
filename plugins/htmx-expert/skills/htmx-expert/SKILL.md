---
name: htmx-expert
description: "Use when building hypermedia-driven web applications with HTMX, server-side rendering with partial HTML responses, SSE integration, WebSocket connections, or when needing help with htmx attributes, extensions, patterns, or Go/Python/Node templating for HTMX. Also use when mentioning 'htmx', 'hx-get', 'hx-post', 'hypermedia', 'HATEOAS', 'html over the wire', 'server-sent events with htmx', or 'hyperscript'."
---

# HTMX Expert

Complete reference for building hypermedia-driven applications with HTMX. Covers philosophy, every attribute, events, server integration, SSE, WebSocket, extensions, patterns, and backend templating for Go, Python, and Node.

## Philosophy

### Hypermedia as the Engine of Application State (HATEOAS)

HTMX returns HTML to the original vision of the web: the server sends hypermedia (HTML with links and forms) and the client renders it. Application state lives in the HTML itself, not in client-side JavaScript objects. The server drives transitions by returning new HTML fragments containing the next set of available actions. This is HATEOAS applied practically.

### HTML Over the Wire vs JSON APIs

Traditional SPAs fetch JSON from an API, then reconstruct HTML in the browser using a JavaScript framework. HTMX inverts this: the server renders HTML fragments and sends them directly. The browser simply swaps the new HTML into the DOM. Benefits: no client-side state management, no serialization/deserialization mismatch, no JavaScript build pipeline, smaller payload for most UIs, and the server remains the single source of truth.

### Locality of Behaviour

HTMX attributes are placed directly on the HTML elements they affect. Behaviour is local to the element, not split across separate JS files. When you read `<button hx-delete="/item/5" hx-target="closest tr" hx-swap="outerHTML" hx-confirm="Delete?">`, you understand the full interaction without looking elsewhere.

### Why HTMX

- No build step, no bundler, no node_modules.
- Progressive enhancement: works with standard HTML forms, HTMX enhances them.
- Server-driven UI: any backend language can serve HTML. No API versioning or contract negotiation.
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

These can be placed on any element. HTMX will issue the request when the element's natural event fires (click for buttons, submit for forms, change for inputs/selects).

### hx-trigger

Controls when the request fires. Default triggers: `click` for most elements, `change` for inputs/selects/textareas, `submit` for forms.

```html
<!-- Trigger on specific event -->
<div hx-get="/news" hx-trigger="click">Click for news</div>

<!-- Trigger on page load -->
<div hx-get="/stats" hx-trigger="load">Loading stats...</div>

<!-- Trigger when element scrolls into view -->
<div hx-get="/lazy" hx-trigger="revealed">Lazy content</div>

<!-- Polling every 2 seconds -->
<div hx-get="/live" hx-trigger="every 2s">Live data</div>

<!-- Intersection observer (visible in viewport) -->
<div hx-get="/more" hx-trigger="intersect once">Load when visible</div>

<!-- Custom event -->
<div hx-get="/refresh" hx-trigger="myCustomEvent from:body">Waiting...</div>

<!-- Modifiers: changed, delay, throttle, once -->
<input hx-get="/search" hx-trigger="keyup changed delay:300ms" name="q">
<button hx-get="/data" hx-trigger="click throttle:1s">Rate limited</button>

<!-- Multiple triggers -->
<div hx-get="/data" hx-trigger="load, click, every 30s">Multi-trigger</div>

<!-- Filter: trigger only when condition met -->
<input hx-get="/search" hx-trigger="keyup[target.value.length > 2]">
```

### hx-target

Specifies where to place the response. Default: the element that made the request.

```html
<button hx-get="/content" hx-target="#result">Load</button>
<div id="result"></div>

<!-- Special selectors -->
<button hx-target="this">Replace self</button>
<button hx-target="closest div">Closest ancestor div</button>
<button hx-target="find .content">First descendant with .content</button>
<button hx-target="next .panel">Next sibling matching .panel</button>
<button hx-target="previous .panel">Previous sibling matching .panel</button>
<button hx-target="body">Target the body</button>
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
<!-- Transition (View Transitions API) -->
<div hx-swap="innerHTML transition:true">

<!-- Timing control -->
<div hx-swap="innerHTML swap:500ms settle:300ms">

<!-- Scroll behavior -->
<div hx-swap="innerHTML scroll:top">
<div hx-swap="innerHTML scroll:#element:bottom">
<div hx-swap="innerHTML show:top">
<div hx-swap="innerHTML show:#element:bottom">

<!-- Focus scroll control -->
<div hx-swap="innerHTML focus-scroll:false">
```

### Other Important Attributes

```html
<!-- Select a fragment from the response -->
<div hx-get="/page" hx-select="#content">Only swap #content from response</div>

<!-- Out-of-band select from response -->
<div hx-get="/page" hx-select-oob="#notification">Also grab #notification</div>

<!-- Add extra values to request (JSON format) -->
<button hx-post="/action" hx-vals='{"key": "value"}'>Submit</button>
<button hx-post="/action" hx-vals='js:{token: getToken()}'>Dynamic</button>

<!-- Add custom headers -->
<button hx-get="/data" hx-headers='{"X-Custom": "value"}'>Fetch</button>

<!-- Include other elements' values in request -->
<button hx-post="/save" hx-include="[name='email']">Save</button>
<button hx-post="/save" hx-include="closest form">Include form</button>

<!-- Loading indicator -->
<button hx-get="/slow" hx-indicator="#spinner">Load</button>
<span id="spinner" class="htmx-indicator">Loading...</span>

<!-- Confirmation dialog -->
<button hx-delete="/item/5" hx-confirm="Are you sure?">Delete</button>

<!-- Disable element -->
<button hx-get="/data" hx-disable>Disabled HTMX</button>

<!-- Disable elements during request -->
<button hx-get="/data" hx-disabled-elt="this">Disables self</button>
<button hx-get="/data" hx-disabled-elt="closest fieldset">Disables fieldset</button>

<!-- Progressive enhancement: boost standard links/forms -->
<nav hx-boost="true">
  <a href="/about">About</a>  <!-- now AJAX with pushURL -->
</nav>

<!-- Push URL to browser history -->
<a hx-get="/page" hx-push-url="true">Navigate</a>
<a hx-get="/page" hx-push-url="/custom-url">Custom URL</a>

<!-- History cache control -->
<div hx-history="false">Don't cache this page</div>

<!-- Load extensions -->
<div hx-ext="sse">SSE enabled</div>
<body hx-ext="preload, head-support">

<!-- Inline event handlers -->
<button hx-get="/data"
        hx-on:htmx:before-request="console.log('requesting...')"
        hx-on:htmx:after-swap="console.log('swapped!')">
  Load
</button>
```

## Out-of-Band Swaps (OOB)

OOB swaps allow a single response to update multiple parts of the page. The server returns additional elements with `hx-swap-oob` that get swapped into matching elements by ID.

```html
<!-- Server response -->
<div id="main-content">...primary content...</div>

<!-- These get swapped OOB into elements with matching IDs -->
<span id="notification-count" hx-swap-oob="true">5</span>
<div id="toast-container" hx-swap-oob="beforeend">
  <div class="toast">Item saved!</div>
</div>
<nav id="breadcrumb" hx-swap-oob="innerHTML">Home > Products > Edit</nav>
```

OOB swap strategies: `true` (outerHTML), `innerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend`, `delete`, `none`.

**Common OOB patterns:** update navbar counters (cart items, notifications), append toast messages, update breadcrumbs, refresh sidebar stats, synchronize multiple views.

## Events

### Client-Side Events

```javascript
// Before request fires
document.body.addEventListener('htmx:beforeRequest', function(evt) {
    console.log('Requesting:', evt.detail.pathInfo.requestPath);
});

// Modify request before send
document.body.addEventListener('htmx:configRequest', function(evt) {
    evt.detail.headers['X-CSRF-Token'] = getCsrfToken();
});

// Before swap occurs — can modify swap behavior
document.body.addEventListener('htmx:beforeSwap', function(evt) {
    if (evt.detail.xhr.status === 422) {
        evt.detail.shouldSwap = true;  // swap even on 4xx
        evt.detail.isError = false;
    }
});

// After swap and settle
document.body.addEventListener('htmx:afterSwap', function(evt) { /* reinit plugins */ });
document.body.addEventListener('htmx:afterSettle', function(evt) { /* DOM stable */ });

// New content loaded (similar to DOMContentLoaded for HTMX content)
document.body.addEventListener('htmx:load', function(evt) {
    // evt.detail.elt is the new element
});

// Error handling
document.body.addEventListener('htmx:responseError', function(evt) {
    console.error('Response error:', evt.detail.xhr.status);
});
document.body.addEventListener('htmx:sendError', function(evt) {
    console.error('Network error');
});
```

### Server-Triggered Events (HX-Trigger Header)

The server can trigger client-side events via response headers:

```
HX-Trigger: myEvent
HX-Trigger: {"showToast": {"message": "Saved!", "level": "success"}}
HX-Trigger-After-Swap: refreshSidebar
HX-Trigger-After-Settle: initAnimations
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
| `HX-Location` | Client-side redirect with AJAX (no full reload) |

### Request Headers (HTMX sends)

| Header | Purpose |
|--------|---------|
| `HX-Request` | Always `true` for HTMX requests |
| `HX-Target` | ID of the target element |
| `HX-Trigger` | ID of the triggered element |
| `HX-Trigger-Name` | Name of the triggered element |
| `HX-Current-URL` | Current URL of the browser |
| `HX-Boosted` | `true` if from a boosted element |
| `HX-Prompt` | User response from `hx-prompt` |
| `HX-History-Restore-Request` | `true` if this is a history restoration |

### Special Response Codes

- **204 No Content**: HTMX does nothing (no swap).
- **286**: Stop polling (for `hx-trigger="every Ns"`).

### Detecting HTMX Requests on the Server

```go
// Go
func handler(w http.ResponseWriter, r *http.Request) {
    if r.Header.Get("HX-Request") == "true" {
        // Return partial HTML fragment
        tmpl.ExecuteTemplate(w, "fragment.html", data)
    } else {
        // Return full page
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

# Flask
@app.route("/items")
def items():
    if request.headers.get("HX-Request"):
        return render_template("partials/items.html", items=items)
    return render_template("page.html", items=items)
```

## SSE (Server-Sent Events)

Use the `sse` extension for live server-to-client updates.

```html
<div hx-ext="sse" sse-connect="/events" sse-swap="message">
  <!-- Content replaced on each "message" event -->
</div>

<!-- Listen for named events -->
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

The server receives form data as JSON. It should respond with HTML fragments. The response targets elements by ID for swapping, or appends if wrapped appropriately.

## Extensions

### Key Built-in Extensions

| Extension | Purpose | Usage |
|-----------|---------|-------|
| `sse` | Server-Sent Events | `hx-ext="sse"` |
| `ws` | WebSocket | `hx-ext="ws"` |
| `json-enc` | JSON-encode request body | `hx-ext="json-enc"` |
| `client-side-templates` | Mustache/Handlebars/Nunjucks | `hx-ext="client-side-templates"` |
| `preload` | Preload on mouseover | `hx-ext="preload"` |
| `head-support` | Merge `<head>` from responses | `hx-ext="head-support"` |
| `response-targets` | Target by response code | `hx-target-4*="#errors"` |
| `class-tools` | Timed class toggling | `classes="add fade-in:1s"` |
| `remove-me` | Auto-remove after delay | `remove-me="2s"` |
| `loading-states` | Scoped loading classes | `data-loading` |
| `path-deps` | Path-based dependencies | `hx-trigger="path-deps" path-deps="/api/items"` |

### Loading Extensions (HTMX 2.x)

```html
<!-- Extensions are separate JS files in HTMX 2.x -->
<script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>
<script src="https://unpkg.com/htmx-ext-ws@2.2.1/ws.js"></script>
<script src="https://unpkg.com/htmx-ext-response-targets@2.0.2/response-targets.js"></script>
```

## Go + HTMX (Primary Stack)

### html/template with Partials

```go
// Define a partial template
// templates/partials/user-row.html
// {{define "user-row"}}
// <tr id="user-{{.ID}}">
//   <td>{{.Name}}</td>
//   <td><button hx-delete="/users/{{.ID}}" hx-target="closest tr" hx-swap="outerHTML">Delete</button></td>
// </tr>
// {{end}}

func deleteUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    db.Delete(id)
    w.WriteHeader(200) // return empty = delete the target via outerHTML swap
}
```

### templ (Type-Safe Templates)

```go
// components/search.templ
templ SearchResults(users []User) {
    for _, u := range users {
        <tr>
            <td>{ u.Name }</td>
            <td>{ u.Email }</td>
        </tr>
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

# views.py
def search(request):
    q = request.GET.get("q", "")
    results = Item.objects.filter(name__icontains=q)
    if request.htmx:
        return render(request, "partials/results.html", {"results": results})
    return render(request, "search.html", {"results": results})
```

### FastAPI + Jinja2

```python
from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="templates")

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

For ready-to-use code patterns with full HTML and server examples, read `references/patterns-cookbook.md`. Key patterns covered:

- **Active Search**: search-as-you-type with debounce
- **Infinite Scroll**: load more on scroll with `revealed` trigger
- **Click to Edit**: inline editing with save/cancel
- **Bulk Update**: checkbox selection with batch operations
- **Lazy Loading**: defer content until visible
- **Progress Bar**: poll for progress with auto-stop
- **Cascading Selects**: dependent dropdowns
- **Inline Validation**: field-level validation on blur
- **Delete Row**: with confirmation and fade-out
- **Tabs**: lazy-loaded tab content
- **Modal Dialogs**: server-rendered modals
- **Sortable Tables**: sort/filter via header clicks
- **Toast Notifications**: OOB appended toasts
- **File Upload with Progress**: multipart upload with SSE progress
- **Live Notifications via SSE**: real-time notification feed

## _hyperscript

A companion scripting language for HTMX. Small inline behaviours without writing JavaScript.

```html
<!-- Toggle class -->
<button _="on click toggle .active on me">Toggle</button>

<!-- Hide on click -->
<div _="on click add .fade-out then wait 300ms then remove me">
  Dismissible notice
</div>

<!-- Copy to clipboard -->
<button _="on click writeText(#code.innerText) into navigator.clipboard
           then put 'Copied!' into me
           then wait 2s then put 'Copy' into me">Copy</button>
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
/* Loading indicator */
.htmx-indicator { opacity: 0; transition: opacity 200ms; }
.htmx-request .htmx-indicator { opacity: 1; }
.htmx-request.htmx-indicator { opacity: 1; }

/* Fade in new content */
.htmx-added { opacity: 0; }
.htmx-settling .htmx-added { opacity: 1; transition: opacity 300ms; }

/* View Transitions API */
::view-transition-old(swap) { animation: fade-out 0.2s; }
::view-transition-new(swap) { animation: fade-in 0.2s; }
```

## Troubleshooting

### Debugging

```javascript
htmx.logAll();  // Log all HTMX events to console
```

Check the Network tab: HTMX requests include `HX-Request: true` header. Responses should be HTML fragments, not JSON, not full pages (unless intended).

### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Response is full HTML page, not fragment | Check `HX-Request` header and return partial |
| Wrong swap mode: content disappears | Use `outerHTML` if replacing the element, `innerHTML` to replace children |
| Target not found | Verify CSS selector, check element exists in DOM |
| CORS errors on HTMX requests | Configure server CORS to allow `HX-*` headers |
| Polling never stops | Return 286 status code to stop |
| OOB swap not working | Element in response needs `hx-swap-oob` and matching `id` in DOM |
| Form data not sent | Ensure `name` attributes on inputs |
| Double requests firing | Check for duplicate `hx-trigger` or bubbling events |

### Performance

- **Debounce** search inputs: `hx-trigger="keyup changed delay:300ms"`
- **Throttle** scroll handlers: `hx-trigger="scroll throttle:200ms"`
- **Preload** on hover: use the `preload` extension
- **Cache** responses server-side with appropriate cache headers
- **`hx-sync`** to coalesce or cancel in-flight requests: `hx-sync="closest form:abort"`

## Progressive Disclosure

- For the complete attribute reference table: read `references/attributes-reference.md`
- For ready-to-use HTML + Go server code patterns: read `references/patterns-cookbook.md`
