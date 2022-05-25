class cpi_agent_cfg extends uvm_object;

	// agent cfg knobs
	bit is_active = 1'b1;  // active driver/sequencer or passive monitor
	bit en_cov    = 1'b0;  // enable coverage
	bit en_monitor = 1'b1; // enable monitor
	bit en_driver = 1'b1; // enable driver

	logic [31:0] cpi_min_data_r = 1;
	logic [31:0] cpi_max_data_r = 10;

	`uvm_object_utils_begin(cpi_agent_cfg)
	  `uvm_field_int(is_active,      UVM_DEFAULT)
	  `uvm_field_int(en_cov,         UVM_DEFAULT)
	  `uvm_field_int(en_monitor,     UVM_DEFAULT)
	  `uvm_field_int(en_driver,      UVM_DEFAULT)
	  `uvm_field_int(cpi_min_data_r, UVM_DEFAULT)
	  `uvm_field_int(cpi_max_data_r, UVM_DEFAULT)
	`uvm_object_utils_end

	// could be replaced by uvm_object_new if dv_macros are available
	function new (string name=""); 
	  super.new(name); 
	endfunction : new

endclass : cpi_agent_cfg
