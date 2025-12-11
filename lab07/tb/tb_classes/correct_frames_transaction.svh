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
class correct_frames_transaction extends command_transaction;
    `uvm_object_utils(correct_frames_transaction)

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

    constraint edge_values {
        frame_address dist {8'h00:=2, [8'h01 : 8'hFE]:=1, 8'hFF:=2};
        frame_data dist {8'h00:=2, [8'h01 : 8'hFE]:=1, 8'hFF:=2};
        frame_type dist {correct_pck:=1};
        op_type dist {regular_op:=1};
    }

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name="");
        super.new(name);
    endfunction
    
    
endclass : correct_frames_transaction


