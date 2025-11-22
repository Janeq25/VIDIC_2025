module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import simple_uart_switch_tb_pkg::*;
    
    simple_uart_switch_bfm bfm();
    
    simple_switch_uart DUT (
        .clk  (bfm.clk), //posedge active clock
        .prog (bfm.prog), //1=programming, 0=functional
        .rst_n(bfm.rst_n), //async active-low
        .sin  (bfm.sin), //serial input
        .sout0(bfm.sout0), //serial output port 0
        .sout1(bfm.sout1) //serial output port 1
    );
    
    initial begin
        uvm_config_db #(virtual simple_uart_switch_bfm)::set(null, "*", "bfm", bfm);
        run_test();
    end
    
    endmodule : top
    
    
    