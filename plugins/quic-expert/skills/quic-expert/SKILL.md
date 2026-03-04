---
name: quic-expert
description: Use when needing help with QUIC protocol, HTTP/3, quic-go, connection migration, 0-RTT, stream multiplexing, or implementing QUIC-based services. Also use when mentioning 'quic', 'http3', 'quic-go', 'h3', 'webtransport', 'msquic', 'ngtcp2', or QUIC troubleshooting.
---

# QUIC Protocol Expert

## QUIC Protocol Fundamentals

QUIC (RFC 9000) is a general-purpose, connection-oriented transport protocol built on UDP. It provides multiplexed streams, built-in encryption via TLS 1.3, and connection migration support. Originally developed at Google and standardized by the IETF, QUIC serves as the transport layer for HTTP/3 (RFC 9114) and is increasingly adopted for real-time, latency-sensitive, and mobile applications.

### Why QUIC Exists

TCP+TLS suffers from several fundamental limitations that QUIC was designed to solve:

- **Head-of-line blocking**: In TCP, a single lost packet stalls all multiplexed streams. QUIC isolates loss to individual streams -- other streams continue unimpeded.
- **Handshake latency**: TCP+TLS requires 2-3 RTTs before application data flows (TCP SYN/SYN-ACK + TLS handshake). QUIC combines transport and crypto handshake into 1 RTT. With session resumption (0-RTT), data can be sent immediately.
- **Connection migration**: TCP connections are bound to a 4-tuple (src IP, src port, dst IP, dst port). Changing network (Wi-Fi to cellular) kills the connection. QUIC uses Connection IDs, allowing seamless migration across network changes and NAT rebinding.
- **Ossification resistance**: TCP is difficult to evolve because middleboxes inspect and sometimes modify TCP headers. QUIC encrypts nearly everything above the header, preventing middlebox interference.

### QUIC vs TCP+TLS Comparison

| Feature | TCP+TLS 1.3 | QUIC |
|---------|-------------|------|
| Transport | TCP (kernel) | UDP (userspace) |
| Encryption | Optional (TLS layer) | Mandatory (TLS 1.3 built-in) |
| Handshake | 2 RTT (TCP + TLS) | 1 RTT (combined), 0-RTT resumption |
| Multiplexing | Application-layer only (HTTP/2) | Native stream multiplexing |
| Head-of-line blocking | Yes (all streams stall) | No (per-stream only) |
| Connection migration | No (4-tuple bound) | Yes (Connection ID based) |
| NAT rebinding | Breaks connection | Transparent via Connection ID |
| Middlebox traversal | Headers inspectable | Encrypted, ossification-resistant |
| Congestion control | Kernel-space | Pluggable, userspace |
| Loss recovery | Per-connection | Per-stream |

### Connection Establishment

**1-RTT Handshake**: The client sends an Initial packet containing a TLS ClientHello. The server responds with its ServerHello, certificates, and handshake completion. Application data can flow after this single round trip.

**0-RTT Resumption**: If the client has previously connected to the server and cached a session ticket plus transport parameters, it can send application data in the very first packet (0-RTT). The server can process this data immediately. Caveat: 0-RTT data is not forward-secret and is vulnerable to replay attacks -- only idempotent operations should use 0-RTT.

### Stream Model

QUIC provides ordered, reliable byte streams within a single connection:

- **Bidirectional streams**: Both endpoints can send and receive. Client-initiated streams have even IDs (0, 4, 8...), server-initiated have odd IDs (1, 5, 9...).
- **Unidirectional streams**: Data flows in one direction only. Client-initiated use IDs 2, 6, 10...; server-initiated use 3, 7, 11...
- **Flow control**: Operates at both the stream level (per-stream byte limits) and the connection level (aggregate across all streams). Receivers advertise MAX_STREAM_DATA and MAX_DATA frames to control flow.
- **Stream priorities**: Senders can prioritize streams to allocate bandwidth fairly or according to application needs.
- **Graceful shutdown**: Streams can be closed independently with FIN, or aborted with RESET_STREAM (sender) and STOP_SENDING (receiver).

### Connection ID and Migration

Each QUIC connection uses Connection IDs (CIDs) rather than the IP/port 4-tuple for identification. Each endpoint assigns CIDs to the other. When a device changes network (e.g., Wi-Fi to cellular), the peer sees a new source IP but the same Connection ID and continues the session transparently. Endpoints can supply multiple CIDs via NEW_CONNECTION_ID frames, and proactively validate new paths with PATH_CHALLENGE/PATH_RESPONSE.

---

## HTTP/3 (RFC 9114)

HTTP/3 is the mapping of HTTP semantics onto QUIC. It replaces HTTP/2's TCP-based framing with QUIC streams, eliminating head-of-line blocking entirely.

### HTTP/3 vs HTTP/2 vs HTTP/1.1

| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---------|----------|--------|--------|
| Transport | TCP | TCP + TLS | QUIC (UDP + TLS 1.3) |
| Multiplexing | None (pipelining rarely used) | Stream multiplexing | Stream multiplexing |
| Head-of-line blocking | Per-connection | TCP-level (all streams) | None (per-stream only) |
| Header compression | None | HPACK | QPACK |
| Server push | No | Yes | Yes (rarely used) |
| Connection migration | No | No | Yes |
| 0-RTT | No | No | Yes |

### QPACK Header Compression (RFC 9204)

QPACK replaces HPACK for HTTP/3. HPACK relied on ordered delivery (guaranteed by TCP) to synchronize the dynamic table. Since QUIC streams are independent and may arrive out of order, QPACK uses two dedicated unidirectional streams -- an encoder stream and a decoder stream -- to signal dynamic table state, allowing references to be used safely without head-of-line blocking.

### HTTP/3 Discovery via Alt-Svc

Clients discover HTTP/3 support through the `Alt-Svc` HTTP header or the `HTTPS` DNS record:

```
Alt-Svc: h3=":443"; ma=86400
```

The client initially connects via HTTP/1.1 or HTTP/2 over TCP, receives the Alt-Svc header, then switches to HTTP/3 over QUIC for subsequent requests. The `HTTPS` DNS record (`SVCB` type) allows discovery before any HTTP connection.

### Priority Signaling

HTTP/3 uses the Extensible Priorities scheme (RFC 9218) with `urgency` (0-7) and `incremental` (boolean) parameters, replacing HTTP/2's complex dependency tree model.

---

## Go Implementation (quic-go)

quic-go (`github.com/quic-go/quic-go`) is the primary QUIC implementation in Go. It supports QUIC v1 (RFC 9000), HTTP/3, 0-RTT, connection migration, and WebTransport.

### Basic Server

```go
listener, err := quic.Listen(udpConn, tlsConfig, quicConfig)
// or simply:
listener, err := quic.ListenAddr("0.0.0.0:4242", tlsConfig, &quic.Config{})

conn, err := listener.Accept(ctx)
stream, err := conn.AcceptStream(ctx)
buf := make([]byte, 1024)
n, err := stream.Read(buf)
stream.Write([]byte("response"))
stream.Close()
```

### Basic Client

```go
conn, err := quic.DialAddr(ctx, "server:4242", tlsConfig, &quic.Config{})
stream, err := conn.OpenStreamSync(ctx)
stream.Write([]byte("hello"))
buf := make([]byte, 1024)
n, err := stream.Read(buf)
```

### quic.Transport (Advanced)

For connection migration, reusing UDP sockets, and fine-grained control:

```go
udpConn, _ := net.ListenUDP("udp4", &net.UDPAddr{Port: 0})
tr := &quic.Transport{Conn: udpConn}
conn, err := tr.Dial(ctx, serverAddr, tlsConfig, quicConfig)
```

### TLS Configuration (Mandatory)

QUIC requires TLS 1.3. Every server needs a certificate:

```go
tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{cert},
    NextProtos:   []string{"my-protocol"}, // ALPN
    MinVersion:   tls.VersionTLS13,
}
```

For development, use self-signed certificates or `generate_cert.go` from the Go standard library.

### 0-RTT

```go
// Server: use EarlyListener
listener, _ := quic.ListenAddrEarly("0.0.0.0:4242", tlsConfig, quicConfig)
conn, _ := listener.Accept(ctx) // returns EarlyConnection

// Client: use DialEarly (requires a cached session ticket)
conn, _ := quic.DialAddrEarly(ctx, "server:4242", tlsConfig, quicConfig)
```

### HTTP/3 with quic-go

```go
import "github.com/quic-go/quic-go/http3"

// Server
server := &http3.Server{
    Addr:      ":443",
    Handler:   myHandler,
    TLSConfig: tlsConfig,
}
server.ListenAndServe()

// Client
transport := &http3.Transport{
    TLSClientConfig: &tls.Config{},
}
client := &http.Client{Transport: transport}
resp, err := client.Get("https://example.com")
```

### WebTransport

```go
import "github.com/quic-go/webtransport-go"

wtServer := &webtransport.Server{
    H3: http3.Server{Addr: ":443", TLSConfig: tlsConfig},
}
http.HandleFunc("/wt", func(w http.ResponseWriter, r *http.Request) {
    session, _ := wtServer.Upgrade(w, r)
    stream, _ := session.AcceptStream(r.Context())
    // read/write on stream
})
wtServer.ListenAndServe()
```

### Configuration (quic.Config)

```go
quicConfig := &quic.Config{
    MaxIdleTimeout:        30 * time.Second,
    KeepAlivePeriod:       10 * time.Second,
    MaxIncomingStreams:     100,
    MaxIncomingUniStreams:  100,
    InitialStreamReceiveWindow:    512 * 1024,  // 512 KB
    MaxStreamReceiveWindow:        6 * 1024 * 1024,  // 6 MB
    InitialConnectionReceiveWindow: 1024 * 1024, // 1 MB
    MaxConnectionReceiveWindow:     15 * 1024 * 1024, // 15 MB
    Allow0RTT:            true,
    EnableDatagrams:       true,
}
```

For detailed code examples, see `references/quic-go-guide.md`.

---

## Other Implementations

### Rust

- **quinn** (`quinn-rs/quinn`): Pure Rust, async/await, built on rustls. Most popular Rust QUIC library. `cargo add quinn`
- **s2n-quic** (`aws/s2n-quic`): AWS-backed, performance-focused, uses s2n-tls. `cargo add s2n-quic`
- **quiche** (`cloudflare/quiche`): Cloudflare's implementation in Rust with C API. Powers Cloudflare's edge. `cargo add quiche`

### C/C++

- **msquic** (Microsoft): Cross-platform, high-performance. Used in Windows, .NET, and Xbox. Install: `apt install libmsquic` or build from source.
- **ngtcp2**: Lightweight C library, often paired with nghttp3 for HTTP/3. Used by curl.
- **lsquic** (LiteSpeed): Powers LiteSpeed web server and OpenLiteSpeed.
- **picoquic**: Minimal C implementation by Christian Huitema (QUIC co-author), great for testing and experimentation.

### Python

- **aioquic** (`aiortc/aioquic`): Async QUIC implementation for Python. `pip install aioquic`. Supports HTTP/3 and WebTransport.

### Node.js

- Built-in `node:quic` module (experimental, behind `--experimental-quic` flag).
- Third-party: `@aspect-build/quic` and `webtransport` npm packages.

### curl

```bash
curl --http3-only https://example.com    # Force HTTP/3
curl --http3 https://example.com         # Try HTTP/3, fall back to HTTP/2 or 1.1
curl -I --http3 https://cloudflare.com   # Check HTTP/3 headers
```

Requires curl built with nghttp3+ngtcp2 or quiche backend. Check: `curl --version | grep HTTP3`.

---

## WebTransport

WebTransport is a web API that provides low-latency, bidirectional communication between a client (browser) and server over HTTP/3 and QUIC. It supports both reliable streams and unreliable datagrams.

### Browser API

```javascript
const wt = new WebTransport("https://server.example/wt");
await wt.ready;

// Bidirectional stream
const stream = await wt.createBidirectionalStream();
const writer = stream.writable.getWriter();
await writer.write(new TextEncoder().encode("hello"));

// Unreliable datagrams
const dgWriter = wt.datagrams.writable.getWriter();
await dgWriter.write(new Uint8Array([1, 2, 3]));
```

### Use Cases

Real-time multiplayer gaming, live video/audio streaming, IoT telemetry, collaborative editing, and any scenario needing low-latency bidirectional communication with optional reliability.

---

## QUIC-based Protocols

- **DNS over QUIC (DoQ, RFC 9250)**: Encrypted DNS queries over QUIC. Lower latency than DoH (HTTP/3) for DNS-specific traffic.
- **MASQUE (RFC 9298, 9484)**: Proxying UDP traffic over QUIC. Enables VPN-like tunneling and IP proxying through QUIC connections.
- **Media over QUIC (MoQ)**: IETF draft standard for live media streaming. Uses QUIC datagrams and streams for adaptive, low-latency media delivery.
- **QUIC Datagrams (RFC 9221)**: Unreliable data transmission within a QUIC connection. Useful for real-time data where retransmission is unnecessary (game state, voice frames).

---

## Configuration and Tuning

| Parameter | Purpose | Typical Value |
|-----------|---------|---------------|
| Initial congestion window | Starting send rate | 10 * MTU (~14 KB) |
| Max stream limits | Concurrent streams allowed | 100-1000 per direction |
| Idle timeout | Close connection after inactivity | 30s (mobile: 120s) |
| Keep-alive interval | Prevent idle timeout / NAT expiry | 15-25s |
| Max datagram frame size | Unreliable datagram payload limit | 1200 bytes |
| Connection ID length | CID size in bytes | 8-20 bytes |
| 0-RTT token store | Cache for session resumption | File or in-memory cache |
| Stream receive window | Per-stream flow control | 256 KB - 6 MB |
| Connection receive window | Aggregate flow control | 1 MB - 15 MB |

---

## Deployment

### Reverse Proxies with HTTP/3

- **Caddy**: Native HTTP/3 support out of the box. Simply enable HTTPS and Caddy serves HTTP/3 automatically.
- **nginx**: Experimental HTTP/3 support since 1.25.0 (`listen 443 quic`). Requires building with `--with-http_v3_module`.
- **HAProxy**: QUIC support added in 2.6+ (experimental). Configuration: `bind quic4@:443 ssl crt /path/cert.pem alpn h3`.
- **Envoy**: HTTP/3 upstream and downstream support.

### CDN Support

Cloudflare, Akamai, Fastly, AWS CloudFront, and Google Cloud CDN all support HTTP/3 on their edge networks.

### Firewall Considerations

- QUIC uses **UDP port 443** (by convention). Firewalls must allow UDP 443 inbound/outbound.
- Many corporate firewalls block non-TCP traffic -- this is the primary deployment obstacle for QUIC.
- NAT traversal: QUIC handles NAT rebinding via Connection IDs, but aggressive NAT timeout (< 30s) can still disrupt connections. Use keep-alive to maintain NAT bindings.

### Mobile Deployment

Connection migration makes QUIC ideal for mobile: seamless handoff between Wi-Fi and cellular without reconnecting. Google reports significant latency improvements for YouTube and Google Search on mobile via QUIC.

---

## Troubleshooting and Debugging

### qlog (Structured QUIC Logging)

qlog is the standardized logging format for QUIC events (connection state, packet sent/received, frames, congestion). Most implementations support qlog output. Visualize with [qvis](https://qvis.quictools.info/).

```go
// quic-go qlog
import "github.com/quic-go/quic-go/qlog"
quicConfig := &quic.Config{
    Tracer: qlog.DefaultConnectionTracer,
}
```

### Wireshark

Wireshark has a built-in QUIC dissector. To decrypt QUIC traffic:

```bash
export SSLKEYLOGFILE=/tmp/quic-keys.log
# Run your QUIC client/server
# Open capture in Wireshark: Edit > Preferences > Protocols > TLS > (Pre)-Master-Secret log filename
```

### Testing with curl

```bash
curl --http3-only -v https://example.com      # Force HTTP/3
curl --http3 -v https://cloudflare-quic.com    # Try HTTP/3
curl -I --http3 https://quic.tech:8443         # Check QUIC headers
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection timeout | UDP 443 blocked by firewall | Open UDP 443 inbound/outbound |
| MTU errors / packet loss | Path MTU < 1200 bytes | QUIC mandates 1200-byte minimum; fix network MTU |
| Certificate errors | Missing or invalid TLS cert | QUIC requires valid TLS 1.3 cert; check ALPN config |
| 0-RTT not working | No cached session ticket | Ensure client stores and reuses session tickets |
| Poor performance | Small receive windows | Tune stream and connection receive windows |
| Connection migration fails | Server not using Connection IDs | Use quic.Transport with proper CID handling |

### Performance Analysis

Key metrics to monitor: congestion window (cwnd), smoothed RTT (srtt), packet loss rate, retransmission rate, stream throughput, and handshake duration. Use qlog + qvis for visualization.

---

## Security

- **Built-in encryption**: All QUIC packets (except the header type bits and Connection ID) are encrypted with TLS 1.3. There is no plaintext mode.
- **Amplification attack protection**: Servers must not send more than 3x the data received from an unvalidated address. Address validation tokens (in Retry packets or NEW_TOKEN frames) lift this limit.
- **Retry packets**: Servers under load can require clients to prove their address by responding to a Retry packet with a valid token -- an anti-DDoS mechanism.
- **Connection migration security**: Path validation via PATH_CHALLENGE/PATH_RESPONSE prevents off-path attackers from hijacking connections.
- **Version negotiation**: If the server does not support the client's QUIC version, it responds with a Version Negotiation packet listing supported versions.
- **Header protection**: QUIC encrypts packet numbers and other header fields to prevent ossification and tracking.

---

## Progressive Disclosure

- Practical quic-go code examples: `references/quic-go-guide.md`
- Deep protocol internals (packets, frames, state machine, RFCs): `references/protocol-deep-dive.md`
- Quick QUIC/HTTP3 reference: `/quic-help` command
