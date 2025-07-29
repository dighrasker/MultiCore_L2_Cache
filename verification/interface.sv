interface cache_interface (input logic clk, rst);

    //--------------------
    //Signal Declaration
    //--------------------



    //--------------------
    //Driver CB
    //--------------------
    clocking driver_cb @(posedge clk);



    endclocking


    //--------------------
    //Monitor CB
    //--------------------
    clocking monitor_cb @(posedge clk);


    endclocking


    modport DRIVER(clocking driver_cb, input clk, rst);
    modport MONITOR(clocking monitor_cb, input clk, rst);

endinterface