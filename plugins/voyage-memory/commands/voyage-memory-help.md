---
description: Quick Voyage AI memory reference -- show embedding patterns, storage schema, search implementation, or help with a specific memory topic
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Voyage Memory Help

Provide quick help for Voyage AI memory management based on what the user asks. If no specific topic is given, show a general quick-reference covering the most common tasks.

## Steps

1. Determine what the user needs help with (embedding API, storage schema, search, CRUD operations, namespace management, model selection, or general).
2. If they ask about their current project state, examine Go files related to storage and embeddings.
3. Provide a focused, actionable response with code examples.

## Gathering Project State

If the user wants help with their Voyage AI memory project, check for relevant files:

```bash
find . -name "*.go" -type f | xargs grep -l "voyage\|VoyageStore\|embedding\|Embed" 2>/dev/null | head -20
```

```bash
find . -name "*.db" -type f 2>/dev/null | head -10
```

```bash
grep -r "VOYAGE_API_KEY" .env* 2>/dev/null || echo "No .env with VOYAGE_API_KEY found"
```

```bash
cat go.mod 2>/dev/null | head -20
```

## Quick Reference

### Voyage AI Embed Call

```go
reqBody := voyageEmbedRequest{
    Input:     texts,
    Model:     "voyage-3-large",
    InputType: "document", // or "query" for search queries
}
```

### Model Selection

| Use Case | Model |
|---|---|
| General memory | `voyage-3-large` |
| Code search | `voyage-code-3` |
| Budget-friendly | `voyage-3` |
| Minimal storage | `voyage-3-lite` |

### Storage Schema

```sql
CREATE TABLE IF NOT EXISTS embeddings (
    id          TEXT PRIMARY KEY,
    namespace   TEXT NOT NULL DEFAULT 'default',
    text        TEXT NOT NULL,
    vector      BLOB NOT NULL,
    metadata    TEXT NOT NULL DEFAULT '{}',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at  DATETIME
);
```

### Binary Vector Encoding

```go
func encodeVector(v []float64) []byte {
    buf := make([]byte, len(v)*8)
    for i, f := range v {
        binary.LittleEndian.PutUint64(buf[i*8:], math.Float64bits(f))
    }
    return buf
}
```

### Search Pattern

```go
// 1. Embed query with "query" type
vectors, _ := voyage.Embed(ctx, []string{query}, "query")
queryVec := vectors[0]

// 2. Load vectors from namespace
// 3. Compute CosineSimilarity(queryVec, storedVec)
// 4. Sort by similarity descending, take top-k
```

### Batch Limits

- Max 128 texts per API call
- Max 320,000 tokens per batch
- Max 32,000 tokens per single text

### SQLite Pragmas

```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=-64000;
PRAGMA mmap_size=268435456;
```

### Cleanup Expired Entries

```sql
DELETE FROM embeddings WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;
```
