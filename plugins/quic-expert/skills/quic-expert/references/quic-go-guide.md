# quic-go Practical Guide

Complete code examples for building QUIC and HTTP/3 services in Go with `github.com/quic-go/quic-go`.

## Installation

```bash
go get github.com/quic-go/quic-go
go get github.com/quic-go/quic-go/http3
go get github.com/quic-go/webtransport-go
```

Requires Go 1.22+.

---

## TLS Certificate Setup (Required)

QUIC mandates TLS 1.3. Every server needs a certificate. For development:

```go
package main

import (
    "crypto/ecdsa"
    "crypto/elliptic"
    "crypto/rand"
    "crypto/tls"
    "crypto/x509"
    "encoding/pem"
    "math/big"
    "time"
)

// generateSelfSignedCert creates a self-signed TLS certificate for development.
func generateSelfSignedCert() (tls.Certificate, error) {
    key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
    if err != nil {
        return tls.Certificate{}, err
    }

    template := &x509.Certificate{
        SerialNumber: big.NewInt(1),
        NotBefore:    time.Now(),
        NotAfter:     time.Now().Add(365 * 24 * time.Hour),
        KeyUsage:     x509.KeyUsageDigitalSignature,
        ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
        DNSNames:     []string{"localhost"},
    }

    certDER, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
    if err != nil {
        return tls.Certificate{}, err
    }

    keyBytes, err := x509.MarshalECPrivateKey(key)
    if err != nil {
        return tls.Certificate{}, err
    }

    certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certDER})
    keyPEM := pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyBytes})

    return tls.X509KeyPair(certPEM, keyPEM)
}
```

For production, use certificates from Let's Encrypt or your CA. Load them with:

```go
cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{cert},
    NextProtos:   []string{"my-app-protocol"},
    MinVersion:   tls.VersionTLS13,
}
```

---

## Basic Echo Server

```go
package main

import (
    "context"
    "crypto/tls"
    "fmt"
    "io"
    "log"

    "github.com/quic-go/quic-go"
)

const addr = "0.0.0.0:4242"

func main() {
    cert, err := generateSelfSignedCert()
    if err != nil {
        log.Fatal(err)
    }

    tlsConfig := &tls.Config{
        Certificates: []tls.Certificate{cert},
        NextProtos:   []string{"echo-protocol"},
    }

    listener, err := quic.ListenAddr(addr, tlsConfig, &quic.Config{
        MaxIdleTimeout:    30 * time.Second,
        MaxIncomingStreams: 100,
    })
    if err != nil {
        log.Fatal(err)
    }
    defer listener.Close()

    fmt.Printf("Echo server listening on %s\n", addr)

    for {
        conn, err := listener.Accept(context.Background())
        if err != nil {
            log.Printf("Accept error: %v", err)
            continue
        }
        go handleConnection(conn)
    }
}

func handleConnection(conn quic.Connection) {
    defer conn.CloseWithError(0, "bye")
    fmt.Printf("New connection from %s\n", conn.RemoteAddr())

    for {
        stream, err := conn.AcceptStream(context.Background())
        if err != nil {
            log.Printf("AcceptStream error: %v", err)
            return
        }
        go handleStream(stream)
    }
}

func handleStream(stream quic.Stream) {
    defer stream.Close()

    // Echo: read and write back
    buf := make([]byte, 4096)
    for {
        n, err := stream.Read(buf)
        if err != nil {
            if err != io.EOF {
                log.Printf("Read error: %v", err)
            }
            return
        }
        _, err = stream.Write(buf[:n])
        if err != nil {
            log.Printf("Write error: %v", err)
            return
        }
    }
}
```

---

## Basic Echo Client

```go
package main

import (
    "context"
    "crypto/tls"
    "fmt"
    "log"

    "github.com/quic-go/quic-go"
)

func main() {
    tlsConfig := &tls.Config{
        InsecureSkipVerify: true, // Development only!
        NextProtos:         []string{"echo-protocol"},
    }

    conn, err := quic.DialAddr(
        context.Background(),
        "localhost:4242",
        tlsConfig,
        &quic.Config{},
    )
    if err != nil {
        log.Fatal(err)
    }
    defer conn.CloseWithError(0, "done")

    stream, err := conn.OpenStreamSync(context.Background())
    if err != nil {
        log.Fatal(err)
    }
    defer stream.Close()

    // Send message
    message := []byte("Hello, QUIC!")
    _, err = stream.Write(message)
    if err != nil {
        log.Fatal(err)
    }

    // Read echo response
    buf := make([]byte, 4096)
    n, err := stream.Read(buf)
    if err != nil {
        log.Fatal(err)
    }

    fmt.Printf("Echo response: %s\n", string(buf[:n]))
}
```

---

## HTTP/3 Server

```go
package main

import (
    "crypto/tls"
    "fmt"
    "log"
    "net/http"

    "github.com/quic-go/quic-go/http3"
)

func main() {
    cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
    if err != nil {
        log.Fatal(err)
    }

    mux := http.NewServeMux()

    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Alt-Svc", `h3=":443"; ma=86400`)
        fmt.Fprintf(w, "Hello from HTTP/3! Protocol: %s\n", r.Proto)
    })

    mux.HandleFunc("/api/data", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.Write([]byte(`{"status":"ok","protocol":"h3"}`))
    })

    server := &http3.Server{
        Addr:    ":443",
        Handler: mux,
        TLSConfig: &tls.Config{
            Certificates: []tls.Certificate{cert},
            MinVersion:   tls.VersionTLS13,
        },
    }

    fmt.Println("HTTP/3 server listening on :443")
    log.Fatal(server.ListenAndServe())
}
```

### HTTP/3 Client

```go
package main

import (
    "crypto/tls"
    "fmt"
    "io"
    "log"
    "net/http"

    "github.com/quic-go/quic-go/http3"
)

func main() {
    transport := &http3.Transport{
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: true, // Development only
        },
    }
    defer transport.Close()

    client := &http.Client{Transport: transport}

    resp, err := client.Get("https://localhost:443/")
    if err != nil {
        log.Fatal(err)
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    fmt.Printf("Status: %d\nProto: %s\nBody: %s\n", resp.StatusCode, resp.Proto, body)
}
```

---

## Stream Multiplexing Patterns

### Multiple Concurrent Streams (Client)

```go
func sendMultipleStreams(conn quic.Connection, messages []string) error {
    var wg sync.WaitGroup

    for i, msg := range messages {
        wg.Add(1)
        go func(idx int, data string) {
            defer wg.Done()

            stream, err := conn.OpenStreamSync(context.Background())
            if err != nil {
                log.Printf("Stream %d open error: %v", idx, err)
                return
            }
            defer stream.Close()

            // Write data
            _, err = stream.Write([]byte(data))
            if err != nil {
                log.Printf("Stream %d write error: %v", idx, err)
                return
            }

            // Signal end of write
            stream.CancelWrite(0) // or stream.Close() for graceful

            // Read response
            resp, err := io.ReadAll(stream)
            if err != nil {
                log.Printf("Stream %d read error: %v", idx, err)
                return
            }
            fmt.Printf("Stream %d response: %s\n", idx, resp)
        }(i, msg)
    }

    wg.Wait()
    return nil
}
```

### Unidirectional Streams

```go
// Server: accept unidirectional streams (client -> server only)
func handleUniStreams(conn quic.Connection) {
    for {
        stream, err := conn.AcceptUniStream(context.Background())
        if err != nil {
            return
        }
        go func(s quic.ReceiveStream) {
            data, _ := io.ReadAll(s)
            log.Printf("Received uni-stream data: %s", data)
        }(stream)
    }
}

// Client: open unidirectional stream
func sendUniStream(conn quic.Connection, data []byte) error {
    stream, err := conn.OpenUniStreamSync(context.Background())
    if err != nil {
        return err
    }
    _, err = stream.Write(data)
    if err != nil {
        return err
    }
    return stream.Close()
}
```

### Request/Response Multiplexing (Protocol Pattern)

```go
// Simple length-prefixed message protocol over a QUIC stream
func writeMessage(stream quic.Stream, msg []byte) error {
    // Write 4-byte length prefix (big-endian)
    length := uint32(len(msg))
    if err := binary.Write(stream, binary.BigEndian, length); err != nil {
        return err
    }
    _, err := stream.Write(msg)
    return err
}

func readMessage(stream quic.Stream) ([]byte, error) {
    var length uint32
    if err := binary.Read(stream, binary.BigEndian, &length); err != nil {
        return nil, err
    }
    buf := make([]byte, length)
    _, err := io.ReadFull(stream, buf)
    return buf, err
}
```

---

## File Transfer Over QUIC

### Sender (Client)

```go
func sendFile(conn quic.Connection, filename string) error {
    f, err := os.Open(filename)
    if err != nil {
        return err
    }
    defer f.Close()

    stat, _ := f.Stat()

    stream, err := conn.OpenStreamSync(context.Background())
    if err != nil {
        return err
    }
    defer stream.Close()

    // Send metadata: filename + size
    meta := fmt.Sprintf("%s|%d", filepath.Base(filename), stat.Size())
    if err := writeMessage(stream, []byte(meta)); err != nil {
        return err
    }

    // Stream file contents
    n, err := io.Copy(stream, f)
    if err != nil {
        return err
    }

    log.Printf("Sent %s (%d bytes)", filename, n)
    return nil
}
```

### Receiver (Server)

```go
func receiveFile(stream quic.Stream, outputDir string) error {
    // Read metadata
    metaBytes, err := readMessage(stream)
    if err != nil {
        return err
    }
    parts := strings.SplitN(string(metaBytes), "|", 2)
    filename := parts[0]
    size, _ := strconv.ParseInt(parts[1], 10, 64)

    outPath := filepath.Join(outputDir, filename)
    f, err := os.Create(outPath)
    if err != nil {
        return err
    }
    defer f.Close()

    n, err := io.Copy(f, io.LimitReader(stream, size))
    if err != nil {
        return err
    }

    log.Printf("Received %s (%d bytes)", outPath, n)
    return nil
}
```

---

## WebTransport Server

```go
package main

import (
    "context"
    "crypto/tls"
    "fmt"
    "io"
    "log"
    "net/http"

    "github.com/quic-go/quic-go/http3"
    "github.com/quic-go/webtransport-go"
)

func main() {
    cert, _ := tls.LoadX509KeyPair("cert.pem", "key.pem")

    wtServer := &webtransport.Server{
        H3: http3.Server{
            Addr: ":4443",
            TLSConfig: &tls.Config{
                Certificates: []tls.Certificate{cert},
            },
        },
        CheckOrigin: func(r *http.Request) bool {
            return true // In production, validate origin
        },
    }

    http.HandleFunc("/wt", func(w http.ResponseWriter, r *http.Request) {
        session, err := wtServer.Upgrade(w, r)
        if err != nil {
            log.Printf("Upgrade error: %v", err)
            return
        }

        fmt.Printf("WebTransport session from %s\n", r.RemoteAddr)

        // Handle bidirectional streams
        go func() {
            for {
                stream, err := session.AcceptStream(r.Context())
                if err != nil {
                    return
                }
                go func(s webtransport.Stream) {
                    defer s.Close()
                    io.Copy(s, s) // Echo
                }(stream)
            }
        }()

        // Handle datagrams
        go func() {
            for {
                msg, err := session.ReceiveDatagram(r.Context())
                if err != nil {
                    return
                }
                log.Printf("Datagram: %s", msg)
                session.SendDatagram(msg) // Echo
            }
        }()

        // Keep session alive
        <-session.Context().Done()
    })

    log.Println("WebTransport server on :4443")
    log.Fatal(wtServer.ListenAndServe())
}
```

### Browser Client (JavaScript)

```html
<script>
async function connectWebTransport() {
    const wt = new WebTransport("https://localhost:4443/wt");
    await wt.ready;
    console.log("WebTransport connected");

    // Open a bidirectional stream
    const stream = await wt.createBidirectionalStream();
    const writer = stream.writable.getWriter();
    const reader = stream.readable.getReader();

    // Send data
    await writer.write(new TextEncoder().encode("Hello WebTransport!"));

    // Read response
    const { value, done } = await reader.read();
    if (!done) {
        console.log("Response:", new TextDecoder().decode(value));
    }

    // Send a datagram (unreliable)
    const dgWriter = wt.datagrams.writable.getWriter();
    await dgWriter.write(new Uint8Array([0x01, 0x02, 0x03]));

    // Receive datagrams
    const dgReader = wt.datagrams.readable.getReader();
    const dg = await dgReader.read();
    console.log("Datagram:", dg.value);
}
</script>
```

---

## 0-RTT Optimization

### Server with 0-RTT (EarlyListener)

```go
func startEarlyServer(addr string, tlsConfig *tls.Config) error {
    quicConfig := &quic.Config{
        Allow0RTT: true,
        MaxIdleTimeout: 30 * time.Second,
    }

    listener, err := quic.ListenAddrEarly(addr, tlsConfig, quicConfig)
    if err != nil {
        return err
    }
    defer listener.Close()

    for {
        conn, err := listener.Accept(context.Background())
        if err != nil {
            return err
        }

        go func(c quic.EarlyConnection) {
            // Check if this is a 0-RTT connection
            // c.HandshakeComplete() returns a channel that closes when
            // the handshake is complete. Until then, data is 0-RTT.

            stream, err := c.AcceptStream(context.Background())
            if err != nil {
                return
            }
            defer stream.Close()

            // Process 0-RTT data (ensure idempotent handling!)
            data, _ := io.ReadAll(stream)
            log.Printf("Received (possibly 0-RTT): %s", data)

            // Wait for handshake to complete before sending sensitive data
            <-c.HandshakeComplete()
            stream.Write([]byte("handshake confirmed"))
        }(conn)
    }
}
```

### Client with 0-RTT (DialEarly)

```go
func dialEarlyClient(addr string, tlsConfig *tls.Config) error {
    // The TLS config should have a session cache for 0-RTT to work
    tlsConfig.ClientSessionCache = tls.NewLRUClientSessionCache(100)

    quicConfig := &quic.Config{
        Allow0RTT: true,
    }

    // First connection: 1-RTT (no cached session)
    conn1, err := quic.DialAddrEarly(context.Background(), addr, tlsConfig, quicConfig)
    if err != nil {
        return err
    }

    // Do some work, then close
    stream, _ := conn1.OpenStreamSync(context.Background())
    stream.Write([]byte("first connection"))
    stream.Close()
    conn1.CloseWithError(0, "done")

    // Second connection: 0-RTT (session ticket cached)
    conn2, err := quic.DialAddrEarly(context.Background(), addr, tlsConfig, quicConfig)
    if err != nil {
        return err
    }

    // This data may be sent as 0-RTT (before handshake completes)
    stream2, _ := conn2.OpenStreamSync(context.Background())
    stream2.Write([]byte("0-RTT data!"))

    // Wait for handshake confirmation
    <-conn2.HandshakeComplete()
    log.Println("Handshake complete, 0-RTT confirmed")

    stream2.Close()
    return conn2.CloseWithError(0, "done")
}
```

---

## Connection Migration Demo

Using `quic.Transport` for connection migration support:

```go
package main

import (
    "context"
    "crypto/tls"
    "fmt"
    "log"
    "net"
    "time"

    "github.com/quic-go/quic-go"
)

func main() {
    // Create a UDP socket on a specific local address
    udpAddr, _ := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
    udpConn, err := net.ListenUDP("udp4", udpAddr)
    if err != nil {
        log.Fatal(err)
    }

    // Create a Transport (supports migration)
    transport := &quic.Transport{
        Conn: udpConn,
    }
    defer transport.Close()

    tlsConfig := &tls.Config{
        InsecureSkipVerify: true,
        NextProtos:         []string{"migration-demo"},
    }

    serverAddr, _ := net.ResolveUDPAddr("udp4", "server:4242")

    conn, err := transport.Dial(
        context.Background(),
        serverAddr,
        tlsConfig,
        &quic.Config{
            KeepAlivePeriod: 10 * time.Second,
        },
    )
    if err != nil {
        log.Fatal(err)
    }
    defer conn.CloseWithError(0, "done")

    // Open a stream and keep communicating
    stream, _ := conn.OpenStreamSync(context.Background())

    // Send periodic messages — the connection survives network changes
    for i := 0; i < 100; i++ {
        msg := fmt.Sprintf("Message %d from %s", i, udpConn.LocalAddr())
        stream.Write([]byte(msg))

        buf := make([]byte, 4096)
        n, err := stream.Read(buf)
        if err != nil {
            log.Printf("Read error (possible migration): %v", err)
            break
        }
        fmt.Printf("Response: %s\n", buf[:n])

        time.Sleep(1 * time.Second)
    }
}
```

When the client's network changes (e.g., Wi-Fi to cellular), QUIC detects the new path, sends PATH_CHALLENGE/PATH_RESPONSE frames, and continues the connection transparently.

---

## Error Handling Patterns

### Connection Errors

```go
conn, err := listener.Accept(ctx)
if err != nil {
    // Check if the listener was closed
    var appErr *quic.ApplicationError
    if errors.As(err, &appErr) {
        log.Printf("Application error: code=%d, reason=%s", appErr.ErrorCode, appErr.ErrorMessage)
    }

    var transportErr *quic.TransportError
    if errors.As(err, &transportErr) {
        log.Printf("Transport error: code=%s", transportErr.ErrorCode)
    }

    if errors.Is(err, context.Canceled) {
        log.Println("Context canceled")
    }
    return
}
```

### Stream Errors

```go
n, err := stream.Read(buf)
if err != nil {
    if err == io.EOF {
        // Peer gracefully closed their send side
        log.Println("Stream ended")
        return
    }

    var streamErr *quic.StreamError
    if errors.As(err, &streamErr) {
        log.Printf("Stream reset by peer: code=%d", streamErr.ErrorCode)
        return
    }

    log.Printf("Unexpected read error: %v", err)
    return
}
```

### Closing with Application Error Codes

```go
// Define application-level error codes
const (
    ErrCodeNone       quic.ApplicationErrorCode = 0
    ErrCodeBadRequest quic.ApplicationErrorCode = 1
    ErrCodeInternal   quic.ApplicationErrorCode = 2
    ErrCodeTimeout    quic.ApplicationErrorCode = 3
)

// Close connection with error
conn.CloseWithError(ErrCodeBadRequest, "invalid request format")

// Reset a single stream
stream.CancelRead(ErrCodeBadRequest)
stream.CancelWrite(ErrCodeBadRequest)
```

### Context and Timeout Management

```go
// Per-connection timeout
ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
defer cancel()

conn, err := quic.DialAddr(ctx, addr, tlsConfig, quicConfig)
if err != nil {
    if errors.Is(err, context.DeadlineExceeded) {
        log.Println("Connection timed out")
    }
    return
}

// Per-stream deadline
stream, _ := conn.OpenStreamSync(ctx)
stream.SetDeadline(time.Now().Add(10 * time.Second))
stream.SetReadDeadline(time.Now().Add(5 * time.Second))
stream.SetWriteDeadline(time.Now().Add(5 * time.Second))
```

---

## QUIC Datagrams (Unreliable Data)

```go
// Enable datagrams in config
quicConfig := &quic.Config{
    EnableDatagrams: true,
}

// Server: receive datagrams
conn, _ := listener.Accept(ctx)
go func() {
    for {
        msg, err := conn.ReceiveDatagram(ctx)
        if err != nil {
            return
        }
        log.Printf("Datagram received: %s", msg)

        // Send datagram back (unreliable, no retransmission)
        conn.SendDatagram(msg)
    }
}()

// Client: send datagrams
conn, _ := quic.DialAddr(ctx, addr, tlsConfig, quicConfig)
err = conn.SendDatagram([]byte("unreliable game state"))
```

---

## Testing QUIC Services

### Unit Testing with Loopback

```go
func TestEchoServer(t *testing.T) {
    // Generate test certificate
    cert, err := generateSelfSignedCert()
    require.NoError(t, err)

    serverTLS := &tls.Config{
        Certificates: []tls.Certificate{cert},
        NextProtos:   []string{"test"},
    }
    clientTLS := &tls.Config{
        InsecureSkipVerify: true,
        NextProtos:         []string{"test"},
    }

    // Start server
    listener, err := quic.ListenAddr("127.0.0.1:0", serverTLS, &quic.Config{})
    require.NoError(t, err)
    defer listener.Close()

    serverAddr := listener.Addr().String()

    // Server goroutine
    go func() {
        conn, _ := listener.Accept(context.Background())
        stream, _ := conn.AcceptStream(context.Background())
        io.Copy(stream, stream) // Echo
        stream.Close()
    }()

    // Client test
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    conn, err := quic.DialAddr(ctx, serverAddr, clientTLS, &quic.Config{})
    require.NoError(t, err)
    defer conn.CloseWithError(0, "test done")

    stream, err := conn.OpenStreamSync(ctx)
    require.NoError(t, err)

    _, err = stream.Write([]byte("test message"))
    require.NoError(t, err)
    stream.Close() // Signal write done

    response, err := io.ReadAll(stream)
    require.NoError(t, err)
    assert.Equal(t, "test message", string(response))
}
```

### Integration Testing with HTTP/3

```go
func TestHTTP3Server(t *testing.T) {
    cert, _ := generateSelfSignedCert()

    mux := http.NewServeMux()
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200)
        w.Write([]byte(`{"status":"healthy"}`))
    })

    server := &http3.Server{
        Addr:    "127.0.0.1:0",
        Handler: mux,
        TLSConfig: &tls.Config{
            Certificates: []tls.Certificate{cert},
        },
    }

    go server.ListenAndServe()
    defer server.Close()
    time.Sleep(100 * time.Millisecond) // Wait for server to start

    transport := &http3.Transport{
        TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
    }
    defer transport.Close()

    client := &http.Client{Transport: transport}
    resp, err := client.Get(fmt.Sprintf("https://%s/health", server.Addr))
    require.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)

    body, _ := io.ReadAll(resp.Body)
    assert.Contains(t, string(body), "healthy")
}
```

### Benchmarking QUIC Throughput

```go
func BenchmarkQUICThroughput(b *testing.B) {
    // Setup server and client (similar to test above)
    // ...

    data := make([]byte, 1024*1024) // 1 MB
    rand.Read(data)

    b.SetBytes(int64(len(data)))
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        stream, _ := conn.OpenStreamSync(context.Background())
        _, err := stream.Write(data)
        if err != nil {
            b.Fatal(err)
        }
        stream.Close()

        _, err = io.ReadAll(stream)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

---

## qlog Integration (Debugging)

```go
import "github.com/quic-go/quic-go/qlog"

quicConfig := &quic.Config{
    Tracer: qlog.DefaultConnectionTracer,
}

// This writes qlog files to the current directory.
// Visualize with https://qvis.quictools.info/
```

To write qlog to a custom directory:

```go
import (
    "github.com/quic-go/quic-go/logging"
    "github.com/quic-go/quic-go/qlog"
)

quicConfig := &quic.Config{
    Tracer: func(ctx context.Context, p logging.Perspective, connID quic.ConnectionID) *logging.ConnectionTracer {
        filename := fmt.Sprintf("qlogs/%s_%s.qlog", p, connID)
        f, err := os.Create(filename)
        if err != nil {
            return nil
        }
        return qlog.NewConnectionTracer(f, p, connID)
    },
}
```

---

## Dual-Stack HTTP/1.1+HTTP/3 Server

Serve both TCP (HTTP/1.1 + HTTP/2) and QUIC (HTTP/3) on the same port:

```go
package main

import (
    "crypto/tls"
    "log"
    "net/http"

    "github.com/quic-go/quic-go/http3"
)

func main() {
    cert, _ := tls.LoadX509KeyPair("cert.pem", "key.pem")
    tlsConfig := &tls.Config{Certificates: []tls.Certificate{cert}}

    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        // Advertise HTTP/3 to HTTP/1.1 and HTTP/2 clients
        w.Header().Set("Alt-Svc", `h3=":443"; ma=86400`)
        w.Write([]byte("Hello! Protocol: " + r.Proto))
    })

    // HTTP/3 server (QUIC)
    h3Server := &http3.Server{
        Addr:      ":443",
        Handler:   mux,
        TLSConfig: tlsConfig,
    }

    // TCP server (HTTP/1.1 + HTTP/2)
    tcpServer := &http.Server{
        Addr:      ":443",
        Handler:   mux,
        TLSConfig: tlsConfig,
    }

    go func() {
        log.Println("HTTP/3 (QUIC) on :443")
        log.Fatal(h3Server.ListenAndServe())
    }()

    log.Println("HTTP/1.1+HTTP/2 (TCP) on :443")
    log.Fatal(tcpServer.ListenAndServeTLS("", ""))
}
```
