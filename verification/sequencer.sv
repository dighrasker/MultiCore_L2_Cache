/*========================================
Filename: sequencer.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/



class cache_sequencer extends uvm_sequencer;


    `uvm_component_utils(cache_sequencer)


    //--------------------
    //Class constructor
    //--------------------
    function new (string name, uvm_component parent)

        super.new(name,parent);

    endfunction




endclass