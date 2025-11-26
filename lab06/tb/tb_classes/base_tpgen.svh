



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
    pure virtual protected function op_type_t get_op_type();
    pure virtual protected function frame_types_t get_frame();

    function void build_phase(uvm_phase phase);
        command_port = new("command_port", this);
    endfunction : build_phase


    
    task run_phase(uvm_phase phase);

        command_s command;

        phase.raise_objection(this);
        command.op_type = reset_op;
        command_port.put(command);
        command.op_type = prog_switch;
        command_port.put(command);
        repeat (50) begin : random_loop
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