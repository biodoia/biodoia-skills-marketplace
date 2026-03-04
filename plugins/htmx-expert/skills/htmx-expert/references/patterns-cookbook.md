# HTMX Patterns Cookbook

Ready-to-use HTML + Go server handler patterns for common HTMX interactions. Each pattern is self-contained and can be adapted to any backend.

---

## 1. Active Search with Debounce

Search-as-you-type with 300ms debounce. The server returns matching rows.

### HTML

```html
<input type="search" name="q"
       hx-get="/search"
       hx-trigger="input changed delay:300ms, search"
       hx-target="#search-results"
       hx-indicator="#search-spinner"
       placeholder="Search users...">
<span id="search-spinner" class="htmx-indicator">Searching...</span>

<table>
  <thead>
    <tr><th>Name</th><th>Email</th></tr>
  </thead>
  <tbody id="search-results">
    <!-- Results swapped here -->
  </tbody>
</table>
```

### Go Handler

```go
func searchHandler(w http.ResponseWriter, r *http.Request) {
    q := r.URL.Query().Get("q")
    users := db.SearchUsers(q)

    tmpl := template.Must(template.New("rows").Parse(`
        {{range .}}
        <tr>
            <td>{{.Name}}</td>
            <td>{{.Email}}</td>
        </tr>
        {{end}}
        {{if not .}}
        <tr><td colspan="2">No results found</td></tr>
        {{end}}
    `))
    tmpl.Execute(w, users)
}
```

---

## 2. Infinite Scroll

Load more items when the user scrolls to the bottom. The last element triggers the next page load.

### HTML

```html
<div id="item-list">
  <div class="item">Item 1</div>
  <div class="item">Item 2</div>
  <!-- ... -->
  <div class="item">Item 10</div>
  <!-- Sentinel: triggers load when revealed -->
  <div hx-get="/items?page=2"
       hx-trigger="revealed"
       hx-swap="outerHTML"
       hx-indicator="#load-more-spinner">
    <span id="load-more-spinner" class="htmx-indicator">Loading more...</span>
  </div>
</div>
```

### Go Handler

```go
func itemsHandler(w http.ResponseWriter, r *http.Request) {
    page, _ := strconv.Atoi(r.URL.Query().Get("page"))
    if page < 1 { page = 1 }
    pageSize := 10
    offset := (page - 1) * pageSize

    items := db.GetItems(offset, pageSize)
    hasMore := len(items) == pageSize

    tmpl := template.Must(template.New("items").Parse(`
        {{range .Items}}
        <div class="item">{{.Title}}</div>
        {{end}}
        {{if .HasMore}}
        <div hx-get="/items?page={{.NextPage}}"
             hx-trigger="revealed"
             hx-swap="outerHTML"
             hx-indicator="#load-more-spinner">
          <span id="load-more-spinner" class="htmx-indicator">Loading more...</span>
        </div>
        {{end}}
    `))

    data := struct {
        Items    []Item
        HasMore  bool
        NextPage int
    }{items, hasMore, page + 1}

    tmpl.Execute(w, data)
}
```

---

## 3. Click to Edit with Cancel

Click a display element to show an edit form. Cancel returns the display view.

### HTML (Display Mode)

```html
<div id="user-1" hx-target="this" hx-swap="outerHTML">
  <p><strong>John Doe</strong> — john@example.com</p>
  <button hx-get="/users/1/edit">Edit</button>
</div>
```

### HTML (Edit Mode — returned by GET /users/1/edit)

```html
<form id="user-1" hx-put="/users/1" hx-target="this" hx-swap="outerHTML">
  <input name="name" value="John Doe">
  <input name="email" value="john@example.com">
  <button type="submit">Save</button>
  <button hx-get="/users/1" hx-target="#user-1" hx-swap="outerHTML">Cancel</button>
</form>
```

### Go Handler

```go
func userEditHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    user := db.GetUser(id)

    editTmpl := template.Must(template.New("edit").Parse(`
        <form id="user-{{.ID}}" hx-put="/users/{{.ID}}" hx-target="this" hx-swap="outerHTML">
            <input name="name" value="{{.Name}}">
            <input name="email" value="{{.Email}}">
            <button type="submit">Save</button>
            <button hx-get="/users/{{.ID}}" hx-target="#user-{{.ID}}" hx-swap="outerHTML">Cancel</button>
        </form>
    `))
    editTmpl.Execute(w, user)
}

func userUpdateHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    r.ParseForm()
    user := db.UpdateUser(id, r.FormValue("name"), r.FormValue("email"))

    displayTmpl := template.Must(template.New("display").Parse(`
        <div id="user-{{.ID}}" hx-target="this" hx-swap="outerHTML">
            <p><strong>{{.Name}}</strong> — {{.Email}}</p>
            <button hx-get="/users/{{.ID}}/edit">Edit</button>
        </div>
    `))
    displayTmpl.Execute(w, user)
}

func userViewHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    user := db.GetUser(id)
    // Same template as userUpdateHandler display
    displayTmpl := template.Must(template.New("display").Parse(`
        <div id="user-{{.ID}}" hx-target="this" hx-swap="outerHTML">
            <p><strong>{{.Name}}</strong> — {{.Email}}</p>
            <button hx-get="/users/{{.ID}}/edit">Edit</button>
        </div>
    `))
    displayTmpl.Execute(w, user)
}
```

---

## 4. Bulk Operations with Checkboxes

Select multiple items with checkboxes, then apply a bulk action.

### HTML

```html
<form id="bulk-form">
  <div id="bulk-actions" style="display:none;">
    <button hx-post="/items/bulk-delete"
            hx-include="#bulk-form"
            hx-target="#item-table"
            hx-confirm="Delete selected items?"
            hx-indicator="#bulk-spinner">
      Delete Selected
    </button>
    <span id="bulk-spinner" class="htmx-indicator">Processing...</span>
  </div>

  <table>
    <thead>
      <tr>
        <th><input type="checkbox" onclick="toggleAll(this)"></th>
        <th>Name</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody id="item-table">
      <tr>
        <td><input type="checkbox" name="ids" value="1" onchange="updateBulkUI()"></td>
        <td>Item 1</td>
        <td>Active</td>
      </tr>
      <tr>
        <td><input type="checkbox" name="ids" value="2" onchange="updateBulkUI()"></td>
        <td>Item 2</td>
        <td>Active</td>
      </tr>
    </tbody>
  </table>
</form>

<script>
function toggleAll(source) {
    document.querySelectorAll('input[name="ids"]').forEach(cb => cb.checked = source.checked);
    updateBulkUI();
}
function updateBulkUI() {
    const checked = document.querySelectorAll('input[name="ids"]:checked').length;
    document.getElementById('bulk-actions').style.display = checked > 0 ? 'block' : 'none';
}
</script>
```

### Go Handler

```go
func bulkDeleteHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseForm()
    ids := r.Form["ids"] // []string of selected IDs

    for _, id := range ids {
        db.DeleteItem(id)
    }

    // Return the updated table body
    items := db.GetAllItems()
    tmpl := template.Must(template.New("rows").Parse(`
        {{range .}}
        <tr>
            <td><input type="checkbox" name="ids" value="{{.ID}}" onchange="updateBulkUI()"></td>
            <td>{{.Name}}</td>
            <td>{{.Status}}</td>
        </tr>
        {{end}}
    `))
    tmpl.Execute(w, items)
}
```

---

## 5. Live Notifications via SSE

Real-time notification feed using Server-Sent Events.

### HTML

```html
<div hx-ext="sse" sse-connect="/notifications/stream">
  <span id="notif-count" class="badge">0</span>

  <div id="notification-feed" sse-swap="notification" hx-swap="afterbegin">
    <!-- New notifications prepended here -->
  </div>
</div>
```

### Go Handler

```go
type NotificationBroker struct {
    clients map[chan string]bool
    mu      sync.RWMutex
}

func (b *NotificationBroker) Subscribe() chan string {
    ch := make(chan string, 10)
    b.mu.Lock()
    b.clients[ch] = true
    b.mu.Unlock()
    return ch
}

func (b *NotificationBroker) Unsubscribe(ch chan string) {
    b.mu.Lock()
    delete(b.clients, ch)
    close(ch)
    b.mu.Unlock()
}

func (b *NotificationBroker) Publish(html string) {
    b.mu.RLock()
    defer b.mu.RUnlock()
    for ch := range b.clients {
        select {
        case ch <- html:
        default: // drop if full
        }
    }
}

func sseNotificationsHandler(broker *NotificationBroker) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "text/event-stream")
        w.Header().Set("Cache-Control", "no-cache")
        w.Header().Set("Connection", "keep-alive")

        flusher, ok := w.(http.Flusher)
        if !ok {
            http.Error(w, "Streaming not supported", http.StatusInternalServerError)
            return
        }

        ch := broker.Subscribe()
        defer broker.Unsubscribe(ch)

        for {
            select {
            case msg := <-ch:
                fmt.Fprintf(w, "event: notification\ndata: %s\n\n", msg)
                flusher.Flush()
            case <-r.Context().Done():
                return
            }
        }
    }
}

// When a notification is created:
func createNotification(broker *NotificationBroker, msg string) {
    html := fmt.Sprintf(`<div class="notification">%s <small>just now</small></div>`, msg)
    broker.Publish(html)
}
```

---

## 6. Modal Dialogs

Server-rendered modal that appears on button click. The modal HTML is loaded from the server.

### HTML (Page)

```html
<button hx-get="/modals/confirm-delete?id=5"
        hx-target="#modal-container"
        hx-swap="innerHTML">
  Delete Item
</button>

<div id="modal-container"></div>
```

### HTML (Modal Fragment — returned by server)

```html
<div class="modal-backdrop" _="on click remove closest .modal-backdrop">
  <div class="modal" _="on click halt">
    <h2>Confirm Deletion</h2>
    <p>Are you sure you want to delete this item?</p>
    <div class="modal-actions">
      <button hx-delete="/items/5"
              hx-target="#item-5"
              hx-swap="outerHTML"
              hx-on:htmx:after-request="document.querySelector('.modal-backdrop').remove()">
        Yes, Delete
      </button>
      <button _="on click remove closest .modal-backdrop">Cancel</button>
    </div>
  </div>
</div>
```

### Go Handler

```go
func modalConfirmDeleteHandler(w http.ResponseWriter, r *http.Request) {
    id := r.URL.Query().Get("id")
    item := db.GetItem(id)

    tmpl := template.Must(template.New("modal").Parse(`
        <div class="modal-backdrop" _="on click remove closest .modal-backdrop">
            <div class="modal" _="on click halt">
                <h2>Confirm Deletion</h2>
                <p>Delete "{{.Name}}"? This cannot be undone.</p>
                <div class="modal-actions">
                    <button hx-delete="/items/{{.ID}}"
                            hx-target="#item-{{.ID}}"
                            hx-swap="outerHTML"
                            hx-on:htmx:after-request="document.querySelector('.modal-backdrop').remove()">
                        Yes, Delete
                    </button>
                    <button _="on click remove closest .modal-backdrop">Cancel</button>
                </div>
            </div>
        </div>
    `))
    tmpl.Execute(w, item)
}
```

---

## 7. Tabs with Lazy Loading

Tab navigation where content is loaded only when the tab is clicked.

### HTML

```html
<div class="tabs" hx-target="#tab-content" hx-swap="innerHTML">
  <button hx-get="/tabs/overview" class="active"
          hx-on:htmx:after-request="activateTab(this)">Overview</button>
  <button hx-get="/tabs/details"
          hx-on:htmx:after-request="activateTab(this)">Details</button>
  <button hx-get="/tabs/history"
          hx-on:htmx:after-request="activateTab(this)">History</button>
</div>

<div id="tab-content" hx-get="/tabs/overview" hx-trigger="load">
  Loading...
</div>

<script>
function activateTab(btn) {
    document.querySelectorAll('.tabs button').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
}
</script>
```

### Go Handler

```go
func tabOverviewHandler(w http.ResponseWriter, r *http.Request) {
    data := db.GetOverview()
    tmpl := template.Must(template.New("tab").Parse(`
        <div class="tab-panel">
            <h3>Overview</h3>
            <p>Total items: {{.TotalItems}}</p>
            <p>Active: {{.ActiveItems}}</p>
        </div>
    `))
    tmpl.Execute(w, data)
}

func tabDetailsHandler(w http.ResponseWriter, r *http.Request) {
    details := db.GetDetails()
    tmpl := template.Must(template.New("tab").Parse(`
        <div class="tab-panel">
            <h3>Details</h3>
            <table>
                {{range .}}
                <tr><td>{{.Key}}</td><td>{{.Value}}</td></tr>
                {{end}}
            </table>
        </div>
    `))
    tmpl.Execute(w, details)
}
```

---

## 8. File Upload with Progress

Multipart file upload with a progress bar updated via SSE.

### HTML

```html
<form hx-post="/upload"
      hx-encoding="multipart/form-data"
      hx-target="#upload-result"
      hx-indicator="#upload-spinner">
  <input type="file" name="file" required>
  <button type="submit">Upload</button>
  <span id="upload-spinner" class="htmx-indicator">Uploading...</span>
</form>

<div id="upload-result"></div>

<!-- For real-time progress, use SSE after form submit -->
<div id="progress-container" style="display:none;"
     hx-ext="sse" sse-connect="/upload/progress" sse-swap="progress">
  <div class="progress-bar">
    <div class="progress-fill" style="width: 0%">0%</div>
  </div>
</div>
```

### Go Handler

```go
func uploadHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseMultipartForm(32 << 20) // 32MB max
    file, header, err := r.FormFile("file")
    if err != nil {
        http.Error(w, "Upload failed", http.StatusBadRequest)
        return
    }
    defer file.Close()

    dst, err := os.Create(filepath.Join("uploads", header.Filename))
    if err != nil {
        http.Error(w, "Save failed", http.StatusInternalServerError)
        return
    }
    defer dst.Close()

    _, err = io.Copy(dst, file)
    if err != nil {
        http.Error(w, "Write failed", http.StatusInternalServerError)
        return
    }

    fmt.Fprintf(w, `<div class="success">Uploaded %s (%d bytes)</div>`,
        html.EscapeString(header.Filename), header.Size)
}
```

---

## 9. Toast Notifications via OOB Swaps

Server actions return a toast notification appended OOB alongside the primary response.

### HTML (Page Layout)

```html
<div id="toast-container" class="toast-container"></div>

<!-- Any action that needs feedback -->
<button hx-post="/items" hx-target="#item-list" hx-swap="beforeend"
        hx-vals='{"name": "New Item"}'>
  Add Item
</button>

<div id="item-list">
  <!-- Items here -->
</div>

<style>
.toast-container { position: fixed; top: 1rem; right: 1rem; z-index: 1000; }
.toast { padding: 0.75rem 1rem; margin-bottom: 0.5rem; border-radius: 4px;
         background: #333; color: #fff; animation: fadeIn 0.3s; }
.toast.success { background: #16a34a; }
.toast.error { background: #dc2626; }
</style>
```

### Go Handler

```go
func createItemHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseForm()
    name := r.FormValue("name")
    item := db.CreateItem(name)

    // Primary response: the new item row
    tmpl := template.Must(template.New("response").Parse(`
        <div class="item" id="item-{{.ID}}">{{.Name}}</div>

        <!-- OOB toast notification -->
        <div id="toast-container" hx-swap-oob="beforeend">
            <div class="toast success" remove-me="3s">
                Item "{{.Name}}" created!
            </div>
        </div>
    `))
    tmpl.Execute(w, item)
}
```

Alternative approach using HX-Trigger header:

```go
func createItemAltHandler(w http.ResponseWriter, r *http.Request) {
    r.ParseForm()
    item := db.CreateItem(r.FormValue("name"))

    // Trigger a custom event the client listens for
    w.Header().Set("HX-Trigger", `{"showToast": {"message": "Item created!", "type": "success"}}`)

    tmpl.Execute(w, item) // just the item HTML
}
```

Client-side listener:

```javascript
document.body.addEventListener('showToast', function(evt) {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${evt.detail.type}`;
    toast.textContent = evt.detail.message;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
});
```

---

## 10. Sortable and Filterable Tables

Column sorting and filtering, all server-driven.

### HTML

```html
<div id="table-controls">
  <input type="search" name="q"
         hx-get="/users/table"
         hx-trigger="input changed delay:300ms"
         hx-target="#user-table-wrapper"
         hx-include="#table-controls"
         placeholder="Filter...">

  <select name="status"
          hx-get="/users/table"
          hx-trigger="change"
          hx-target="#user-table-wrapper"
          hx-include="#table-controls">
    <option value="">All Statuses</option>
    <option value="active">Active</option>
    <option value="inactive">Inactive</option>
  </select>

  <input type="hidden" name="sort" value="name" id="sort-field">
  <input type="hidden" name="order" value="asc" id="sort-order">
</div>

<div id="user-table-wrapper">
  <table>
    <thead>
      <tr>
        <th hx-get="/users/table"
            hx-target="#user-table-wrapper"
            hx-include="#table-controls"
            hx-vals='{"sort": "name"}'
            style="cursor:pointer">
          Name
        </th>
        <th hx-get="/users/table"
            hx-target="#user-table-wrapper"
            hx-include="#table-controls"
            hx-vals='{"sort": "email"}'
            style="cursor:pointer">
          Email
        </th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody id="user-rows">
      <!-- Server-rendered rows -->
    </tbody>
  </table>
</div>
```

### Go Handler

```go
func userTableHandler(w http.ResponseWriter, r *http.Request) {
    q := r.URL.Query().Get("q")
    status := r.URL.Query().Get("status")
    sortField := r.URL.Query().Get("sort")
    order := r.URL.Query().Get("order")

    if sortField == "" { sortField = "name" }
    if order == "" { order = "asc" }

    // Toggle order if same column clicked again
    newOrder := "asc"
    if order == "asc" { newOrder = "desc" }

    users := db.QueryUsers(q, status, sortField, order)

    tmpl := template.Must(template.New("table").Parse(`
        <table>
            <thead>
                <tr>
                    <th hx-get="/users/table"
                        hx-target="#user-table-wrapper"
                        hx-include="#table-controls"
                        hx-vals='{"sort": "name", "order": "{{if eq .Sort "name"}}{{.NewOrder}}{{else}}asc{{end}}"}'
                        style="cursor:pointer">
                        Name {{if eq .Sort "name"}}{{if eq .Order "asc"}}↑{{else}}↓{{end}}{{end}}
                    </th>
                    <th hx-get="/users/table"
                        hx-target="#user-table-wrapper"
                        hx-include="#table-controls"
                        hx-vals='{"sort": "email", "order": "{{if eq .Sort "email"}}{{.NewOrder}}{{else}}asc{{end}}"}'
                        style="cursor:pointer">
                        Email {{if eq .Sort "email"}}{{if eq .Order "asc"}}↑{{else}}↓{{end}}{{end}}
                    </th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                {{range .Users}}
                <tr>
                    <td>{{.Name}}</td>
                    <td>{{.Email}}</td>
                    <td>{{.Status}}</td>
                </tr>
                {{end}}
                {{if not .Users}}
                <tr><td colspan="3">No users found</td></tr>
                {{end}}
            </tbody>
        </table>
    `))

    data := struct {
        Users    []User
        Sort     string
        Order    string
        NewOrder string
    }{users, sortField, order, newOrder}

    tmpl.Execute(w, data)
}
```

---

## Bonus Patterns

### Inline Validation

```html
<input name="email" type="email"
       hx-post="/validate/email"
       hx-trigger="blur changed"
       hx-target="next .error"
       hx-swap="innerHTML">
<span class="error"></span>
```

```go
func validateEmailHandler(w http.ResponseWriter, r *http.Request) {
    email := r.FormValue("email")
    if !isValidEmail(email) {
        fmt.Fprint(w, `<span class="text-red">Invalid email address</span>`)
        return
    }
    if db.EmailExists(email) {
        fmt.Fprint(w, `<span class="text-red">Email already taken</span>`)
        return
    }
    fmt.Fprint(w, `<span class="text-green">Available</span>`)
}
```

### Delete Row with Fade Out

```html
<tr id="row-5">
  <td>Item 5</td>
  <td>
    <button hx-delete="/items/5"
            hx-target="closest tr"
            hx-swap="outerHTML swap:500ms"
            hx-confirm="Delete this item?">
      Delete
    </button>
  </td>
</tr>

<style>
tr.htmx-swapping { opacity: 0; transition: opacity 500ms ease-out; }
</style>
```

```go
func deleteItemHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    db.DeleteItem(id)
    // Return empty response — outerHTML swap with empty replaces the row
    w.WriteHeader(http.StatusOK)
}
```

### Cascading Selects

```html
<select name="country"
        hx-get="/regions"
        hx-trigger="change"
        hx-target="#region-select">
  <option value="">Select Country</option>
  <option value="US">United States</option>
  <option value="IT">Italy</option>
</select>

<select id="region-select" name="region">
  <option value="">Select Country First</option>
</select>
```

```go
func regionsHandler(w http.ResponseWriter, r *http.Request) {
    country := r.URL.Query().Get("country")
    regions := db.GetRegions(country)

    tmpl := template.Must(template.New("opts").Parse(`
        <select id="region-select" name="region">
            <option value="">Select Region</option>
            {{range .}}
            <option value="{{.Code}}">{{.Name}}</option>
            {{end}}
        </select>
    `))
    tmpl.Execute(w, regions)
}
```

### Progress Bar with Polling

```html
<div hx-get="/jobs/123/progress"
     hx-trigger="every 1s"
     hx-target="this"
     hx-swap="innerHTML">
  <div class="progress-bar">
    <div class="progress-fill" style="width: 0%">0%</div>
  </div>
</div>
```

```go
func jobProgressHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    job := db.GetJob(id)

    if job.Progress >= 100 {
        // Return 286 to stop polling
        w.WriteHeader(286)
        fmt.Fprint(w, `<div class="success">Job complete!</div>`)
        return
    }

    fmt.Fprintf(w, `
        <div class="progress-bar">
            <div class="progress-fill" style="width: %d%%">%d%%</div>
        </div>
    `, job.Progress, job.Progress)
}
```

### Lazy Loading

```html
<div hx-get="/dashboard/chart"
     hx-trigger="load"
     hx-swap="outerHTML">
  <div class="skeleton-loader">Loading chart...</div>
</div>

<div hx-get="/dashboard/stats"
     hx-trigger="revealed"
     hx-swap="outerHTML">
  <div class="skeleton-loader">Loading stats...</div>
</div>
```

```go
func dashboardChartHandler(w http.ResponseWriter, r *http.Request) {
    data := db.GetChartData()
    tmpl := template.Must(template.New("chart").Parse(`
        <div id="chart">
            <!-- Rendered chart HTML -->
            <canvas data-values="{{.Values}}"></canvas>
        </div>
    `))
    tmpl.Execute(w, data)
}
```
