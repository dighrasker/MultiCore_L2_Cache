/*========================================
Filename: interface.sv
Description:
==========================================*/

`include "sys_defs.svh"

interface cache_interface (input logic clk, input logic rst);

  // --------------------
  // To/From L1 Cache side
  // --------------------
  L2_ENTRY_PACKET                    l2_entry_packet;
  L2_EXIT_PACKET   [`NUM_CORES-1:0]  l2_exit_packet;
  SNOOP_RESP_PACKET [`NUM_CORES-1:0] snoop_resp;
  SNOOP_REQ_PACKET  [`NUM_CORES-1:0] snoop_req;

  // --------------------
  // Memory / AXI-like side (as referenced in your DUT instantiation)
  // --------------------
  logic       ar_ready;  
  AR_PACKET   ar_packet;  

  R_PACKET    r_packet;  
  logic       r_ready;    

  logic       aw_ready;
  AW_PACKET   aw_packet;

  logic       w_ready;
  W_PACKET    w_packet;

  B_PACKET    b_packet;
  logic       b_ready;

  // --------------------
  // Driver clocking block
  // - Outputs are what the driver/TB is allowed to drive
  // - Inputs are what the driver/TB is allowed to sample
  // --------------------
  clocking driver_cb @(posedge clk);
    // Driver stimulus (what TB commonly drives)
    output l2_entry_packet;
    output snoop_resp;

    output ar_packet;
    output r_ready;
    output aw_packet;
    output w_packet;
    output b_ready;

    // Driver sampling (what DUT/memory commonly drives)
    input  l2_exit_packet;
    input  l2_exit_valid;
    input  snoop_req;

    input  ar_ready;
    input  r_packet;
    input  aw_ready;
    input  w_ready;
    input  b_packet;
  endclocking

  // --------------------
  // Monitor clocking block
  // - Monitor only samples
  // --------------------
  clocking monitor_cb @(posedge clk);
    input l2_entry_packet;
    input l2_exit_packet;
    input l2_exit_valid;
    input snoop_req;
    input snoop_resp;

    input ar_ready;
    input ar_packet;

    input r_packet;
    input r_ready;

    input aw_ready;
    input aw_packet;

    input w_ready;
    input w_packet;

    input b_packet;
    input b_ready;
  endclocking

  // --------------------
  // Modports
  // --------------------
  modport DRIVER  (clocking driver_cb,  input clk, input rst);
  modport MONITOR (clocking monitor_cb, input clk, input rst);

endinterface
