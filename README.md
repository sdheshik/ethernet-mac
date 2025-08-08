# FPGA Ethernet RMII Stack (VHDL)

A compact, modular Ethernet transmit/receive stack for FPGAs using an RMII PHY interface, written in VHDL. It builds complete Ethernet frames on TX (Ethernet + IPv4 + UDP + CRC32), streams payload from a ROM/FIFO, and receives frames on RX with preamble/SFD detection and CRC checking.

- RMII MAC-side interface with preamble (0x55 × 7) and SFD (0xD5) generation and detection
- UDP header generator with proper 8-byte header layout and length computation
- Ethernet FCS generator (CRC32, IEEE 802.3 polynomial 0x04C11DB7, reflected form 0xEDB88320)
- Simple IPv4 header generator without options (IHL = 5)
- Clean handshakes between header generation, payload ROM, and RMII streaming

Note: Preamble and SFD are handled explicitly for RMII timing and alignment.

## Top-Level Architecture

- **ethernet_top**
  - System integration: clocks/resets, FIFOs, ROM source, header pipeline, CRC generator/checker, and RMII interface wiring
- **phy_rmii_if**
  - TX: emits preamble + SFD, header FIFO bytes, payload FIFO bytes, and final CRC nibble-wise over RMII
  - RX: converts 2-bit RMII to bytes, detects preamble/SFD, captures payload, tracks last 4 bytes, and flags frame end for CRC compare
- **header_control**
  - Sequences Ethernet → IPv4 → UDP header modules and streams bytes into a header FIFO
- **ethernet_header**
  - Outputs destination/source MAC and EtherType (0x0800)
- **ip_header**
  - Outputs 20-byte IPv4 header (no options), computes header checksum
- **udp_header**
  - Outputs 8-byte UDP header, computes checksum over pseudo-header + UDP header + payload
- **tx_rom**
  - Byte ROM streamer providing payload to TX FIFO (file-backed)
- **crc_gen**
  - Byte-wise Ethernet CRC32 generator (reflected, init 0xFFFFFFFF, final inversion)
- **crc**
  - Byte-wise CRC32 checker for RX (reflected mapping)

## Features

### RMII TX Path
- 7-byte preamble 0x55 and SFD 0xD5 generation
- Headers from header FIFO, payload from payload FIFO, CRC32 appended at end
- CRC32 per IEEE 802.3 (0x04C11DB7, reflected implementation 0xEDB88320)

### RMII RX Path
- 2-bit-to-8-bit deserializer, preamble/SFD detection, frame byte counting, last-4-byte tracking
- RX CRC calculation and crc_ok/frame_ready at frame completion

### UDP Encapsulation
- UDP header is 8 bytes; Length = header (8) + payload

### Parameterized Payload Source
- tx_rom loads bytes from a text/MIF file and streams to the TX FIFO

### Debug Support
- MARK_DEBUG on internal nets; LED/status outputs for bring-up

## Repository Layout

- `ethernet_top.vhd` — Top-level integration
- `phy_rmii_if.vhd` — RMII TX/RX FSMs, preamble/SFD, CRC hookups, FIFO interfacing
- `header_control.vhd` — Orchestrates ethernet_header, ip_header, udp_header
- `ethernet_header.vhd` — Destination MAC, Source MAC, EtherType
- `ip_header.vhd` — 20-byte IPv4 header, checksum
- `udp_header.vhd` — 8-byte UDP header, checksum
- `crc_gen.vhd` — CRC32 generator (TX path)
- `crc.vhd` — CRC32 checker (RX path)
- `tx_rom.vhd` — ROM-backed payload source
- `fifo.vhd`, `rst_sync.vhd`, `clk_wiz_0` (IP), `vio_reset` (IP), `shift2to8.vhd`, `synchronizer.vhd` — Support modules

*Filenames may vary slightly with your project structure.*

## Getting Started

### Prerequisites

- FPGA toolchain with VHDL-2008 support (recommended)
- sys_clk source; a clocking wizard derives a 50 MHz RMII ref clock
- RMII PHY wired to: phy_ref_clk (50 MHz), phy_txd[1:0], phy_tx_en, phy_rxd[1:0], phy_crs_dv, phy_mdio, phy_mdc
- Optional: ILA for MARK_DEBUG nets

### Build and Synthesize

1. Add all VHDL sources and vendor IP (clk_wiz_0, vio_reset) to your project
2. Ensure `tx_data.mif` (or equivalent) is present for tx_rom initialization
3. Constrain RMII pins and clocks as per your board
4. Synthesize, implement, and generate bitstream

### Simulation Tips

- Drive `start_frame_tx` to initiate transmission from ethernet_top
- Drive `head_start` to generate headers via header_control
- Provide `tx_data.mif` for payload
- For RX, feed a valid RMII stream with preamble 0x55 × 7 and SFD 0xD5; expect `crc_ok` and `frame_ready` when complete

## Configuration

### tx_rom Generics
- `data_width`: typically 8
- `depth`: number of payload bytes
- `data_file`: path to payload file

### Header Constants
- MAC addresses (ethernet_header)
- IP addresses, TTL, protocol (ip_header)
- UDP ports and payload length (udp_header)

**Note:** UDP length must equal 8 + payload length

## CRC32 Details

- **Polynomial:** IEEE 802.3 CRC32 0x04C11DB7 (reflected 0xEDB88320)
- **Initialization:** 0xFFFFFFFF
- **Output:** reflected and inverted for Ethernet FCS

## Usage Flow

1. **Pulse `head_start`:** header_control fills header FIFO (Ethernet → IP → UDP)
2. **Pulse `start_frame_tx`:** phy_rmii_if streams preamble + SFD, headers, payload from TX FIFO, then CRC
3. **Payload streaming:** tx_rom streams bytes to TX FIFO on init_frame or init_tx
4. **RX processing:** phy_rmii_if deserializes RMII RX into bytes, pushes to RX FIFO, and asserts frame_ready/crc_ok on completion

## Notes and Limitations

- IPv4 header fixed to IHL = 5 (no options)
- Ensure IPs, ports, and lengths match your payload when using UDP checksum
- MDIO control is not implemented (phy_mdio tri-stated; phy_mdc simple divider)

## Extending the Design

- Replace tx_rom with a live data producer (streaming FIFO, DMA)
- Add MDIO management for PHY configuration
- Parameterize IP/UDP fields via registers/control bus
- Add RX parsing beyond CRC validation