/*========================================
Filename: interface.sv
Description: interface
==========================================*/

`include "sys_defs.svh"


interface cache_interface (input logic clk, rst);

    //--------------------
    //Signal Declaration
    //--------------------
        logic clock,
        logic reset,
        //-------------To/From L1 Cache------------//
        L2_ENTRY_PACKET l2_entry_packet, //seq
        L2_EXIT_PACKET [`NUM_CORES-1: 0] l2_exit_packet, //seq
        SNOOP_RESP_PACKET [`NUM_CORES-1: 0] snoop_resp, //seq
        SNOOP_REQ_PACKET [`NUM_CORES-1: 0] snoop_req, //seq


    //--------------------
    //Driver CB
    //--------------------
    clocking driver_cb @(posedge clk);



    endclocking


    //--------------------
    //Monitor CB
    //--------------------
    clocking monitor_cb @(posedge clk);


    endclocking


    modport DRIVER(clocking driver_cb, input clk, rst);
    modport MONITOR(clocking monitor_cb, input clk, rst);

endinterface