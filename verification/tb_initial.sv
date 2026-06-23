
`include "include/sys_defs.svh"

module tb();

    
	logic clock;
	logic reset;
//-------------To/From L1 Cache------------//
    L2_ENTRY_PACKET l2_entry_packet; //seq
    L2_EXIT_PACKET [`NUM_CORES-1: 0] l2_exit_packet; //seq
    logic  [`NUM_CORES-1: 0] l2_exit_valid;
    SNOOP_RESP_PACKET [`NUM_CORES-1: 0] snoop_resp; //seq
    SNOOP_REQ_PACKET [`NUM_CORES-1: 0] snoop_req; //seq
//-------------To/From DRAM (AXI4)----------------//
//Address Read: Master tells slave what address it is trying to read
    logic ar_ready; //comb
    ADDRESS_READ_PACKET ar_packet; //seq
// Read Data: Slave gives master the data it wants to read
    READ_DATA_PACKET r_packet; //seq
    logic r_ready; //comb
//Address Write: Master tells slave what address it is trying to write to
    logic aw_ready; //comb
    ADDRESS_WRITE_PACKET aw_packet; //seq
//Write Data: Master gives slave the data it is trying to write
    logic w_ready; //comb
    WRITE_DATA_PACKET w_packet; //seq
//Write Response: Slave tells master if it successfully received the new data
    WRITE_RESPONSE_PACKET b_packet;
    logic b_ready;


    initial clock = 1'b0;

    always #0.5 clock <= ~clock;

    L2Cache dut (
        .clock(clock),
	    .reset(reset),
        .l2_entry_packet (l2_entry_packet), //seq
        .l2_exit_packet(l2_exit_packet), //seq
        .l2_exit_valid(l2_exit_valid),
        .snoop_resp(snoop_resp), //seq
        .snoop_req(snoop_req), //seq
        .ar_ready(ar_ready), //comb
        .ar_packet(ar_packet), //seq
        .r_packet(r_packet), //seq
        .r_ready(r_ready), //comb
        .aw_ready(aw_ready), //comb
        .aw_packet(aw_packet), //seq
        .w_ready(w_ready), //comb
        .w_packet(w_packet), //seq
        .b_packet(b_packet),
        .b_ready(b_ready)
    );



    initial begin
        // Initialize all inputs to 0
        reset           = 1'b1;
        l2_entry_packet = '0;
        snoop_resp      = '0;
        r_packet        = '0;
        b_packet        = '0;
        ar_ready        = 1'b0;
        r_ready         = 1'b0;
        aw_ready        = 1'b0;
        w_ready         = 1'b0;

        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        // Hold reset for 5 cycles
        @(posedge clock); #1;
        @(posedge clock); #1;
        @(posedge clock); #1;
        @(posedge clock); #1;
        @(posedge clock); #1;

        // Release reset
        reset = 1'b0;

        // Run for 10 more cycles
        repeat(10) @(posedge clock);

        $display("SUCCESS: simulation completed");
        $finish;
    end



endmodule


