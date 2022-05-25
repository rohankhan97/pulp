class cpi_frame_item extends uvm_sequence_item;

	rand logic [FRAME_LINES-1:0][LINE_PIXELS-1:0][9:0] pdata;
	rand logic [31:0] lat_cycles;
	logic [31:0] frame_id;
	
	`uvm_object_utils_begin(cpi_frame_item)
		`uvm_field_int(pdata,UVM_DEFAULT)
		`uvm_field_int(lat_cycles,UVM_DEFAULT)
		`uvm_field_int(frame_id,UVM_DEFAULT)
	`uvm_object_utils_end

	constraint lat_cycle_limit {
	  lat_cycles < LAT_CYCLE_LIMIT;
	}

	virtual function string convert2str();
		`ifdef VERBOSE
			return $sformatf("[CPI VIP] pdata = %0h",pdata);
		`else 
			return $sformatf("Omitting data packed print, use VERBOSE define to print it");
		`endif
	endfunction

	function new (string name = "cpi_frame_item");
		super.new(name);
	endfunction
endclass