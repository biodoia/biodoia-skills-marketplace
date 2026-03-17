# SQLite Vector Storage Patterns

Advanced patterns for storing and querying embedding vectors in SQLite, optimized for Go applications.

## Binary Encoding Performance

### BLOB vs JSON Text Storage

Vectors stored as binary BLOBs (little-endian float64) are significantly more compact and faster to deserialize than JSON text.

| Format | 1024-dim size | Encode time | Decode time |
|---|---|---|---|
| Binary BLOB | 8,192 bytes | ~2 us | ~1 us |
| JSON text | ~20,000 bytes | ~50 us | ~80 us |
| Base64 BLOB | ~11,000 bytes | ~5 us | ~4 us |

Always use binary BLOB encoding for production. JSON is acceptable only for debugging.

### Encoding Implementation

```go
import (
    "encoding/binary"
    "math"
)

// encodeVector serializes a float64 slice to a compact binary representation.
// Layout: consecutive little-endian IEEE 754 float64 values, no header.
func encodeVector(v []float64) []byte {
    buf := make([]byte, len(v)*8)
    for i, f := range v {
        binary.LittleEndian.PutUint64(buf[i*8:], math.Float64bits(f))
    }
    return buf
}

// decodeVector deserializes a binary BLOB back to a float64 slice.
func decodeVector(b []byte) []float64 {
    n := len(b) / 8
    v := make([]float64, n)
    for i := range v {
        v[i] = math.Float64frombits(binary.LittleEndian.Uint64(b[i*8:]))
    }
    return v
}
```

### Float32 Optimization

For large collections where storage matters more than precision, use float32 (halves storage, negligible quality loss for cosine similarity):

```go
func encodeVectorF32(v []float64) []byte {
    buf := make([]byte, len(v)*4)
    for i, f := range v {
        binary.LittleEndian.PutUint32(buf[i*4:], math.Float32bits(float32(f)))
    }
    return buf
}

func decodeVectorF32(b []byte) []float64 {
    n := len(b) / 4
    v := make([]float64, n)
    for i := range v {
        v[i] = float64(math.Float32frombits(binary.LittleEndian.Uint32(b[i*4:])))
    }
    return v
}
```

| Precision | 1024-dim | 100K vectors | Quality impact |
|---|---|---|---|
| float64 | 8,192 bytes | ~780 MB | Baseline |
| float32 | 4,096 bytes | ~390 MB | Negligible (<0.1% retrieval loss) |

## Schema Patterns

### Basic Schema

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
```

### With Full-Text Search Hybrid

Combine vector search with SQLite FTS5 for hybrid retrieval:

```sql
CREATE VIRTUAL TABLE IF NOT EXISTS embeddings_fts USING fts5(
    text,
    content='embeddings',
    content_rowid='rowid'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS embeddings_ai AFTER INSERT ON embeddings BEGIN
    INSERT INTO embeddings_fts(rowid, text) VALUES (new.rowid, new.text);
END;

CREATE TRIGGER IF NOT EXISTS embeddings_ad AFTER DELETE ON embeddings BEGIN
    INSERT INTO embeddings_fts(embeddings_fts, rowid, text) VALUES('delete', old.rowid, old.text);
END;

CREATE TRIGGER IF NOT EXISTS embeddings_au AFTER UPDATE ON embeddings BEGIN
    INSERT INTO embeddings_fts(embeddings_fts, rowid, text) VALUES('delete', old.rowid, old.text);
    INSERT INTO embeddings_fts(rowid, text) VALUES (new.rowid, new.text);
END;
```

### Hybrid Search Query

```go
func (m *MemoryStore) HybridSearch(ctx context.Context, query string, namespace string, topK int) ([]SearchResult, error) {
    // 1. FTS candidates (keyword match)
    ftsRows, err := m.db.QueryContext(ctx,
        `SELECT e.id, e.text, e.vector, e.metadata,
                rank * -1.0 as fts_score
         FROM embeddings_fts f
         JOIN embeddings e ON e.rowid = f.rowid
         WHERE embeddings_fts MATCH ? AND e.namespace = ?
         ORDER BY rank LIMIT ?`,
        query, namespace, topK*3)
    // ... process FTS results ...

    // 2. Vector candidates (semantic match)
    vecResults, err := m.Search(ctx, query, SearchOptions{
        Namespace: namespace,
        TopK:      topK * 3,
    })
    // ... process vector results ...

    // 3. Reciprocal Rank Fusion (RRF) to combine
    return reciprocalRankFusion(ftsResults, vecResults, topK), nil
}

func reciprocalRankFusion(lists ...[]SearchResult) []SearchResult {
    const k = 60 // RRF constant
    scores := make(map[string]float64)
    entries := make(map[string]MemoryEntry)

    for _, list := range lists {
        for rank, result := range list {
            scores[result.Entry.ID] += 1.0 / float64(k+rank+1)
            entries[result.Entry.ID] = result.Entry
        }
    }
    // Sort by fused score and return top results
    // ...
}
```

## Performance Tuning

### SQLite Pragmas for Vector Workloads

```go
pragmas := []string{
    "PRAGMA journal_mode=WAL",        // concurrent reads during writes
    "PRAGMA synchronous=NORMAL",      // safe with WAL, faster than FULL
    "PRAGMA cache_size=-64000",       // 64 MB page cache (negative = KB)
    "PRAGMA mmap_size=268435456",     // 256 MB memory-mapped I/O
    "PRAGMA temp_store=MEMORY",       // temp tables in memory
    "PRAGMA page_size=8192",          // larger pages for BLOB workloads
}
```

### Batch Insert Performance

Use prepared statements in transactions for bulk loading:

```go
func (m *MemoryStore) BulkInsert(ctx context.Context, entries []MemoryEntry) error {
    tx, err := m.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    stmt, err := tx.PrepareContext(ctx,
        `INSERT OR REPLACE INTO embeddings
         (id, namespace, text, vector, metadata, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`)
    if err != nil {
        return err
    }
    defer stmt.Close()

    now := time.Now()
    for _, e := range entries {
        meta, _ := json.Marshal(e.Metadata)
        if _, err := stmt.ExecContext(ctx, e.ID, e.Namespace, e.Text,
            encodeVector(e.Vector), string(meta), now, now); err != nil {
            return err
        }
    }
    return tx.Commit()
}
```

Typical throughput: 10,000-50,000 inserts/second with WAL mode and prepared statements.

### Search Scan Performance

Brute-force cosine similarity scans are I/O-bound when vectors do not fit in the page cache. Performance benchmarks on typical hardware:

| Collection size | 1024-dim scan time | With namespace filter |
|---|---|---|
| 1,000 | < 1 ms | < 1 ms |
| 10,000 | ~5 ms | ~2 ms |
| 100,000 | ~50 ms | ~15 ms |
| 1,000,000 | ~500 ms | ~150 ms |

For collections exceeding 100K vectors, consider namespace sharding or the sqlite-vec extension.

## Namespace Sharding

For very large deployments, shard namespaces across separate SQLite files:

```go
type ShardedMemoryStore struct {
    baseDir string
    shards  map[string]*MemoryStore
    voyage  *VoyageStore
    mu      sync.RWMutex
}

func (s *ShardedMemoryStore) getShard(namespace string) (*MemoryStore, error) {
    s.mu.RLock()
    if shard, ok := s.shards[namespace]; ok {
        s.mu.RUnlock()
        return shard, nil
    }
    s.mu.RUnlock()

    s.mu.Lock()
    defer s.mu.Unlock()

    // Double-check after acquiring write lock
    if shard, ok := s.shards[namespace]; ok {
        return shard, nil
    }

    dbPath := filepath.Join(s.baseDir, namespace+".db")
    shard, err := NewMemoryStore(dbPath, s.voyage)
    if err != nil {
        return nil, err
    }
    s.shards[namespace] = shard
    return shard, nil
}
```

Benefits of sharding:
- Each namespace scan only touches its own database file
- Independent WAL files prevent write contention across namespaces
- Easy namespace deletion (delete the file)
- Better OS page cache utilization

## sqlite-vec Extension

For approximate nearest neighbor (ANN) search at scale, the `sqlite-vec` extension adds native vector operations to SQLite.

### Installation

```bash
# Build from source
git clone https://github.com/asg017/sqlite-vec.git
cd sqlite-vec && make

# Or download prebuilt
# Available for Linux, macOS, Windows
```

### Schema with sqlite-vec

```sql
-- Load extension
.load ./vec0

-- Create virtual table for vector search
CREATE VIRTUAL TABLE IF NOT EXISTS vec_embeddings USING vec0(
    id TEXT PRIMARY KEY,
    vector float[1024]  -- 1024 dimensions
);

-- Keep metadata in a regular table
CREATE TABLE IF NOT EXISTS embedding_meta (
    id          TEXT PRIMARY KEY,
    namespace   TEXT NOT NULL,
    text        TEXT NOT NULL,
    metadata    TEXT NOT NULL DEFAULT '{}',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### KNN Query with sqlite-vec

```sql
-- Find 10 nearest neighbors
SELECT m.id, m.text, m.metadata, v.distance
FROM vec_embeddings v
JOIN embedding_meta m ON m.id = v.id
WHERE v.vector MATCH ?  -- bind the query vector
  AND k = 10            -- top-k
ORDER BY v.distance;
```

### Go Integration with sqlite-vec

```go
import (
    "database/sql"
    _ "github.com/mattn/go-sqlite3"
)

func init() {
    // Register sqlite-vec extension
    sql.Register("sqlite3_vec",
        &sqlite3.SQLiteDriver{
            Extensions: []string{"./vec0"},
        },
    )
}

func (m *MemoryStore) SearchVec(ctx context.Context, queryVec []float64, topK int) ([]SearchResult, error) {
    rows, err := m.db.QueryContext(ctx,
        `SELECT m.id, m.text, m.metadata, v.distance
         FROM vec_embeddings v
         JOIN embedding_meta m ON m.id = v.id
         WHERE v.vector MATCH ?
           AND k = ?
         ORDER BY v.distance`,
        serializeForVec(queryVec), topK,
    )
    // ... scan results ...
}
```

## Migration Scripts

### Add Namespace Column (if upgrading from no-namespace schema)

```sql
-- Check if column exists first
SELECT COUNT(*) FROM pragma_table_info('embeddings') WHERE name='namespace';

-- Add if missing
ALTER TABLE embeddings ADD COLUMN namespace TEXT NOT NULL DEFAULT 'default';
CREATE INDEX IF NOT EXISTS idx_embeddings_namespace ON embeddings(namespace);
```

### Add TTL Support

```sql
ALTER TABLE embeddings ADD COLUMN expires_at DATETIME;
CREATE INDEX IF NOT EXISTS idx_embeddings_expires ON embeddings(expires_at);
```

### Migrate JSON Vectors to Binary BLOBs

```go
func migrateJSONToBinary(db *sql.DB) error {
    rows, err := db.Query(`SELECT id, vector FROM embeddings_old`)
    if err != nil {
        return err
    }
    defer rows.Close()

    tx, _ := db.Begin()
    stmt, _ := tx.Prepare(`UPDATE embeddings SET vector = ? WHERE id = ?`)

    for rows.Next() {
        var id, vecJSON string
        rows.Scan(&id, &vecJSON)

        var vec []float64
        json.Unmarshal([]byte(vecJSON), &vec)

        stmt.Exec(encodeVector(vec), id)
    }
    return tx.Commit()
}
```

## Backup and Durability

### Online Backup

SQLite's backup API allows copying the database while it is being read/written:

```go
func (m *MemoryStore) Backup(ctx context.Context, destPath string) error {
    _, err := m.db.ExecContext(ctx, `VACUUM INTO ?`, destPath)
    return err
}
```

`VACUUM INTO` creates a consistent, compacted copy without locking the source database.

### WAL Checkpoint

Periodically checkpoint the WAL to keep the WAL file from growing unbounded:

```go
func (m *MemoryStore) Checkpoint() error {
    _, err := m.db.Exec(`PRAGMA wal_checkpoint(TRUNCATE)`)
    return err
}
```

Run checkpoints during low-traffic periods or after bulk inserts.
