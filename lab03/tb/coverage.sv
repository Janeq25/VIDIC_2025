


module coverage(simple_uart_switch_bfm bfm);
    import simple_uart_switch_tb_pkg::*;


    // Covergroup checking the generated frames and their sequences
    covergroup frame_cov;
        option.name = "cg_frame_cov";
    
        coverpoint bfm.current_frame_type {
            bins ALL_FRAMES[]              = {[wrong_parity_frame1 : correct_pck]};
        }
    
    endgroup
    
    covergroup op_cov;
    
        option.name = "cg_oper_cov";
    
    
        coverpoint bfm.current_op {
            bins ALL_OPS[]             = {[regular_op : reset_op]};
            bins ALL_OPS_TWICE[]       = ([regular_op : reset_op] [* 2]);
            bins REG_AFTER_PROG[]      = (prog_op => regular_op);
            bins REG_AFTER_RESET[]     = (reset_op => regular_op);
        }
    
    endgroup
    
    covergroup data_cov;
    
        option.name = "cg_data_cov";
    
    
        coverpoint bfm.current_packet.address.data {
            bins ALL[]             = {[8'h00:8'hFF]};
        }
    
        coverpoint bfm.current_packet.data.data {
            bins ALL[]             = {[8'h00:8'hFF]};
        }
    
    
    
    endgroup
    
    op_cov       oc;
    frame_cov    fc;
    data_cov     dc;
    
    initial begin : coverage
        oc      = new();
        fc      = new();
        dc      = new();
        forever begin : sample_cov
            @(posedge bfm.clk);
            oc.sample();
            fc.sample();
            dc.sample();
    
            /* #1step delay is necessary before checking for the coverage
             * as the .sample methods run in parallel threads
              */
            #1step;
            if($get_coverage() == 100) break; //disable, if needed
    
            // you can print the coverage after each sample
    //            $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
        end
    end : coverage
    
endmodule