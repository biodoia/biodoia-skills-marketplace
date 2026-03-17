---
name: voyage-memory
description: Voyage AI embedding API, SQLite-backed persistent vector storage, semantic similarity search, namespace management, and Go MCP server integration patterns. Use when the user mentions Voyage AI, vector storage, embedding persistence, cosine similarity, semantic memory, or permanent memory systems.
---

# Voyage AI Memory Management

Voyage AI provides state-of-the-art text embeddings optimized for retrieval and semantic search. This skill covers the full lifecycle of embedding-backed permanent memory: generating embeddings via the Voyage AI API, persisting them in SQLite with metadata and namespaces, performing cosine similarity search, and managing the stored data over time. All patterns target Go implementations aligned with the AutoSchei ecosystem.

## Voyage AI Embedding API

### Endpoint and Authentication

The embedding endpoint is `https://api.voyageai.com/v1/embeddings`. Authenticate with a Bearer token in the Authorization header.

```go
const voyageEmbedURL = "https://api.voyageai.com/v1/embeddings"

req, err := http.NewRequestWithContext(ctx, http.MethodPost, voyageEmbedURL, bytes.NewReader(body))
req.Header.Set("Content-Type", "application/json")
req.Header.Set("Authorization", "Bearer "+apiKey)
```

### Models

| Model | Dimensions | Max Tokens | Best For |
|---|---|---|---|
| `voyage-3-large` | 1024 | 32000 | General-purpose retrieval, highest quality |
| `voyage-3` | 1024 | 32000 | General-purpose, balanced cost/quality |
| `voyage-3-lite` | 512 | 32000 | Lightweight, lower latency |
| `voyage-code-3` | 1024 | 32000 | Code search, code-related queries |
| `voyage-finance-2` | 1024 | 32000 | Financial documents |
| `voyage-law-2` | 1024 | 32000 | Legal documents |

For MCP servers and general memory systems, use `voyage-3-large`. For codebases and developer tools, use `voyage-code-3`.

### Input Types

Voyage AI distinguishes between document and query embeddings. This asymmetry improves retrieval quality.

- `"document"` -- use when embedding text for storage (the corpus)
- `"query"` -- use when embedding a search query (the question)

Always set the correct input type. Mixing them degrades search quality.

### Request Format

```go
type voyageEmbedRequest struct {
    Input     []string `json:"input"`
    Model     string   `json:"model"`
    InputType string   `json:"input_type"`
}

type voyageEmbedResponse struct {
    Data []struct {
        Embedding []float64 `json:"embedding"`
        Index     int       `json:"index"`
    } `json:"data"`
    Usage struct {
        TotalTokens int `json:"total_tokens"`
    } `json:"usage"`
}
```

### Batching

Voyage AI accepts up to 128 texts per request and up to 320,000 tokens per batch. Batch embedding calls to minimize round-trips.

```go
const maxBatchSize = 128

func (v *VoyageStore) EmbedBatch(ctx context.Context, texts []string, inputType string) ([][]float64, error) {
    var allEmbeddings [][]float64

    for i := 0; i < len(texts); i += maxBatchSize {
        end := i + maxBatchSize
        if end > len(texts) {
            end = len(texts)
        }
        batch := texts[i:end]

        embeddings, err := v.Embed(ctx, batch, inputType)
        if err != nil {
            return nil, fmt.Errorf("batch %d-%d: %w", i, end, err)
        }
        allEmbeddings = append(allEmbeddings, embeddings...)
    }
    return allEmbeddings, nil
}
```

### Rate Limiting

Voyage AI enforces rate limits per API key. Handle 429 responses with exponential backoff.

```go
func (v *VoyageStore) embedWithRetry(ctx context.Context, texts []string, inputType string) ([][]float64, error) {
    var lastErr error
    for attempt := 0; attempt < 3; attempt++ {
        embeddings, err := v.Embed(ctx, texts, inputType)
        if err == nil {
            return embeddings, nil
        }
        if !isRateLimited(err) {
            return nil, err
        }
        lastErr = err
        backoff := time.Duration(1<<uint(attempt)) * time.Second
        select {
        case <-ctx.Done():
            return nil, ctx.Err()
        case <-time.After(backoff):
        }
    }
    return nil, fmt.Errorf("rate limited after retries: %w", lastErr)
}

func isRateLimited(err error) bool {
    return err != nil && strings.Contains(err.Error(), "429")
}
```

## Persistent Storage with SQLite

### Schema Design

Store embeddings in SQLite with metadata, namespace support, and timestamps for lifecycle management. Vectors are stored as JSON-encoded float64 arrays (SQLite has no native vector type, but this is efficient for sub-million-scale collections).

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

CREATE INDEX IF NOT EXISTS idx_embeddings_namespace ON embeddings(namespace);
CREATE INDEX IF NOT EXISTS idx_embeddings_expires ON embeddings(expires_at);
CREATE INDEX IF NOT EXISTS idx_embeddings_created ON embeddings(created_at);
```

Vectors are stored as BLOB (binary-encoded float64 slices) for compactness and faster deserialization compared to JSON text.

### Go Storage Implementation

```go
package storage

import (
    "database/sql"
    "encoding/binary"
    "encoding/json"
    "fmt"
    "math"
    "time"

    _ "github.com/mattn/go-sqlite3"
)

type MemoryStore struct {
    db     *sql.DB
    voyage *VoyageStore
}

type MemoryEntry struct {
    ID        string            `json:"id"`
    Namespace string            `json:"namespace"`
    Text      string            `json:"text"`
    Vector    []float64         `json:"vector,omitempty"`
    Metadata  map[string]string `json:"metadata"`
    CreatedAt time.Time         `json:"created_at"`
    UpdatedAt time.Time         `json:"updated_at"`
    ExpiresAt *time.Time        `json:"expires_at,omitempty"`
}

type SearchResult struct {
    Entry      MemoryEntry `json:"entry"`
    Similarity float64     `json:"similarity"`
}

func NewMemoryStore(dbPath string, voyage *VoyageStore) (*MemoryStore, error) {
    db, err := sql.Open("sqlite3", dbPath+"?_journal=WAL&_busy_timeout=5000")
    if err != nil {
        return nil, fmt.Errorf("memory store: open: %w", err)
    }

    // Performance pragmas for embedding workloads
    pragmas := []string{
        "PRAGMA journal_mode=WAL",
        "PRAGMA synchronous=NORMAL",
        "PRAGMA cache_size=-64000",   // 64MB cache
        "PRAGMA mmap_size=268435456", // 256MB mmap
    }
    for _, p := range pragmas {
        if _, err := db.Exec(p); err != nil {
            db.Close()
            return nil, fmt.Errorf("pragma %s: %w", p, err)
        }
    }

    store := &MemoryStore{db: db, voyage: voyage}
    if err := store.migrate(); err != nil {
        db.Close()
        return nil, err
    }
    return store, nil
}

func (m *MemoryStore) migrate() error {
    schema := `
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
    CREATE INDEX IF NOT EXISTS idx_embeddings_namespace ON embeddings(namespace);
    CREATE INDEX IF NOT EXISTS idx_embeddings_expires ON embeddings(expires_at);
    CREATE INDEX IF NOT EXISTS idx_embeddings_created ON embeddings(created_at);
    `
    _, err := m.db.Exec(schema)
    return err
}
```

### Vector Serialization

Encode float64 slices to binary for compact BLOB storage. A 1024-dimension vector occupies 8KB as binary versus approximately 20KB as JSON text.

```go
func encodeVector(v []float64) []byte {
    buf := make([]byte, len(v)*8)
    for i, f := range v {
        binary.LittleEndian.PutUint64(buf[i*8:], math.Float64bits(f))
    }
    return buf
}

func decodeVector(b []byte) []float64 {
    v := make([]float64, len(b)/8)
    for i := range v {
        v[i] = math.Float64frombits(binary.LittleEndian.Uint64(b[i*8:]))
    }
    return v
}
```

## CRUD Operations

### Store (Create/Update)

```go
func (m *MemoryStore) Store(ctx context.Context, entry MemoryEntry) error {
    // Generate embedding from text
    vectors, err := m.voyage.Embed(ctx, []string{entry.Text}, "document")
    if err != nil {
        return fmt.Errorf("embed: %w", err)
    }
    entry.Vector = vectors[0]

    metadata, _ := json.Marshal(entry.Metadata)
    vectorBlob := encodeVector(entry.Vector)

    _, err = m.db.ExecContext(ctx,
        `INSERT INTO embeddings (id, namespace, text, vector, metadata, created_at, updated_at, expires_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
             text = excluded.text,
             vector = excluded.vector,
             metadata = excluded.metadata,
             updated_at = excluded.updated_at,
             expires_at = excluded.expires_at`,
        entry.ID, entry.Namespace, entry.Text, vectorBlob,
        string(metadata), time.Now(), time.Now(), entry.ExpiresAt,
    )
    return err
}
```

### Store Batch

```go
func (m *MemoryStore) StoreBatch(ctx context.Context, entries []MemoryEntry) error {
    // Collect texts for batch embedding
    texts := make([]string, len(entries))
    for i, e := range entries {
        texts[i] = e.Text
    }

    // Batch embed
    vectors, err := m.voyage.EmbedBatch(ctx, texts, "document")
    if err != nil {
        return fmt.Errorf("batch embed: %w", err)
    }

    // Store in a transaction
    tx, err := m.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    stmt, err := tx.PrepareContext(ctx,
        `INSERT INTO embeddings (id, namespace, text, vector, metadata, created_at, updated_at, expires_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
             text = excluded.text, vector = excluded.vector,
             metadata = excluded.metadata, updated_at = excluded.updated_at,
             expires_at = excluded.expires_at`)
    if err != nil {
        return err
    }
    defer stmt.Close()

    now := time.Now()
    for i, entry := range entries {
        metadata, _ := json.Marshal(entry.Metadata)
        _, err := stmt.ExecContext(ctx,
            entry.ID, entry.Namespace, entry.Text,
            encodeVector(vectors[i]), string(metadata),
            now, now, entry.ExpiresAt,
        )
        if err != nil {
            return fmt.Errorf("insert %s: %w", entry.ID, err)
        }
    }
    return tx.Commit()
}
```

### Retrieve (Read)

```go
func (m *MemoryStore) Get(ctx context.Context, id string) (*MemoryEntry, error) {
    var entry MemoryEntry
    var metadataStr string
    var vectorBlob []byte

    err := m.db.QueryRowContext(ctx,
        `SELECT id, namespace, text, vector, metadata, created_at, updated_at, expires_at
         FROM embeddings WHERE id = ?`, id,
    ).Scan(&entry.ID, &entry.Namespace, &entry.Text, &vectorBlob,
        &metadataStr, &entry.CreatedAt, &entry.UpdatedAt, &entry.ExpiresAt)
    if err != nil {
        return nil, err
    }

    entry.Vector = decodeVector(vectorBlob)
    json.Unmarshal([]byte(metadataStr), &entry.Metadata)
    return &entry, nil
}

func (m *MemoryStore) ListByNamespace(ctx context.Context, namespace string, limit int) ([]MemoryEntry, error) {
    rows, err := m.db.QueryContext(ctx,
        `SELECT id, namespace, text, metadata, created_at, updated_at, expires_at
         FROM embeddings WHERE namespace = ? ORDER BY updated_at DESC LIMIT ?`,
        namespace, limit,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var entries []MemoryEntry
    for rows.Next() {
        var e MemoryEntry
        var metadataStr string
        if err := rows.Scan(&e.ID, &e.Namespace, &e.Text, &metadataStr,
            &e.CreatedAt, &e.UpdatedAt, &e.ExpiresAt); err != nil {
            return nil, err
        }
        json.Unmarshal([]byte(metadataStr), &e.Metadata)
        entries = append(entries, e)
    }
    return entries, nil
}
```

### Delete

```go
func (m *MemoryStore) Delete(ctx context.Context, id string) error {
    result, err := m.db.ExecContext(ctx, `DELETE FROM embeddings WHERE id = ?`, id)
    if err != nil {
        return err
    }
    affected, _ := result.RowsAffected()
    if affected == 0 {
        return fmt.Errorf("embedding %s not found", id)
    }
    return nil
}

func (m *MemoryStore) DeleteByNamespace(ctx context.Context, namespace string) (int64, error) {
    result, err := m.db.ExecContext(ctx,
        `DELETE FROM embeddings WHERE namespace = ?`, namespace)
    if err != nil {
        return 0, err
    }
    return result.RowsAffected()
}
```

### TTL / Cleanup

```go
func (m *MemoryStore) CleanExpired(ctx context.Context) (int64, error) {
    result, err := m.db.ExecContext(ctx,
        `DELETE FROM embeddings WHERE expires_at IS NOT NULL AND expires_at < ?`,
        time.Now(),
    )
    if err != nil {
        return 0, err
    }
    return result.RowsAffected()
}

// SetTTL sets an expiration time on an existing entry.
func (m *MemoryStore) SetTTL(ctx context.Context, id string, ttl time.Duration) error {
    expiresAt := time.Now().Add(ttl)
    _, err := m.db.ExecContext(ctx,
        `UPDATE embeddings SET expires_at = ? WHERE id = ?`, expiresAt, id)
    return err
}
```

## Semantic Search

### Cosine Similarity

```go
func CosineSimilarity(a, b []float64) float64 {
    if len(a) != len(b) || len(a) == 0 {
        return 0
    }
    var dot, normA, normB float64
    for i := range a {
        dot += a[i] * b[i]
        normA += a[i] * a[i]
        normB += b[i] * b[i]
    }
    if normA == 0 || normB == 0 {
        return 0
    }
    return dot / (math.Sqrt(normA) * math.Sqrt(normB))
}
```

### Search Implementation

Search embeds the query with input_type "query" (asymmetric retrieval), then computes cosine similarity against all vectors in the target namespace. Results are sorted by similarity descending.

```go
type SearchOptions struct {
    Namespace    string            // filter to this namespace ("" for all)
    TopK         int               // max results (default 10)
    MinScore     float64           // minimum similarity threshold (0.0 - 1.0)
    MetadataFilter map[string]string // filter by metadata key-value pairs
}

func (m *MemoryStore) Search(ctx context.Context, query string, opts SearchOptions) ([]SearchResult, error) {
    if opts.TopK <= 0 {
        opts.TopK = 10
    }

    // Embed query with "query" input type for asymmetric retrieval
    vectors, err := m.voyage.Embed(ctx, []string{query}, "query")
    if err != nil {
        return nil, fmt.Errorf("embed query: %w", err)
    }
    queryVec := vectors[0]

    // Load candidate vectors
    var rows *sql.Rows
    if opts.Namespace != "" {
        rows, err = m.db.QueryContext(ctx,
            `SELECT id, namespace, text, vector, metadata, created_at, updated_at, expires_at
             FROM embeddings
             WHERE namespace = ? AND (expires_at IS NULL OR expires_at > ?)`,
            opts.Namespace, time.Now())
    } else {
        rows, err = m.db.QueryContext(ctx,
            `SELECT id, namespace, text, vector, metadata, created_at, updated_at, expires_at
             FROM embeddings
             WHERE expires_at IS NULL OR expires_at > ?`,
            time.Now())
    }
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var results []SearchResult
    for rows.Next() {
        var entry MemoryEntry
        var vectorBlob []byte
        var metadataStr string

        if err := rows.Scan(&entry.ID, &entry.Namespace, &entry.Text, &vectorBlob,
            &metadataStr, &entry.CreatedAt, &entry.UpdatedAt, &entry.ExpiresAt); err != nil {
            return nil, err
        }

        json.Unmarshal([]byte(metadataStr), &entry.Metadata)

        // Apply metadata filter
        if !matchesMetadata(entry.Metadata, opts.MetadataFilter) {
            continue
        }

        vec := decodeVector(vectorBlob)
        sim := CosineSimilarity(queryVec, vec)

        if sim >= opts.MinScore {
            results = append(results, SearchResult{
                Entry:      entry,
                Similarity: sim,
            })
        }
    }

    // Sort by similarity descending
    sort.Slice(results, func(i, j int) bool {
        return results[i].Similarity > results[j].Similarity
    })

    // Truncate to top-k
    if len(results) > opts.TopK {
        results = results[:opts.TopK]
    }
    return results, nil
}

func matchesMetadata(meta, filter map[string]string) bool {
    for k, v := range filter {
        if meta[k] != v {
            return false
        }
    }
    return true
}
```

### Search Performance

For collections under 100,000 vectors, brute-force cosine similarity in Go is fast enough (sub-100ms on modern hardware for 1024-dimension vectors). For larger collections:

- Prefilter by namespace to reduce the candidate set
- Use metadata filters to narrow scope before computing similarity
- Consider sharding namespaces across separate SQLite databases
- For million-scale, migrate to a dedicated vector database (Qdrant, Milvus) or use SQLite with the `sqlite-vec` extension

## Namespace Organization

Namespaces partition the embedding space for multi-tenant or multi-purpose memory systems.

### Common Namespace Patterns

| Namespace | Purpose |
|---|---|
| `conversations/{session_id}` | Per-session conversation memory |
| `knowledge/{topic}` | Domain knowledge base |
| `code/{repo}` | Code snippet embeddings |
| `user/{user_id}` | Per-user personalization |
| `system/instructions` | System-level persistent instructions |

### Namespace Management

```go
func (m *MemoryStore) ListNamespaces(ctx context.Context) ([]string, error) {
    rows, err := m.db.QueryContext(ctx,
        `SELECT DISTINCT namespace FROM embeddings ORDER BY namespace`)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var namespaces []string
    for rows.Next() {
        var ns string
        if err := rows.Scan(&ns); err != nil {
            return nil, err
        }
        namespaces = append(namespaces, ns)
    }
    return namespaces, nil
}

func (m *MemoryStore) NamespaceStats(ctx context.Context, namespace string) (count int, totalSize int64, err error) {
    err = m.db.QueryRowContext(ctx,
        `SELECT COUNT(*), COALESCE(SUM(LENGTH(vector)), 0)
         FROM embeddings WHERE namespace = ?`, namespace,
    ).Scan(&count, &totalSize)
    return
}
```

## Model Selection Guide

### voyage-3-large vs voyage-code-3

Use `voyage-3-large` as the default for general text memory. Use `voyage-code-3` when the memory system stores or retrieves code-related content (source code, stack traces, API documentation, technical specifications).

Do not mix models within the same namespace. Vectors from different models are incompatible -- cosine similarity between them is meaningless.

### Dimensionality and Storage Costs

| Model | Dimensions | Bytes per Vector | 100K vectors |
|---|---|---|---|
| `voyage-3-large` | 1024 | 8,192 | ~780 MB |
| `voyage-3` | 1024 | 8,192 | ~780 MB |
| `voyage-3-lite` | 512 | 4,096 | ~390 MB |

Include text and metadata overhead when estimating total database size. A typical entry with 500-character text, 1024-dim vector, and minimal metadata occupies approximately 10 KB.

## Integration with MCP Servers

### Memory Tools Pattern

Expose memory operations as MCP tools for Claude to call directly.

```go
func registerMemoryTools(s *server.MCPServer, mem *MemoryStore) {
    s.AddTool(mcp.NewTool("memory_store",
        mcp.WithDescription("Store text in permanent semantic memory"),
        mcp.WithString("id", mcp.Required(), mcp.Description("Unique identifier")),
        mcp.WithString("text", mcp.Required(), mcp.Description("Text to remember")),
        mcp.WithString("namespace", mcp.Description("Memory namespace")),
    ), handleMemoryStore(mem))

    s.AddTool(mcp.NewTool("memory_search",
        mcp.WithDescription("Search semantic memory by meaning"),
        mcp.WithString("query", mcp.Required(), mcp.Description("Search query")),
        mcp.WithString("namespace", mcp.Description("Namespace to search")),
        mcp.WithNumber("top_k", mcp.Description("Max results")),
    ), handleMemorySearch(mem))

    s.AddTool(mcp.NewTool("memory_delete",
        mcp.WithDescription("Delete a memory entry"),
        mcp.WithString("id", mcp.Required(), mcp.Description("Entry ID to delete")),
    ), handleMemoryDelete(mem))
}
```

### Startup Pattern

Initialize the memory store at server startup alongside the existing SQLite store.

```go
func main() {
    voyageStore := storage.NewVoyageStore(os.Getenv("VOYAGE_API_KEY"), "voyage-3-large")
    memoryStore, err := storage.NewMemoryStore("memory.db", voyageStore)
    if err != nil {
        log.Fatal(err)
    }
    defer memoryStore.Close()

    // Start periodic cleanup
    go func() {
        ticker := time.NewTicker(1 * time.Hour)
        defer ticker.Stop()
        for range ticker.C {
            cleaned, _ := memoryStore.CleanExpired(context.Background())
            if cleaned > 0 {
                log.Printf("cleaned %d expired embeddings", cleaned)
            }
        }
    }()

    // Register MCP tools...
}
```

## Best Practices Summary

1. **Always use the correct input_type** -- "document" for storage, "query" for search. This is critical for Voyage AI's asymmetric retrieval quality.
2. **Batch embedding calls** -- send up to 128 texts per API call to reduce latency and stay within rate limits.
3. **Store vectors as binary BLOBs** -- 2.5x more compact than JSON text encoding.
4. **Use WAL mode** -- SQLite WAL journal mode allows concurrent reads during writes, essential for MCP servers handling simultaneous requests.
5. **Namespace everything** -- partition by purpose, session, or user to keep search scopes focused and results relevant.
6. **Do not mix embedding models** in the same namespace -- vectors from different models are incompatible.
7. **Set TTLs on ephemeral data** -- conversation memory and session data should expire; knowledge base entries should not.
8. **Run cleanup periodically** -- a background goroutine cleaning expired entries every hour prevents unbounded growth.
9. **Handle rate limits gracefully** -- implement exponential backoff on 429 responses from the Voyage AI API.
10. **Keep the HTTP client timeout generous** -- embedding large batches can take several seconds; 60 seconds is a safe timeout.

## Additional Resources

Consult these reference files for deeper coverage beyond this skill's body:

- **`references/voyage-api.md`** -- Complete Voyage AI API reference covering all embedding models, request/response schemas, error codes, rate limits, and token counting. Consult when integrating with the Voyage AI API or troubleshooting embedding requests.
- **`references/sqlite-vector-patterns.md`** -- Advanced SQLite patterns for vector workloads: binary encoding benchmarks, indexing strategies, sharding by namespace, migration scripts, and integration with the sqlite-vec extension for approximate nearest neighbor search. Consult when optimizing storage performance or scaling beyond brute-force search.
