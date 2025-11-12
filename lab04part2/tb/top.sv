



module top();
    import simple_uart_switch_tb_pkg::*;

    simple_uart_switch_bfm bfm();
    testbench testbench_h;

    initial begin
        testbench_h = new(bfm);
        testbench_h.execute();
        $finish;
    end

    simple_switch_uart DUT (
        .clk  (bfm.clk), //posedge active clock
        .prog (bfm.prog), //1=programming, 0=functional
        .rst_n(bfm.rst_n), //async active-low
        .sin  (bfm.sin), //serial input
        .sout0(bfm.sout0), //serial output port 0
        .sout1(bfm.sout1) //serial output port 1
    );

    

endmodule