



class tpgen extends uvm_component;
    `uvm_component_utils (tpgen)

    protected bit [7:0] address;
    protected bit [7:0] data;

//------------------------------------------------------------------------------
// port for sending the transactions
//------------------------------------------------------------------------------
    uvm_put_port #(command_transaction) command_port;



    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        command_port = new("command_port", this);
    endfunction : build_phase



    
    task run_phase(uvm_phase phase);

        command_transaction command;
        command    = new("command");

        phase.raise_objection(this);

        command.op_type = reset_op;
        command_port.put(command);

        command    = new("command");

        command.op_type = prog_switch;
        command_port.put(command);

        command    = command_transaction::type_id::create("command");
        repeat (100) begin
            assert(command.randomize());
            command_port.put(command);
        end

        #500;
        phase.drop_objection(this);
    endtask : run_phase
endclass