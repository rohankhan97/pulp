class cpi_agent #(
  parameter int unsigned DW = 8
) extends uvm_agent;

	`uvm_component_param_utils(cpi_agent#(DW))

	// could be replaced by uvm_component_new if dv_macros are available
	function new (string name="", uvm_component parent=null); 
	  super.new(name, parent); 
	endfunction : new

	cpi_agent_cfg cfg;
    cpi_driver#(DW) vip_driver;
    cpi_monitor#(DW) vip_monitor;
    cpi_sequencer vip_sequencer; 

	function void build_phase(uvm_phase phase);
	  super.build_phase(phase);
	  // get cpi_agent_cfg object from uvm_config_db
	  if (!uvm_config_db#(cpi_agent_cfg)::get(this, "", "cfg", cfg)) begin
	    `uvm_fatal(get_full_name(), $sformatf("failed to get %s from uvm_config_db", cfg.get_type_name()))
	  end
	  `uvm_info(get_full_name(), $sformatf("\n%0s", cfg.sprint()), UVM_HIGH)

		// create components
		vip_monitor = cpi_monitor#(DW)::type_id::create("vip_monitor",this);
		if (cfg.is_active) begin
			vip_sequencer = cpi_sequencer::type_id::create("vip_sequencer",this);
			if (cfg.en_driver) begin
				vip_driver = cpi_driver#(DW)::type_id::create("vip_driver",this);
			end
		end
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if (cfg.en_driver) begin
			vip_driver.seq_item_port.connect(vip_sequencer.seq_item_export);
		end
	endfunction

endclass : cpi_agent
