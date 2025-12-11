


class scoreboard extends uvm_subscriber #(result_transaction);
    `uvm_component_utils(scoreboard)


    protected const packet_s ignored_pkt = packet_s'('1);


//------------------------------------------------------------------------------
// local typedefs
//------------------------------------------------------------------------------
    typedef enum bit {
        TEST_PASSED,
        TEST_FAILED
    } test_result;

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
//    virtual tinyalu_bfm bfm;
    uvm_tlm_analysis_fifo #(command_transaction) cmd_f;

    local test_result tr = TEST_PASSED; // the result of the current test

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------
    local function void print_test_result (test_result r);
        if(tr == TEST_PASSED) begin
            set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
            $write ("-----------------------------------\n");
            $write ("----------- Test PASSED -----------\n");
            $write ("-----------------------------------");
            set_print_color(COLOR_DEFAULT);
            $write ("\n");
        end
        else begin
            set_print_color(COLOR_BOLD_BLACK_ON_RED);
            $write ("-----------------------------------\n");
            $write ("----------- Test FAILED -----------\n");
            $write ("-----------------------------------");
            set_print_color(COLOR_DEFAULT);
            $write ("\n");
        end
    endfunction

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        cmd_f = new ("cmd_f", this);
    endfunction : build_phase




    protected function bit pck_is_correct(packet_s pck);

        if (pck.address.start_bit != 1'b0) return FALSE;
        if (pck.data.start_bit != 1'b0) return FALSE;
        if (pck.address.stop_bit != 1'b1) return FALSE;
        if (pck.data.stop_bit != 1'b1) return FALSE;
        if (pck.address.parity_bit != get_parity(pck.address.data)) return FALSE;
        if (pck.data.parity_bit != get_parity(pck.data.data)) return FALSE;
    
        return TRUE;
    
    endfunction

    protected function bit get_port(packet_s pck);

        bit [7:0] address;
    
        address = {<<{pck.address.data}};
    
        return switch_memory[address];
    
    endfunction 

    protected function verify_packet(packet_s sent_pkt, packet_s sout0, packet_s sout1);
    
    
        if (pck_is_correct(sent_pkt) != TRUE) begin
            if (sout0 != ignored_pkt) begin
                `ifdef DEBUG
                $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_pkt, sout0, sout1);
                `endif
                tr = TEST_FAILED;
            end
            if (sout1 != ignored_pkt) begin
                `ifdef DEBUG
                $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_pkt, sout0, sout1);
                `endif
                tr = TEST_FAILED;
            end
        end
        else begin
            if (get_port(sent_pkt) == 1'b0) begin
                if (sout0 != sent_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT CORRESPONDS TO SENT PKT\n\n", sent_pkt, sout0, sout1);
                    `endif
                    tr = TEST_FAILED;
                end
                if (sout1 != ignored_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_pkt, sout0, sout1);
                    `endif
                    tr = TEST_FAILED;
                end
            end
            else begin
                if (sout1 != sent_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT CORRESPONDS TO SENT PKT\n\n", sent_pkt, sout0, sout1);
                    `endif
                    tr = TEST_FAILED; 
                end
                if (sout0 != ignored_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_pkt, sout0, sout1);
                    `endif
                    tr = TEST_FAILED;
                end
            end
        end
    endfunction


    task print_result();
        print_test_result(tr);
    endtask
    




//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------
    function void write(result_transaction t);
        command_transaction cmd;
        packet_s packet;
        do
            while (!cmd_f.try_get(cmd))
                $fatal(1, "Missing command in self checker");
        while (!(cmd.op_type == regular_op));

        packet = construct_packet(.frame_type(cmd.frame_type), .address({<<{cmd.frame_address}}), .data({<<{cmd.frame_data}}));

        `ifdef DEBUG
        $display("PACKET DATA: Address: %h, Data: %h, OP Type: %s, Frame Type: %s\n", cmd.frame_address, cmd.frame_data, cmd.op_type.name(), cmd.frame_type.name());
        $display("PACKET SOUT0: Address: %h, Data: %h, OP Type: %s, Frame Type: %s\n", t.packet_sout0.address.data, t.packet_sout0.data.data, cmd.op_type.name(), cmd.frame_type.name());
        $display("PACKET SOUT1: Address: %h, Data: %h, OP Type: %s, Frame Type: %s\n", t.packet_sout1.address.data, t.packet_sout1.data.data, cmd.op_type.name(), cmd.frame_type.name());
        `endif

        verify_packet(packet, t.packet_sout0, t.packet_sout1);
    endfunction : write

//------------------------------------------------------------------------------
// check phase
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        print_test_result(tr);
    endfunction : report_phase

endclass