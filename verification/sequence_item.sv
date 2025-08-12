/*========================================
Filename: sequence_item.sv
Description: 
==========================================*/

class cache_packet extends uvm_sequence_item;

    // -----------------------
    // UVM registration
    // -----------------------
    `uvm_object_utils_begin(cache_packet)
        `uvm_field_enum(REQ_TYPE_ENUM, req_type,    UVM_ALL_ON)
        `uvm_field_int (core_id,                      UVM_ALL_ON)
    `uvm_object_utils_end


    // -----------------------
    // Stimulus fields (rand) - L2_entry_packet
    // -----------------------
    rand REQ_TYPE_ENUM             req_type;
    rand ADDR                      addr;
    rand bit [`NUM_CORE_BITS-1:0]  core_id; 
    rand CACHE_LINE                wdata;


    // Keep requests line-aligned
    constraint c_line_aligned { addr.l2_addr.offset == 6'd0; }

    //-----------------------
    // Constructor
    //-----------------------
    function new(string name ="cache_packet")
        super.new(name);
    endfunction

    // -----------------------
    // Helpers
    // -----------------------

    //raw 32-bits of the address
    function automatic logic [31:0] addr32();
        return addr.addr;
    endfunction

    //given tag and set, construct a line-aligned address
    static function automatic ADDR make_addr(logic [15:0] tag, SET_IDX set,logic [5:0] off = 6'd0);
        ADDR a; a.addr = '0;
        a.l2_addr.tag     = tag;
        a.l2_addr.set_idx = set;
        a.l2_addr.offset  = off;
        return a;
    endfunction

    //clean log statements
    virtual function string convert2string();
        string s;
        $sformat(s, "{req=%0s core=%0d addr=0x%08h set=%0d off=%0d}",
                req_type.name(), core_id, addr32(),
                addr.l2_addr.set_idx, addr.l2_addr.offset);
        if (req_type == WRITE)
        s = {s, " wdata=<512b>"};
        return s;
    endfunction

    //pack into a bit stream
    virtual function void do_pack(uvm_packer packer);
        super.do_pack(packer);

        // req_type: 3 bits
        packer.pack_field_int(req_type, 3);

        // core_id: NUM_CORE_BITS bits
        packer.pack_field_int(core_id, `NUM_CORE_BITS);

        // address as 32 bits
        packer.pack_field_int(addr32(), 32);

        // wdata: split into 32-bit chunks to avoid tool limits.
        for (int i = 0; i < `LINE_SIZE_BITS; i += 32) begin
        int unsigned chunk = wdata[i +: 32];
        packer.pack_field_int(chunk, 32);
        end
    endfunction


    //unpack from a bit stream
    virtual function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);

        // req_type
        req_type = REQ_TYPE_ENUM'(packer.unpack_field_int(3));

        // core_id
        core_id = packer.unpack_field_int(`NUM_CORE_BITS);

        // addr
        addr.addr = packer.unpack_field_int(32);

        // wdata
        for (int i = 0; i < `LINE_SIZE_BITS; i += 32) begin
        int unsigned chunk = packer.unpack_field_int(32);
        wdata[i +: 32] = chunk;
        end
    endfunction


    //compare items
    virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
        cache_packet other;
        if (! $cast(other, rhs))
        return 0;

        if (this.req_type != other.req_type) return 0;
        if (this.core_id  != other.core_id ) return 0;
        if (this.addr32() != other.addr32()) return 0;
        if (this.wdata    != other.wdata   ) return 0;

        return super.do_compare(rhs, comparer);
    endfunction

    //copy items
    virtual function void do_copy(uvm_object rhs);
        cache_packet other;
        if (!$cast(other, rhs)) begin
        `uvm_fatal(get_name(), "do_copy: cast failed")
        end
        this.req_type   = other.req_type;
        this.core_id    = other.core_id;
        this.addr       = other.addr;
        this.wdata      = other.wdata;
        this.think_cycles = other.think_cycles;
        super.do_copy(rhs);
    endfunction

endclass