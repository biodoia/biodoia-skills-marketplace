# Protocol Buffers (proto3) Cheatsheet

Complete proto3 syntax reference with examples for every type, option, and pattern.

## File Structure

```protobuf
// Every proto file must start with syntax declaration
syntax = "proto3";

// Package prevents naming conflicts between proto definitions
package mycompany.myproject.v1;

// Options configure code generation
option go_package = "github.com/mycompany/myproject/gen/v1;v1";
option java_package = "com.mycompany.myproject.v1";
option java_multiple_files = true;
option csharp_namespace = "MyCompany.MyProject.V1";
option objc_class_prefix = "MPV";

// Imports
import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";
import "google/protobuf/any.proto";
import "google/protobuf/empty.proto";
import "google/protobuf/struct.proto";
import "google/protobuf/wrappers.proto";
import "google/protobuf/field_mask.proto";
import public "other_file.proto";  // transitive import
```

## Scalar Types

| Proto Type | Go | Python | Java | Notes |
|---|---|---|---|---|
| `double` | `float64` | `float` | `double` | 64-bit IEEE 754 |
| `float` | `float32` | `float` | `float` | 32-bit IEEE 754 |
| `int32` | `int32` | `int` | `int` | Varint, inefficient for negatives |
| `int64` | `int64` | `int` | `long` | Varint, inefficient for negatives |
| `uint32` | `uint32` | `int` | `int` | Varint, unsigned |
| `uint64` | `uint64` | `int` | `long` | Varint, unsigned |
| `sint32` | `int32` | `int` | `int` | ZigZag varint, efficient for negatives |
| `sint64` | `int64` | `int` | `long` | ZigZag varint, efficient for negatives |
| `fixed32` | `uint32` | `int` | `int` | Always 4 bytes, efficient if > 2^28 |
| `fixed64` | `uint64` | `int` | `long` | Always 8 bytes, efficient if > 2^56 |
| `sfixed32` | `int32` | `int` | `int` | Always 4 bytes, signed |
| `sfixed64` | `int64` | `int` | `long` | Always 8 bytes, signed |
| `bool` | `bool` | `bool` | `boolean` | true/false |
| `string` | `string` | `str` | `String` | UTF-8 or 7-bit ASCII |
| `bytes` | `[]byte` | `bytes` | `ByteString` | Arbitrary byte sequence |

## Messages

### Basic Message

```protobuf
message Person {
  string name = 1;
  int32 age = 2;
  string email = 3;
}
```

### Nested Messages

```protobuf
message SearchResponse {
  message Result {
    string url = 1;
    string title = 2;
    repeated string snippets = 3;
  }
  repeated Result results = 1;
  int32 total_count = 2;
}

// Reference nested type from outside
message Other {
  SearchResponse.Result result = 1;
}
```

### Repeated Fields (Lists)

```protobuf
message Playlist {
  repeated string song_ids = 1;       // list of strings
  repeated int32 track_numbers = 2;   // list of integers
  repeated Song songs = 3;            // list of messages
}
```

### Map Fields

```protobuf
message Project {
  map<string, string> labels = 1;        // string -> string
  map<string, int32> scores = 2;         // string -> int
  map<int32, Feature> features = 3;      // int -> message
}
```

Maps cannot be `repeated`. Key types can be any integral or string type (not float, double, bytes, enums, or messages). Value types can be any type except another map.

### Oneof Fields

Only one field in a oneof can be set at a time. Setting one clears the others.

```protobuf
message Notification {
  string id = 1;
  oneof content {
    TextMessage text = 2;
    ImageMessage image = 3;
    VideoMessage video = 4;
  }
}
```

Oneof fields cannot be `repeated` or `map`.

### Reserved Fields

Prevent reuse of deleted field numbers or names:

```protobuf
message Obsolete {
  reserved 2, 15, 9 to 11;
  reserved "old_name", "another_old_name";
  string current_field = 1;
}
```

### Default Values

In proto3, all fields have default values when not set:

| Type | Default |
|---|---|
| `string` | `""` |
| `bytes` | `b""` / empty |
| `bool` | `false` |
| Numeric | `0` |
| Enum | First value (must be 0) |
| Message | Language-dependent null/nil |
| `repeated` | Empty list |
| `map` | Empty map |

To distinguish "field was set to default" from "field was not set", use wrapper types or optional:

```protobuf
import "google/protobuf/wrappers.proto";

message Config {
  google.protobuf.Int32Value max_retries = 1;   // nullable int
  google.protobuf.StringValue nickname = 2;     // nullable string
  optional string description = 3;              // has has_description() method
}
```

## Enums

```protobuf
enum Priority {
  PRIORITY_UNSPECIFIED = 0;  // must have zero value
  PRIORITY_LOW = 1;
  PRIORITY_MEDIUM = 2;
  PRIORITY_HIGH = 3;
  PRIORITY_CRITICAL = 4;
}
```

### Enum Aliases

Allow multiple names for the same value:

```protobuf
enum Status {
  option allow_alias = true;
  STATUS_UNSPECIFIED = 0;
  STATUS_RUNNING = 1;
  STATUS_STARTED = 1;  // alias for RUNNING
}
```

### Reserved Enum Values

```protobuf
enum Fruit {
  reserved 2, 15, 9 to 11;
  reserved "FRUIT_BANANA", "FRUIT_KIWI";
  FRUIT_UNSPECIFIED = 0;
  FRUIT_APPLE = 1;
}
```

## Service Definitions

```protobuf
service OrderService {
  // Unary: single request, single response
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);

  // Server streaming: single request, stream of responses
  rpc ListOrders(ListOrdersRequest) returns (stream Order);

  // Client streaming: stream of requests, single response
  rpc UploadOrderBatch(stream Order) returns (UploadResponse);

  // Bidirectional streaming: both sides stream
  rpc OrderChat(stream OrderMessage) returns (stream OrderMessage);
}
```

## Well-Known Types Reference

### Timestamp

```protobuf
import "google/protobuf/timestamp.proto";

message Event {
  string name = 1;
  google.protobuf.Timestamp created_at = 2;
  google.protobuf.Timestamp updated_at = 3;
}
```

Go usage:

```go
import "google.golang.org/protobuf/types/known/timestamppb"
event.CreatedAt = timestamppb.Now()
event.UpdatedAt = timestamppb.New(time.Now().Add(-24 * time.Hour))
t := event.CreatedAt.AsTime()  // convert back to time.Time
```

### Duration

```protobuf
import "google/protobuf/duration.proto";

message TaskConfig {
  google.protobuf.Duration timeout = 1;
  google.protobuf.Duration retry_delay = 2;
}
```

Go usage:

```go
import "google.golang.org/protobuf/types/known/durationpb"
config.Timeout = durationpb.New(30 * time.Second)
d := config.Timeout.AsDuration()  // convert back to time.Duration
```

### Any

Wraps an arbitrary serialized message:

```protobuf
import "google/protobuf/any.proto";

message ErrorDetail {
  string code = 1;
  google.protobuf.Any detail = 2;
}
```

Go usage:

```go
import "google.golang.org/protobuf/types/known/anypb"
anyVal, _ := anypb.New(&pb.MyMessage{Field: "value"})
var msg pb.MyMessage
anypb.UnmarshalTo(anyVal, &msg, proto.UnmarshalOptions{})
```

### Empty

For RPCs with no meaningful request or response:

```protobuf
import "google/protobuf/empty.proto";

service HealthService {
  rpc Ping(google.protobuf.Empty) returns (google.protobuf.Empty);
}
```

### Struct (Dynamic JSON)

```protobuf
import "google/protobuf/struct.proto";

message WebhookPayload {
  string event = 1;
  google.protobuf.Struct data = 2;     // arbitrary JSON object
  google.protobuf.Value metadata = 3;  // any JSON value
}
```

### FieldMask

For partial reads and updates:

```protobuf
import "google/protobuf/field_mask.proto";

message UpdateUserRequest {
  User user = 1;
  google.protobuf.FieldMask update_mask = 2;
}
```

Usage: `update_mask: { paths: ["name", "email"] }` means only update those fields.

### Wrapper Types

Nullable versions of scalar types:

```protobuf
import "google/protobuf/wrappers.proto";

message Settings {
  google.protobuf.BoolValue enabled = 1;       // nullable bool
  google.protobuf.StringValue label = 2;        // nullable string
  google.protobuf.Int32Value max_count = 3;     // nullable int32
  google.protobuf.FloatValue threshold = 4;     // nullable float
  google.protobuf.DoubleValue precision = 5;    // nullable double
  google.protobuf.BytesValue payload = 6;       // nullable bytes
  google.protobuf.UInt32Value retry_count = 7;  // nullable uint32
  google.protobuf.Int64Value big_number = 8;    // nullable int64
  google.protobuf.UInt64Value big_unsigned = 9; // nullable uint64
}
```

## Options

### File-Level Options

```protobuf
option go_package = "github.com/org/repo/gen/v1;v1";
option java_package = "com.org.project.v1";
option java_outer_classname = "MyServiceProto";
option java_multiple_files = true;
option csharp_namespace = "Org.Project.V1";
option objc_class_prefix = "OPV";
option optimize_for = SPEED;  // SPEED, CODE_SIZE, or LITE_RUNTIME
option cc_enable_arenas = true;
```

### Field-Level Options

```protobuf
message Deprecated {
  string old_field = 1 [deprecated = true];
  int32 packed_field = 2 [packed = true];    // default in proto3
  string json_name = 3 [json_name = "customName"];
}
```

### Custom Options (Extensions)

```protobuf
import "google/protobuf/descriptor.proto";

extend google.protobuf.FieldOptions {
  optional string validate = 51234;
}

message User {
  string email = 1 [(validate) = "email"];
}
```

## Common Patterns

### Request/Response Naming

```protobuf
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
}
```

### Pagination

```protobuf
message ListUsersRequest {
  int32 page_size = 1;     // max items per page
  string page_token = 2;   // opaque token from previous response
  string filter = 3;       // optional filter expression
  string order_by = 4;     // optional sort field
}

message ListUsersResponse {
  repeated User users = 1;
  string next_page_token = 2;  // empty if no more pages
  int32 total_size = 3;        // optional total count
}
```

### Resource Name Pattern

Follow the AIP-122 pattern: `{resource_type}/{resource_id}`:

```protobuf
message GetBookRequest {
  // Format: "shelves/{shelf_id}/books/{book_id}"
  string name = 1;
}
```

### Status / Error Detail Pattern

```protobuf
import "google/rpc/status.proto";
import "google/rpc/error_details.proto";

// In response or as rich error:
// google.rpc.Status {
//   code: 3 (INVALID_ARGUMENT)
//   message: "invalid email format"
//   details: [BadRequest { field_violations: [...] }]
// }
```

### Enum Best Practices

```protobuf
// DO: prefix with type name, start with UNSPECIFIED
enum TaskState {
  TASK_STATE_UNSPECIFIED = 0;
  TASK_STATE_PENDING = 1;
  TASK_STATE_RUNNING = 2;
  TASK_STATE_COMPLETED = 3;
  TASK_STATE_FAILED = 4;
}

// DON'T: bare names, missing unspecified
enum BadState {
  PENDING = 0;   // bad: not prefixed, 0 should be UNSPECIFIED
  RUNNING = 1;
}
```

## Wire Format Quick Reference

| Wire Type | ID | Used For |
|---|---|---|
| Varint | 0 | int32, int64, uint32, uint64, sint32, sint64, bool, enum |
| 64-bit | 1 | fixed64, sfixed64, double |
| Length-delimited | 2 | string, bytes, embedded messages, packed repeated |
| 32-bit | 5 | fixed32, sfixed32, float |

Field key = `(field_number << 3) | wire_type`

Fields 1-15 require one byte for the key. Fields 16-2047 require two bytes. Always use 1-15 for frequently set fields.

## Proto File Organization

```
proto/
  mycompany/
    myproject/
      v1/
        user.proto           # User message
        user_service.proto   # UserService RPCs
        common.proto         # shared types
      v2/
        user_service.proto   # v2 with breaking changes
  google/
    api/
      annotations.proto      # HTTP annotations
      http.proto
    protobuf/
      timestamp.proto        # well-known types (usually from includes)
```

### Import Best Practices

- Use fully qualified paths: `import "mycompany/myproject/v1/user.proto";`
- Group imports: well-known types first, then third-party, then local
- Use `import public` sparingly (only for re-exporting)
- Never use relative imports
