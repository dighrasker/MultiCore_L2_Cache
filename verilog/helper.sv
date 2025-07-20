module L2Cache #() (
	input                    logic clock,
	input                    logic reset,
//-------------To/From L1 Cache------------//
    input          L2_ENTRY_PACKET l2_entry_packet, //seq
    output          L2_EXIT_PACKET [`NUM_CORES-1: 0] l2_exit_packet, //seq
    input        SNOOP_RESP_PACKET snoop_resp, //seq
    output        SNOOP_REQ_PACKET snoop_req, //seq
//-------------To/From DRAM (AXI4)----------------//
//Address Read: Master tells slave what address it is trying to read
    input                     logic ar_ready, //comb
    output      ADDRESS_READ_PACKET ar_packet, //seq
// Read Data: Slave gives master the data it wants to read
    input          READ_DATA_PACKET r_packet, //seq
    output                    logic r_ready, //comb
//Address Write: Master tells slave what address it is trying to write to
    input                     logic aw_ready, //comb
    output     ADDRESS_WRITE_PACKET aw_packet, //seq
//Write Data: Master gives slave the data it is trying to write
    input                     logic w_ready, //comb
    output        WRITE_DATA_PACKET w_packet, //seq
//Write Response: Slave tells master if it successfully received the new data
    input     WRITE_RESPONSE_PACKET b_packet,
    output                    logic b_valid
); 


//general signals
logic waiting;


//L1 signals
L2_EXIT_PACKET [`NUM_CORES-1: 0] next_l2_exit_packet;
SNOOP_REQ_PACKET next_snoop_req;


//------ DATA memDP ------------//
//read signals
logic [`WAYS-1:0] read_en;
SET_IDX [`WAYS-1:0] read_addr;
CACHE_LINE  [`WAYS-1: 0] read_data; //stores the value we are reading from data memDP


//write
logic [`WAYS-1: 0] write_en;
SET_IDX [`WAYS-1:0] write_addr;
CACHE_LINE  [`WAYS-1: 0] write_data, next_write_data; //stores the value we are writing to data memDP


//------- META memDP---------//
//read signals
logic [`WAYS-1:0] read_meta_en;
SET_IDX [`WAYS-1:0] read_meta_addr;
META_PACKET [`WAYS-1: 0] read_meta;

//write signals
logic [`WAYS-1: 0] write_meta_en;
SET_IDX [`WAYS-1:0] write_meta_addr;
META_PACKET [`WAYS-1: 0] write_meta, next_write_meta;


logic [`WAYS-1:0] hit;
logic hit_any;
LRU [`NUM_SETS-1:0][`WAY-1:0] lrus, next_lrus;

//MSHR signals + storage
MSHR   [`NUM_MSHRS-1: 0] mshrs, next_mshrs;
logic [2:0] free_idx, next_free_idx;
logic [2:0] wait_idx;
logic mshr_exists;

//AXI4 signals
ADDRESS_WRITE_PACKET next_aw_packet;
WRITE_DATA_PACKET next_w_packet;
ADDRESS_READ_PACKET next_ar_packet;


//-------------------------
//Cache Data and Meta Data
//-------------------------

for(genvar w = 0; w < `WAYS; ++w) begin : ways
    //creates 8 data arrays for each way
    memDP #(
        .WIDTH     (`LINE_SIZE_BITS),
        .DEPTH     (`NUM_SETS),
        .READ_PORTS(1),
        .BYPASS_EN (0))
    L2_data (
        .clock(clock),
        .reset(reset),
        .re   (read_en[w]),
        .raddr(read_addr[w]),
        .rdata(read_data[w]),
        .we   (write_en[w]),
        .waddr(write_addr[w]),
        .wdata(write_data[w])
    );

    //corresponding tag array
    memDP #(
        .WIDTH     (`META_WIDTH),
        .DEPTH     (`NUM_SETS),
        .READ_PORTS(1),
        .BYPASS_EN (0))
    L2_tags (
        .clock(clock),
        .reset(reset),
        .re   (read_meta_en[w]),
        .raddr(read_meta_addr[w]),
        .rdata(read_meta[w]),
        .we   (write_meta_en[w]),
        .waddr(write_meta_addr[w]),
        .wdata(write_meta[w])
    );

    assign hit[w] = read_meta[w].valid && (read_meta[w].tag == l2_entry_packet.target_addr.l2_addr.tag);

end

//--------------------
//Combinational Logic
//--------------------

always_comb begin

    //--------------------
    //Default values (avoid latching)
    //--------------------
    read_en = 0;
    read_meta_en = 0;
    write_en = 0;
    write_meta_en = 0;
    next_l2_exit_packet = l2_exit_packet;
    next_snoop_req = snoop_req;
    next_mshrs = mshrs;
    next_free_idx = free_idx;
    next_aw_packet = aw_packet;
    next_ar_packet = ar_packet;
    next_w_packet = w_packet;
    write_meta_en = 0'b0;
    next_lrus = lrus;

    hit_any = |hit;


    //------------------------
    //Signals from DRAM
    //------------------------
    
    if(r_valid) begin //we are recieving data from DRAM in this cycle
        //READ DATA LOGIC
        int winner = 0;
        for(int i = 0; i < `WAYS; ++i) begin
            if(lrus[mshr[wait_idx].addr.l2_addr.set_idx][i] == 0) winner = i;
        end

        //update lru
        for(int i = 0; i < `WAYS; ++i) begin
            if(i == winner) begin
                next_lrus[mshr[wait_idx].addr.l2_addr.set_idx][i] = `WAYS - 1;
            end else begin
                next_lrus[mshr[wait_idx].addr.l2_addr.set_idx][i] -= 1;
            end
        end

        //increment wait_idx
        wait_idx = (wait_idx + 1) % `NUM_MSHRS;


        write_en[winner] = 1'b1;
        read_meta_en[winner] = 1'b1;
        write_addr[winner] = mshr[wait_idx].addr.l2_addr.set_idx;
        write_data[winner] = r_data;

        if(read_meta[winner].valid && read_meta[winner].owner_state == MODIFIED) begin
        


        end else if (read_meta[winner].valid && read_meta[winner].dirty) begin //L2 is dirty but it has the most update copy
            

            

        
        end else begin 
            //line we are evicting is not dirty, but other L1's might have it in shared

            //line we are evicitng is not dirty, and other L1's do not have it

        end
        //if I just got new data from dram BUT I am writing it to smtg that has a valid cache line in it
            //WRITE ADDRESS + WRITE DATA channels

            //WRITE RESP channel

        /*
            if (we get data from DRAM this cycle) {
                1. using curr ptr, find relevant mshr entry
                2. feed the tag from the addr in the mshr entry into meta memDP
                if (the valid bit for corresponding cache line is high)
                    3.feed the tag from the addr in the mshr entry into memDP to get the current cache line
                1. update that cache line with the new data
                2. in meta packet set valid bit high, 


            }



        */
    end

    //--------------------
    //L1 Cache Communication
    //--------------------
    
    if(!l2_exit_packet[l2_entry_packet.core_id].stall) begin  //lets check what l2_entry_packet has ONLY IF we are not stall

        case(l2_entry_packet.req_type)
            READ:
                if(hit_any) begin //there was a tag match in L2
                    //which way is actually the tag match
                    int winner = 0;
                    for (int i = 0; i < `WAYS; i++) begin
                        if (hit[i]) begin 
                            winner = i;
                        end 
                    end
                    read_en[winner] = 1'b1;
                    read_meta_en[winner] = 1'b1;
                    read_addr[winner] = l2_entry_packet.addr.l2_addr.set_idx;
                    read_meta_addr[winner] = l2_entry_packet.addr.l2_addr.set_idx;
                    //another core has this line in MODIFIED
                    if ((read_meta[winner].owner_state == MODIFIED) && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                        waiting = 1'b1;
                        snoop_req.valid = 1'b1;
                        snoop_req.addr = l2_entry_packet.target_addr;
                        snoop_req.req_type = SHARED;
                        for (int c = 0; c < `NUM_CORES; c++) begin
                            if (read_meta[winner].sharers[c])   //which core already had this line in MODIFIED
                                snoop_req.core_id = c;
                        end
                        if (snoop_resp.valid && (snoop_resp.addr == l2_entry_packet.target_addr)) begin //after we get back the response
                            waiting = 1'b0;
                            // Install dirty line into L2
                            next_write_data   = snoop_resp.data;

                            //update meta data
                            next_write_meta   = read_meta[winner];
                            next_write_meta.dirty       = 1'b0;
                            next_write_meta.owner_state = SHARED;
                            next_write_meta.sharers     = (1 << l2_entry_packet.core_id) || write_meta.sharers;

                            //send updated cache line back to requester
                            l2_exit.cache_line = snoop_resp.data;
                        end
                    end else begin //no other core has this line in modified
                        l2_exit.cache_line  = read_data[winner];
                        next_write_meta[winner]     = read_meta[winner];
                        next_write_meta[winner].sharers[l2_entry_packet.core_id] = 1'b1;
                        next_write_meta[winner].owner_state = (next_write_meta[winner].sharers == (1 << l2_entry_packet.core_id)) ? EXCLUSIVE : SHARED; 
                    end
                
                end else begin //L2 miss => need to request DRAM for this cache line

                    //first check if any of the other MSHRs have an outstanding request for the same addr
                    for(int i = 0; i < `NUM_MSHRS; ++i) begin
                        if(mshrs[i].addr == l2_entry_packet.target_addr) mshr_exists = 1'b1; 
                    end

                    if(mshr_exists) begin
                        l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                    end else begin
                        if(mshrs[free_idx].valid) begin
                            //the next mshr in line is in use => all MSHRs are in flight => stall
                            l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                        end else begin
                            //fill up MSHR with relevant MSHR data
                            mshrs[free_idx].valid = 1'b1;
                            mshrs[free_idx].addr = l2_entry_packet.target_addr;
                            mshrs[free_idx].core_id = l2_entry_packet.core_id;
                            mshrs[free_idx].req_type = l2_entry_packet.req_type;

                            //initiate ADDRESS READ channel
                            if(ar_ready) begin
                                ar_valid = 1'b1;
                                ar_addr = l2_entry_packet.target_addr;
                                ar_prot = 3'b000;
                                l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                            end

                            free_idx = (free_idx + 1) % `NUM_MSHRS;
                        end
                    end
                end
            WRITE:
                if(hit_any) begin
                    //which way is actually the tag match
                    int winner = 0;
                    for (int i = 0; i < `WAYS; i++) begin
                        if (hit[i]) winner = i;
                    end
                    read_en[winner] = 1'b1;
                    read_meta_en[winner] = 1'b1;
                    read_addr[winner] = l2_entry_packet.addr.l2_addr.set_idx;
                    read_meta_addr[winner] = l2_entry_packet.addr.l2_addr.set_idx;

                    //another core has this line in MODIFIED
                    if ((read_meta[winner].owner_state == MODIFIED) && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                        waiting = 1'b1;
                        snoop_req.valid = 1'b1;
                        snoop_req.addr = l2_entry_packet.target_addr;
                        snoop_req.req_type = INVALID;
                        for (int c = 0; c < `NUM_CORES; c++) begin
                            if (read_meta[winner].sharers[c])   //which core already had this line in MODIFIED
                                snoop_req.core_id = c;
                        end
                        if (snoop_resp.valid && (snoop_resp.addr == l2_entry_packet.target_addr)) begin //after we get back the response
                            waiting = 1'b0;
                            // Install dirty line into L2
                            next_write_data   = snoop_resp.data;

                            //update meta data
                            next_write_meta[winner]   = read_meta[winner];
                            next_write_meta[winner].dirty       = 1'b0;
                            next_write_meta[winner].owner_state = MODIFIED;
                            next_write_meta[winner].sharers     = (1 << l2_entry_packet.core_id) || write_meta.sharers;

                            //send updated cache line back to requester
                            l2_exit[l2_entry_packet.core_id].cache_line = snoop_resp.data;
                        end
                    end else begin //no other core has this line in modified
                        write_meta_en[winner] = 1'b1;
                        l2_exit[l2_entry_packet.core_id].cache_line  = read_data[winner];
                        next_write_meta[winner]     = read_meta[winner];
                        next_write_meta[winner].sharers[l2_entry_packet.core_id] = 1'b1;
                        next_write_meta[winner].owner_state = (next_write_meta.sharers == (1 << l2_entry_packet.core_id)) ? MODIFIED : INVALID; 
                    end
                
                end else begin
                    //first check if any of the other MSHRs have an outstanding request for the same addr
                    for(int i = 0; i < `NUM_MSHRS; ++i) begin
                        if(mshrs[i].addr == l2_entry_packet.target_addr) mshr_exists = 1'b1; 
                    end

                    if(mshr_exists) begin
                        l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                    end else begin
                        if(mshrs[free_idx].valid) begin
                            //the next mshr in line is in use => all MSHRs are in flight => stall
                            l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                        end else begin
                            //fill up MSHR with relevant MSHR data
                            mshrs[free_idx].valid = 1'b1;
                            mshrs[free_idx].addr = l2_entry_packet.target_addr;
                            mshrs[free_idx].core_id = l2_entry_packet.core_id;
                            mshrs[free_idx].req_type = l2_entry_packet.req_type;

                            //initiate ADDRESS READ channel
                            if(ar_ready) begin
                                ar_valid = 1'b1;
                                ar_addr = l2_entry_packet.target_addr;
                                ar_prot = 3'b000;
                                l2_exit[l2_entry_packet.core_id].stall = 1'b1;
                            end

                            free_idx = (free_idx + 1) % `NUM_MSHRS;
                        end
                    end
                end

            UPGRADE: //can't be an L2 miss on an upgrade, just need to invalidate and update meta data
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end

                //no other core has this line in modified
                write_meta_en[winner] = 1'b1;
                l2_exit[l2_entry_packet.core_id].cache_line  = read_data[winner];
                next_write_meta[winner]     = read_meta[winner];
                next_write_meta[winner].sharers[l2_entry_packet.core_id] = 1'b1;
                next_write_meta[winner].owner_state = (next_write_meta[winner].sharers == (1 << l2_entry_packet.core_id)) ? MODIFIED : INVALID;

            EVICTION: //can't be an L2 miss on an eviction, just need to update MESI status and meta data
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end

                next_write_data[winner] = l2_entry_packet.cache_line;
                write_meta_en[winner] = 1'b1;
                next_write_meta[winner] = read_meta[winner];
                next_write_meta[winner].sharers = 0;
                next_write_meta[winner].dirty = 1'b1;
                next_write_meta[winner].owner_state = INVALID;
            default:


        endcase
    
    end


    //------------------------
    //Signals to DRAM (MSHR)
    //------------------------
    if(mshrs[wait_idx].valid) begin
        if(mshrs[wait_idx].req_type == READ || mshrs[wait_idx].req_type == WRITE) begin //use the Read Address channel
            
            

        end else if (mshrs[wait_idx].req_type == EVICTION) begin // use the Write Address and Data Write channel
            

        end
    
    end



end

always_ff @(posedge clock) begin
    if(reset) begin
        l2_exit_packet = 0;
        snoop_req = 0;
        mshrs = 0;
        free_idx = 0;
        aw_packet = 0;
        ar_packet = 0;
        w_packet = 0;
        wait_idx = 0;
        for (int i = 0; i < `NUM_SETS; ++i) begin
        for(int j = 0; j , `WAYS; ++j) begin
            lrus[i][j] = j;
        end
    end
    end else if (waiting) begin
        l2_exit_packet = l2_exit_packet;
        snoop_req = snoop_req;
        mshrs = mshrs;
        free_idx = free_idx;
        aw_packet = aw_packet;
        ar_packet = ar_packet;
        w_packet = w_packet;
        lrus = lrus;
        wait_idx = wait_idx;
    end else begin
        l2_exit_packet = next_l2_exit_packet;
        snoop_req = next_snoop_req;
        mshrs = next_mshrs;
        free_idx = next_free_idx;
        aw_packet = next_aw_packet;
        ar_packet = next_ar_packet;
        w_packet = next_w_packet;
        lrus = next_lrus;
        wait_idx = next_way_idx;
    end

end

endmodule



/*
Doubts:
    1. Do I need to send a snoop signal to respective L1s everytime I update the MESI status in the meta data?


*/