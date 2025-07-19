/*========================================
Filename: sequencer.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/



class cache_sequencer extends uvm_sequencer;


    `uvm_component_util(cache_sequencer)


    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache_sequencer", uvm_component parent = null)

        super.new(name,parent);

    endfunction

    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);

    endfunction

    //--------------------
    //Connect Phase
    //--------------------
    function void connect_phase(uvm_phase phase);

    endfunction
    

    //--------------------
    //Run Phase
    //--------------------
    task run_phase(uvm_phase phase);


    endtask


endclass