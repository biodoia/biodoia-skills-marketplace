# QUIC Protocol Deep Dive

Technical reference for QUIC protocol internals: packet formats, frame types, state machines, loss detection, congestion control, and RFC coverage.

---

## Packet Types

QUIC defines two categories of packets: **long header** packets (used during connection establishment) and **short header** packets (used after the handshake).

### Long Header Packets

All long header packets share a common format:

```
Long Header Packet {
    Header Form (1) = 1,
    Fixed Bit (1) = 1,
    Long Packet Type (2),
    Type-Specific Bits (4),
    Version (32),
    Destination Connection ID Length (8),
    Destination Connection ID (0..160),
    Source Connection ID Length (8),
    Source Connection ID (0..160),
    Type-Specific Payload (..),
}
```

#### Initial Packet (Type 0x00)

- First packet sent by client to initiate a connection.
- Contains the TLS ClientHello in CRYPTO frames.
- Must be padded to at least 1200 bytes (amplification protection).
- Protected with keys derived from the Destination Connection ID (not secret -- allows servers to decrypt without state).
- Includes a Token field (empty on first flight, populated after Retry or NEW_TOKEN).

#### Handshake Packet (Type 0x02)

- Carries TLS handshake messages (ServerHello completion, Finished).
- Protected with handshake-level encryption keys derived from the TLS handshake.
- Sent by both client and server during the handshake phase.

#### 0-RTT Packet (Type 0x01)

- Sent by the client before the handshake completes, using keys from a previous session.
- Contains early application data (must be idempotent).
- Protected with 0-RTT keys derived from the pre-shared key (PSK) / session ticket.
- Not forward-secret. Server may reject 0-RTT data.

#### Retry Packet (Type 0x03)

- Sent by the server to force address validation.
- Contains a Retry Token that the client must include in a new Initial packet.
- Has an Integrity Tag (not encrypted) to prevent tampering.
- The server does not retain state -- the token encodes all necessary information.

### Short Header Packets (1-RTT)

Used after the handshake completes. Most data transfer occurs in these packets.

```
Short Header Packet {
    Header Form (1) = 0,
    Fixed Bit (1) = 1,
    Spin Bit (1),
    Reserved Bits (2),
    Key Phase (1),
    Packet Number Length (2),
    Destination Connection ID (0..160),
    Packet Number (8..32),
    Packet Payload (..),
}
```

- **Spin Bit**: Alternates with each RTT, allowing passive latency measurement by on-path observers without decryption.
- **Key Phase**: Toggles when encryption keys are rotated (key update).
- **Packet Number**: Monotonically increasing, encoded with variable length (1-4 bytes). Protected by header protection.

### Version Negotiation Packet

Sent by the server when it does not support the client's proposed QUIC version:

```
Version Negotiation {
    Header Form (1) = 1,
    Unused (7),
    Version (32) = 0x00000000,
    DCID Len (8), DCID (..),
    SCID Len (8), SCID (..),
    Supported Versions (32) * N,
}
```

Not cryptographically protected. QUIC v1 version: `0x00000001`. QUIC v2 version: `0x6b3343cf`.

---

## Frame Types

QUIC packets contain one or more frames. Each frame has a type byte followed by type-specific fields.

### Data Transfer Frames

| Type | Name | Description |
|------|------|-------------|
| 0x08-0x0f | **STREAM** | Carries application data on a stream. Includes Stream ID, Offset, Length, and FIN bit. Multiple encoding variants based on which optional fields are present. |
| 0x00 | **PADDING** | Zero-length frame for packet padding. Used to meet minimum packet size requirements. |

### Acknowledgment Frames

| Type | Name | Description |
|------|------|-------------|
| 0x02-0x03 | **ACK** | Acknowledges received packets. Contains Largest Acknowledged, ACK Delay, ACK Range Count, and ACK Ranges (gaps and ranges). Type 0x03 includes ECN counts (CE, ECT0, ECT1). |

### Flow Control Frames

| Type | Name | Description |
|------|------|-------------|
| 0x10 | **MAX_DATA** | Increases the connection-level flow control limit. Receiver advertises new maximum data offset. |
| 0x11 | **MAX_STREAM_DATA** | Increases the stream-level flow control limit for a specific stream. |
| 0x12-0x13 | **MAX_STREAMS** | Increases the maximum number of streams the peer can open. 0x12 = bidirectional, 0x13 = unidirectional. |
| 0x14 | **DATA_BLOCKED** | Signals that the sender is flow-control blocked at the connection level. |
| 0x15 | **STREAM_DATA_BLOCKED** | Signals that the sender is blocked on a specific stream. |
| 0x16-0x17 | **STREAMS_BLOCKED** | Signals that the sender cannot open more streams. |

### Connection Management Frames

| Type | Name | Description |
|------|------|-------------|
| 0x06 | **CRYPTO** | Carries TLS handshake data. Similar to STREAM but for the crypto handshake, with its own offset space. |
| 0x07 | **NEW_TOKEN** | Server provides a token for the client to use in future Initial packets (for 0-RTT or address validation). |
| 0x18 | **NEW_CONNECTION_ID** | Provides a new Connection ID to the peer for connection migration. Includes Sequence Number, Retire Prior To, CID, and Stateless Reset Token. |
| 0x19 | **RETIRE_CONNECTION_ID** | Requests the peer to stop using a specific Connection ID (by sequence number). |
| 0x1a | **PATH_CHALLENGE** | Validates a new network path. Contains 8 bytes of random data. |
| 0x1b | **PATH_RESPONSE** | Responds to PATH_CHALLENGE with the same 8 bytes. Proves reachability on the new path. |
| 0x1c-0x1d | **CONNECTION_CLOSE** | Terminates the connection. 0x1c = QUIC layer error (transport error code). 0x1d = application layer error (application error code + reason phrase). |
| 0x01 | **PING** | Keeps the connection alive. Elicits an ACK from the peer. No payload. |
| 0x1e | **HANDSHAKE_DONE** | Sent by the server to confirm the handshake is complete. Allows the client to discard handshake keys. |

### Stream Control Frames

| Type | Name | Description |
|------|------|-------------|
| 0x04 | **RESET_STREAM** | Abruptly terminates sending on a stream. Includes Application Error Code and Final Size. |
| 0x05 | **STOP_SENDING** | Requests the peer to stop sending on a stream. Includes Application Error Code. |

### Datagram Frame (RFC 9221)

| Type | Name | Description |
|------|------|-------------|
| 0x30-0x31 | **DATAGRAM** | Unreliable data. Not retransmitted on loss. 0x30 = no length field (fills packet), 0x31 = includes length. Must be negotiated via transport parameter. |

---

## Connection State Machine

### Client States

```
                    +-----------+
                    |   Idle    |
                    +-----+-----+
                          |
                    send Initial
                          |
                    +-----v-----+
                    | Handshake |<----+
                    | Initiated |     |
                    +-----+-----+     | Retry
                          |           |
                    recv ServerHello  |
                    recv Retry -------+
                          |
                    +-----v-----+
                    | Handshake |
                    | Complete  |
                    +-----+-----+
                          |
                    recv HANDSHAKE_DONE
                          |
                    +-----v-----+
                    | Connected |
                    +-----+-----+
                          |
                    close / error / timeout
                          |
                    +-----v-----+
                    |  Closing  |
                    +-----+-----+
                          |
                    drain timeout (3 * PTO)
                          |
                    +-----v-----+
                    |  Closed   |
                    +-----------+
```

### Server States

```
                    +-----------+
                    |   Idle    |
                    +-----+-----+
                          |
                    recv Initial
                          |
              +-----------+-----------+
              |                       |
         send Retry              send ServerHello
              |                       |
              v                 +-----v-----+
        (wait for new          | Handshake  |
         Initial with          |   Sent     |
         valid token)          +-----+------+
                                     |
                               recv client Finished
                                     |
                               +-----v-----+
                               | Handshake  |
                               | Complete   |
                               +-----+------+
                                     |
                               send HANDSHAKE_DONE
                                     |
                               +-----v-----+
                               | Connected  |
                               +-----+------+
                                     |
                               close / error / timeout
                                     |
                               +-----v-----+
                               |  Closing   |
                               +-----+------+
                                     |
                               +-----v-----+
                               |   Closed   |
                               +-----------+
```

### Stream States

**Sending side:**

```
        +-------+
        | Ready |  (stream created, not yet sent)
        +---+---+
            |
        send STREAM
            |
        +---v---+
        | Send  |  (sending data)
        +---+---+
            |
        send STREAM with FIN
            |
        +---v-------+
        | Data Sent |  (all data sent, awaiting ACK)
        +---+-------+
            |
        all data ACKed
            |
        +---v-------+
        | Data Recvd|  (terminal)
        +-----------+
```

At any point, sending RESET_STREAM moves to the **Reset Sent** state, and receiving ACK of the reset moves to **Reset Recvd** (terminal).

**Receiving side:**

```
        +------+
        | Recv |  (receiving data)
        +--+---+
           |
        recv STREAM with FIN
           |
        +--v--------+
        | Size Known |  (FIN received, may have gaps)
        +--+---------+
           |
        all data received
           |
        +--v--------+
        | Data Recvd |  (all data available)
        +--+---------+
           |
        data read by application
           |
        +--v--------+
        | Data Read  |  (terminal)
        +-----------+
```

Receiving RESET_STREAM at any point moves to **Reset Recvd**, then **Reset Read** after the application is notified.

---

## Loss Detection and Congestion Control (RFC 9002)

### Loss Detection

QUIC uses three mechanisms for loss detection:

1. **Acknowledgment-based detection**: A packet is considered lost if a later-sent packet has been acknowledged and a threshold time or packet count has elapsed since the lost packet was sent.
   - **Packet threshold**: `kPacketThreshold = 3` -- a packet is lost if 3 or more later packets are acknowledged.
   - **Time threshold**: `kTimeThreshold = 9/8` -- a packet is lost if enough time (9/8 of the max of smoothed RTT and latest RTT) has elapsed since it was sent.

2. **Probe Timeout (PTO)**: When no ACK is received within the PTO interval, the sender sends probe packets (1-2 packets) to elicit ACKs. PTO is calculated as:
   ```
   PTO = smoothed_rtt + max(4 * rtt_var, kGranularity) + max_ack_delay
   ```
   PTO doubles on each consecutive timeout (exponential backoff).

3. **Idle timeout**: The connection is closed if no packets are received for the negotiated idle timeout duration.

### RTT Measurement

```
latest_rtt = ack_receive_time - packet_send_time
ack_delay  = (from ACK frame, only for largest acknowledged)

On first RTT sample:
    smoothed_rtt = latest_rtt
    rttvar       = latest_rtt / 2

On subsequent samples:
    adjusted_rtt = latest_rtt - ack_delay  (if latest_rtt > min_rtt + ack_delay)
    rttvar       = 3/4 * rttvar + 1/4 * |smoothed_rtt - adjusted_rtt|
    smoothed_rtt = 7/8 * smoothed_rtt + 1/8 * adjusted_rtt
```

### Congestion Control

QUIC RFC 9002 specifies a **NewReno**-style congestion controller as the baseline, but implementations are free to use any algorithm (Cubic, BBR, etc.).

**Key variables:**
- `congestion_window` (cwnd): Maximum bytes in flight.
- `bytes_in_flight`: Currently unacknowledged bytes.
- `ssthresh`: Slow start threshold.

**Phases:**

1. **Slow Start**: cwnd starts at `kInitialWindow` (typically 10 * max_datagram_size, ~14 KB). cwnd increases by the number of bytes acknowledged (exponential growth). Exit when cwnd >= ssthresh or loss detected.

2. **Congestion Avoidance**: cwnd increases by `max_datagram_size * acked_bytes / cwnd` per ACK (linear growth, approximately one MSS per RTT).

3. **Recovery**: On loss detection, `ssthresh = cwnd / 2` and `cwnd = ssthresh`. In NewReno, cwnd does not decrease again until the recovery period ends (all packets sent before entering recovery are acknowledged).

**Constants:**
```
kInitialWindow    = min(10 * max_datagram_size, max(14720, 2 * max_datagram_size))
kMinimumWindow    = 2 * max_datagram_size
kLossReductionFactor = 0.5   (NewReno)
kPersistentCongestionThreshold = 3  (consecutive PTO timeouts)
```

**Persistent Congestion**: If packets spanning a duration exceeding `kPersistentCongestionThreshold * PTO` are all declared lost, cwnd is reset to `kMinimumWindow`.

### ECN (Explicit Congestion Notification)

QUIC supports ECN (RFC 3168). If the network marks packets with CE (Congestion Experienced), the receiver reports ECN counts in ACK frames. The sender treats CE marks as congestion signals (equivalent to loss for congestion control purposes).

---

## Flow Control

### Connection-Level Flow Control

- The receiver advertises a `MAX_DATA` limit -- the maximum total bytes the sender can send across all streams combined.
- The sender tracks `data_sent` (cumulative bytes sent on all streams) and must not exceed `MAX_DATA`.
- When the receiver consumes data, it sends updated `MAX_DATA` frames to increase the limit.
- If the sender is blocked, it sends `DATA_BLOCKED` to signal the condition.

### Stream-Level Flow Control

- Each stream has its own `MAX_STREAM_DATA` limit.
- The sender tracks the offset of data sent on each stream and must not exceed the stream's limit.
- The receiver sends `MAX_STREAM_DATA` as it consumes data.
- `STREAM_DATA_BLOCKED` signals that a specific stream is flow-control limited.

### Stream Count Limits

- `MAX_STREAMS` limits how many streams of each type (bidirectional, unidirectional) the peer can open.
- Stream IDs encode the initiator (client/server) and type (bidi/uni):
  - Client-initiated bidirectional: 0, 4, 8, 12, ...
  - Server-initiated bidirectional: 1, 5, 9, 13, ...
  - Client-initiated unidirectional: 2, 6, 10, 14, ...
  - Server-initiated unidirectional: 3, 7, 11, 15, ...
- Formula: `Stream ID = 4 * stream_count + type_bits`

### Initial Flow Control Values (Transport Parameters)

| Parameter | Purpose |
|-----------|---------|
| `initial_max_data` | Initial connection-level flow control limit |
| `initial_max_stream_data_bidi_local` | Initial limit for locally-initiated bidirectional streams |
| `initial_max_stream_data_bidi_remote` | Initial limit for remotely-initiated bidirectional streams |
| `initial_max_stream_data_uni` | Initial limit for unidirectional streams |
| `initial_max_streams_bidi` | Max number of bidirectional streams the peer can initiate |
| `initial_max_streams_uni` | Max number of unidirectional streams the peer can initiate |

---

## Transport Parameters

Exchanged during the TLS handshake in the `quic_transport_parameters` extension:

| Parameter | ID | Description |
|-----------|----|-------------|
| `original_destination_connection_id` | 0x00 | DCID from client's first Initial (server only) |
| `max_idle_timeout` | 0x01 | Milliseconds of inactivity before connection close |
| `stateless_reset_token` | 0x02 | Token for stateless reset (server only) |
| `max_udp_payload_size` | 0x03 | Maximum UDP payload size willing to receive (min 1200) |
| `initial_max_data` | 0x04 | Initial connection flow control limit |
| `initial_max_stream_data_bidi_local` | 0x05 | Initial stream limit (bidi, local-initiated) |
| `initial_max_stream_data_bidi_remote` | 0x06 | Initial stream limit (bidi, remote-initiated) |
| `initial_max_stream_data_uni` | 0x07 | Initial stream limit (unidirectional) |
| `initial_max_streams_bidi` | 0x08 | Max bidirectional streams peer can open |
| `initial_max_streams_uni` | 0x09 | Max unidirectional streams peer can open |
| `ack_delay_exponent` | 0x0a | Exponent for ACK Delay field encoding (default 3) |
| `max_ack_delay` | 0x0b | Maximum ACK delay in milliseconds (default 25) |
| `disable_active_migration` | 0x0c | Disables connection migration |
| `preferred_address` | 0x0d | Server's preferred address for migration (server only) |
| `active_connection_id_limit` | 0x0e | Max CIDs from peer to store (min 2) |
| `initial_source_connection_id` | 0x0f | SCID in the first Initial packet |
| `retry_source_connection_id` | 0x10 | SCID in Retry packet (server only) |
| `max_datagram_frame_size` | 0x20 | Max DATAGRAM frame size (RFC 9221, 0 = disabled) |

---

## Version Negotiation

- QUIC v1: `0x00000001` (RFC 9000)
- QUIC v2: `0x6b3343cf` (RFC 9369, uses different salt/labels but same wire format)

When a server receives an Initial with an unsupported version, it responds with a Version Negotiation packet listing supported versions. The client must then retry with a supported version.

**QUIC Version 2 (RFC 9369)** is intentionally compatible with v1 -- same packet formats, same frame types, different cryptographic constants (Initial salt, labels). This tests version negotiation implementations and provides cryptographic agility.

---

## QUIC and TLS 1.3 Integration (RFC 9001)

QUIC replaces TLS's record layer. TLS handshake messages are carried in CRYPTO frames at different encryption levels:

| Encryption Level | Packet Type | Keys Derived From |
|-----------------|-------------|-------------------|
| Initial | Initial | Destination Connection ID (public) |
| Handshake | Handshake | TLS handshake (DH key exchange) |
| 0-RTT | 0-RTT | Pre-shared key / session ticket |
| 1-RTT (Application) | Short Header | TLS handshake completion |

**Key schedule**: QUIC derives packet protection keys from TLS secrets using HKDF-Expand-Label, same as TLS 1.3 but with QUIC-specific labels.

**Header protection**: Packet numbers and certain header bits are encrypted using a separate header protection key derived from the same traffic secret. This prevents ossification of packet number encoding.

**Key update**: Either endpoint can initiate a key update by toggling the Key Phase bit in short header packets. New keys are derived from the current traffic secret using HKDF-Expand-Label. The old keys are retained briefly for decrypting reordered packets.

---

## QUIC Transport Error Codes

| Code | Name | Description |
|------|------|-------------|
| 0x00 | NO_ERROR | Graceful connection close |
| 0x01 | INTERNAL_ERROR | Implementation error |
| 0x02 | CONNECTION_REFUSED | Server refused the connection |
| 0x03 | FLOW_CONTROL_ERROR | Flow control violation |
| 0x04 | STREAM_LIMIT_ERROR | Too many streams opened |
| 0x05 | STREAM_STATE_ERROR | Frame received in invalid stream state |
| 0x06 | FINAL_SIZE_ERROR | Change in final size for a stream |
| 0x07 | FRAME_ENCODING_ERROR | Frame encoding error |
| 0x08 | TRANSPORT_PARAMETER_ERROR | Invalid transport parameter |
| 0x09 | CONNECTION_ID_LIMIT_ERROR | Too many Connection IDs issued |
| 0x0a | PROTOCOL_VIOLATION | Generic protocol violation |
| 0x0b | INVALID_TOKEN | Invalid Retry or NEW_TOKEN token |
| 0x0c | APPLICATION_ERROR | Application-layer error (used when closing with app error code) |
| 0x0d | CRYPTO_BUFFER_EXCEEDED | Too much CRYPTO data buffered |
| 0x0e | KEY_UPDATE_ERROR | Key update failure |
| 0x0f | AEAD_LIMIT_REACHED | Too many packets with same keys (AEAD confidentiality limit) |
| 0x10 | NO_VIABLE_PATH | No valid network path available |
| 0x0100-0x01ff | CRYPTO_ERROR | TLS alert mapped to QUIC (0x0100 + TLS alert code) |

---

## HTTP/3 Frame Types (RFC 9114)

HTTP/3 uses its own framing on top of QUIC streams:

| Type | Name | Description |
|------|------|-------------|
| 0x00 | DATA | HTTP message body data |
| 0x01 | HEADERS | Encoded HTTP header fields (QPACK compressed) |
| 0x03 | CANCEL_PUSH | Cancel a server push (by Push ID) |
| 0x04 | SETTINGS | Connection-level settings (sent on control stream) |
| 0x05 | PUSH_PROMISE | Server push announcement |
| 0x07 | GOAWAY | Graceful connection shutdown (last processed Stream/Push ID) |
| 0x0d | MAX_PUSH_ID | Maximum Push ID the client will accept |

### HTTP/3 Settings

| Setting | ID | Description |
|---------|----|-------------|
| SETTINGS_MAX_FIELD_SECTION_SIZE | 0x06 | Max size of header section (bytes) |
| SETTINGS_QPACK_MAX_TABLE_CAPACITY | 0x01 | Max QPACK dynamic table size |
| SETTINGS_QPACK_BLOCKED_STREAMS | 0x07 | Max streams that can be blocked by QPACK |

### HTTP/3 Error Codes

| Code | Name | Description |
|------|------|-------------|
| 0x0100 | H3_NO_ERROR | No error |
| 0x0101 | H3_GENERAL_PROTOCOL_ERROR | Generic protocol error |
| 0x0102 | H3_INTERNAL_ERROR | Internal error |
| 0x0103 | H3_STREAM_CREATION_ERROR | Stream creation error |
| 0x0104 | H3_CLOSED_CRITICAL_STREAM | Critical stream closed |
| 0x0105 | H3_FRAME_UNEXPECTED | Frame type not permitted |
| 0x0106 | H3_FRAME_ERROR | Frame format error |
| 0x0107 | H3_EXCESSIVE_LOAD | Peer generating excessive load |
| 0x0108 | H3_ID_ERROR | Invalid identifier |
| 0x0109 | H3_SETTINGS_ERROR | Settings error |
| 0x010a | H3_MISSING_SETTINGS | No SETTINGS received |
| 0x010b | H3_REQUEST_REJECTED | Request not processed |
| 0x010c | H3_REQUEST_CANCELLED | Request cancelled |
| 0x010d | H3_REQUEST_INCOMPLETE | Stream terminated early |
| 0x010e | H3_MESSAGE_ERROR | Malformed HTTP message |
| 0x010f | H3_CONNECT_ERROR | CONNECT tunnel error |
| 0x0110 | H3_VERSION_FALLBACK | HTTP/3 version fallback |

---

## RFCs Reference Table

| RFC | Title | Status | Published |
|-----|-------|--------|-----------|
| **9000** | QUIC: A UDP-Based Multiplexed and Secure Transport | Standards Track | May 2021 |
| **9001** | Using TLS to Secure QUIC | Standards Track | May 2021 |
| **9002** | QUIC Loss Detection and Congestion Control | Standards Track | May 2021 |
| **9114** | HTTP/3 | Standards Track | June 2022 |
| **9204** | QPACK: Field Compression for HTTP/3 | Standards Track | June 2022 |
| **9218** | Extensible Prioritization Scheme for HTTP | Standards Track | June 2022 |
| **9221** | An Unreliable Datagram Extension to QUIC | Standards Track | March 2022 |
| **9250** | DNS over Dedicated QUIC Connections (DoQ) | Standards Track | May 2022 |
| **9297** | HTTP Datagrams and the Capsule Protocol | Standards Track | August 2022 |
| **9298** | Proxying UDP in HTTP (MASQUE CONNECT-UDP) | Standards Track | August 2022 |
| **9312** | Manageability of the QUIC Transport Protocol | Informational | September 2022 |
| **9308** | Applicability of the QUIC Transport Protocol | Informational | September 2022 |
| **9368** | Compatible Version Negotiation for QUIC | Standards Track | May 2023 |
| **9369** | QUIC Version 2 | Standards Track | May 2023 |
| **9484** | Proxying IP in HTTP (MASQUE CONNECT-IP) | Standards Track | October 2023 |
| **9457** | Logging QUIC Events with qlog | Informational | -- |

### Related Drafts (Active)

| Draft | Title | Status |
|-------|-------|--------|
| draft-ietf-moq-transport | Media over QUIC Transport | Working Group Draft |
| draft-ietf-webtrans-http3 | WebTransport over HTTP/3 | Working Group Draft |
| draft-ietf-quic-multipath | Multipath QUIC | Working Group Draft |
| draft-ietf-quic-ack-frequency | QUIC ACK Frequency | Working Group Draft |

---

## Minimum Packet Size Requirements

- **Initial packets** must be at least 1200 bytes (padded if necessary). This prevents amplification attacks by ensuring the client commits non-trivial bandwidth.
- **All QUIC packets** must fit within `max_udp_payload_size` (minimum 1200 bytes). The default maximum is 65527 bytes (UDP maximum), but path MTU discovery may constrain this further.
- **PMTUD (Path MTU Discovery)**: QUIC implementations should perform DPLPMTUD (Datagram Packetization Layer PMTU Discovery, RFC 8899) to find the largest packet size the path supports without fragmentation.

---

## Stateless Reset

If a server loses state (crash, restart) and receives a packet for an unknown connection, it can send a **Stateless Reset** -- a packet that looks like a short header packet but ends with a 16-byte Stateless Reset Token. The client recognizes the token (received earlier via `NEW_CONNECTION_ID` or transport parameters) and closes the connection.

```
Stateless Reset {
    Fixed Bits (2) = 01,
    Unpredictable Bits (38..),
    Stateless Reset Token (128),
}
```

The packet must be indistinguishable from a regular short header packet to observers, preventing off-path injection of resets.
