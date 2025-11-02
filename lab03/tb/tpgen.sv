



module tpgen(simple_uart_switch_bfm bfm);
    import simple_uart_switch_tb_pkg::*;
    
    bit [7:0] address;
    bit [7:0] data;
    
    function packet_s encode_packet(uart_frame_s address, uart_frame_s data);
    
        packet_s packet;
    
        packet.address = address;
        packet.data = address;
    
        return packet;
    
    endfunction
    
    function uart_frame_s encode_uart_frame(bit start_bit, bit [7:0] data, bit parity_bit, bit stop_bit);
    
        uart_frame_s frame;
    
        frame.start_bit = start_bit;
        frame.data = {<<{data}};
        frame.parity_bit = parity_bit;
        frame.stop_bit = stop_bit;
    
        return frame;
    
    endfunction
    
    task send_packet(packet_s pkt);
    
        stream_q packet_stream;
    
        pkt.timestamp = $time();
        bfm.current_packet = pkt;
        packet_stream = ({packet_stream, stream_q'(pkt)});
    
        @(negedge bfm.clk)
    
        for (int i = 0; i < 22; i++) begin
            bfm.sin = packet_stream.pop_front();
            wait_clk(16);
        end
    
    endtask


    
    task reset_dut();
        bfm.rst_n = 1'b1;
        @(posedge bfm.clk);
        wait_clk(2);
        bfm.rst_n = 1'b0;
        wait_clk(2);
        bfm.rst_n = 1'b1;
    endtask

    function op_type_t get_op_type();
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
    
    function frame_types_t get_frame();
        
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
    
    function byte get_data();
    
        bit [1:0] zero_ones;
    
        zero_ones = 2'($random);
    
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return 8'($random);
    endfunction : get_data

    task program_switch();

        packet_s config_pkt;
    
        bfm.prog = 1'b1;
    
        for (int i = 0; i < (2**8); i++) begin
            switch_memory[i] = 1'($random());
        end
    
        for (int i = 0; i < (2**8); i++) begin
            config_pkt.address = encode_uart_frame(1'b0, 8'(i), get_parity(8'(i)), 1'b1);
            config_pkt.data = encode_uart_frame(1'b0, 8'(switch_memory[i]), get_parity(8'(switch_memory[i])), 1'b1);
            send_packet(config_pkt);
        end
    
        bfm.prog = 1'b0;
    
    endtask
    

    initial begin : tp_gen

        packet_s test_packet;
    
        bfm.pck_start = 0;
        bfm.test_start = 0;
        bfm.sin = 1'b1;
        bfm.prog = 1'b0;
    
        reset_dut();
    
    
        program_switch();

        bfm.test_start = 1;


    
        for (int i = 0; i <= 10000; i++) begin
            address = get_data();
            data = get_data();
    
            bfm.current_op = get_op_type();
            bfm.current_frame_type = get_frame();
    
    
            case (bfm.current_frame_type)
                correct_pck : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address), 1'b1);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data), 1'b1);
                end
                missing_start_bit_frame0 : begin 
                    test_packet.address = encode_uart_frame(1'b1, address, get_parity(address), 1'b1);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data), 1'b1);
                end
                missing_start_bit_frame1 : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address), 1'b1);
                    test_packet.data = encode_uart_frame(1'b1, data, get_parity(data), 1'b1);
                end
                missing_stop_bit_frame0 : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address), 1'b0);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data), 1'b1);
                end
                missing_stop_bit_frame1 : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address), 1'b1);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data), 1'b0);
                end
                wrong_parity_frame0 : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address) + 1'b1, 1'b1);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data), 1'b1);
                end
                wrong_parity_frame1 : begin 
                    test_packet.address = encode_uart_frame(1'b0, address, get_parity(address), 1'b1);
                    test_packet.data = encode_uart_frame(1'b0, data, get_parity(data) + 1'b1, 1'b1);
                end
            endcase
    
    
    
            case (bfm.current_op)
                regular_op : begin
                    bfm.pck_start = 1'b1;
                    send_packet(test_packet);
                    bfm.pck_start = 1'b0;
                    wait_clk(1);
                end
                reset_op : begin 
                    reset_dut();
                end
                prog_op : begin 
                    bfm.prog = 1'b1;
                    wait_clk(2);
                    bfm.prog = 1'b0;
                 end
            endcase
    
        end
    
    
        bfm.test_start = 0;
    
    end
endmodule