`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

`timescale 1ns/100ps

`define NUM_CORES 4
`define NUM_CORE_BITS $clog{NUM_CORES}
typedef logic [511:0] CACHE_LINE; 

typedef union packed {
    logic [31:0] addr;
    struct packed {
        logic                    [31:13] tag;
        logic                     [12:6] set_idx;
        logic                      [5:0] offset;
    } l1_addr;

    struct packed {
        logic                     [31:16] tag;
        logic                      [15:6] set_idx;
        logic                       [5:0] offset;
    } l2_addr;
} ADDR;

typedef struct packed {
    logic [2:0] req_type;
    CACHE_LINE cache_line;
    ADDR target_addr;
    logic [`NUM_CORE_BITS-1:0] core_id;
} L2_ENTRY_PACKET;

typedef struct packed {
    logic [2:0] req_type;
    CACHE_LINE cache_line;
    ADDR target_addr;
    logic [`NUM_CORE_BITS-1:0] core_id;
    logic evict_confirm;
    logic upgrade_confirm;
} L2_EXIT_PACKET;


typedef struct packed {
    ADDR ar_addr, // Address to read from
    logic ar_valid,//asserted by L2 cache when request is ready
    logic [1:0] ar_len,
    logic [1:0] ar_size,
    logic [1:0] ar_burst,
} ADDRESS_READ_PACKET;

typedef struct packed {
    CACHE_LINE r_data, // Data returned from DRAM
    logic r_valid, // Asserted by DRAM when data is valid
    logic r_last,
    logic r_resp,
} READ_DATA_PACKET;

typedef struct packed {
    logic aw_valid,//asserted by L2 cache when request is ready
    logic [1:0] aw_len,
    logic [1:0] aw_size,
    logic [1:0] aw_burst,
} ADDRESS_WRITE_PACKET;

typedef struct packed {
    CACHE_LINE w_data, // Data to write
    logic w_valid,//asserted by L2 cache when request is ready
    logic [63:0] w_strb, //will always be all 1s as I am not planning on doing partial writes
    logic w_last,
} WRITE_DATA_PACKET;

typedef struct packed {
    logic b_resp,
    logic b_ready
} WRITE_RESPONSE_PACKET;


/*
- Address Read: Master tells slave what address it is trying to read
    - `ARADDR`: Address to read from
    - `ARVALID`: Asserted by L2 cache when request is ready
    - `ARREADY`: Asserted by DRAM when it's ready to accept
    - `ARSIZE`, `ARBURST`, `ARLEN`: Control signals defining burst size, type, and length
- Read Data: Slave gives master the data it wants to read
    - `RDATA`: Data returned from DRAM
    - `RVALID`: Asserted by DRAM when data is valid
    - `RREADY`: Asserted by L2 cache when it’s ready to accept
    - `RLAST`: Marks the final beat in a burst
    - `RRESP`: Response status (e.g., OKAY or SLVERR)
- Address Write: Master tells slave what address it is trying to write to
    - `AWVALID`, `AWREADY`: Same handshake pattern
    - `AWSIZE`, `AWBURST`, `AWLEN`: Similar to `AR` channel
- Write Data: Master gives slave the data it is trying to write
    - `WDATA`: Data to write
    - `WSTRB`: Byte-wise write enables
    - `WVALID`, `WREADY`: Handshake
    - `WLAST`: Final beat of burst
- Write Response: Slave tells master if it successfully received the new data
    - `BRESP`: Status of write
    - `BVALID`, `BREADY`: Standard handshake
*/