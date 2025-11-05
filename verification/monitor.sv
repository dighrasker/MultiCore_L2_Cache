/*========================================
Filename: monitor.sv
Description: Minimal monitor.
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sys_defs.svh"

class cache_monitor extends uvm_monitor;

  `uvm_component_utils(cache_monitor)

  virtual cache_interface.MONITOR vif;

  // analysis port sends observed transactions to scoreboard
  uvm_analysis_port#(cache_packet) ap;

  function new (string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cache_interface.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "No virtual interface.MONITOR for monitor")
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      @(vif.monitor_cb);  // sample once per cycle via clocking block

      L2_EXIT_PACKET resp = vif.monitor_cb.l2_exit_packet;

      cache_packet pkt = cache_packet::type_id::create("mon_pkt", this);
      pkt.req_type = READ;
      pkt.addr     = resp.target_addr;
      pkt.core_id  = '0;                   // not critical for SCB compare
      pkt.wdata    = resp.cache_line;      // observed read data

      ap.write(pkt);
    end
  endtask

endclass
