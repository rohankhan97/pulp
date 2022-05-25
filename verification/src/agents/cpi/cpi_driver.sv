class cpi_driver#(
	parameter int unsigned DW = 8
) extends uvm_driver #(cpi_frame_item);

	`uvm_component_param_utils(cpi_driver#(DW))

	`uvm_component_new

	virtual cpi_if#(DW) vif;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(`gfn,"Driver build",UVM_LOW)
		if (!uvm_config_db#(virtual cpi_if#(DW))::get(this, "", "vif",vif)) begin
			`uvm_fatal(`gfn,"Could not get vif")
		end
	endfunction

	virtual task pre_reset_phase (uvm_phase phase);
		phase.raise_objection(this);
		`uvm_info(`gfn,"CPI BUS RESET",UVM_LOW)
		vif.reset_bus(1'b0);
		phase.drop_objection(this);
	endtask: pre_reset_phase

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			cpi_frame_item m_item;
			seq_item_port.get_next_item(m_item);
			drive_item(m_item);
			seq_item_port.item_done();
		end
	endtask

	task drive_item(cpi_frame_item m_item);
		`uvm_info(`gfn,"CPI VIP Drive frame",UVM_LOW)
		// wait for some random number of cycles
		vif.pclk_ref_clock_cycles(m_item.lat_cycles,0);
		// drive the pixel
		vif.pclk_ref_clock_cycles(2,1);
		vif.set_vref(1);
		vif.pclk_ref_clock_cycles(1,1);
		vif.set_vref(0);
		vif.pclk_ref_clock_cycles(1,1);
		for (int y = 0; y < FRAME_LINES; y++) begin
			vif.pclk_ref_clock_cycles(4,1);
			vif.set_href(1);
			for (int x = 0; x < LINE_PIXELS; x++) begin
				// send a new pixel
				vif.send_pixel(m_item.pdata[y][x]);
			end
			vif.set_href(0);
		end
		vif.set_vref(0);
		vif.pclk_ref_clock_cycles(1,1);

	endtask
endclass