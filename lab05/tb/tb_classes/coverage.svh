


class coverage extends uvm_component;
    `uvm_component_utils(coverage)

    protected virtual simple_uart_switch_bfm bfm;


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


    function new (string name, uvm_component parent);
        super.new(name, parent);
        op_cov = new();
        frame_cov = new();
        data_cov = new();
    endfunction

    

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual simple_uart_switch_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

    
    task run_phase(uvm_phase phase);
        forever begin : sample_cov
            @(posedge bfm.clk);
            op_cov.sample();
            frame_cov.sample();
            data_cov.sample();
    
            /* #1step delay is necessary before checking for the coverage
             * as the .sample methods run in parallel threads
              */
            #1step;
            if($get_coverage() == 100) break; //disable, if needed
    
            // you can print the coverage after each sample
    //            $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
        end
    endtask
    
endclass