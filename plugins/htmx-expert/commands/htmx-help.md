---
description: Quick HTMX reference — look up attributes, events, patterns, and server integration
argument-hint: <topic> (e.g. "hx-trigger", "oob swaps", "sse", "events", "go templates", "infinite scroll")
allowed-tools: ["Read", "Bash", "Glob", "Grep"]
---

# HTMX Quick Help

Provide quick reference information about HTMX based on the user's topic.

**Arguments:** $ARGUMENTS

## Workflow

1. Parse the topic from arguments. If no arguments provided, show a brief overview of available topics.
2. Based on the topic, provide the relevant information:

### Topic Routing

- **Attributes** (`hx-get`, `hx-post`, `hx-trigger`, `hx-target`, `hx-swap`, etc.): Read `references/attributes-reference.md` from the htmx-expert skill and show the relevant attribute section with examples.
- **Events** (`events`, `htmx:beforeRequest`, `HX-Trigger header`, etc.): Show the Events section from the main SKILL.md.
- **OOB** (`oob`, `out-of-band`, `hx-swap-oob`): Show Out-of-Band Swaps section with examples.
- **SSE** (`sse`, `server-sent events`, `sse-connect`): Show SSE section with server implementation.
- **WebSocket** (`ws`, `websocket`, `ws-connect`): Show WebSocket section.
- **Extensions** (`extensions`, `json-enc`, `preload`, `response-targets`): Show Extensions section.
- **Server** (`server`, `headers`, `HX-Request`, `response headers`): Show Server Integration section.
- **Patterns** (`pattern`, `search`, `infinite scroll`, `modal`, `tabs`, `toast`, etc.): Read `references/patterns-cookbook.md` and show the matching pattern with HTML + Go code.
- **Go** (`go`, `templ`, `template`, `chi`, `echo`): Show Go + HTMX section.
- **Python** (`python`, `django`, `flask`, `fastapi`): Show Python + HTMX section.
- **CSS** (`css`, `classes`, `transitions`, `htmx-request`): Show CSS Integration section.
- **Troubleshooting** (`debug`, `troubleshoot`, `common mistakes`): Show Troubleshooting section.
- **hyperscript** (`hyperscript`, `_hyperscript`, `_=`): Show _hyperscript section.

3. Always include a practical code example with the explanation.
4. If the topic is ambiguous, show the most likely match and mention related topics.

## Available Topics Summary

If no topic is provided, show this list:

```
HTMX Quick Reference Topics:
  Attributes:     hx-get, hx-post, hx-trigger, hx-target, hx-swap, hx-vals, hx-headers, hx-include, hx-boost, hx-push-url, hx-confirm, hx-indicator, hx-select, hx-swap-oob, hx-sync, hx-on, hx-ext, hx-disabled-elt, hx-encoding, hx-preserve, hx-disinherit, hx-history, hx-params, hx-prompt, hx-validate
  Events:         htmx:beforeRequest, htmx:afterSwap, htmx:configRequest, HX-Trigger header
  OOB Swaps:      hx-swap-oob, multiple OOB, toast patterns
  SSE:            sse-connect, sse-swap, Go/Python SSE server
  WebSocket:      ws-connect, ws-send, chat patterns
  Extensions:     sse, ws, json-enc, preload, response-targets, class-tools, remove-me, loading-states
  Server:         Request/response headers, partial HTML, status codes (204, 286)
  Patterns:       search, infinite-scroll, click-to-edit, bulk-ops, modal, tabs, toast, file-upload, sort-table, validation, cascading-selects, progress-bar, lazy-loading, delete-row
  Go:             html/template, templ, Chi/Echo handlers, framegotui
  Python:         Django, Flask, FastAPI + HTMX
  CSS:            htmx-request class, transitions, indicators
  Troubleshoot:   htmx.logAll(), common mistakes, performance
  Hyperscript:    _hyperscript syntax and patterns
```
