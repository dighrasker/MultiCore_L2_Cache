/*========================================
Filename: scoreboard.sv
Description: 
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sys_defs.svh"

class cache_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(cache_scoreboard)

  // Connect this to monitor.ap_l1
  uvm_analysis_imp#(cache_packet, cache_scoreboard) l1_imp;

  // expected cache lines by 32-bit address
  CACHE_LINE exp_mem [int unsigned];  // key = addr.addr (line-aligned)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    l1_imp = new("l1_imp", this);
  endfunction

  function void write(cache_packet tr);
    int unsigned a = tr.addr.addr;

    // Only meaningful thing currently received is observed read data.
    CACHE_LINE expected = exp_mem.exists(a) ? exp_mem[a] : '0;

    if (tr.wdata !== expected) begin
      `uvm_error("SCB", $sformatf("DATA MISMATCH a=0x%08h exp!=got", a))
    end
    else begin
      `uvm_info("SCB", $sformatf("DATA MATCH a=0x%08h", a), UVM_LOW)
    end
  endfunction

  // Optional helper for later:
  function void note_write(ADDR addr, CACHE_LINE data);
    exp_mem[addr.addr] = data;
  endfunction

endclass
