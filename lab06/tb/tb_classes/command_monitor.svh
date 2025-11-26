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
class command_monitor extends uvm_component;
    `uvm_component_utils(command_monitor)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual simple_uart_switch_bfm bfm;
    uvm_analysis_port #(command_s) ap;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

//------------------------------------------------------------------------------
// monitoring function called from BFM
//------------------------------------------------------------------------------
    function void write_to_monitor(command_s cmd);
        logic [7:0] address;
        logic [7:0] data;
        address = {<<{cmd.address}};
        data = {<<{cmd.data}};
        `ifdef DEBUG
        $display("COMMAND MONITOR: Address: %h, Data: %h, OP Type: %s, Frame Type: %s", address, data, cmd.op_type.name(), cmd.frame_type.name());
        `endif
        ap.write(cmd);
    endfunction : write_to_monitor

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);

        if(!uvm_config_db #(virtual simple_uart_switch_bfm)::get(null, "*","bfm", bfm))
            $fatal(1, "Failed to get BFM");

        bfm.command_monitor_h = this;
        ap                    = new("ap",this);
    endfunction : build_phase

endclass : command_monitor

