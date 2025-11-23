

package simple_uart_switch_tb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"


    const bit TRUE = 1'b1;
    const bit FALSE = 1'b0;
    
    typedef enum bit [2:0] {
        correct_pck              = 3'b000,
        missing_start_bit_frame0 = 3'b001,
        missing_start_bit_frame1 = 3'b010,
        missing_stop_bit_frame0  = 3'b011,
        missing_stop_bit_frame1  = 3'b100,
        wrong_parity_frame0      = 3'b101,
        wrong_parity_frame1      = 3'b110
    } frame_types_t;
    
    typedef enum bit [1:0] {
        regular_op          = 2'b00,
        prog_op             = 2'b01,
        reset_op            = 2'b10,
        prog_switch         = 2'b11
    } op_type_t;


    typedef struct packed {
        frame_types_t frame_type;
        op_type_t op_type;
        logic [7:0] address;
        logic [7:0] data;
    } command_s;

    
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

    typedef struct packed {
        packet_s packet_sout0;
        packet_s packet_sout1;
    } result_s;
    
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color_t;

    typedef enum bit {
        TEST_PASSED,
        TEST_FAILED
    } test_result_t;

    test_result_t        test_result = TEST_PASSED;


    typedef packet_s packet_q [$];


    task wait_clk(int clk_num);
        #(20*clk_num);
    endtask 

    bit switch_memory [(2**8)-1:0];

    function bit get_parity(bit [7:0] data);

        return ^data;
    
    endfunction 



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



    `include "coverage.svh"
    `include "base_tpgen.svh"
    `include "random_tpgen.svh"
    `include "edgeval_only_tpgen.svh"
    `include "scoreboard.svh"
    `include "driver.svh"
    `include "command_monitor.svh"
    `include "result_monitor.svh"
    `include "env.svh"



    `include "random_test.svh"
    `include "edgeval_only_test.svh"

endpackage