
class random_tpgen extends base_tpgen;
    `uvm_component_utils (random_tpgen)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new



    protected function byte get_data();
    
        bit [1:0] zero_ones;
    
        zero_ones = 2'($random);
    
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return 8'($random);
    endfunction : get_data


    protected function byte get_address();
    
        bit [1:0] zero_ones;
    
        zero_ones = 2'($random);
    
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return 8'($random);
    endfunction : get_address

    protected function op_type_t get_op_type();
        bit [4:0] frame_choice;
        frame_choice = 4'($random());

        if (frame_choice == 4'h0) begin
            return reset_op;
        end
        else if (frame_choice == 4'h1) begin
            return prog_op;
        end
        else begin
            return regular_op;
        end
    endfunction 
    
    protected function frame_types_t get_frame();
        
        bit [2:0] frame_choice;

        frame_choice = 3'($random());
        case (frame_choice)
            3'b000 : return correct_pck;
            3'b001 : return missing_start_bit_frame0;
            3'b010 : return missing_start_bit_frame1;
            3'b011 : return missing_stop_bit_frame0;
            3'b100 : return missing_stop_bit_frame1;
            3'b101 : return wrong_parity_frame0;
            3'b110 : return wrong_parity_frame1;    
        endcase
    
    endfunction

endclass