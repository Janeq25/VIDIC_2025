


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
    packet_s current_packet;
    frame_types_t current_frame_type;
    op_type_t current_op;


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
    
        current_packet = pkt;
        packet_stream = ({packet_stream, stream_q'(pkt)});
    
        @(negedge clk)
    
        for (int i = 0; i < 22; i++) begin
            sin = packet_stream.pop_front();
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

endinterface