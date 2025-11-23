


class scoreboard extends uvm_subscriber #(result_s);
    `uvm_component_utils(scoreboard)


    protected packet_q sent_packets_q;
    protected packet_q received_packets_sout0_q;
    protected packet_q received_packets_sout1_q;
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
    uvm_tlm_analysis_fifo #(command_s) cmd_f;

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

    protected function verify_packets();
        // discard first empty packet
    
        sent_packets_q.pop_front();
        sent_packets_q.pop_front();
    
        foreach (sent_packets_q[i]) begin
    
            if (pck_is_correct(sent_packets_q[i]) != TRUE) begin
                if (received_packets_sout0_q[i] != ignored_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    `endif
                    tr = TEST_FAILED;
                end
                if (received_packets_sout1_q[i] != ignored_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    `endif
                    tr = TEST_FAILED;
                end
            end
            else begin
                if (get_port(sent_packets_q[i]) == 1'b0) begin
                    if (received_packets_sout0_q[i] != sent_packets_q[i]) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        tr = TEST_FAILED;
                    end
                    if (received_packets_sout1_q[i] != ignored_pkt) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        tr = TEST_FAILED;
                    end
                end
                else begin
                    if (received_packets_sout1_q[i] != sent_packets_q[i]) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        tr = TEST_FAILED; 
                    end
                    if (received_packets_sout0_q[i] != ignored_pkt) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        tr = TEST_FAILED;
                    end
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
    function void write(result_s t);
        command_s cmd;
        packet_s packet;
        cmd.address      = 0;
        cmd.data         = 0;
        cmd.frame_type   = correct_pck;
        cmd.op_type      = reset_op;
        do
            if (!cmd_f.try_get(cmd))
                $fatal(1, "Missing command in self checker");
        while (!(cmd.op_type == regular_op));

        packet = construct_packet(cmd.frame_type, cmd.address, cmd.data);

        sent_packets_q.push_back(packet);
        received_packets_sout0_q.push_back(t.packet_sout0);
        received_packets_sout1_q.push_back(t.packet_sout1);
    endfunction : write

//------------------------------------------------------------------------------
// check phase
//------------------------------------------------------------------------------
    function void check_phase(uvm_phase phase);
        phase.raise_objection(this);
        verify_packets();
        phase.drop_objection(this);
    endfunction : check_phase



//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        print_test_result(tr);
    endfunction : report_phase

endclass