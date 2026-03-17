# Voyage AI API Reference

Complete reference for the Voyage AI embedding API as used in Go memory systems.

## Authentication

All requests require an API key passed as a Bearer token:

```
Authorization: Bearer <VOYAGE_API_KEY>
```

Obtain keys from https://dash.voyageai.com/. Keys are scoped per organization.

## Embeddings Endpoint

**POST** `https://api.voyageai.com/v1/embeddings`

### Request Body

```json
{
  "input": ["text to embed", "another text"],
  "model": "voyage-3-large",
  "input_type": "document",
  "truncation": true,
  "encoding_format": "float"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `input` | `string[]` | Yes | Array of texts to embed. Max 128 items. |
| `model` | `string` | Yes | Model identifier (see Models section). |
| `input_type` | `string` | No | `"document"` or `"query"`. Affects embedding optimization. |
| `truncation` | `bool` | No | If true, truncate inputs exceeding max tokens. Default true. |
| `encoding_format` | `string` | No | `"float"` (default) or `"base64"`. |

### Response Body

```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "index": 0,
      "embedding": [0.0123, -0.0456, ...]
    }
  ],
  "model": "voyage-3-large",
  "usage": {
    "total_tokens": 42
  }
}
```

The `data` array preserves input order via the `index` field. Always use `index` to map embeddings back to inputs, as the API may return results out of order for parallel processing.

## Models

### General Purpose

| Model | Dimensions | Context | Price (per 1M tokens) | Notes |
|---|---|---|---|---|
| `voyage-3-large` | 1024 | 32,000 | $0.06 | Highest quality general-purpose |
| `voyage-3` | 1024 | 32,000 | $0.03 | Balanced quality/cost |
| `voyage-3-lite` | 512 | 32,000 | $0.02 | Fast, lower dimensionality |

### Domain-Specific

| Model | Dimensions | Context | Price (per 1M tokens) | Notes |
|---|---|---|---|---|
| `voyage-code-3` | 1024 | 32,000 | $0.06 | Optimized for source code |
| `voyage-finance-2` | 1024 | 32,000 | $0.06 | Financial documents |
| `voyage-law-2` | 1024 | 32,000 | $0.06 | Legal documents |

### Model Selection Decision Tree

1. Embedding source code or technical docs? Use `voyage-code-3`.
2. Need highest retrieval quality? Use `voyage-3-large`.
3. Cost-sensitive with acceptable quality? Use `voyage-3`.
4. Need minimal latency or storage? Use `voyage-3-lite`.
5. Domain-specific (finance/law)? Use the domain model.

## Batch Limits

| Limit | Value |
|---|---|
| Max texts per request | 128 |
| Max tokens per request | 320,000 |
| Max single text length | 32,000 tokens |

If a single text exceeds the model's context window and `truncation` is false, the API returns an error. With `truncation: true` (default), it silently truncates.

### Token Estimation

Voyage AI uses a BPE tokenizer similar to OpenAI's. Rough estimate: 1 token is approximately 4 characters or 0.75 words in English. For precise counting, use the Voyage tokenizer endpoint or count locally with tiktoken as an approximation.

## Rate Limits

Rate limits vary by plan:

| Plan | Requests/min | Tokens/min |
|---|---|---|
| Free | 300 | 1,000,000 |
| Pro | 1,000 | 10,000,000 |
| Enterprise | Custom | Custom |

When rate limited, the API returns HTTP 429 with a `Retry-After` header.

### Go Rate Limit Handler

```go
func (v *VoyageStore) Embed(ctx context.Context, texts []string, inputType string) ([][]float64, error) {
    // ... build and send request ...

    if resp.StatusCode == http.StatusTooManyRequests {
        retryAfter := resp.Header.Get("Retry-After")
        return nil, fmt.Errorf("voyage: rate limited, retry after %s", retryAfter)
    }

    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("voyage: API error %d: %s", resp.StatusCode, string(body))
    }
    // ... decode response ...
}
```

## Error Codes

| HTTP Status | Meaning | Action |
|---|---|---|
| 200 | Success | Process response |
| 400 | Bad request | Check input format, model name, parameter values |
| 401 | Unauthorized | Check API key |
| 403 | Forbidden | Check plan permissions |
| 404 | Not found | Check endpoint URL |
| 422 | Validation error | Input too long, invalid model, etc. |
| 429 | Rate limited | Backoff and retry using Retry-After header |
| 500 | Server error | Retry with backoff |
| 503 | Service unavailable | Retry with backoff |

## Input Type Semantics

The `input_type` parameter enables asymmetric embedding, where documents and queries are embedded differently for optimal retrieval.

- **"document"**: optimizes the embedding for the stored corpus. Use when embedding text that will be searched against later.
- **"query"**: optimizes the embedding for matching against documents. Use when embedding the user's search query.
- **Omitted/null**: symmetric embedding. Use for clustering, classification, or when the same text serves as both document and query.

Mixing input types within a search operation (query vs. document) is the intended usage. Mixing input types within a stored collection (some documents stored as "query" type) corrupts retrieval quality.

## Go Client Pattern

Complete production client with batching, retries, and rate limit handling:

```go
type VoyageClient struct {
    apiKey     string
    model      string
    httpClient *http.Client
    limiter    *rate.Limiter  // golang.org/x/time/rate
}

func NewVoyageClient(apiKey, model string) *VoyageClient {
    return &VoyageClient{
        apiKey:     apiKey,
        model:      model,
        httpClient: &http.Client{Timeout: 60 * time.Second},
        limiter:    rate.NewLimiter(rate.Limit(4), 8), // 4 req/s with burst of 8
    }
}

func (c *VoyageClient) EmbedWithRetry(ctx context.Context, texts []string, inputType string) ([][]float64, error) {
    if err := c.limiter.Wait(ctx); err != nil {
        return nil, err
    }

    var allEmbeddings [][]float64
    for i := 0; i < len(texts); i += 128 {
        end := min(i+128, len(texts))
        batch := texts[i:end]

        var embeddings [][]float64
        var lastErr error

        for attempt := 0; attempt < 3; attempt++ {
            embeddings, lastErr = c.embed(ctx, batch, inputType)
            if lastErr == nil {
                break
            }
            if !isRetryable(lastErr) {
                return nil, lastErr
            }
            select {
            case <-ctx.Done():
                return nil, ctx.Err()
            case <-time.After(time.Duration(1<<uint(attempt)) * time.Second):
            }
        }
        if lastErr != nil {
            return nil, lastErr
        }
        allEmbeddings = append(allEmbeddings, embeddings...)
    }
    return allEmbeddings, nil
}
```

## Tokenization Endpoint

**POST** `https://api.voyageai.com/v1/tokenize`

```json
{
  "input": ["text to count tokens for"],
  "model": "voyage-3-large"
}
```

Response includes token counts per input. Use this to pre-check inputs that may exceed the context window before embedding.
