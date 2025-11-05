/*========================================
Filename: scoreboard.sv
Description: Minimal scoreboard with a tiny reference model.
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sys_defs.svh"

class cache_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(cache_scoreboard)

  // Monitor pushes observed transactions here (we use cache_packet)
  uvm_analysis_imp#(cache_packet, cache_scoreboard) scb_port;

  // simple ref model: expected cache lines by 32-bit address
  CACHE_LINE exp_mem [int unsigned];  // key = addr.addr

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb_port = new("scb_port", this);
  endfunction

  //   - WRITE request: req_type==WRITE, addr set, wdata = write data
  //   - READ  response: req_type==READ,  addr set, wdata = observed rdata
  function void write(cache_packet tr);
    int unsigned a = tr.addr.addr;

    case (tr.req_type)
      WRITE: begin
        exp_mem[a] = tr.wdata;
        `uvm_info("SCB", $sformatf("REF WRITE: a=0x%08h data=<512b>", a), UVM_LOW)
      end

      READ: begin
        // If address never written, assume zero line (very simple model).
        CACHE_LINE expected = exp_mem.exists(a) ? exp_mem[a] : '0;
        if (tr.wdata !== expected) begin
          `uvm_error("SCB",
            $sformatf("READ MISMATCH a=0x%08h exp!=got", a))
        end else begin
          `uvm_info("SCB",
            $sformatf("READ MATCH a=0x%08h", a), UVM_LOW)
        end
      end

      default: begin
        // EVICT/UPGRADE (no ref-state needed for this minimal model)
        `uvm_info("SCB",
          $sformatf("IGNORING req_type=%0s a=0x%08h",
                    tr.req_type.name(), a), UVM_DEBUG)
      end
    endcase
  endfunction

endclass
