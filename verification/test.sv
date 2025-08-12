/*========================================
Filename: test.sv
Description: systemVerilog class that instantiates DUT, uvm environment, and the interface
==========================================*/


class cache_test extends uvm_test;

    //instantiate classes
    cache_environment env;
    virtual cache_interface vif;

    `uvm_component_utils(cache_test)


    //--------------------
    //Class constructor
    //--------------------
    function new(string name = "cache_test", uvm_component parent = null);'
        super.new(name, parent);
    endfunction

    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cache_env::type_id::create("env", this);
        uvm_config_db#(virtual cache_interface)::set(this, "env", "vif", vif);

        if(!uvm_config_db#(virtual cache_interface)::get(this, "", "vif", vif)) begin
            `uvm_error("build_phase", "Test virtual interface failed")
        end
    endfunction

    //--------------------
    //End of Elaboration Phase
    //--------------------
    virtual function void end_of_elaboration();
        print();
    endfunction


    //--------------------
    //Run Phase
    //--------------------
    task run_phase(uvm_phase phase);
    
        cache_sequence cache_seq;
        cache_seq = cache_sequence::type_id::create("cache_seq");

        //objections extend the phase until their task is complete
        phase.raise_objection(this, "Starting main phase", $time);
        cache_seq.start(env.agent.sequencer);
        phase.drop_objection(this, "Finished cache_seq in main phase");

    endtask

endclass