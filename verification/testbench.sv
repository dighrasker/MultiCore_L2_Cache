/*========================================
Filename: testbench.sv
Description: top level module that calls the test class
==========================================*/

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "test.sv"
`include "env.sv"
`include "sequence_item.sv"
`include "sequencer.sv"
`include "sequence.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "scoreboard.sv"
`include "sys_defs.svh"


`include "interface.sv"



module testbench_top;
    bit clock;
    bit reset;

    //--------------------
    //Clock Generation
    //--------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------
    //Reset Generation
    //--------------------
    initial begin
        reset = 0;
        #5 reset = 1;
    end

    //--------------------
    //Interface Instance
    //--------------------
    cache_interface in(clk,reset);

    //--------------------
    //DUT Instance
    //--------------------

    L2Cache dut(
        .clock(in.clock),
        .reset(in.reset ),
        //To/From L1 Cache
        .l2_entry_packet(in.l2_entry_packet), //seq
        .l2_exit_packet(in.l2_exit_packet), //seq
        .snoop_resp(in.snoop_resp), //seq
        .snoop_req(in.snoop_req), //seq
        //Address Read: Master tells slave what address it is trying to read
        .ar_ready(in.ar_ready), //comb
        .ar_packet(in.ar_packet), //seq
        // Read Data: Slave gives master the data it wants to read
        .r_packet(in.r_packet), //seq
        .r_ready(in.r_ready), //comb
        //Address Write: Master tells slave what address it is trying to write to
        .aw_ready(in.aw_ready), //comb
        .aw_packet(in.aw_packet), //seq
        //Write Data: Master gives slave the data it is trying to write
        .w_ready(in.w_ready), //comb
        .w_packet(in.w_packet), //seq
        //Write Response: Slave tells master if it successfully received the new data
        .b_packet(in.b_packet),
        .b_ready(in.b_ready)
    ); //instantiated the design


    //--------------------
    //Config Db
    //--------------------
    initial begin
        uvm_config_db#(virtual cache_instance)::set(null,"*", "vif", in);
    end
    

    //--------------------
    //Triggering Test case
    //--------------------

    initial begin
        run_test("cache_test")
    end

endmodule