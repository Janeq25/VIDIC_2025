


interface simple_uart_switch_bfm;
    import simple_uart_switch_tb_pkg::*;

    logic clk;     // posedge active clock
    logic rst_n;   // async active-low
    logic prog;    // 1=programming, 0=functional
    logic sin;     // serial input
    logic sout0;   // serial output port 0
    logic sout1;   // serial output port 1

    logic pck_start;
    logic test_start;
    logic op_start;

    logic [7:0] address;
    logic [7:0] data;
    op_type_t op_type;
    frame_types_t frame_type;


    command_monitor command_monitor_h;
    result_monitor result_monitor_h;


    initial begin : clk_gen_blk
        clk = 0;
        forever begin : clk_frv_blk
            #10;
            clk = ~clk;
        end
    end
    
    // timestamp monitor
    initial begin
        longint clk_counter;
        clk_counter = 0;
        forever begin
            @(posedge clk) clk_counter++;
            if(clk_counter % 1000 == 0) begin
                $display("%0t Clock cycles elapsed: %0d", $time, clk_counter);
            end
        end
    end
    

    
    task send_packet(packet_s pkt);
    
        stream_q packet_stream;
    
        packet_stream = ({packet_stream, stream_q'(pkt)});
    
        @(negedge clk)
    
        for (int i = 0; i < 22; i++) begin
            sin = packet_stream.pop_front();
            wait_clk(16);
        end
    
    endtask


    task reset_dut();
        rst_n = 1'b1;
        @(posedge clk);
        wait_clk(2);
        rst_n = 1'b0;
        wait_clk(2);
        rst_n = 1'b1;
    endtask


    task program_switch();

        packet_s config_pkt;
    
        prog = 1'b1;
    
        for (int i = 0; i < (2**8); i++) begin
            switch_memory[i] = 1'($random());
        end
    
        for (int i = 0; i < (2**8); i++) begin
            config_pkt.address = encode_uart_frame(1'b0, 8'(i), get_parity(8'(i)), 1'b1);
            config_pkt.data = encode_uart_frame(1'b0, 8'(switch_memory[i]), get_parity(8'(switch_memory[i])), 1'b1);
            send_packet(config_pkt);
        end
    
        prog = 1'b0;
    
    endtask




    task send_op(op_type_t iop_type, frame_types_t iframe_type, logic [7:0] iaddress, logic [7:0] idata);

        packet_s test_packet;

        address = iaddress;
        data = idata;
        op_type = iop_type;
        frame_type = iframe_type;
    
        pck_start = 0;
        sin = 1'b1;
        prog = 1'b0;
        test_start = 1;
        op_start = 1;

    
        test_packet = construct_packet(frame_type, address, data);



        case (op_type)
            regular_op : begin
                pck_start = 1'b1;
                send_packet(test_packet);
                pck_start = 1'b0;
                op_start = 0;
                wait_clk(1);
            end
            reset_op : begin 
                reset_dut();
                op_start = 0;
                wait_clk(1);
            end
            prog_op : begin 
                prog = 1'b1;
                wait_clk(2);
                op_start = 0;
                prog = 1'b0;
                wait_clk(1);
            end
            prog_switch : begin
                program_switch();
            end
        endcase
    
    

    endtask

    task automatic extract_packet(ref logic serial_in, output packet_s packet);

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
        packet = received_packet;
        
    endtask


initial begin : result_monitor_thread
    result_s result;
    @(posedge test_start);
    forever begin
        fork
            begin
                @(posedge pck_start) begin
                    extract_packet(sout0, result.packet_sout0);
                end
            end
            begin
                @(posedge pck_start) begin
                    extract_packet(sout1, result.packet_sout1);
                end
            end
        join
        result_monitor_h.write_to_monitor(result);
    end
end : result_monitor_thread


initial begin : cmd_monitor
    command_s command;
    forever begin
        @(posedge op_start);
        command.address = address;
        command.data = data;
        command.op_type = op_type;
        command.frame_type = frame_type;
        command_monitor_h.write_to_monitor(command);
    end

end : cmd_monitor



endinterface