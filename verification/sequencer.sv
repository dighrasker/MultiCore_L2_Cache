/*========================================
Filename: sequencer.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;


class cache_sequencer extends uvm_sequencer #(cache_packet);


    `uvm_component_utils(cache_sequencer)


    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache+sequencer", uvm_component parent = null)

        super.new(name,parent);

    endfunction



endclass