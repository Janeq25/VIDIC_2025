class testbench;

    virtual simple_uart_switch_bfm bfm;

    tpgen tpgen_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    function new (virtual simple_uart_switch_bfm b);
        bfm          = b;
        tpgen_h      = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);
    endfunction : new

    task execute();
        fork
            begin
                coverage_h.execute();
            end
            begin
                tpgen_h.execute();
            end
            begin
                scoreboard_h.execute();
            end
        join
        scoreboard_h.print_result();
    endtask : execute

endclass : testbench


