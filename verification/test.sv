/*========================================
Filename: test.sv
Description: systemVerilog class that instantiates DUT, uvm environment, and the interface
==========================================*/


class cache_test extends uvm_test;

    `uvm_component_utils(main_test)

    //instantiate classes
    cache_env env;


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
        env = cache_env::type_id::create("", this);

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



    //--------------------
    //Properties
    //--------------------





endclass