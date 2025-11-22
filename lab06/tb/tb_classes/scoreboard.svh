


class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    virtual simple_uart_switch_bfm bfm;


    protected packet_q sent_packets_q;
    protected packet_q received_packets_sout0_q;
    protected packet_q received_packets_sout1_q;
    protected const packet_s ignored_pkt = packet_s'('1);


    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new




    protected task automatic extract_packet(ref logic serial_in, ref packet_q packet_queue);

        stream_q bits_stream;
        packet_s received_packet;
        uart_frame_s received_address_frame;
        uart_frame_s received_data_frame;
    
        for (int i = 0; i < 22; i++) begin
            bits_stream.push_front(serial_in);
            wait_clk(16);
        end
    
        received_address_frame = {uart_frame_s'({<<{bits_stream[$-11:$]}})};
        received_data_frame = {uart_frame_s'({<<{bits_stream[$-22:$-11]}})};
        received_packet.address = received_address_frame;
        received_packet.address.data = {>>{received_packet.address.data}};
        received_packet.data = received_data_frame;
        received_packet.data.data = {>>{received_packet.data.data}};
        packet_queue.push_front(received_packet);
        
    endtask

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
                    test_result = TEST_FAILED;
                end
                if (received_packets_sout1_q[i] != ignored_pkt) begin
                    `ifdef DEBUG
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    `endif
                    test_result = TEST_FAILED;
                end
            end
            else begin
                if (get_port(sent_packets_q[i]) == 1'b0) begin
                    if (received_packets_sout0_q[i] != sent_packets_q[i]) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        test_result = TEST_FAILED;
                    end
                    if (received_packets_sout1_q[i] != ignored_pkt) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        test_result = TEST_FAILED;
                    end
                end
                else begin
                    if (received_packets_sout1_q[i] != sent_packets_q[i]) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        test_result = TEST_FAILED; 
                    end
                    if (received_packets_sout0_q[i] != ignored_pkt) begin
                        `ifdef DEBUG
                        $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                        `endif
                        test_result = TEST_FAILED;
                    end
                end
            end
        end
    endfunction


    task print_result();
        print_test_result(test_result);
    endtask
    

    task store_test_packets();
        begin
            @(posedge bfm.test_start);
            forever begin
                @(posedge bfm.pck_start) begin
                    sent_packets_q.push_front(bfm.current_packet);
                end
            end
        end

    endtask


    task store_packets_from_dut();
        fork
            begin
                @(posedge bfm.test_start);
                forever begin
                    @(posedge bfm.pck_start) begin
                        extract_packet(bfm.sout0, received_packets_sout0_q);
                    end
                end
            end
            
            begin
                @(posedge bfm.test_start);
                forever begin
                    @(posedge bfm.pck_start) begin
                        extract_packet(bfm.sout1, received_packets_sout1_q);
                    end
                end
            end
        join

    endtask



//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual simple_uart_switch_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        fork
            store_test_packets();
            store_packets_from_dut();
        join_none
    endtask : run_phase

//------------------------------------------------------------------------------
// check phase
//------------------------------------------------------------------------------
    function void check_phase(uvm_phase phase);
        verify_packets();
    endfunction : check_phase



//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        print_test_result(test_result);
    endfunction : report_phase

endclass