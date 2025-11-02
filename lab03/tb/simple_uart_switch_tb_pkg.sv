

package simple_uart_switch_tb_pkg;
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
        reset_op            = 2'b10
    } op_type_t;
    
    
    
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


    task wait_clk(int clk_num);
        #(20*clk_num);
    endtask 

    bit switch_memory [(2**8)-1:0];


endpackage