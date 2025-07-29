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
    //all signals come from interface
    L2Cache dut(); //instantiated the design

    initial begin
        run_test("cache_test");
    end

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

endmodule