class cache_sequence extends uvm_sequence(cache_seq_item);

    `uvm_object_utils(cache_sequence)

    //--------------------
    //Class constructor
    //--------------------
    function new(string name = "cache_seq_item");
        super.new(name);
    endfunction


    //--------------------
    //Send to driver
    //--------------------
    virtual task body();
        repeat(15) begin
        



        end


    endtask






endclass