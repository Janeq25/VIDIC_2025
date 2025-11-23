



virtual class base_tpgen extends uvm_component;


    protected bit [7:0] address;
    protected bit [7:0] data;

//------------------------------------------------------------------------------
// port for sending the transactions
//------------------------------------------------------------------------------
    uvm_put_port #(command_s) command_port;



    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new


    pure virtual protected function byte get_data();
    pure virtual protected function byte get_address();

    function void build_phase(uvm_phase phase);
        command_port = new("command_port", this);
    endfunction : build_phase

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
    
    task run_phase(uvm_phase phase);

        command_s command;

        phase.raise_objection(this);
        command.op_type = reset_op;
        command_port.put(command);
        command.op_type = prog_switch;
        command_port.put(command);
        repeat (10000) begin : random_loop
            command.op_type = get_op_type();
            command.frame_type = get_frame();
            command.data  = get_data();
            command.address  = get_address();
            command_port.put(command);
        end : random_loop
        #500;
        phase.drop_objection(this);
    endtask : run_phase
endclass