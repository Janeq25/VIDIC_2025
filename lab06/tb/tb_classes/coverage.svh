


class coverage extends uvm_subscriber #(command_s);
    `uvm_component_utils(coverage)

        protected frame_types_t frame_type;
        protected op_type_t op_type;
        protected logic [7:0] address;
        protected logic [7:0] data;

    // Covergroup checking the generated frames and their sequences
    covergroup frame_cov;
        option.name = "cg_frame_cov";
    
        coverpoint frame_type {
            bins ALL_FRAMES[]              = {[wrong_parity_frame1 : correct_pck]};
        }
    
    endgroup
    
    covergroup op_cov;
    
        option.name = "cg_oper_cov";
    
    
        coverpoint op_type {
            bins ALL_OPS[]             = {[regular_op : reset_op]};
            bins ALL_OPS_TWICE[]       = ([regular_op : reset_op] [* 2]);
            bins REG_AFTER_PROG[]      = (prog_op => regular_op);
            bins REG_AFTER_RESET[]     = (reset_op => regular_op);
        }
    
    endgroup
    
    covergroup data_cov;
    
        option.name = "cg_data_cov";
    
    
        coverpoint address {
            bins ALL[]             = {[8'h00:8'hFF]};
        }
    
        coverpoint data {
            bins ALL[]             = {[8'h00:8'hFF]};
        }
    
    
    
    endgroup


    function new (string name, uvm_component parent);
        super.new(name, parent);
        op_cov = new();
        frame_cov = new();
        data_cov = new();
    endfunction


//------------------------------------------------------------------------------
// subscriber write function
//------------------------------------------------------------------------------
    function void write(command_s t);
        frame_type = t.frame_type;
        op_type = t.op_type;
        address = t.address;
        data = t.data;
        op_cov.sample();
        frame_cov.sample();
        data_cov.sample();
    endfunction : write
    
endclass