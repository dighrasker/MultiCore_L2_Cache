always_comb begin
    // Default assignments
    l2_exit               = '0;
    snoop_req_valid       = 1'b0;
    snoop_req_addr        = '0;
    snoop_req_target_core = '0;

    next_write_meta       = write_meta;
    next_write_data       = write_data;

    // Common exit fields
    l2_exit.req_type      = l2_entry_packet.req_type;
    l2_exit.target_addr   = l2_entry_packet.target_addr;
    l2_exit.core_id       = l2_entry_packet.core_id;

    case (l2_entry_packet.req_type)

        //--------------------------------------------------------------------------
        READ: begin
            if (hit_any) begin
                // Locate winning way
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end
                // If another core holds it Modified, snoop for dirty data
                if ((read_meta[winner].owner_state == MODIFIED)
                    && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                    snoop_req_valid = 1'b1;
                    snoop_req_addr  = l2_entry_packet.target_addr;
                    for (int c = 0; c < `NUM_CORES; c++) begin
                        if (read_meta[winner].sharers[c])
                            snoop_req_target_core = c;
                    end
                    if (snoop_resp_valid && (snoop_resp_addr == l2_entry_packet.target_addr)) begin
                        // Install dirty line into L2
                        next_write_data   = snoop_resp_data;
                        next_write_meta   = read_meta[winner];
                        next_write_meta.dirty       = 1'b0;
                        next_write_meta.owner_state = EXCLUSIVE;
                        next_write_meta.sharers     = 1 << snoop_resp_from_core;
                        // Forward to requester
                        l2_exit.cache_line = snoop_resp_data;
                    end
                end else begin
                    // Read hit: return L2 copy and update sharers
                    l2_exit.cache_line  = read_data[winner];
                    next_write_meta     = read_meta[winner];
                    next_write_meta.sharers[l2_entry_packet.core_id] = 1'b1;
                    next_write_meta.owner_state =
                        (next_write_meta.sharers == (1 << l2_entry_packet.core_id))
                          ? EXCLUSIVE : SHARED;
                end
            end else begin
                // Read miss: MSHR + AXI read logic
            end
        end

        //--------------------------------------------------------------------------
        WRITE: begin
            if (hit_any) begin
                // Locate winning way
                int winner = 0;
                for (int i = 0; i < `WAYS; i++) begin
                    if (hit[i]) winner = i;
                end
                // If another core holds it Modified, snoop before write
                if ((read_meta[winner].owner_state == MODIFIED)
                    && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                    snoop_req_valid = 1'b1;
                    snoop_req_addr  = l2_entry_packet.target_addr;
                    for (int c = 0; c < `NUM_CORES; c++) begin
                        if (read_meta[winner].sharers[c])
                            snoop_req_target_core = c;
                    end
                    if (snoop_resp_valid && (snoop_resp_addr == l2_entry_packet.target_addr)) begin
                        // Install returned dirty line then grant write
                        next_write_data   = snoop_resp_data;
                        next_write_meta   = read_meta[winner];
                        next_write_meta.dirty       = 1'b0;
                        next_write_meta.owner_state = EXCLUSIVE;
                        next_write_meta.sharers     = 1 << snoop_resp_from_core;
                        // Now upgrade to Modified for requester
                        next_write_meta.dirty       = 1'b1;
                        next_write_meta.owner_state = MODIFIED;
                        next_write_meta.sharers     = 1 << l2_entry_packet.core_id;
                        l2_exit.cache_line = snoop_resp_data;
                    end
                end else begin
                    // Write hit: grant Modified directly
                    l2_exit.cache_line    = read_data[winner];
                    next_write_meta       = read_meta[winner];
                    next_write_meta.dirty = 1'b1;
                    next_write_meta.owner_state = MODIFIED;
                    next_write_meta.sharers     = 1 << l2_entry_packet.core_id;
                    next_write_data       = l2_entry_packet.cache_line;
                end
            end else begin
                // Write miss: MSHR + AXI write-for-ownership
            end
        end

        //--------------------------------------------------------------------------
        UPGRADE: begin
            // Similar to WRITE hit but requester already had line
            int winner = 0;
            for (int i = 0; i < `WAYS; i++) begin
                if (hit[i]) winner = i;
            end
            if ((read_meta[winner].owner_state == MODIFIED)
                && (read_meta[winner].sharers != (1 << l2_entry_packet.core_id))) begin
                snoop_req_valid       = 1'b1;
                snoop_req_addr        = l2_entry_packet.target_addr;
                for (int c = 0; c < `NUM_CORES; c++) begin
                    if (read_meta[winner].sharers[c])
                        snoop_req_target_core = c;
                end
                if (snoop_resp_valid && (snoop_resp_addr == l2_entry_packet.target_addr)) begin
                    next_write_data   = snoop_resp_data;
                    next_write_meta   = read_meta[winner];
                    next_write_meta.dirty       = 1'b0;
                    next_write_meta.owner_state = EXCLUSIVE;
                    next_write_meta.sharers     = 1 << snoop_resp_from_core;
                    l2_exit.cache_line = snoop_resp_data;
                end
            end else begin
                l2_exit.cache_line    = read_data[winner];
                next_write_meta       = read_meta[winner];
                next_write_meta.dirty       = 1'b1;
                next_write_meta.owner_state = MODIFIED;
                next_write_meta.sharers     = 1 << l2_entry_packet.core_id;
                next_write_data       = read_data[winner];
            end
        end

        //--------------------------------------------------------------------------
        default: begin
            // EVICT and others handled elsewhere
        end
    endcase
end
