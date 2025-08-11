/*========================================
Filename: monitor.sv
Description: systemVerilog class that 
==========================================*/


`define MON_IF vif.MONITOR.monitor_cb

class cache_monitor extends uvm_monitor;
    
    virtual cache_interface vif;

    //analysis port declaration
    uvm_analysis_port#(fifo_seq_item) ap;

    `uvm_component_utils(cache_monitor)

    //--------------------
    //Class constructor
    //--------------------
    function new (string name, uvm_component parent)
        super.new(name,parent);
        ap = new("ap", this);
    endfunction

    //--------------------
    //Build Phase
    //--------------------
    function void build_phase(uvm_phase phase)
        super.build_phase(phase);
        if(!uvm_config_db#(virtual cache_interface)::get(this, "", "vif", vif)) begin
            `uvm_error("build_phase", "No virtual interface specified for this monitor instance")
        end
    endfunction
    

    //--------------------
    //Run Phase
    //--------------------
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            cache_seq_item trans;
            trans = cache_seq_item::type_id::create("trans");

            

        end

    endtask


endclass