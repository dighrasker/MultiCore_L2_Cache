/*========================================
Filename: testbench.sv
Description: top level module that calls the test class
==========================================*/

import uvm_pkg::*;
`include "uvm_macros.svh"



module testbench_top;
    bit clock;
    bit reset;


    //--------------------
    //Clock Generation
    //--------------------



    //--------------------
    //Reset Generation
    //--------------------


    //--------------------
    //Interface Instance
    //--------------------


    //--------------------
    //DUT Instance
    //--------------------
    L2Cache dut(); //instantiated the design

    initial begin
        run_test("cache_test");
    end

    //--------------------
    //Config Db
    //--------------------

endmodule