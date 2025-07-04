module L2Cache #() (
	input logic clock,
	input logic reset,
	
//-------------To/From L1 Cache------------//
	input logic evict_valid, //High when L1 wants to evict a cache line
	input logic [511:0] evict_line,  //64 byte cache line that L1 wants to evict
	input logic [31:0] evict_addr,   //Address associated with the evicted cache line
	output logic evict_ready,   //L2 cache is ready to accept eviction
	
	output logic refill_valid, //L2 has a line to send back to L1
	output logic [511:0] refill_data,  //Cache line that L2 wants to send to L1
	output logic [31:0] refill_addr, //address associated with the cache line going to L1
	input logic refill_ready, //L1 is ready to accept the refill line
    output logic [3:0] l1_mask,
	output logic [1:0] mesi_state,
	
//-------------To/From DRAM----------------//
	
//Address Read: Master tells slave what address it is trying to read
    output logic [31:0] ar_addr, // Address to read from
    output logic ar_valid,//asserted by L2 cache when request is ready
    input logic ar_ready, //asserted by DRAM
    output logic [1:0] ar_len,
    output logic [1:0] ar_size,
    output logic [1:0] ar_burst,
// Read Data: Slave gives master the data it wants to read
    input logic [511:0] r_data, // Data returned from DRAM
    input logic r_valid, // Asserted by DRAM when data is valid
    output logic r_ready, // Asserted by L2 cache when it’s ready to accept
    input logic r_last,
    input logic r_resp,
//Address Write: Master tells slave what address it is trying to write to
    output logic aw_valid,//asserted by L2 cache when request is ready
    input logic aw_ready, //asserted by DRAM
    output logic [1:0] aw_len,
    output logic [1:0] aw_size,
    output logic [1:0] aw_burst,
//Write Data: Master gives slave the data it is trying to write
    output logic [511:0] w_data, // Data to write
    output logic w_valid,//asserted by L2 cache when request is ready
    input logic w_ready, //asserted by DRAM
    output logic [63:0] w_strb, //will always be all 1s as I am not planning on doing partial writes
    output logic w_last,
//Write Response: Slave tells master if it successfully received the new data
    input logic b_resp,
    output logic b_valid,
    input logic b_ready
); 

memDP #(
    .WIDTH     ($bits(MEM_BLOCK)),
    .DEPTH     (),
    .READ_PORTS(1),
    .BYPASS_EN (0))
L2_mem (
    .clock(clock),
    .reset(reset),
    .re   (),
    .raddr(),
    .rdata(),
    .we   (),
    .waddr(),
    .wdata()
);


//logic that deals with L1 communication

//logic that tracks MESI protocol

//logic that deals with DRAM communication

endmodule