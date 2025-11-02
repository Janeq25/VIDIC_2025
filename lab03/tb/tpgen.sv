



module tp_gen(simple_uart_switch_bfm bfm);
    import simple_uart_switch_tb_pkg::*;
    
    bit [7:0] address;
    bit [7:0] data;
    

    
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
    

    initial begin : tp_gen

        packet_s test_packet;
    
        bfm.pck_start = 0;
        bfm.test_start = 0;
        bfm.sin = 1'b1;
        bmf.prog = 1'b0;
    
        reset_dut();
    
    
        program_switch();

        bfm.test_start = 1;


    
        for (int i = 0; i <= 10000; i++) begin
            address = get_data();
            data = get_data();
    
            bfm.operation_type = get_op_type();
            bfm.frame_type = get_frame();
    
    
            case (bfm.frame_type)
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
    
    
    
            case (bfm.operation_type)
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
    
    
        bfm.test_end = 1;
    
    end
endmodule