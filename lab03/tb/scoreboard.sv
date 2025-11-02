


module scoreboard(simple_uart_switch_bfm bfm);
    import simple_uart_switch_tb_pkg::*;

    packet_q sent_packets_q;
    packet_q received_packets_sout0_q;
    packet_q received_packets_sout1_q;
    const packet_s ignored_pkt = packet_s'('1);


    typedef enum bit {
        TEST_PASSED,
        TEST_FAILED
    } test_result_t;
    
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color_t;
    


    test_result_t        test_result = TEST_PASSED;


    task automatic extract_packet(ref logic serial_in, ref packet_q packet_queue);

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

    function bit pck_is_correct(packet_s pck);

        if (pck.address.start_bit != 1'b0) return FALSE;
        if (pck.data.start_bit != 1'b0) return FALSE;
        if (pck.address.stop_bit != 1'b1) return FALSE;
        if (pck.data.stop_bit != 1'b1) return FALSE;
        if (pck.address.parity_bit != get_parity(pck.address.data)) return FALSE;
        if (pck.data.parity_bit != get_parity(pck.data.data)) return FALSE;
    
        return TRUE;
    
    endfunction

    function bit get_port(packet_s pck);

        bit [7:0] address;
    
        address = {<<{pck.address.data}};
    
        return switch_memory[address];
    
    endfunction 

    task verify_packets();
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
    endtask

// used to modify the color of the text printed on the terminal
    function void set_print_color ( print_color_t c );
        string ctl;
        case(c)
            COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
            COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
            COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
            COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
            COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
            COLOR_DEFAULT : ctl              = "\033\[0m\n";
            default : begin
                $error("set_print_color: bad argument");
                ctl                          = "";
            end
        endcase
        $write(ctl);
    endfunction

    function void print_test_result (test_result_t r);
        if(r == TEST_PASSED) begin
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
    


    initial begin
        @(posedge bfm.test_start);
        forever begin
            @(posedge bfm.pck_start) begin
                extract_packet(bfm.sout0, received_packets_sout0_q);
            end
        end
    end
    
    initial begin
        @(posedge bfm.test_start);
        forever begin
            @(posedge bfm.pck_start) begin
                extract_packet(bfm.sout1, received_packets_sout1_q);
            end
        end
    end

    initial begin
        @(posedge bfm.test_start);
        forever begin
            @(posedge bfm.pck_start) begin
                sent_packets_q.push_front(bfm.current_packet);
            end
        end
    end

    initial begin
        @(negedge bfm.test_start) begin
            verify_packets();
            print_test_result(test_result);
            $finish();
        end
    end


    initial begin
        @(posedge bfm.clk);
        if (~bfm.rst_n) begin
            if (~bfm.sout0 || ~bfm.sout1) begin
                `ifdef DEBUG
                    $display("sout0 and sout1 shall be asserted when reset is active");
                `endif
                test_result = TEST_FAILED;
            end
        end
    end

    initial begin
        @(posedge bfm.clk);
        if (bfm.prog) begin
            if (~bfm.sout0 || ~bfm.sout1) begin
                `ifdef DEBUG
                    $display("sout0 shall be asserted when prog is active");
                `endif
                test_result = TEST_FAILED;
            end
        end
    end


endmodule