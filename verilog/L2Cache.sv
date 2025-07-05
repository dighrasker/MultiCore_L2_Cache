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
    output             ADDRESS_READ ar_packet,
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


//instantiating all the memDPs

/*
-> Things we need to keep track of in the L2 cache
    1. the actual data itself  ---DONE
    2. Tags for each cache line for tag comparisons  --DONE
    3. MESI state for each core --DONE
    4. Eviction policy (LRU bits) --NOOTTTT DONEEEE
    5. Dirty + valid bits   --DONE
*/

logic read_en, write_en;
CACHE_LINE read_data;
META_PACKET read_meta;

assign read_en = l2_entry_packet.req_type == READ || WRITE;
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
        .rdata(read_data),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata(l2_entry_packet.cache_line)
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
        .rdata(read_meta),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata()
    );

end

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


*/


always_comb begin


end

always_ff @(posedge clock) begin

end
	


endmodule
