/*========================================
Filename: scoreboard.sv
Description: 
==========================================*/


class cache_scoreboard extends uvm_scoreboard;

    `uvm_compound_utils(cache_scoreboard)


    uvm_analysis_imp#(cache_seq_item, cache_scoreboard) scb_port;

    cache_seq_item que[$];

    cache_seq_item trans;

    //--------------------
    //Class constructor
    //--------------------
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction


    //--------------------
    //Build phase
    //--------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scb_port = new("scb_port", this);
    endfunction

    function void write(fifo_seq_item transaction);
        que.push_back(transaction);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            wait(que.size()>0);
            trans = que.pop_front();

            //WRITE
            if(trans.wr==1) begin
                mem.push_back(trans.data_in);
            end

            //READ
            if(trans.rd == 1 || (read_delay_clk != 0))
            
        
        end

    endtask

endclass