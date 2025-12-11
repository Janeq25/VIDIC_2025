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
 */
class result_monitor extends uvm_component;
    `uvm_component_utils(result_monitor)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual simple_uart_switch_bfm bfm;
    uvm_analysis_port #(result_transaction) ap;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// access function for BFM
//------------------------------------------------------------------------------
    // this variable is defined here as static for that you can see it in the
    // Simvision waveforms.
    static result_transaction result_t;

    function void write_to_monitor(packet_s packet_sout0, packet_s packet_sout1);
//        result_transaction result_t;
        result_t        = new("result_t");
        result_t.packet_sout0 = packet_sout0;
        result_t.packet_sout1 = packet_sout1;


        `ifdef DEBUG
            $display("RESULT MONITOR: packet sout0: %p, packet sout1: %p\n", packet_sout0, packet_sout1);
        `endif

        ap.write(result_t);
    endfunction : write_to_monitor


//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual simple_uart_switch_bfm)::get(null, "*","bfm", bfm))
            `uvm_fatal("RESULT MONITOR", "Failed to get BFM")

        bfm.result_monitor_h = this;
        ap                   = new("ap",this);
    endfunction : build_phase


endclass : result_monitor






