# gRPC Implementation Patterns

Comprehensive patterns for building production-grade gRPC services.

## Service Definition Best Practices

### Resource-Oriented Design

Follow Google's API Design Guide (AIP) principles. Design services around resources, not actions:

```protobuf
syntax = "proto3";
package myapp.v1;

import "google/protobuf/empty.proto";
import "google/protobuf/field_mask.proto";
import "google/protobuf/timestamp.proto";

service BookService {
  rpc GetBook(GetBookRequest) returns (Book);
  rpc ListBooks(ListBooksRequest) returns (ListBooksResponse);
  rpc CreateBook(CreateBookRequest) returns (Book);
  rpc UpdateBook(UpdateBookRequest) returns (Book);
  rpc DeleteBook(DeleteBookRequest) returns (google.protobuf.Empty);
}

message Book {
  string name = 1;          // "shelves/shelf1/books/book1"
  string display_name = 2;
  string author = 3;
  string isbn = 4;
  google.protobuf.Timestamp create_time = 5;
  google.protobuf.Timestamp update_time = 6;
}

message GetBookRequest {
  string name = 1;  // resource name
}

message ListBooksRequest {
  string parent = 1;        // "shelves/shelf1"
  int32 page_size = 2;
  string page_token = 3;
}

message ListBooksResponse {
  repeated Book books = 1;
  string next_page_token = 2;
}

message CreateBookRequest {
  string parent = 1;
  Book book = 2;
  string book_id = 3;  // optional client-assigned ID
}

message UpdateBookRequest {
  Book book = 1;
  google.protobuf.FieldMask update_mask = 2;
}

message DeleteBookRequest {
  string name = 1;
}
```

### Method Naming Conventions

| Operation | Method Name | HTTP Mapping |
|---|---|---|
| Get single | `GetBook` | `GET /v1/{name=shelves/*/books/*}` |
| List collection | `ListBooks` | `GET /v1/{parent=shelves/*}/books` |
| Create | `CreateBook` | `POST /v1/{parent=shelves/*}/books` |
| Update | `UpdateBook` | `PATCH /v1/{book.name=shelves/*/books/*}` |
| Delete | `DeleteBook` | `DELETE /v1/{name=shelves/*/books/*}` |
| Custom | `ArchiveBook` | `POST /v1/{name=shelves/*/books/*}:archive` |

## Error Handling Patterns

### Structured Error Responses

Use `google.rpc.Status` with typed error details for machine-readable errors:

```go
import (
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
    "google.golang.org/genproto/googleapis/rpc/errdetails"
)

// Validation error with field violations
func validationError(violations []*errdetails.BadRequest_FieldViolation) error {
    st := status.New(codes.InvalidArgument, "validation failed")
    br := &errdetails.BadRequest{FieldViolations: violations}
    st, err := st.WithDetails(br)
    if err != nil {
        return status.Error(codes.Internal, "failed to attach error details")
    }
    return st.Err()
}

// Usage
return nil, validationError([]*errdetails.BadRequest_FieldViolation{
    {Field: "email", Description: "must be a valid email address"},
    {Field: "name", Description: "must not be empty"},
})
```

### Error Code Selection Guide

```go
// Use InvalidArgument for client-provided bad input
status.Error(codes.InvalidArgument, "page_size must be > 0")

// Use NotFound when a specific resource doesn't exist
status.Errorf(codes.NotFound, "book %q not found", name)

// Use AlreadyExists for create conflicts
status.Errorf(codes.AlreadyExists, "book %q already exists", name)

// Use FailedPrecondition when system state prevents the operation
status.Error(codes.FailedPrecondition, "account is suspended")

// Use PermissionDenied when the caller lacks permission (authenticated but not authorized)
status.Error(codes.PermissionDenied, "caller cannot delete this book")

// Use Unauthenticated when there are no valid credentials
status.Error(codes.Unauthenticated, "missing or invalid token")

// Use ResourceExhausted for rate limiting or quota
status.Error(codes.ResourceExhausted, "rate limit exceeded, retry after 30s")

// Use Unavailable for transient failures (client should retry)
status.Error(codes.Unavailable, "service temporarily unavailable")

// Use Internal for unexpected server errors (bugs)
status.Error(codes.Internal, "unexpected nil pointer")

// Use Unimplemented for methods not yet available
status.Error(codes.Unimplemented, "UpdateBook is not implemented")

// Use DeadlineExceeded only if you detect the deadline will be missed
// (gRPC automatically returns this when the deadline passes)
```

### Client-Side Error Handling

```go
resp, err := client.GetBook(ctx, req)
if err != nil {
    st, ok := status.FromError(err)
    if !ok {
        // Not a gRPC error
        log.Fatalf("non-gRPC error: %v", err)
    }

    switch st.Code() {
    case codes.NotFound:
        log.Printf("book not found: %s", st.Message())
    case codes.InvalidArgument:
        // Extract error details
        for _, detail := range st.Details() {
            if br, ok := detail.(*errdetails.BadRequest); ok {
                for _, v := range br.GetFieldViolations() {
                    log.Printf("field %s: %s", v.GetField(), v.GetDescription())
                }
            }
        }
    case codes.Unavailable:
        // Retry logic
        log.Printf("service unavailable, retrying...")
    default:
        log.Printf("RPC error: code=%s message=%s", st.Code(), st.Message())
    }
}
```

## Interceptor Chain Patterns

### Logging Interceptor

```go
func loggingUnaryInterceptor(
    ctx context.Context,
    req any,
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (any, error) {
    start := time.Now()
    resp, err := handler(ctx, req)
    duration := time.Since(start)

    code := codes.OK
    if err != nil {
        if st, ok := status.FromError(err); ok {
            code = st.Code()
        }
    }

    log.Printf("grpc unary method=%s code=%s duration=%s",
        info.FullMethod, code, duration)

    return resp, err
}
```

### Authentication Interceptor

```go
func authUnaryInterceptor(
    ctx context.Context,
    req any,
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (any, error) {
    // Skip auth for health checks
    if info.FullMethod == "/grpc.health.v1.Health/Check" {
        return handler(ctx, req)
    }

    md, ok := metadata.FromIncomingContext(ctx)
    if !ok {
        return nil, status.Error(codes.Unauthenticated, "missing metadata")
    }

    authHeader := md.Get("authorization")
    if len(authHeader) == 0 {
        return nil, status.Error(codes.Unauthenticated, "missing authorization header")
    }

    token := strings.TrimPrefix(authHeader[0], "Bearer ")
    claims, err := validateToken(token)
    if err != nil {
        return nil, status.Errorf(codes.Unauthenticated, "invalid token: %v", err)
    }

    // Add claims to context for downstream handlers
    ctx = context.WithValue(ctx, claimsKey{}, claims)
    return handler(ctx, req)
}
```

### Recovery Interceptor (Panic Handler)

```go
func recoveryUnaryInterceptor(
    ctx context.Context,
    req any,
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (resp any, err error) {
    defer func() {
        if r := recover(); r != nil {
            log.Printf("PANIC in %s: %v\n%s", info.FullMethod, r, debug.Stack())
            err = status.Errorf(codes.Internal, "internal server error")
        }
    }()
    return handler(ctx, req)
}
```

### Metrics Interceptor (Prometheus)

```go
var (
    grpcRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "grpc_requests_total"},
        []string{"method", "code"},
    )
    grpcRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "grpc_request_duration_seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method"},
    )
)

func metricsUnaryInterceptor(
    ctx context.Context,
    req any,
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (any, error) {
    start := time.Now()
    resp, err := handler(ctx, req)

    code := codes.OK
    if st, ok := status.FromError(err); ok {
        code = st.Code()
    }

    grpcRequestsTotal.WithLabelValues(info.FullMethod, code.String()).Inc()
    grpcRequestDuration.WithLabelValues(info.FullMethod).Observe(time.Since(start).Seconds())

    return resp, err
}
```

### Chaining Interceptors

```go
s := grpc.NewServer(
    grpc.ChainUnaryInterceptor(
        recoveryUnaryInterceptor,   // outermost: catch panics
        loggingUnaryInterceptor,    // log all requests
        metricsUnaryInterceptor,    // record metrics
        authUnaryInterceptor,       // authenticate
    ),
    grpc.ChainStreamInterceptor(
        recoveryStreamInterceptor,
        loggingStreamInterceptor,
        authStreamInterceptor,
    ),
)
```

Order matters: interceptors execute from first to last. Place recovery first (outermost), then logging, then auth.

## Streaming Patterns

### Server Streaming: Fan-Out (Event Broadcast)

```go
// Proto
// rpc WatchEvents(WatchRequest) returns (stream Event);

type eventServer struct {
    mu          sync.RWMutex
    subscribers map[string][]chan *pb.Event
}

func (s *eventServer) WatchEvents(req *pb.WatchRequest, stream pb.EventService_WatchEventsServer) error {
    ch := make(chan *pb.Event, 100)

    s.mu.Lock()
    s.subscribers[req.Topic] = append(s.subscribers[req.Topic], ch)
    s.mu.Unlock()

    defer func() {
        s.mu.Lock()
        subs := s.subscribers[req.Topic]
        for i, sub := range subs {
            if sub == ch {
                s.subscribers[req.Topic] = append(subs[:i], subs[i+1:]...)
                break
            }
        }
        s.mu.Unlock()
        close(ch)
    }()

    for {
        select {
        case event := <-ch:
            if err := stream.Send(event); err != nil {
                return err
            }
        case <-stream.Context().Done():
            return stream.Context().Err()
        }
    }
}

// Publish to all watchers
func (s *eventServer) publish(topic string, event *pb.Event) {
    s.mu.RLock()
    defer s.mu.RUnlock()
    for _, ch := range s.subscribers[topic] {
        select {
        case ch <- event:
        default:
            // subscriber too slow, drop event
        }
    }
}
```

### Client Streaming: Fan-In (Batch Upload)

```go
// Proto
// rpc UploadMetrics(stream Metric) returns (UploadResponse);

func (s *server) UploadMetrics(stream pb.MetricService_UploadMetricsServer) error {
    var count int32
    var batch []*pb.Metric

    for {
        metric, err := stream.Recv()
        if err == io.EOF {
            // Client done sending, process final batch
            if len(batch) > 0 {
                if err := s.processBatch(batch); err != nil {
                    return status.Errorf(codes.Internal, "batch processing failed: %v", err)
                }
            }
            return stream.SendAndClose(&pb.UploadResponse{
                ReceivedCount: count,
            })
        }
        if err != nil {
            return err
        }

        batch = append(batch, metric)
        count++

        // Process in batches of 100
        if len(batch) >= 100 {
            if err := s.processBatch(batch); err != nil {
                return status.Errorf(codes.Internal, "batch processing failed: %v", err)
            }
            batch = batch[:0]
        }
    }
}
```

### Bidirectional Streaming: Chat

```go
// Proto
// rpc Chat(stream ChatMessage) returns (stream ChatMessage);

func (s *server) Chat(stream pb.ChatService_ChatServer) error {
    // Read user ID from metadata
    md, _ := metadata.FromIncomingContext(stream.Context())
    userID := md.Get("user-id")[0]

    // Register this stream
    s.registerClient(userID, stream)
    defer s.unregisterClient(userID)

    for {
        msg, err := stream.Recv()
        if err == io.EOF {
            return nil
        }
        if err != nil {
            return err
        }

        // Broadcast to other clients
        msg.SenderId = userID
        msg.Timestamp = timestamppb.Now()
        s.broadcast(msg, userID)
    }
}

func (s *server) broadcast(msg *pb.ChatMessage, senderID string) {
    s.mu.RLock()
    defer s.mu.RUnlock()
    for id, stream := range s.clients {
        if id != senderID {
            // Best-effort send; if client is slow, skip
            _ = stream.Send(msg)
        }
    }
}
```

### Streaming with Backpressure

```go
func (s *server) StreamData(req *pb.StreamRequest, stream pb.DataService_StreamDataServer) error {
    cursor := s.newCursor(req)
    defer cursor.Close()

    for cursor.Next() {
        // stream.Send blocks if the client is slow (HTTP/2 flow control)
        // This naturally provides backpressure
        if err := stream.Send(cursor.Item()); err != nil {
            return err
        }

        // Check for cancellation periodically
        if stream.Context().Err() != nil {
            return stream.Context().Err()
        }
    }
    return cursor.Err()
}
```

## gRPC-Gateway REST Transcoding

### Setup

Add HTTP annotations to your proto file:

```protobuf
syntax = "proto3";
package myapp.v1;

import "google/api/annotations.proto";

service BookService {
  rpc GetBook(GetBookRequest) returns (Book) {
    option (google.api.http) = {
      get: "/v1/{name=shelves/*/books/*}"
    };
  }

  rpc ListBooks(ListBooksRequest) returns (ListBooksResponse) {
    option (google.api.http) = {
      get: "/v1/{parent=shelves/*}/books"
    };
  }

  rpc CreateBook(CreateBookRequest) returns (Book) {
    option (google.api.http) = {
      post: "/v1/{parent=shelves/*}/books"
      body: "book"
    };
  }

  rpc UpdateBook(UpdateBookRequest) returns (Book) {
    option (google.api.http) = {
      patch: "/v1/{book.name=shelves/*/books/*}"
      body: "book"
    };
  }

  rpc DeleteBook(DeleteBookRequest) returns (google.protobuf.Empty) {
    option (google.api.http) = {
      delete: "/v1/{name=shelves/*/books/*}"
    };
  }
}
```

### buf.gen.yaml for Gateway

```yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: gen
    opt: paths=source_relative
  - remote: buf.build/grpc/go
    out: gen
    opt: paths=source_relative
  - remote: buf.build/grpc-ecosystem/gateway
    out: gen
    opt: paths=source_relative
  - remote: buf.build/grpc-ecosystem/openapiv2
    out: gen/openapiv2
```

### Gateway Server (Go)

```go
import (
    "github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    gw "myapp/gen/myapp/v1"
)

func runGateway() error {
    ctx := context.Background()
    mux := runtime.NewServeMux(
        runtime.WithMarshalerOption(runtime.MIMEWildcard, &runtime.JSONPb{
            MarshalOptions: protojson.MarshalOptions{
                EmitUnpopulated: true,
            },
        }),
    )

    opts := []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
    err := gw.RegisterBookServiceHandlerFromEndpoint(ctx, mux, "localhost:50051", opts)
    if err != nil {
        return err
    }

    log.Println("gRPC-Gateway listening on :8080")
    return http.ListenAndServe(":8080", mux)
}
```

### In-Process Gateway (No Separate Port)

Serve gRPC and REST on the same port using `cmux` or HTTP handler switching:

```go
func main() {
    grpcServer := grpc.NewServer()
    pb.RegisterBookServiceServer(grpcServer, &bookServer{})

    gwMux := runtime.NewServeMux()
    pb.RegisterBookServiceHandlerServer(context.Background(), gwMux, &bookServer{})

    // Route based on content type
    handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.ProtoMajor == 2 && strings.HasPrefix(
            r.Header.Get("Content-Type"), "application/grpc") {
            grpcServer.ServeHTTP(w, r)
        } else {
            gwMux.ServeHTTP(w, r)
        }
    })

    http.ListenAndServeTLS(":443", "cert.pem", "key.pem",
        h2c.NewHandler(handler, &http2.Server{}))
}
```

## Health Checking and Graceful Shutdown

### Health Check Server

```go
import (
    "google.golang.org/grpc/health"
    healthpb "google.golang.org/grpc/health/grpc_health_v1"
)

func main() {
    s := grpc.NewServer()

    // Register your services
    pb.RegisterBookServiceServer(s, &bookServer{})

    // Register health service
    healthServer := health.NewServer()
    healthpb.RegisterHealthServer(s, healthServer)

    // Set status per service
    healthServer.SetServingStatus("myapp.v1.BookService",
        healthpb.HealthCheckResponse_SERVING)

    // Set overall status
    healthServer.SetServingStatus("",
        healthpb.HealthCheckResponse_SERVING)

    // Check health with grpcurl:
    // grpcurl -plaintext localhost:50051 grpc.health.v1.Health/Check
    // grpcurl -plaintext -d '{"service":"myapp.v1.BookService"}' \
    //     localhost:50051 grpc.health.v1.Health/Check
}
```

### Graceful Shutdown

```go
func main() {
    lis, _ := net.Listen("tcp", ":50051")
    s := grpc.NewServer()
    pb.RegisterBookServiceServer(s, &bookServer{})

    healthServer := health.NewServer()
    healthpb.RegisterHealthServer(s, healthServer)
    healthServer.SetServingStatus("", healthpb.HealthCheckResponse_SERVING)

    // Start serving in a goroutine
    go func() {
        if err := s.Serve(lis); err != nil {
            log.Fatalf("failed to serve: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("shutting down...")

    // Mark as not serving (load balancers will stop sending traffic)
    healthServer.SetServingStatus("", healthpb.HealthCheckResponse_NOT_SERVING)

    // Give load balancers time to detect the change
    time.Sleep(5 * time.Second)

    // Gracefully stop: finish in-flight RPCs, reject new ones
    s.GracefulStop()

    log.Println("server stopped")
}
```

### Kubernetes Health Probes

```yaml
# Kubernetes deployment with gRPC health probes
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: myapp
          ports:
            - containerPort: 50051
          livenessProbe:
            grpc:
              port: 50051
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            grpc:
              port: 50051
            initialDelaySeconds: 5
            periodSeconds: 5
```

## Testing gRPC Services

### Unit Testing with bufconn

Use `bufconn` to create an in-memory gRPC connection without a real network:

```go
import (
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    "google.golang.org/grpc/test/bufconn"
)

const bufSize = 1024 * 1024

func setupTest(t *testing.T) (pb.BookServiceClient, func()) {
    lis := bufconn.Listen(bufSize)

    s := grpc.NewServer()
    pb.RegisterBookServiceServer(s, newBookServer())

    go func() {
        if err := s.Serve(lis); err != nil {
            t.Errorf("server exited with error: %v", err)
        }
    }()

    conn, err := grpc.NewClient("passthrough://bufconn",
        grpc.WithContextDialer(func(ctx context.Context, addr string) (net.Conn, error) {
            return lis.DialContext(ctx)
        }),
        grpc.WithTransportCredentials(insecure.NewCredentials()),
    )
    if err != nil {
        t.Fatalf("failed to dial: %v", err)
    }

    client := pb.NewBookServiceClient(conn)
    cleanup := func() {
        conn.Close()
        s.GracefulStop()
    }

    return client, cleanup
}

func TestGetBook(t *testing.T) {
    client, cleanup := setupTest(t)
    defer cleanup()

    resp, err := client.GetBook(context.Background(), &pb.GetBookRequest{
        Name: "shelves/shelf1/books/book1",
    })
    if err != nil {
        t.Fatalf("GetBook failed: %v", err)
    }
    if resp.DisplayName != "Expected Title" {
        t.Errorf("got %q, want %q", resp.DisplayName, "Expected Title")
    }
}
```

### Testing Streaming RPCs

```go
func TestListBooks(t *testing.T) {
    client, cleanup := setupTest(t)
    defer cleanup()

    stream, err := client.ListBooks(context.Background(), &pb.ListBooksRequest{
        Parent: "shelves/shelf1",
    })
    if err != nil {
        t.Fatalf("ListBooks failed: %v", err)
    }

    var books []*pb.Book
    for {
        book, err := stream.Recv()
        if err == io.EOF {
            break
        }
        if err != nil {
            t.Fatalf("stream.Recv failed: %v", err)
        }
        books = append(books, book)
    }

    if len(books) != 3 {
        t.Errorf("got %d books, want 3", len(books))
    }
}
```

### Testing Error Responses

```go
func TestGetBook_NotFound(t *testing.T) {
    client, cleanup := setupTest(t)
    defer cleanup()

    _, err := client.GetBook(context.Background(), &pb.GetBookRequest{
        Name: "shelves/shelf1/books/nonexistent",
    })

    st, ok := status.FromError(err)
    if !ok {
        t.Fatalf("expected gRPC error, got: %v", err)
    }
    if st.Code() != codes.NotFound {
        t.Errorf("got code %v, want NotFound", st.Code())
    }
}
```

### Integration Testing with grpcurl

```bash
#!/bin/bash
# integration-test.sh

SERVER="localhost:50051"

echo "=== Health Check ==="
grpcurl -plaintext $SERVER grpc.health.v1.Health/Check

echo "=== Create Book ==="
grpcurl -plaintext -d '{
  "parent": "shelves/shelf1",
  "book": {
    "display_name": "The Go Programming Language",
    "author": "Donovan & Kernighan",
    "isbn": "978-0134190440"
  },
  "book_id": "go-book"
}' $SERVER myapp.v1.BookService/CreateBook

echo "=== Get Book ==="
grpcurl -plaintext -d '{
  "name": "shelves/shelf1/books/go-book"
}' $SERVER myapp.v1.BookService/GetBook

echo "=== List Books ==="
grpcurl -plaintext -d '{
  "parent": "shelves/shelf1",
  "page_size": 10
}' $SERVER myapp.v1.BookService/ListBooks
```

### Load Testing with ghz

```bash
# Install: go install github.com/bojand/ghz/cmd/ghz@latest

ghz --insecure \
    --proto ./proto/book_service.proto \
    --call myapp.v1.BookService/GetBook \
    -d '{"name": "shelves/shelf1/books/book1"}' \
    -n 10000 \
    -c 50 \
    --connections 5 \
    localhost:50051
```

## Deadline and Timeout Propagation

### Setting Deadlines

```go
// Client: always set a deadline
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
resp, err := client.GetBook(ctx, req)

// Server: check remaining time
deadline, ok := ctx.Deadline()
if ok {
    remaining := time.Until(deadline)
    if remaining < 100*time.Millisecond {
        return nil, status.Error(codes.DeadlineExceeded, "insufficient time remaining")
    }
}

// Server: propagate deadline to downstream calls
// The context already carries the deadline, just pass it through
downstreamResp, err := downstreamClient.GetData(ctx, downstreamReq)
```

### Default Deadline via Interceptor

```go
func defaultDeadlineInterceptor(timeout time.Duration) grpc.UnaryClientInterceptor {
    return func(ctx context.Context, method string, req, reply any,
        cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
        if _, ok := ctx.Deadline(); !ok {
            var cancel context.CancelFunc
            ctx, cancel = context.WithTimeout(ctx, timeout)
            defer cancel()
        }
        return invoker(ctx, method, req, reply, cc, opts...)
    }
}

conn, _ := grpc.NewClient(addr,
    grpc.WithUnaryInterceptor(defaultDeadlineInterceptor(10*time.Second)),
)
```

## Connection Management

### Client Connection Options

```go
conn, err := grpc.NewClient(target,
    grpc.WithTransportCredentials(creds),

    // Load balancing
    grpc.WithDefaultServiceConfig(`{"loadBalancingConfig":[{"round_robin":{}}]}`),

    // Keep-alive
    grpc.WithKeepaliveParams(keepalive.ClientParameters{
        Time:                10 * time.Second,  // ping interval if no activity
        Timeout:             3 * time.Second,    // wait for ping ack
        PermitWithoutStream: true,               // ping even without active RPCs
    }),

    // Default call options
    grpc.WithDefaultCallOptions(
        grpc.MaxCallRecvMsgSize(16*1024*1024),   // 16 MB
        grpc.MaxCallSendMsgSize(16*1024*1024),
        grpc.UseCompressor(gzip.Name),
    ),

    // Retry
    grpc.WithDefaultServiceConfig(`{
        "methodConfig": [{
            "name": [{"service": "myapp.v1.BookService"}],
            "retryPolicy": {
                "maxAttempts": 3,
                "initialBackoff": "0.1s",
                "maxBackoff": "1s",
                "backoffMultiplier": 2,
                "retryableStatusCodes": ["UNAVAILABLE", "RESOURCE_EXHAUSTED"]
            }
        }]
    }`),
)
```

### Server Options

```go
s := grpc.NewServer(
    grpc.Creds(creds),

    // Interceptors
    grpc.ChainUnaryInterceptor(recovery, logging, auth),
    grpc.ChainStreamInterceptor(streamRecovery, streamLogging, streamAuth),

    // Message size limits
    grpc.MaxRecvMsgSize(16*1024*1024),
    grpc.MaxSendMsgSize(16*1024*1024),

    // Keep-alive
    grpc.KeepaliveParams(keepalive.ServerParameters{
        MaxConnectionIdle:     15 * time.Minute,
        MaxConnectionAge:      30 * time.Minute,
        MaxConnectionAgeGrace: 5 * time.Second,
        Time:                  5 * time.Minute,
        Timeout:               1 * time.Second,
    }),

    // Enforcement policy
    grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
        MinTime:             5 * time.Second,  // min time between pings
        PermitWithoutStream: true,
    }),

    // Concurrent streams per connection
    grpc.MaxConcurrentStreams(100),
)
```
