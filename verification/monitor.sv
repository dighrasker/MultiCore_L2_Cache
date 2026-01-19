/*========================================
Filename: monitor.sv
Description: 
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sys_defs.svh"

// Tiny memory-side event object (minimal fields, easy to extend)
class mem_txn extends uvm_sequence_item;
  typedef enum int unsigned { MEM_AR, MEM_R, MEM_AW, MEM_W, MEM_B } mem_chan_e;

  `uvm_object_utils(mem_txn)

  mem_chan_e chan;
  ADDR       addr;
  CACHE_LINE data;

  function new(string name="mem_txn");
    super.new(name);
    addr = '0;
    data = '0;
  endfunction
endclass


class cache_monitor extends uvm_monitor;

  `uvm_component_utils(cache_monitor)

  virtual cache_interface.MONITOR vif;

  // L1-facing observations (responses)
  uvm_analysis_port#(cache_packet) ap_l1;

  // DRAM-facing observations (memory bus activity)
  uvm_analysis_port#(mem_txn)      ap_mem;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_l1  = new("ap_l1", this);
    ap_mem = new("ap_mem", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cache_interface.MONITOR)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "No virtual cache_interface.MONITOR for cache_monitor")
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      @(vif.monitor_cb);

      // ----------------------------
      // A) L1-facing: L2 -> L1 exits
      // ----------------------------
      for (int c = 0; c < `NUM_CORES; c++) begin
        if (vif.monitor_cb.l2_exit_valid[c]) begin
          L2_EXIT_PACKET resp = vif.monitor_cb.l2_exit_packet[c];

          cache_packet pkt = cache_packet::type_id::create($sformatf("l1_rsp_c%0d", c), this);
          pkt.req_type = READ;
          pkt.addr     = resp.target_addr;
          pkt.core_id  = c[`NUM_CORE_BITS-1:0];
          pkt.wdata    = resp.cache_line;

          ap_l1.write(pkt);
        end
      end


      // ----------------------------
      // B) DRAM-facing: valid/ready handshakes
      // ----------------------------

      // Address Read handshake: DUT issues read request to DRAM
      if (vif.monitor_cb.ar_packet.ar_valid && vif.monitor_cb.ar_ready) begin
        mem_txn t = mem_txn::type_id::create("mem_ar", this);
        t.chan = mem_txn::MEM_AR;
        t.addr = vif.monitor_cb.ar_packet.ar_addr;
        ap_mem.write(t);
      end

      // Read Data handshake: DRAM returns data to DUT
      if (vif.monitor_cb.r_packet.r_valid && vif.monitor_cb.r_ready) begin
        mem_txn t = mem_txn::type_id::create("mem_r", this);
        t.chan = mem_txn::MEM_R;
        t.data = vif.monitor_cb.r_packet.r_data;
        ap_mem.write(t);
      end

      // Address Write handshake: DUT issues write address
      if (vif.monitor_cb.aw_packet.aw_valid && vif.monitor_cb.aw_ready) begin
        mem_txn t = mem_txn::type_id::create("mem_aw", this);
        t.chan = mem_txn::MEM_AW;
        t.addr = vif.monitor_cb.aw_packet.aw_addr;
        ap_mem.write(t);
      end

      // Write Data handshake: DUT issues write data
      if (vif.monitor_cb.w_packet.w_valid && vif.monitor_cb.w_ready) begin
        mem_txn t = mem_txn::type_id::create("mem_w", this);
        t.chan = mem_txn::MEM_W;
        t.data = vif.monitor_cb.w_packet.w_data;
        ap_mem.write(t);
      end

      // Write Response handshake: DRAM acks write completion
      if (vif.monitor_cb.b_packet.b_valid && vif.monitor_cb.b_ready) begin
        mem_txn t = mem_txn::type_id::create("mem_b", this);
        t.chan = mem_txn::MEM_B;
        ap_mem.write(t);
      end

    end
  endtask

endclass
