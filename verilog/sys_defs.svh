`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

`timescale 1ns/100ps

`define NUM_CORES 4
`define NUM_CORE_BITS $clog2(NUM_CORES)


//L2 Cache size parameters
`define CACHE_SIZE_BYTES 512000
`define WAYS 8
`define LINE_SIZE_BYTES 64
`define SET_SIZE_BYTES `WAYS * `LINE_SIZE_BYTES
`define NUM_SETS `CACHE_SIZE_BYTES / `SET_SIZE_BYTES
`define NUM_SETS_BITS $clog2(`NUM_SETS)
`define LINE_SIZE_BITS (`LINE_SIZE_BYTES * 8)
`define L2_TAG_WIDTH 32 - $clog2(`NUM_SETS) - $clog2(`LINE_SIZE_BITS)
`define META_WIDTH 1 + 1 + `NUM_CORES + 2 + `L2_TAG_WIDTH
`define NUM_MSHRS 8
`define WAY_IDX_BITS $clog2(`WAYS)

typedef logic [`WAY_IDX_BITS-1:0] LRU;
typedef logic [`NUM_SETS_BITS-1:0] SET_IDX;

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

typedef enum logic [2:0] {
    UPGRADE  = 3'b000,
    READ     = 3'b001,
    WRITE    = 3'b010,
    EVICT    = 3'b011
} REQ_TYPE_ENUM;

typedef enum logic [1:0] {
    INAVLID  = 2'b00,
    SHARED     = 2'b01,
    EXCLUSIVE    = 2'b10,
    MODIFIED    = 2'b11
} OWNER_STATE_ENUM;

typedef struct packed {
    REQ_TYPE_ENUM req_type;
    CACHE_LINE cache_line;
    ADDR target_addr;
    logic [`NUM_CORE_BITS-1:0] core_id;
} L2_ENTRY_PACKET;

typedef struct packed {
    logic [2:0] req_type;
    CACHE_LINE cache_line;
    ADDR target_addr;
    //logic [`NUM_CORE_BITS-1:0] core_id;
    logic evict_confirm;
    logic upgrade_confirm;
    logic stall;
} L2_EXIT_PACKET;

typedef struct packed {
    ADDR ar_addr; // Address to read from
    logic ar_valid;//asserted by L2 cache when request is ready
    logic [2:0] ar_prot;
} ADDRESS_READ_PACKET;

typedef struct packed {
    CACHE_LINE r_data; // Data returned from DRAM
    logic r_valid; // Asserted by DRAM when data is valid
    logic r_resp;
} READ_DATA_PACKET;

typedef struct packed {
    ADDR aw_addr; // Address to read from
    logic aw_valid;//asserted by L2 cache when request is ready
    logic [2:0] aw_prot;
} ADDRESS_WRITE_PACKET;

typedef struct packed {
    CACHE_LINE w_data; // Data to write
    logic w_valid;//asserted by L2 cache when request is ready
    logic [63:0] w_strb; //will always be all 1s as I am not planning on doing partial writes
} WRITE_DATA_PACKET;

typedef struct packed {
    logic b_resp;
    logic b_valid;
} WRITE_RESPONSE_PACKET;

typedef struct packed {
    logic                        valid;
    logic                        dirty;
    logic [`NUM_CORES-1:0]       sharers;
    OWNER_STATE_ENUM             owner_state;
    ADDR                         addr;
} META_PACKET;

typedef struct packed {
    logic                       valid;
    ADDR                        addr;
    logic [`NUM_CORE_BITS-1:0]  core_id;
    REQ_TYPE_ENUM               req_type;
} SNOOP_REQ_PACKET;

typedef struct packed {
    logic                       valid;
    ADDR                        addr;
    CACHE_LINE                  data;
    logic [`NUM_CORE_BITS-1:0]  core_id;
} SNOOP_RESP_PACKET;

typedef struct packed {
    logic                       valid;
    ADDR                        addr;
    CACHE_LINE                  data;
    logic [`NUM_CORE_BITS-1:0]  core_id;
    logic                       write_req;
} MSHR;

/*
meta_packet.owner_state
• 00 = Invalid / not present (only valid=0 uses this)
• 01 = Shared (no core has write permission; can be many sharers)
• 10 = Exclusive (exactly one sharer, clean)
• 11 = Modified (exactly one sharer, dirty).
*/