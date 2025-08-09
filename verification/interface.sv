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
        //-------------To/From DRAM (AXI4)----------------//
        //Address Read: Master tells slave what address it is trying to read
        logic ar_ready, //comb
        ADDRESS_READ_PACKET ar_packet, //seq
        // Read Data: Slave gives master the data it wants to read
        READ_DATA_PACKET r_packet, //seq
        logic r_ready, //comb
        //Address Write: Master tells slave what address it is trying to write to
        logic aw_ready, //comb
        ADDRESS_WRITE_PACKET aw_packet, //seq
        //Write Data: Master gives slave the data it is trying to write
        logic w_ready, //comb
        WRITE_DATA_PACKET w_packet, //seq
        //Write Response: Slave tells master if it successfully received the new data
        WRITE_RESPONSE_PACKET b_packet,
        logic b_ready


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