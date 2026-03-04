---
description: Quick gRPC reference — show essential commands, patterns, or help with a specific gRPC topic
allowed-tools: ["Bash"]
---

# gRPC Help

Provide quick gRPC help based on what the user asks. If no specific topic is given, show a general quick-reference covering the most common tasks.

## Steps

1. Determine what the user needs help with (proto definitions, code generation, server/client setup, streaming, interceptors, tooling, debugging, or general).
2. If they ask about their current project state, examine proto files and generated code.
3. Provide a focused, actionable response with code examples.

## Gathering Project State

If the user wants help with their gRPC project, check for proto files and configuration:

```bash
find . -name "*.proto" -type f 2>/dev/null | head -20
```

```bash
cat buf.yaml 2>/dev/null || cat buf.gen.yaml 2>/dev/null || echo "No buf config found"
```

```bash
ls -la proto/ 2>/dev/null || ls -la api/ 2>/dev/null || echo "No proto directory found"
```

```bash
which protoc 2>/dev/null && protoc --version || echo "protoc not installed"
```

```bash
which buf 2>/dev/null && buf --version || echo "buf not installed"
```

```bash
which grpcurl 2>/dev/null || echo "grpcurl not installed"
```

## Quick Reference

### Proto File Template

```protobuf
syntax = "proto3";
package myapp.v1;

option go_package = "github.com/org/repo/gen/myapp/v1;myappv1";

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";

service MyService {
  rpc Get(GetRequest) returns (GetResponse);
  rpc List(ListRequest) returns (stream Item);
  rpc Create(CreateRequest) returns (CreateResponse);
}
```

### Code Generation

With buf:

```bash
buf generate
buf lint
buf breaking --against '.git#branch=main'
```

With protoc (Go):

```bash
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/service.proto
```

### grpcurl Commands

```bash
# List services (requires reflection)
grpcurl -plaintext localhost:50051 list

# Describe a service
grpcurl -plaintext localhost:50051 describe myapp.v1.MyService

# Call a method
grpcurl -plaintext -d '{"id": "123"}' localhost:50051 myapp.v1.MyService/Get

# With proto file (no reflection needed)
grpcurl -plaintext -import-path ./proto -proto service.proto \
    -d '{"id": "123"}' localhost:50051 myapp.v1.MyService/Get

# With TLS
grpcurl -cacert ca.crt host:443 list
```

### Go Server Skeleton

```go
s := grpc.NewServer()
pb.RegisterMyServiceServer(s, &server{})
reflection.Register(s)
lis, _ := net.Listen("tcp", ":50051")
s.Serve(lis)
```

### Go Client Skeleton

```go
conn, _ := grpc.NewClient("localhost:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()),
)
defer conn.Close()
client := pb.NewMyServiceClient(conn)
resp, err := client.Get(ctx, &pb.GetRequest{Id: "123"})
```

### Common Status Codes

| Code | When to Use |
|---|---|
| `codes.InvalidArgument` | Bad client input |
| `codes.NotFound` | Resource doesn't exist |
| `codes.AlreadyExists` | Duplicate create |
| `codes.PermissionDenied` | Not authorized |
| `codes.Unauthenticated` | No valid credentials |
| `codes.Unavailable` | Transient failure (retry) |
| `codes.DeadlineExceeded` | Timeout |
| `codes.Unimplemented` | Method not available |
| `codes.Internal` | Server bug |

### Debug Environment Variables

```bash
GRPC_VERBOSITY=DEBUG GRPC_TRACE=all ./myserver
GRPC_GO_LOG_SEVERITY_LEVEL=info ./myserver
GRPC_GO_LOG_VERBOSITY_LEVEL=2 ./myserver
```

### Install Tools

```bash
# buf (recommended)
curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-$(uname -s)-$(uname -m) -o /usr/local/bin/buf && chmod +x /usr/local/bin/buf

# grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# protoc-gen-go + protoc-gen-go-grpc
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# evans (interactive client)
go install github.com/ktr0731/evans@latest

# ghz (load testing)
go install github.com/bojand/ghz/cmd/ghz@latest
```
