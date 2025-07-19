/*========================================
Filename: monitor.sv
Description: systemVerilog class that 
==========================================*/

class cache_packet extends uvm_sequence_item;
    `uvm_object_utils(our_packet)



    function new(string name ="our_packet")
        super.new(name);

    endfunction

endclass