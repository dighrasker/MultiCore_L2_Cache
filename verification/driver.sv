/*========================================
Filename: driver.sv
Description: systemVerilog class that instantiates monitor, driver, and sequencer
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;


class cache_driver extends uvm_driver #(cache_packet);

    virtual cache_interface.DRIVER vif;
    cache_item trans;


    `uvm_component_utils(cache_driver)


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
        super.build_phase(phase);
        if(!uvm_config_db#(virtual cache_interface.DRIVER)::get(this,"","vif", vif)) begin
            `uvm_fatal("NO_VIF", $sformatf("virtual interface must be set for %s.vif", get_full_name()))
        end
    endfunction
    

    //--------------------
    //Run Phase
    //--------------------
    task run_phase(uvm_phase phase);
        cache_packet req;
       
        forever begin
            seq_item_port.get_next_item(trans);
            drive_task();
            seq_item_port.item_done();
        end

    endtask


endclass