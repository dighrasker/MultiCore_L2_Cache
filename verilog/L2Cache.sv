`include "verilog/sys_defs.svh"

module L2Cache #() (
	input                    logic clock,
	input                    logic reset,
//-------------To/From L1 Cache------------//
    input          L2_ENTRY_PACKET l2_entry_packet, 
    output          L2_EXIT_PACKET l2_exit_packet,
//-------------To/From DRAM (AXI4)----------------//
//Address Read: Master tells slave what address it is trying to read
    input                     logic ar_ready, 
    output      ADDRESS_READ_PACKET ar_packet,
// Read Data: Slave gives master the data it wants to read
    input          READ_DATA_PACKET r_packet,
    output                    logic r_ready,
//Address Write: Master tells slave what address it is trying to write to
    input                     logic aw_ready, 
    output     ADDRESS_WRITE_PACKET aw_packet,
//Write Data: Master gives slave the data it is trying to write
    input                     logic w_ready, //asserted by DRAM
    output        WRITE_DATA_PACKET w_packet,
//Write Response: Slave tells master if it successfully received the new data
    input     WRITE_RESPONSE_PACKET b_packet,
    output                    logic b_valid
); 


// Eviction policy (LRU bits) --NOOTTTT DONEEEE

//parameters for memDP
logic read_en, write_en;
CACHE_LINE  [`WAYS-1: 0] read_data;
CACHE_LINE  [`WAYS-1: 0] write_data, next_write_data;
META_PACKET [`WAYS-1: 0] read_meta;
META_PACKET [`WAYS-1: 0] write_meta, next_write_meta;


L2_EXIT_PACKET l2_exit;
logic [`WAYS-1:0] hit;
logic hit_any;

assign read_en = (l2_entry_packet.req_type == READ)|| (l2_entry_packet.req_type == WRITE);
assign write_en = l2_entry_packet.req_type == EVICT;

for(genvar w = 0; w < `WAYS; ++w) begin : ways
    //creates 8 data arrays for each way
    memDP #(
        .WIDTH     (`LINE_SIZE_BITS),
        .DEPTH     (`NUM_SETS),
        .READ_PORTS(1),
        .BYPASS_EN (0))
    L2_data (
        .clock(clock),
        .reset(reset),
        .re   (read_en),
        .raddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .rdata(read_data[w]),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata(write_data)
    );

    //corresponding tag array
    memDP #(
        .WIDTH     (`META_WIDTH),
        .DEPTH     (`NUM_SETS),
        .READ_PORTS(1),
        .BYPASS_EN (0))
    L2_tags (
        .clock(clock),
        .reset(reset),
        .re   (read_en),
        .raddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .rdata(read_meta[w]),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata(write_meta)
    );

    hit[w] = read_meta[w].valid && (read_meta[w].tag == l2_entry_packet.target_addr.l2_addr.tag);

end

always_comb begin
    /*
        logic evict_confirm;
        logic upgrade_confirm;
    */

    l2_exit = '0;
    l2_exit.req_type = l2_entry_packet.req_type;
    l2_exit.target_addr = l2_entry_packet.target_addr;
    l2_exit.core_id = l2_entry_packet.core_id;

    hit_any = |hit;

    next_write_meta = write_meta;
    
    if(l2_entry_packet.req_type == READ || l2_entry_packet.req_type == WRITE) begin
        if(hit_any) begin

            //send back the requested cache line
            for(int i = 0; i < `WAYS; ++i) begin
                if(hit[i]) begin
                    l2_exit.cache_line = read_data[i];
                end
            end

            //update meta data in case of a read
            if(l2_entry_packet.req_type == READ) begin
                next_write_meta.sharers[l2_entry_packet.core_id] = 1'b1;
                next_write_meta.owner_state = 
            end

            //update meta data in case of a write
            if(l2_entry_packet.req_type == WRITE) begin
                for(int k = 0; k < `NUM_CORES; ++k) begin
                    next_write_meta.sharers[k] = (k == l2_entry_packet.core_id);
                end
                next_write_meta.dirty = 1'b1;
                next_write_meta.owner_state = MODIFIED;
            end

        end else begin //MSHR and AXI4 read logic
        
        end
    end else if (l2_entry_packet.req_type == EVICT) begin

    
    end else begin

    end
end

always_ff @(posedge clock) begin
    if (reset) begin
        l2_exit_packet <= 0;
        write_meta <= 0;
        write_data <= 0;
    end else begin
        l2_exit_packet <= l2_exit;
        write_meta <= next_write_meta;
        write_data <= next_write_data;
    end

end


endmodule



/*
  1. How are we structuring the meta data
    -> each cache line needs bits to tell us what MESI state its in 
    -> tag bits 



  L2 receives an L2_ENTRY_PACKET from L1 as input

    1. L1 is requesting to read data because that instruction missed in the L1 cache
        -> Decompose the adress into tag/index/offset bits
        -> use set index bits to retrieve tag, data in parallel
        -> If there is a tag match
            - we return the requested data line
            - we update the meta data table to give exclusive access if no other core has it, shared access if other cores have it, and Modified access if req_type is a write
        -> If there it is a L2 miss
            - we need to allocate an MSHR so we can access DRAM for it
            - one the cache line is back from DRAM, update memDP and send data line back to the L1 that requested it
    2. L1 is evicting a dirty line and we need to update 


    TODO:
    1. Figure out MSHR stuff
    2. 


*/
