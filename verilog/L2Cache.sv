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



memDP #(
    .WIDTH     (),
    .DEPTH     (),
    .READ_PORTS(1),
    .BYPASS_EN (0))
L2_mem (
    .clock(clock),
    .reset(reset),
    .re   (read_en),
    .raddr(read_addr),
    .rdata(read_data),
    .we   (write_en),
    .waddr(write_addr),
    .wdata(write_data)
);


/*
    if(evict_valid) begin
        memDP[evict_address] = evict_line;

    end


*/


always_comb begin


end

always_ff @(posedge clock) begin

end
	


endmodule



/*
    TODO:

        1. Understand how memDP works
            - look through EECS470 material?
            - look at 470 final project    


*/