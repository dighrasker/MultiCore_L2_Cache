`include "verilog/sys_defs.svh"

module L2Cache #() (
	input                    logic clock,
	input                    logic reset,
//-------------To/From L1 Cache------------//
    input          L2_ENTRY_PACKET l2_entry_packet, 
    output          L2_EXIT_PACKET l2_exit_packet,
    input        SNOOP_RESP_PACKET snoop_resp,
    output        SNOOP_REQ_PACKET snoop_req,
//-------------To/From DRAM (AXI4)----------------//
//Address Read: Master tells slave what address it is trying to read
    input                     logic ar_ready, 
    output      ADDRESS_READ_PACKET ar_packet,
// Read Data: Slave gives master the data it wants to read
    input          READ_DATA_PACKET r_packet,
    output                    logic r_ready,
//Address Write: Master tells slave what address it is trying to write to
    input                     logic aw_ready, 
    output     ADDRESS_WRITE_PACKET aw_packet,
//Write Data: Master gives slave the data it is trying to write
    input                     logic w_ready, //asserted by DRAM
    output        WRITE_DATA_PACKET w_packet,
//Write Response: Slave tells master if it successfully received the new data
    input     WRITE_RESPONSE_PACKET b_packet,
    output                    logic b_valid
); 


// Eviction policy (LRU bits) --NOOTTTT DONEEEE

//parameters for memDP
logic read_en, write_en;
CACHE_LINE  [`WAYS-1: 0] read_data;
CACHE_LINE  [`WAYS-1: 0] write_data, next_write_data;
META_PACKET [`WAYS-1: 0] read_meta;
META_PACKET [`WAYS-1: 0] write_meta, next_write_meta;


L2_EXIT_PACKET l2_exit;
logic [`WAYS-1:0] hit;
logic hit_any;

assign read_en = (l2_entry_packet.req_type == READ)|| (l2_entry_packet.req_type == WRITE);
assign write_en = l2_entry_packet.req_type == EVICT;

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
        .re   (read_en),
        .raddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .rdata(read_data[w]),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata(write_data)
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
        .re   (read_en),
        .raddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .rdata(read_meta[w]),
        .we   (write_en),
        .waddr(l2_entry_packet.target_addr.l2_addr.set_idx),
        .wdata(write_meta)
    );

    hit[w] = read_meta[w].valid && (read_meta[w].tag == l2_entry_packet.target_addr.l2_addr.tag);

end

always_comb begin
    /*
        logic evict_confirm;
        logic upgrade_confirm;
    */

    l2_exit             = '0;
    snoop_req           = 0;

    next_write_meta     = write_meta;
    next_write_data     = write_data;

    l2_exit.req_type    = l2_entry_packet.req_type;
    l2_exit.target_addr = l2_entry_packet.target_addr;
    l2_exit.core_id     = l2_entry_packet.core_id;    

    hit_any = |hit;

    case(l2_entry_packet.req_type)

        READ: begin
            if(hit_any) begin
                //which way is a tag match
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end

                //another core has this line in MODIFIED
                if ((read_meta[winner].owner_state == MODIFIED) && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                    snoop_req.valid = 1'b1;
                    snoop_req.addr = l2_entry_packet.target_addr;
                    snoop_req.req_type = SHARED;
                    for (int c = 0; c < `NUM_CORES; c++) begin
                        if (read_meta[winner].sharers[c])   //which core already had this line in MODIFIED
                            snoop_req.target_core = c;
                    end
                    if (snoop_resp.valid && (snoop_resp.addr == l2_entry_packet.target_addr)) begin //after we get back the response
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
                end 
                
                //no other core has this line in modified
                else begin
                    l2_exit.cache_line  = read_data[winner];
                    next_write_meta     = read_meta[winner];
                    next_write_meta.sharers[l2_entry_packet.core_id] = 1'b1;
                    next_write_meta.owner_state = (next_write_meta.sharers == (1 << l2_entry_packet.core_id)) ? EXCLUSIVE : SHARED; 
                end
            end else begin
                //No tags matched, need to use MSHRS to acces DRAM


            end
        end

        WRITE: begin
            if(hit_any) begin
                //which way is a tag match
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end

                //another core has this line in MODIFIED
                if ((read_meta[winner].owner_state == MODIFIED) && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                    snoop_req.valid = 1'b1;
                    snoop_req.addr = l2_entry_packet.target_addr;
                    snoop_req.req_type = INVALID;
                    for (int c = 0; c < `NUM_CORES; c++) begin
                        if (read_meta[winner].sharers[c])   //which core already had this line in MODIFIED
                            snoop_req.target_core = c;
                    end
                    if (snoop_resp.valid && (snoop_resp.addr == l2_entry_packet.target_addr)) begin //after we get back the response
                        // Install dirty line into L2
                        next_write_data   = snoop_resp.data;

                        //update meta data
                        next_write_meta   = read_meta[winner];
                        next_write_meta.dirty       = 1'b1;
                        next_write_meta.owner_state = MODIFIED;
                        next_write_meta.sharers     = (1 << l2_entry_packet.core_id);

                        //send updated cache line back to requester
                        l2_exit.cache_line = snoop_resp.data;
                    end
                end 
                
                //no other core has this line in modified
                else begin
                    l2_exit.cache_line  = read_data[winner];
                    next_write_meta     = read_meta[winner];
                    next_write_meta.dirty       = 1'b1;
                    next_write_meta.owner_state = MODIFIED;
                    next_write_meta.sharers = 1 << l2_entry_packet.core_id;
                end
            end else begin
                //No tags matched, need to use MSHRS to acces DRAM
                

            end
        end

        UPGRADE: begin
            snoop_req.valid = 1'b1;
            snoop_req.addr = l2_entry_packet.target_addr;
            snoop_req.req_type = INVALID;
            if (snoop_resp.valid && (snoop_resp.addr == l2_entry_packet.target_addr)) begin
                l2_exit.cache_line  = read_data[winner];
                next_write_meta     = read_meta[winner];
                next_write_meta.dirty       = 1'b1;
                next_write_meta.owner_state = MODIFIED;
                next_write_meta.sharers = 1 << l2_entry_packet.core_id;
            end
        end

        default: begin

        

        end
    endcase
end

always_ff @(posedge clock) begin
    if (reset) begin
        l2_exit_packet <= 0;
        write_meta <= 0;
        write_data <= 0;
    end else begin
        l2_exit_packet <= l2_exit;
        write_meta <= next_write_meta;
        write_data <= next_write_data;
    end

end

endmodule