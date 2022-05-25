interface cpi_if #(parameter DW = 8) (input logic rclk);

	wire vref;
	wire href;
	wire pclk;
	wire [DW-1:0] data;

	// support signals to workaround illegal wire driving from procedural assignments
	logic vref_l;
	logic href_l;
	logic pclk_l;
	logic [DW-1:0] data_l;

	assign vref = vref_l;
	assign href = href_l;
	assign pclk = pclk_l;
	assign data = data_l;

	clocking slave_cb @(negedge rclk);
		inout vref;
		inout href;
		inout data;
		inout pclk;
	endclocking

	task send_pixel (input logic [DW-1:0] pixel);
		for (int i = 0; i < DW; i++) begin
			if (pixel[i]) begin
				data_l[i] = 1'b1;
			end else begin
				data_l[i] = 1'b0;
			end
		end
		@(negedge rclk);
		pclk_l = 1'b1;
		@(posedge rclk);
		pclk_l = 1'b0;
	endtask

	task reset_bus (input logic value);
		for (int i = 0; i < DW; i++) begin
			data_l[i] = value;
		end
		vref_l = value;
		href_l = value;
		pclk_l = value;
	endtask

	task pclk_ref_clock_cycles(input int cycles, input bit active);
		for (int i = 0; i < cycles; i++) begin
			@(negedge rclk);
			if (active) begin
				pclk_l = 1'b1;
			end else begin
				pclk_l = 1'b0;
			end
			@(posedge rclk);
			pclk_l = 1'b0;
		end
	endtask

	task set_vref(input value );
		vref_l = value;
	endtask : set_vref

	task set_href(input value);
		href_l = value;
	endtask : set_href

	modport slave_mp(clocking slave_cb);

endinterface