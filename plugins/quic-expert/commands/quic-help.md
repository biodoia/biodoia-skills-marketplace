---
description: Quick QUIC/HTTP3 protocol reference — key concepts, common commands, and implementation cheat sheet
allowed-tools: ["Bash"]
---

# QUIC / HTTP/3 Quick Help

Provide a concise QUIC and HTTP/3 reference based on the user's question.

## Quick Reference

### What is QUIC?
- UDP-based transport protocol (RFC 9000) with built-in TLS 1.3 encryption
- Solves TCP head-of-line blocking via independent stream multiplexing
- 1-RTT handshake (vs 2-3 RTT for TCP+TLS), 0-RTT resumption for repeat connections
- Connection migration: seamless network changes via Connection IDs

### HTTP/3 (RFC 9114)
- HTTP semantics over QUIC instead of TCP
- QPACK header compression (replaces HPACK)
- Discovery via `Alt-Svc: h3=":443"` header or `HTTPS` DNS record

### Test HTTP/3 Support

```bash
curl --http3 -I https://cloudflare.com 2>&1 | head -5
```

```bash
curl --version | grep -i http3
```

### Go (quic-go) Quick Start

```bash
go get github.com/quic-go/quic-go
go get github.com/quic-go/quic-go/http3
```

**Minimal server:**
```go
listener, _ := quic.ListenAddr(":4242", tlsConfig, &quic.Config{})
conn, _ := listener.Accept(ctx)
stream, _ := conn.AcceptStream(ctx)
```

**Minimal client:**
```go
conn, _ := quic.DialAddr(ctx, "server:4242", tlsConfig, &quic.Config{})
stream, _ := conn.OpenStreamSync(ctx)
```

**HTTP/3 server:**
```go
server := &http3.Server{Addr: ":443", Handler: mux, TLSConfig: tlsCfg}
server.ListenAndServe()
```

### Rust (quinn) Quick Start

```bash
cargo add quinn rustls
```

### Python (aioquic) Quick Start

```bash
pip install aioquic
```

### Key Ports and Firewall

- QUIC uses **UDP port 443** (conventional)
- Firewalls must allow UDP 443 (not just TCP 443)
- NAT keep-alive: 15-25 second interval recommended

### Debugging

```bash
# Enable TLS key logging for Wireshark decryption
export SSLKEYLOGFILE=/tmp/quic-keys.log

# Force HTTP/3
curl --http3-only -v https://example.com

# Check if server supports QUIC
curl -I --http3 https://example.com 2>&1 | grep -i alt-svc
```

### Key RFCs

| RFC | Title |
|-----|-------|
| 9000 | QUIC: A UDP-Based Multiplexed and Secure Transport |
| 9001 | Using TLS to Secure QUIC |
| 9002 | QUIC Loss Detection and Congestion Control |
| 9114 | HTTP/3 |
| 9204 | QPACK: Field Compression for HTTP/3 |
| 9221 | QUIC Datagrams |
| 9250 | DNS over Dedicated QUIC Connections |

## How to Respond

1. If the user asks a specific QUIC question, answer it concisely with code examples where appropriate.
2. If the user asks about HTTP/3, include the relationship to QUIC and practical setup steps.
3. If the user asks about a specific implementation (quic-go, quinn, msquic, etc.), provide language-specific guidance.
4. For debugging questions, provide the relevant diagnostic commands and common solutions.
5. Point users to `references/quic-go-guide.md` for detailed Go examples and `references/protocol-deep-dive.md` for protocol internals.
