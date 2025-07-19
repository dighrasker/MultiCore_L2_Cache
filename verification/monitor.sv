/*========================================
Filename: monitor.sv
Description: systemVerilog class that 
==========================================*/



class cache_monitor extends uvm_monitor;


    `uvm_component_util(cache_monitor)

    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache_monitor", uvm_component parent = null)

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