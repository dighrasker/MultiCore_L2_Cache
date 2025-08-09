/*========================================
Filename: env.sv
Description: systemVerilog class that instantiates scoreboard and agent
==========================================*/

class cache_environment extends uvm_env;

    `uvm_component_util(cache_environment)

    //instantiate classes
    cache_agent agt;
    cache_scoreboard scb;

    //--------------------
    //Class constructor
    //--------------------
    function new (string name, uvm_component parent)
        super.new(name,parent);
    endfunction


    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase)
        agt = cache_agent::type_id::create("agent", this);
        scb = cache_scoreboard::type_id::create("scb", this);
        
    endfunction

    //--------------------
    //Connect Phase
    //--------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.scb_port);
        uvm_report_info("CACHE_ENVIRONMENT", "connect_phase, Connected monitor to scoreboard")
    endfunction

endclass