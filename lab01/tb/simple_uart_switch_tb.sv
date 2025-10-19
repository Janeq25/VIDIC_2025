/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */
module top;

//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------

const bit TRUE = 1'b1;
const bit FALSE = 1'b0;

typedef bit stream_q [$];

typedef struct packed {
    bit start_bit;
    bit [7:0] data;
    bit parity_bit;
    bit stop_bit;
} uart_frame_s;

typedef struct packed {
    uart_frame_s address;
    uart_frame_s data;
} packet_s;

typedef packet_s packet_q [$];


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

//------------------------------------------------------------------------------
// Local variables
//------------------------------------------------------------------------------

logic clk;
logic rst_n;
logic prog;
logic sin;
logic sout0;
logic sout1;

packet_q sent_packets_q;
packet_q received_packets_sout0_q;
packet_q received_packets_sout1_q;

packet_s ignored_pkt = packet_s'('1);

bit switch_memory [(2**8)-1:0];
logic baud_clk;


test_result_t        test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------


simple_switch_uart u_simple_switch_uart (
    .clk  (clk), //posedge active clock
    .prog (prog), //1=programming, 0=functional
    .rst_n(rst_n), //async active-low
    .sin  (sin), //serial input
    .sout0(sout0), //serial output port 0
    .sout1(sout1) //serial output port 1
);

//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

initial begin : clk_gen_blk
    clk = 0;
    forever begin : clk_frv_blk
        #10;
        clk = ~clk;
    end
end

initial begin : baud_clk_gen_blk
    baud_clk = 0;
    @(posedge rst_n);
    @(posedge rst_n);
    forever begin : baud_clk_frv_blk
        wait_clk(16);
        baud_clk = ~baud_clk;
    end
end


initial begin : reset_gen_clk
    rst_n = 1'b1;
    @(posedge clk);
    wait_clk(2);
    rst_n = 1'b0;
    wait_clk(2);
    rst_n = 1'b1;
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

//------------------------------------------------------------------------------
// Tester
//------------------------------------------------------------------------------

//---------------------------------
// Random data generation functions
//---------------------------------



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
    sent_packets_q.push_front(pkt);
    packet_stream = ({packet_stream, stream_q'(pkt)});
    @(negedge clk)
    for (int i = 0; i < 22; i++) begin
        sin = packet_stream.pop_front();
        wait_clk(16);
    end
endtask

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

function bit get_parity(bit [7:0] data);
    return ^data;
endfunction 



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


//------------------------
// Frame sender
//------------------------

initial begin

    packet_s test_packet;
    bit [7:0] address;
    bit [7:0] data;

    sin = 1'b1;
    prog = 1'b0;

    // wait for reset
    @(posedge rst_n);
    @(posedge clk);

    program_switch();

    sent_packets_q = {};
    received_packets_sout0_q = {};
    received_packets_sout1_q = {};

    for (int i = 0; i <= 8'hff; i++) begin
        address = 8'($random());
        data = 8'($random());
        test_packet.address = encode_uart_frame(1'($random()), address, get_parity(address), 1'($random()));
        test_packet.data = encode_uart_frame(1'($random()), data, get_parity(data), 1'($random()));
        send_packet(test_packet);
    end


    verify_packets();

    $finish();
end
//------------------------
// Frame receiver
//------------------------


initial begin
    @(posedge rst_n);
    wait_clk(3);
    forever begin
        extract_packet(sout0, received_packets_sout0_q);
    end
end

initial begin
    @(posedge rst_n);
    wait_clk(3);
    forever begin
        extract_packet(sout1, received_packets_sout1_q);
    end
end


//------------------------
// Tester main
//------------------------

task verify_packets();
    // discard first empty packet

    sent_packets_q.pop_front();
    sent_packets_q.pop_front();

    foreach (sent_packets_q[i]) begin

        if (pck_is_correct(sent_packets_q[i]) != TRUE) begin
            if (received_packets_sout0_q[i] != ignored_pkt) begin
                $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                test_result = TEST_FAILED;
            end
            if (received_packets_sout1_q[i] != ignored_pkt) begin
                $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p INVALID PACKET NOT IGNORED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                test_result = TEST_FAILED;
            end
        end
        else begin
            if (get_port(sent_packets_q[i]) == 1'b0) begin
                if (received_packets_sout0_q[i] != sent_packets_q[i]) begin
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    test_result = TEST_FAILED;
                end
                if (received_packets_sout1_q[i] != ignored_pkt) begin
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    test_result = TEST_FAILED;
                end
            end
            else begin
                if (received_packets_sout1_q[i] != sent_packets_q[i]) begin
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT1 NOT CORRESPONDS TO SENT PKT\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    test_result = TEST_FAILED; 
                end
                if (received_packets_sout0_q[i] != ignored_pkt) begin
                    $display(" sent:           %p,\n received sout0: %p,\n received sout1: %p PKT ON PORT0 NOT IGNORED WHILE PORT0 IS ADDRESSED\n\n", sent_packets_q[i], received_packets_sout0_q[i], received_packets_sout1_q[i]);
                    test_result = TEST_FAILED;
                end
            end
        end
    end
endtask




//------------------------------------------------------------------------------
// Temporary. The scoreboard will be later used for checking the data
final begin : finish_of_the_test
    print_test_result(test_result);
end

//------------------------------------------------------------------------------
// Other functions
//------------------------------------------------------------------------------

task reset_dut();
    @(posedge clk)
    rst_n = 1'b1;
    wait_clk(2);
    rst_n = 1'b0;
    wait_clk(2);
    rst_n = 1'b1;
endtask

task wait_clk(int clk_num);
    #(20*clk_num);
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


endmodule : top
