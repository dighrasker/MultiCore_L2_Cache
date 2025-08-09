/*========================================
Filename: driver.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/



class cache_driver extends uvm_driver;

    virtual cache_interface vif;
    cache_item trans;


    `uvm_component_util(cache_driver)


    //--------------------
    //Class constructor
    //--------------------
    function new (string name = "cache_driver", uvm_component parent = null)

        super.new(name,parent);

    endfunction

    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual fifo_interface)::get(this,"","vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for:", get_full_name(),".vif"});
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
        forever begin
            seq_item_port.get_next_item(trans);
            drive_task();
            seq_item_port.item_done();
        end

    endtask


endclass