//Recieving signals from DRAM

if(b_packet.b_valid) begin //Slave confirmed that it got the updated data from master
    next_mshrs[wait_idx].valid = 1'b0;
    wait_idx = (wait_idx + 1) % `WAYS;

end

if(r_packet.r_valid) begin //Slave is sending back data that master requested for
    next_mshr[wait_idx].valid = 1'b0;
    //calculate (using lru) which cache line to write to
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

    //taking care of the cache line that is beign replaced
    if(read_meta[winner].valid && read_meta[winner].owner_state == MODIFIED) begin //some L1 has a dirty version of the cache line beign evicted
        waiting = 1'b1;
        int target_core = -1;
        for (int c = 0; c < `NUM_CORES; c++) begin
            if (read_meta[winner].sharers[c])   //which core already had this line in MODIFIED
                target_core = c;
        end
        snoop_req[target_core].valid = 1'b1;
        snoop_req[target_core].addr = read_meta[winner].addr;
        snoop_req[target_core].req_type = INVALID;
        if (snoop_resp[target_core].valid && (snoop_resp[target_core].addr == read_meta[winner].addr)) begin //after we get back the response
            waiting = 1'b0;
            // Give MSHR the updated line
            next_mshr[free_idx].valid = 1'b1;
            next_mshr[free_idx].addr = snoop_resp[target_core].addr;
            next_mshr[free_idx].data = snoop_resp[target_core].data;
            next_mshr[free_idx].core_id = snoop_resp[target_core].core_id;
            next_mshr[free_idx].write_req = 1'b1;
        end
    end else if (read_meta[winner].valid && read_meta[winner].dirty) begin //L2 is dirty but it has the most updated copy
        waiting = 1'b1;
        for (int c = 0; c < `NUM_CORES; c++) begin
            snoop_req[c].valid = 1'b1;
            snoop_req[c].addr = read_meta[winner].addr;
            snoop_req[c].req_type = INVALID;  
        end
        logic all_back;
        all_back = snoop_resp[0].valid && snoop_resp[1].valid && snoop_resp[2].valid && snoop_resp[3].valid;        
        if (all_back) begin //after we get back the response
            waiting = 1'b0;
            next_mshr[free_idx].valid = 1'b1;
            next_mshr[free_idx].addr = read_meta[winner].addr;
            next_mshr[free_idx].data = read_data[winner];
            next_mshr[free_idx].core_id = 0;
            next_mshr[free_idx].write_req = 1'b1;  
        end     
    end

    //update meta data and bring in the cache line
    write_en[winner] = 1'b1;
    read_meta_en[winner] = 1'b1;
    write_addr[winner] = mshr[wait_idx].addr.l2_addr.set_idx;
    next_write_data[winner] = r_data;
    write_meta_addr[winner] = mshr[wait_idx].addr.l2_addr.set_idx;


    //increment wait_idx
    wait_idx = (wait_idx + 1) % `NUM_MSHRS;
end








//Sending signals to DRAM
if(mshrs[wait_idx].valid && mshr[wait_idx].write_req) begin //mshr wants to write a dirty line to DRAM 
    
end else if (mshrs[wait_idx].valid && ~mshr[wait_idx].write_req) begin //mshr wants to read from DRAM

end