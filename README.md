# FPGA-Based SERDES Implementation with CRC Error Detection

## Overview

This project implements a Serializer/Deserializer (SERDES) system using Verilog HDL. It converts 8-bit parallel data into a serial bitstream for transmission and reconstructs the original data at the receiver.

The design combines 8b/10b encoding and CRC-8 ATM error detection to improve data integrity during serial communication.

## Project Features

- 8-bit parallel data transmission.
- 8b/10b encoding and decoding.
- 20-bit frame construction.
- Serial-to-parallel and parallel-to-serial conversion.
- CRC-8 ATM generation and verification.
- Invalid symbol detection.
- CRC error detection.
- Optional CRC error injection for testing.
- CRC pass and failure LED indicators.

## System Architecture

The design consists of three main components:

### 1. SERDES Transmitter

The transmitter accepts 8-bit parallel input data and performs the following operations:

1. Accepts input data when `data_valid` is asserted.
2. Calculates the CRC-8 ATM value.
3. Encodes the 8-bit data into a 10-bit symbol using 8b/10b encoding.
4. Encodes the CRC into another 10-bit symbol.
5. Combines both symbols into a 20-bit frame.
6. Serializes and transmits the frame one bit at a time.

### 2. SERDES Receiver

The receiver performs the following operations:

1. Receives the serial bitstream.
2. Collects 20 bits to reconstruct the frame.
3. Separates the encoded data and CRC symbols.
4. Decodes both 10-bit symbols.
5. Checks the validity of the decoded symbols.
6. Recalculates CRC-8 ATM.
7. Compares the calculated CRC with the received CRC.

### 3. 8b/10b Encoder and Decoder

The encoding and decoding functions convert each 8-bit input symbol into a 10-bit code and recover the original data at the receiver.

The implementation also maintains running disparity information during encoding and decoding.

## Frame Format

Each transmitted frame contains two 10-bit symbols.

| Field | Size |
|---|---:|
| Encoded data symbol | 10 bits |
| Encoded CRC symbol | 10 bits |
| **Total frame size** | **20 bits** |

## CRC Configuration

| Parameter | Value |
|---|---|
| CRC Type | CRC-8 ATM |
| Polynomial | `0x07` |
| Initial Value | `0x00` |
| CRC Width | 8 bits |

The transmitter includes an optional `force_crc_error` input that deliberately flips one CRC bit to demonstrate CRC error detection.

## Technologies Used

- Verilog HDL
- FPGA Design
- Digital Logic Design
- SERDES Architecture
- 8b/10b Encoding and Decoding
- CRC Error Detection
- Xilinx Design Tools

## Repository Structure

```text
Fpga_serdes_implementation/
│
├── serdes_transmitter.v
├── serdes_receiver.v
├── eightbtenb_functions.vh
└── README.md
```

## Applications

- High-speed serial communication systems
- Data transmission interfaces
- FPGA-based communication systems
- Digital communication and error detection

## Future Enhancements

- Develop a comprehensive simulation testbench.
- Verify functionality with different input data patterns.
- Perform FPGA hardware implementation and validation.
- Improve and verify running disparity handling.
- Extend the design for higher-speed serial communication.

## Project Status

The Verilog source modules for the transmitter, receiver, and encoding/decoding functions are available in this repository. Further simulation and hardware validation are required to establish complete functional verification.
