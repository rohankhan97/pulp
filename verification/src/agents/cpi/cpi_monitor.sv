class cpi_monitor#(
	parameter int unsigned DW = 8
) extends uvm_monitor;
	`uvm_component_param_utils(cpi_monitor#(DW))

	`uvm_component_new

	uvm_analysis_port #(cpi_frame_item) mon_analysis_port;

	virtual cpi_if#(DW) vif;

	semaphore sema4;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual cpi_if#(DW))::get(this, "", "vif",vif)) begin
			`uvm_fatal(`gfn,"Could not get vif")
		end
		sema4 = new(1);
		mon_analysis_port = new("mon_analysis_port",this);
	endfunction

	task sniff_camera_item_input(ref cpi_frame_item item);
		int line_pixels = 0;
		int frame_lines = 0;
		@(posedge vif.vref);
		while (frame_lines < FRAME_LINES) begin
			@(posedge vif.pclk);
			line_pixels = 0;
			while (line_pixels < LINE_PIXELS) begin
				@(posedge vif.pclk);
				if (vif.href) begin
					item.pdata[frame_lines][line_pixels][0] = vif.data[0];
					item.pdata[frame_lines][line_pixels][1] = vif.data[1];
					item.pdata[frame_lines][line_pixels][2] = vif.data[2];
					item.pdata[frame_lines][line_pixels][3] = vif.data[3];
					item.pdata[frame_lines][line_pixels][4] = vif.data[4];
					item.pdata[frame_lines][line_pixels][5] = vif.data[5];
					item.pdata[frame_lines][line_pixels][6] = vif.data[6];
					item.pdata[frame_lines][line_pixels][7] = vif.data[7];
					item.pdata[frame_lines][line_pixels][8] = vif.data[8];
					item.pdata[frame_lines][line_pixels][9] = vif.data[9];
					line_pixels = line_pixels + 1;
				end
			end
			frame_lines = frame_lines + 1;
		end
	endtask

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			cpi_frame_item item_res = new;
			fork
				sniff_camera_item_input(item_res);
			join
			`uvm_info(get_type_name(),$sformatf("CPI VIP Monitor collected frame %s",item_res.convert2str()),UVM_LOW)
			mon_analysis_port.write(item_res);
		end
	endtask
endclass