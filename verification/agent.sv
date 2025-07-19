/*========================================
Filename: agent.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/



class cache_agent extends uvm_agent;


    `uvm_component_util(cache_agent)

    //instantiate class
    cache_sequencer sequencer;
    cache_driver driver;
    cache_monitor monitor;

    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache_agent", uvm_component parent = null)

        super.new(name,parent);

    endfunction

    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);
        sequencer = cache_agent::type_id::create("sequencer", this);
        driver = cache_agent::type_id::create("driver", this);
        monitor = cache_agent::type_id::create("monitor", this);
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