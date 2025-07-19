/*========================================
Filename: env.sv
Description: systemVerilog class that instantiates scoreboard and agent
==========================================*/

class cache_env extends uvm_env;

    `uvm_component_util(cache_env)

    //instantiate classes
    cache_agent agent;

    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache_env", uvm_component parent = null)

        super.new(name,parent);

    endfunction


    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);
        agent = cache_agent::type_id::create("agent", this);
        
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