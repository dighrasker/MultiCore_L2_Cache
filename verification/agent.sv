/*========================================
Filename: agent.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/



class cache_agent extends uvm_agent;

    //instantiate class pointers
    cache_sequencer seqr;
    cache_driver driv;
    cache_monitor mon;

    `uvm_component_utils_begin(cache_agent)
        `uvm_field_object(seqr, UVM_ALL_ON)
        `uvm_field_object(driv, UVM_ALL_ON)
        `uvm_field_object(mon, UVM_ALL_ON)
    `uvm_component_utils_end


    //--------------------
    //Class constructor
    //--------------------
    function new (string name, uvm_component parent)
        super.new(name,parent);
    endfunction

    //--------------------
    //Build Phase
    //--------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = cache_sequencer::type_id::create("seqr", this);
        driv = cache_driver::type_id::create("driv", this);
        mon = cache_monitor::type_id::create("mon", this);
    endfunction

    //--------------------
    //Connect Phase
    //--------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driv.seq_item_port.connect(seqr.seq_item_export);
        uvm_report_info("CACHE_AGENT", "conenct_phase, Connected driver to sequencer");
    endfunction


endclass