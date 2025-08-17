/*========================================
Filename: sequence_item.sv
Description: 
==========================================*/

`include "uvm_macros.svh"
import uvm_pkg::*;

class cache_base_seq extends uvm_sequence #(cache_packet);

    `uvm_object_utils(cache_base_seq)


    //--------------------
    //User-configurable knobs
    //--------------------

    //number of transactions
    rand int unsigned num_txns;


    //core selection
    rand bit use_fixed_core;
    rand int unsigned fixed_core_id;

    //bias traffic kind
    rand int unsigned rd_weight;
    rand int unsigned wr_weight;
    rand int unsigned evict_weight;
    rand int unsigned upgrade_weight;

    //adress steering
    rand bit use_fixed_set;
    rand SET_IDX fixed_set;
    rand bit use_fixed_tag;
    rand logic[15:0] fixed_tag;

    //--------------------
    //Constraints/ Defaults
    //--------------------

    constraint c_defaults{
        num_txns inside {[1:1000]};
        rd_weight inside {[0:100]};
        wr_weight inside {[0:100]};
        evict_weight inside {[0:100]};
        upgrade_weight inside {[0:100]};
    }

    //--------------------
    //Class constructor
    //--------------------
    function new(string name = "cache_base_seq");
        super.new(name);

        //default knob values
        num_txns = 100;
        rd_weight = 60;
        wr_weight = 20;
        evict_weight = 10;
        upgrade_weight = 10;
        use_fixed_core = 0;
        use_fixed_set  = 0;
        use_fixed_tag  = 0;
        fixed_core_id = '0;
        fixed_set     = '0;
        fixed_tag     = '0;
    endfunction

    //--------------------
    //Objection Handling
    //--------------------
    virtual task pre_body();
        if(starting_phase != null)
            starting_phase.raise_objection(this, $sformatf("%s start", get_name()));
    endtask

    virtual task post_body();
        if(starting_phase != null)
            starting_phase.drop_objection(this, $sformatf("%s done", get_name()));
    endtask

    //--------------------
    //Send to driver
    //--------------------
    virtual task body();
        cache_packet req;
        ADDR base_addr;

        for(int unsigned i = 0; i < num_txns; i++) begin
            req = cache_packet::type_id::create($sformatf("req_%0d", i), this);

            REQ_TYPE_ENUM kind = choose_kind();
            ADDR a = choose_addr();
            CACHE_LINE w = make_wdata(i,a);

            start_item(req);
            if(!req.randomize() with {
                    req_type == kind;
                    core_id == (use_fixed_core ? fixed_core_id : core_id);
                    addr == a;
                    wdata == w;
            }) begin
                `uvm_error(get_name(), "req.randomize() failed")
            end
            finish_item(req);
        end
    endtask

    //--------------------
    //Helpers
    //--------------------

    //choose the type of the transaction
    protected function REQ_TYPE_ENUM choose_kind();
        int total = rd_weight + wr_weight + evict_weight + upgrade_weight;
        if(total == 0) return READ;
        int r = $urandom_range(total-1, 0);
        if( r < rd_weight) return READ;
        else if (r < rd_weight + wr_weight) return WRITE;
        else if (r < rd_weight + wr_weight + evict_weight) return EVICT;
        else return UPGRADE;
    endfunction

    //create an address
    protected function ADDR choose_addr();
        SET_IDX set_sel;
        logic[15:0] tag_sel;

        if(use_fixed_set) set_sel = fixed_set;
        else set_sel = $urandom;

        if(use_fixed_tag) tag_sel = fixed_tag;
        else tag_sel = $urandom;

        return cache_packet::make_addr(tag_sel, set_sel, 6'd0);
    endfunction

    //create data for writes
    protected function CACHE_LINE make_wdata(int unsigned i, ADDR a);
        CACHE_LINE line;

        for(int k = 0; k < `LINE_SIZE_BITS; k += 32) begin
            line[k +: 32] = (i ^ a.addr) + k;
        end

        return line;

    endfunction


    //single read
    virtual task do_read_line(ADDR a, int unsigned core = 0);
        send_one(READ, a, '0, core);
    endtask

    //single write
    virtual task do_write_line(ADDR a, CACHE_LINE w, int unsigned core = 0);
        send_one(WRITE, a, w, core);
    endtask

    //single upgrade
    virtual task do_upgrade_line(ADDR a, int unsigned core = 0);
        send_one(UPGRADE, a, '0, core);
    endtask

    //single evict
    virtual task do_evict_line(ADDR a, CACHE_LINE w, int unsigned core = 0);
        send_one(EVICT, a, w, core);
    endtask



    //send-one usef for single read + single write
    protected task send_one (REQ_TYPE_ENUM kind, ADDR a, CACHE_LINE w, int unsigned core);
        cache_packet req = cache_packet::type_id::create("direct_rq", this);
        start_item(req);
        if(!req.randomize() with {
            req_type == kind;
            core_id == core;
            addr == a;
            wdata == w;
        }) `uvm_error(get_name(), "direct_rq.randomize() failed");

        finish_item(req);
    endtask
endclass



/*========================================
Sequence: dirty_eviction_set_seq
Description: 
==========================================*/

class dirty_evict_set_seq extends cache_base_seq;
    //register object with factory
    `uvm_object_utils(dirty_evict_set_seq)

    function new (string name = "dirty_evict_set_seq");
        super.new(name);

        rd_weight = 0;
        wr_weight = 100;
        evict_weight = 0;
        upgrade_weight = 0;
        use_fixed_set = 1;
        fixed_set = '0;
        use_fixed_tag = 0;
        use_fixed_core = 1;
        fixed_core_id = 1;
        num_txns = `WAYS + 2;

    endfunction

    virtual task body();
        SET_IDX setX = use_fixed_set ? fixed_set : '0;

        logic[15:0] tag = 16'h1000;

        for(int unsigned i = 0; i < num_txns; i++) begin
            ADDR a = cache_packet::make_addr(tag + i, setX, 6'd0);
            CACHE_LINE w = make_wdata(i, a);
            do_write_line(a, w, fixed_core_id);
        end
    endtask
endclass


/*========================================
Sequence: dirty_eviction_set_seq
Description: 
==========================================*/

class shared_then_upgrade_seq extends cache_base_seq;

    `uvm_object_utils(shared_then_upgrade_seq)

    function new(string name = "shared_then_upgrade_seq");
        super.new(name);
        num_txns        = 5;
        rd_weight       = 0;
        wr_weight       = 0;
        evict_weight    = 0;
        upgrade_weight  = 0;
        use_fixed_set   = 1;
        fixed_set       = '0;     
        use_fixed_tag   = 1;
        fixed_tag       = 16'h4A3B; 
    endfunction

    virtual task body();
        ADDR A = cache_packet::make_addr(fixed_tag, fixed_set, 6'd0);

        do_read_line(A, 0);
        do_read_line(A, 1);
        do_upgrade_line(A, 0);
        CACHE_LINE w = make_wdata(0, A);
        do_write_line(A, w, 0);
        do_read_line(A, 1);
    endtask

endclass