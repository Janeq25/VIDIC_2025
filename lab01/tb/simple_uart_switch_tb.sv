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

typedef bit stream_q [$];
stream_q output_stream;
stream_q input_stream;



typedef struct packed {
    bit start_bit;
    bit [7:0] data;
    bit parity_bit;
    bit stop_bit;
} uart_frame_s;

typedef struct {
    uart_frame_s address;
    uart_frame_s data;
} packet_s;



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

function set_programming_mode();
    prog = 1'b1;
endfunction

function set_functional_mode();
    prog = 1'b0;
endfunction


function packet_s encode_packet(uart_frame_s address, uart_frame_s data);
    packet_s packet;
    packet.address = address;
    packet.data = address;
    return packet;
endfunction

function uart_frame_s encode_uart_frame(bit start_bit, bit [7:0] data, bit parity_bit, bit stop_bit);
    uart_frame_s frame;
    frame.start_bit = start_bit;
    frame.data = data;
    frame.parity_bit = parity_bit;
    frame.stop_bit = stop_bit;
    return frame;
endfunction


//------------------------
// Frame sender
//------------------------

initial begin
    uart_frame_s frame_to_send;
    frame_to_send = encode_uart_frame(1'b1, 8'haa, 1'b1, 1'b1);
    input_stream = ({input_stream, stream_q'(frame_to_send)});
    frame_to_send = encode_uart_frame(1'b1, 8'h55, 1'b1, 1'b1);
    input_stream = ({input_stream, stream_q'(frame_to_send)});
    frame_to_send = encode_uart_frame(1'b1, 8'h12, 1'b1, 1'b1);
    input_stream = ({input_stream, stream_q'(frame_to_send)});

    forever begin
        wait_clk(16);
        @(negedge clk) begin
            if (input_stream.size() > 0) begin
                sin = input_stream.pop_front();
            end
        end
    end

end

//------------------------
// Frame receiver
//------------------------

initial begin

    wait_clk(1);

    forever begin

        wait_clk(16);

        output_stream.push_front(sin);
    end
end

initial begin

    uart_frame_s frame_out;
    bit flag;

    forever begin
        @(posedge clk) begin
            if (output_stream.size() >= 11) begin
                flag = 1'b1;
                frame_out = {uart_frame_s'({<<{output_stream[$-11:$]}})};
                output_stream = output_stream[0:$-11];
            end
        end
    end
end



//------------------------
// Tester main
//------------------------






//------------------------------------------------------------------------------
// Temporary. The scoreboard will be later used for checking the data
final begin : finish_of_the_test
    print_test_result(test_result);
end

//------------------------------------------------------------------------------
// Other functions
//------------------------------------------------------------------------------

task wait_clk(int clk_num);
    for (int i=0; i < clk_num; i++) begin
        @(posedge clk);
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


endmodule : top
