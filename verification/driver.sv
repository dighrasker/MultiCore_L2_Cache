/*========================================
Filename: driver.sv
Description: Minimal driver.
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sys_defs.svh"

class cache_driver extends uvm_driver #(cache_packet);

  `uvm_component_utils(cache_driver)

  virtual cache_interface.DRIVER vif;

  function new (string name = "cache_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cache_interface.DRIVER)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("virtual interface must be set for %s.vif", get_full_name()))
    end
  endfunction

  task run_phase(uvm_phase phase);
    cache_packet req;

    forever begin
      seq_item_port.get_next_item(req);

      // Translate cache_packet -> L2_ENTRY_PACKET
      L2_ENTRY_PACKET p;
      p.req_type    = req.req_type;
      p.cache_line  = (req.req_type == WRITE) ? req.wdata : '0;
      p.target_addr = req.addr;
      p.core_id     = req.core_id;


      @(vif.driver_cb);
      vif.driver_cb.l2_entry_packet <= p;

      // Optionally hold one more cycle to ensure capture
      @(vif.driver_cb);

      seq_item_port.item_done();
    end
  endtask

endclass
