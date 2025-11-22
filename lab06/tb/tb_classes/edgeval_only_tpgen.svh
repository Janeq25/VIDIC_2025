
class edgeval_only_tpgen extends random_tpgen;
    `uvm_component_utils (edgeval_only_tpgen)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new



    protected function byte get_data();
    
        bit [1:0] zero_ones;
    
        zero_ones = 2'($random);
    
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return 8'($random);
    endfunction : get_data


    protected function byte get_address();
    
        bit zero_ones;
    
        zero_ones = 1'($random);
    
        if (zero_ones == '1)
            return 8'h00;
        else
            return 8'hFF;
    endfunction : get_address

endclass