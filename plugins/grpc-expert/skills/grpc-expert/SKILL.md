---
name: grpc-expert
description: Use when needing help with gRPC services, Protocol Buffers, protoc compilation, service definitions, streaming patterns, interceptors, load balancing, or troubleshooting gRPC connections. Also use when mentioning 'grpc', 'protobuf', 'proto file', 'grpc-go', 'grpc streaming', 'buf', 'connect-go', 'tonic', or 'grpcurl'.
---

# gRPC Expert

gRPC is a high-performance, open-source RPC framework built on HTTP/2 and Protocol Buffers. It provides efficient binary serialization, bidirectional streaming, flow control, and language-agnostic service definitions. gRPC is the backbone of modern microservice architectures, service meshes, and internal APIs at scale.

## Protocol Buffers (proto3)

Protocol Buffers (protobuf) is the Interface Definition Language (IDL) and serialization format used by gRPC. The current version is proto3.

### Syntax Fundamentals

Every proto file starts with a syntax declaration and package:

```protobuf
syntax = "proto3";

package myapp.v1;

option go_package = "github.com/myorg/myapp/gen/myapp/v1;myappv1";
option java_package = "com.myorg.myapp.v1";
```

### Messages

Messages define data structures. Fields have a type, name, and unique field number:

```protobuf
message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int32 age = 4;
  repeated string tags = 5;        // list
  map<string, string> labels = 6;  // key-value map
  UserStatus status = 7;
  oneof contact {                  // only one field set at a time
    string phone = 8;
    string address = 9;
  }
}
```

### Scalar Types

- Integers: `int32`, `int64`, `uint32`, `uint64`, `sint32`, `sint64`, `fixed32`, `fixed64`, `sfixed32`, `sfixed64`
- Floating point: `float`, `double`
- Boolean: `bool`
- Strings: `string` (UTF-8 or 7-bit ASCII)
- Bytes: `bytes`

Use `sint32`/`sint64` for frequently negative values (ZigZag encoding). Use `fixed32`/`fixed64` when values are frequently large (more efficient than varint).

### Enums

Enums must have a zero value as their first entry:

```protobuf
enum UserStatus {
  USER_STATUS_UNSPECIFIED = 0;
  USER_STATUS_ACTIVE = 1;
  USER_STATUS_INACTIVE = 2;
  USER_STATUS_BANNED = 3;
}
```

### Well-Known Types

Import and use Google's standard types:

```protobuf
import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";
import "google/protobuf/any.proto";
import "google/protobuf/empty.proto";
import "google/protobuf/struct.proto";
import "google/protobuf/wrappers.proto";
import "google/protobuf/field_mask.proto";
```

- `google.protobuf.Timestamp` -- point in time (seconds + nanos since epoch)
- `google.protobuf.Duration` -- span of time
- `google.protobuf.Any` -- arbitrary serialized message with type URL
- `google.protobuf.Empty` -- empty message for RPCs with no request/response
- `google.protobuf.Struct` -- dynamic JSON-like structure
- `google.protobuf.FieldMask` -- specify which fields to read/update
- Wrappers (`StringValue`, `Int32Value`, etc.) -- nullable scalar fields

### Field Numbering Rules

- Field numbers 1-15 use 1 byte on the wire (use for frequent fields)
- Field numbers 16-2047 use 2 bytes
- Range 19000-19999 is reserved by protobuf
- Never reuse a deleted field number; use `reserved`:

```protobuf
message Foo {
  reserved 2, 15, 9 to 11;
  reserved "old_field", "deprecated_field";
}
```

### Proto Style Guide

- Messages: `PascalCase` (e.g., `UserProfile`)
- Fields: `snake_case` (e.g., `user_name`)
- Enums: `UPPER_SNAKE_CASE` with type prefix (e.g., `USER_STATUS_ACTIVE`)
- Services: `PascalCase` (e.g., `UserService`)
- RPC methods: `PascalCase` (e.g., `GetUser`)
- Files: `snake_case.proto` (e.g., `user_service.proto`)

## Service Definition Patterns

gRPC supports four RPC patterns:

### Unary RPC

Single request, single response. The most common pattern. Use for CRUD operations, lookups, and simple commands.

```protobuf
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}
```

### Server Streaming RPC

Single request, stream of responses. Use for subscriptions, real-time feeds, large result sets, and progress updates.

```protobuf
rpc ListUsers(ListUsersRequest) returns (stream User);
rpc WatchEvents(WatchRequest) returns (stream Event);
```

### Client Streaming RPC

Stream of requests, single response. Use for file uploads, batch operations, and aggregation.

```protobuf
rpc UploadFile(stream FileChunk) returns (UploadResponse);
rpc RecordMetrics(stream Metric) returns (RecordResponse);
```

### Bidirectional Streaming RPC

Stream of requests and responses simultaneously. Use for chat, collaborative editing, and real-time sync.

```protobuf
rpc Chat(stream ChatMessage) returns (stream ChatMessage);
rpc SyncState(stream StateUpdate) returns (stream StateUpdate);
```

## Code Generation

### protoc

The Protocol Buffer compiler generates language-specific code:

```bash
# Go
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/service.proto

# Python
protoc --python_out=. --grpc_python_out=. proto/service.proto

# Java
protoc --java_out=. --grpc-java_out=. proto/service.proto

# TypeScript (via ts-proto or grpc-tools)
protoc --plugin=protoc-gen-ts=./node_modules/.bin/protoc-gen-ts \
       --ts_out=. proto/service.proto
```

### buf

buf is the modern replacement for protoc. It provides linting, breaking change detection, and a schema registry.

`buf.yaml` (at proto root):

```yaml
version: v2
modules:
  - path: proto
lint:
  use:
    - STANDARD
breaking:
  use:
    - FILE
```

`buf.gen.yaml`:

```yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: gen
    opt: paths=source_relative
  - remote: buf.build/grpc/go
    out: gen
    opt: paths=source_relative
```

Commands:

```bash
buf generate              # generate code
buf lint                  # lint proto files
buf breaking --against '.git#branch=main'  # check breaking changes
buf push                  # push to BSR (Buf Schema Registry)
buf dep update            # update dependencies
```

### buf vs protoc

| Feature | protoc | buf |
|---|---|---|
| Dependency management | Manual includes | buf.lock + BSR |
| Linting | External tools | Built-in (buf lint) |
| Breaking change detection | None | Built-in (buf breaking) |
| Plugin management | Manual install | Remote plugins |
| Config | CLI flags | YAML files |
| Speed | Single-threaded | Parallel, cached |

### Connect-go / Connect-ES

Connect is a modern alternative that generates HTTP/1.1+JSON compatible handlers alongside gRPC:

```bash
buf generate  # with buf.build/connectrpc/go plugin
```

Connect servers handle gRPC, gRPC-Web, and Connect protocol (HTTP/1.1+JSON) on the same port, no proxy needed. Clients work from browsers without Envoy.

## Go Implementation

### Server

```go
import (
    "google.golang.org/grpc"
    "google.golang.org/grpc/reflection"
    pb "myapp/gen/myapp/v1"
)

type server struct {
    pb.UnimplementedUserServiceServer
}

func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
    // implementation
    return &pb.GetUserResponse{User: user}, nil
}

func main() {
    lis, _ := net.Listen("tcp", ":50051")
    s := grpc.NewServer(
        grpc.UnaryInterceptor(loggingInterceptor),
        grpc.ChainUnaryInterceptor(authInterceptor, loggingInterceptor),
    )
    pb.RegisterUserServiceServer(s, &server{})
    reflection.Register(s)  // enable reflection for grpcurl
    s.Serve(lis)
}
```

### Client

```go
conn, err := grpc.NewClient("localhost:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()),
)
defer conn.Close()

client := pb.NewUserServiceClient(conn)
resp, err := client.GetUser(ctx, &pb.GetUserRequest{Id: "123"})
```

### Interceptors

Interceptors are middleware for gRPC calls. They handle cross-cutting concerns like logging, authentication, metrics, and retries.

```go
// Unary interceptor
func loggingInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler) (any, error) {
    start := time.Now()
    resp, err := handler(ctx, req)
    log.Printf("method=%s duration=%s error=%v", info.FullMethod, time.Since(start), err)
    return resp, err
}

// Stream interceptor
func streamLoggingInterceptor(srv any, ss grpc.ServerStream,
    info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
    log.Printf("stream started: %s", info.FullMethod)
    return handler(srv, ss)
}
```

### Metadata

Metadata is gRPC's equivalent of HTTP headers:

```go
// Client: send metadata
md := metadata.Pairs("authorization", "Bearer "+token)
ctx := metadata.NewOutgoingContext(ctx, md)
resp, err := client.GetUser(ctx, req)

// Server: read metadata
md, ok := metadata.FromIncomingContext(ctx)
authHeader := md.Get("authorization")
```

### Error Handling

gRPC uses status codes (similar to HTTP) with rich error details:

```go
import (
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

// Return an error
return nil, status.Errorf(codes.NotFound, "user %s not found", id)
return nil, status.Error(codes.PermissionDenied, "not authorized")

// Check error code on client
st, ok := status.FromError(err)
if ok && st.Code() == codes.NotFound {
    // handle not found
}
```

Common codes: `OK`, `Canceled`, `InvalidArgument`, `NotFound`, `AlreadyExists`, `PermissionDenied`, `ResourceExhausted`, `FailedPrecondition`, `Unimplemented`, `Internal`, `Unavailable`, `DeadlineExceeded`, `Unauthenticated`.

### Health Checking

```go
import "google.golang.org/grpc/health"
import healthpb "google.golang.org/grpc/health/grpc_health_v1"

healthServer := health.NewServer()
healthpb.RegisterHealthServer(s, healthServer)
healthServer.SetServingStatus("myapp.v1.UserService", healthpb.HealthCheckResponse_SERVING)
```

## Python Implementation

### Server

```python
import grpc
from concurrent import futures
import user_pb2_grpc, user_pb2

class UserServiceServicer(user_pb2_grpc.UserServiceServicer):
    def GetUser(self, request, context):
        return user_pb2.GetUserResponse(user=user)

server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
user_pb2_grpc.add_UserServiceServicer_to_server(UserServiceServicer(), server)
server.add_insecure_port("[::]:50051")
server.start()
server.wait_for_termination()
```

### Client

```python
channel = grpc.insecure_channel("localhost:50051")
stub = user_pb2_grpc.UserServiceStub(channel)
response = stub.GetUser(user_pb2.GetUserRequest(id="123"))
```

### Async (grpc.aio)

```python
async def serve():
    server = grpc.aio.server()
    user_pb2_grpc.add_UserServiceServicer_to_server(UserServiceServicer(), server)
    server.add_insecure_port("[::]:50051")
    await server.start()
    await server.wait_for_termination()
```

## Authentication and Security

### TLS / mTLS

```go
// Server with TLS
creds, _ := credentials.NewServerTLSFromFile("server.crt", "server.key")
s := grpc.NewServer(grpc.Creds(creds))

// Client with TLS
creds, _ := credentials.NewClientTLSFromFile("ca.crt", "")
conn, _ := grpc.NewClient("host:443", grpc.WithTransportCredentials(creds))

// mTLS (mutual TLS)
cert, _ := tls.LoadX509KeyPair("client.crt", "client.key")
caCert, _ := os.ReadFile("ca.crt")
pool := x509.NewCertPool()
pool.AppendCertsFromPEM(caCert)
creds := credentials.NewTLS(&tls.Config{
    Certificates: []tls.Certificate{cert},
    RootCAs:      pool,
})
```

### Token-Based Auth

Implement per-RPC credentials via an interceptor or `grpc.PerRPCCredentials`:

```go
type tokenAuth struct{ token string }
func (t tokenAuth) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
    return map[string]string{"authorization": "Bearer " + t.token}, nil
}
func (t tokenAuth) RequireTransportSecurity() bool { return true }

conn, _ := grpc.NewClient("host:443",
    grpc.WithTransportCredentials(creds),
    grpc.WithPerRPCCredentials(tokenAuth{token: "my-jwt"}),
)
```

## Tooling

### grpcurl

A command-line tool for interacting with gRPC servers (requires reflection or proto files):

```bash
# List services (server must have reflection enabled)
grpcurl -plaintext localhost:50051 list

# Describe a service
grpcurl -plaintext localhost:50051 describe myapp.v1.UserService

# Call a method
grpcurl -plaintext -d '{"id": "123"}' localhost:50051 myapp.v1.UserService/GetUser

# With TLS
grpcurl -cacert ca.crt -cert client.crt -key client.key host:443 list

# From proto file (no reflection needed)
grpcurl -plaintext -import-path ./proto -proto user.proto \
    -d '{"id": "123"}' localhost:50051 myapp.v1.UserService/GetUser

# Server streaming
grpcurl -plaintext -d '{"query": "test"}' localhost:50051 myapp.v1.UserService/ListUsers
```

### Evans

Interactive gRPC client with REPL mode:

```bash
evans --host localhost --port 50051 -r repl
# Inside REPL:
# > package myapp.v1
# > service UserService
# > call GetUser
```

### buf CLI

Beyond code generation, buf provides:

```bash
buf lint                                    # lint proto files
buf breaking --against '.git#branch=main'   # detect breaking changes
buf format -w                               # format proto files
buf curl --protocol grpc \                  # like grpcurl but integrated
    http://localhost:50051/myapp.v1.UserService/GetUser
```

### Additional Tools

- **Postman/Insomnia**: GUI-based gRPC clients (import proto files)
- **BloomRPC / gRPCox**: Desktop GUI clients for exploring gRPC APIs
- **grpc_cli**: Official gRPC command-line tool (C++ based)

## Patterns and Best Practices

### API Versioning

Version via the protobuf package name:

```protobuf
package myapp.v1;  // v1 of the API
package myapp.v2;  // v2, can coexist
```

### Deadline / Timeout Propagation

Always set deadlines. Deadlines propagate across service boundaries automatically:

```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
resp, err := client.GetUser(ctx, req)
// If deadline exceeded: codes.DeadlineExceeded
```

### Retry Policies

Configure via service config (client-side):

```go
serviceConfig := `{
  "methodConfig": [{
    "name": [{"service": "myapp.v1.UserService"}],
    "retryPolicy": {
      "maxAttempts": 3,
      "initialBackoff": "0.1s",
      "maxBackoff": "1s",
      "backoffMultiplier": 2,
      "retryableStatusCodes": ["UNAVAILABLE"]
    }
  }]
}`
conn, _ := grpc.NewClient(addr, grpc.WithDefaultServiceConfig(serviceConfig))
```

### Load Balancing

- **Client-side**: Round-robin, pick-first (default), or custom via `grpc.WithDefaultServiceConfig`
- **Proxy-based**: Envoy, nginx (with gRPC support), HAProxy
- **xDS**: Dynamic config from control plane (Istio, Traffic Director)

```go
// Client-side round-robin
conn, _ := grpc.NewClient("dns:///myservice:50051",
    grpc.WithDefaultServiceConfig(`{"loadBalancingConfig":[{"round_robin":{}}]}`),
)
```

### gRPC-Gateway (REST Transcoding)

Expose gRPC services as REST APIs using grpc-gateway annotations:

```protobuf
import "google/api/annotations.proto";

service UserService {
  rpc GetUser(GetUserRequest) returns (User) {
    option (google.api.http) = {
      get: "/v1/users/{id}"
    };
  }
}
```

### Error Model

Use `google.rpc.Status` with error details for rich errors:

```go
st := status.New(codes.InvalidArgument, "invalid input")
st, _ = st.WithDetails(&errdetails.BadRequest_FieldViolation{
    Field:       "email",
    Description: "not a valid email",
})
return nil, st.Err()
```

## Performance

### Connection Pooling

A single gRPC connection multiplexes many RPCs over HTTP/2. For very high throughput, use a pool of connections. Most applications need only one connection per target.

### Keep-Alive

```go
grpc.NewServer(
    grpc.KeepaliveParams(keepalive.ServerParameters{
        MaxConnectionIdle:     15 * time.Minute,
        MaxConnectionAge:      30 * time.Minute,
        MaxConnectionAgeGrace: 5 * time.Second,
        Time:                  5 * time.Minute,
        Timeout:               1 * time.Second,
    }),
)
```

### Max Message Size

Default max message size is 4 MB. Override when needed:

```go
grpc.NewServer(grpc.MaxRecvMsgSize(16 * 1024 * 1024))  // 16 MB
conn, _ := grpc.NewClient(addr, grpc.WithDefaultCallOptions(
    grpc.MaxCallRecvMsgSize(16 * 1024 * 1024),
))
```

### Compression

```go
import "google.golang.org/grpc/encoding/gzip"

// Client
resp, err := client.GetUser(ctx, req, grpc.UseCompressor(gzip.Name))

// Server: automatically handles compressed requests
```

## Troubleshooting

### Debug Logging

```bash
GRPC_VERBOSITY=DEBUG GRPC_TRACE=all ./myserver      # maximum verbosity
GRPC_GO_LOG_SEVERITY_LEVEL=info ./myserver           # Go-specific
GRPC_GO_LOG_VERBOSITY_LEVEL=2 ./myserver
```

### Common Errors

| Code | Meaning | Typical Cause |
|---|---|---|
| `UNAVAILABLE` | Service not reachable | Server down, DNS failure, firewall |
| `DEADLINE_EXCEEDED` | Timeout | Slow server, network latency, no deadline set |
| `UNIMPLEMENTED` | Method not found | Wrong service name, server missing implementation |
| `UNAUTHENTICATED` | Auth failed | Missing/expired token, wrong credentials |
| `RESOURCE_EXHAUSTED` | Quota/limit hit | Message too large, rate limited |
| `INTERNAL` | Server error | Panic, serialization error |

### TLS Issues

- "transport: authentication handshake failed" -- certificate mismatch, expired cert, wrong CA
- Verify with: `openssl s_client -connect host:port -servername host`
- Ensure the SAN (Subject Alternative Name) in the cert matches the hostname

### HTTP/2 and Proxy Issues

- gRPC requires HTTP/2. Some proxies, load balancers, and firewalls do not support it.
- AWS ALB supports gRPC natively. Classic ELB does not.
- nginx needs `grpc_pass` directive (not `proxy_pass`).
- If behind a proxy that terminates TLS, ensure it speaks HTTP/2 to the backend.
- CloudFlare and some CDNs may buffer streaming responses; use gRPC-specific endpoints.
