package pulp_agents_pkg;
	import uvm_pkg::*;

	// Macros include
	`include "uvm_macros.svh"
	`include "dv_macros.svh"

	parameter DATA_WIDTH = 10;
	parameter LINE_PIXELS = 166;
	parameter FRAME_LINES = 128;
	parameter LAT_CYCLE_LIMIT = 64;
	parameter TRANSACTIONS = 4;

	// CPI Package sources
	`include "cpi/cpi_frame_item.sv"
	`include "cpi/cpi_seq_lib.sv"
	`include "cpi/cpi_driver.sv"
	`include "cpi/cpi_monitor.sv"
	`include "cpi/cpi_sequencer.sv"
	`include "cpi/cpi_agent_cfg.sv"
	`include "cpi/cpi_agent.sv"


endpackage : pulp_agents_pkg