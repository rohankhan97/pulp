//-----------------------------------------------------------------------------
// Copyright (C) 2021 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// SPDX-License-Identifier: SHL-0.51
//-----------------------------------------------------------------------------

class io_mux_agent #(
  parameter int unsigned NUM_IO_SIGNALS,
  parameter int unsigned NUM_DUT_SIGNALS
) extends uvm_agent;
  io_mux_agent_cfg cfg;

  io_mux_monitor#(NUM_IO_SIGNALS) vip_monitor;
  io_mux_driver#(NUM_IO_SIGNALS)  vip_driver;
  io_mux_monitor#(NUM_DUT_SIGNALS) dut_monitor;
  io_mux_driver#(NUM_DUT_SIGNALS)  dut_driver;
  io_mux_sequencer vip2dut_sequencer;
  io_mux_sequencer dut2vip_sequencer;

  `uvm_component_param_utils_begin(io_mux_agent#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(io_mux_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn, "Failed to obtain cfg from uvm_config_db");
    // set configuration objects for subcomponents.
    uvm_config_db#(io_mux_driver_cfg)::set(this, "vip_driver", "cfg", cfg.vip_driver_cfg);
    uvm_config_db#(io_mux_driver_cfg)::set(this, "dut_driver", "cfg", cfg.dut_driver_cfg);

    // Create components
    vip_monitor       = io_mux_monitor#(.NUM_SIGNALS(NUM_IO_SIGNALS))::type_id::create("vip_monitor", this);
    vip_driver        = io_mux_driver#(.NUM_SIGNALS(NUM_IO_SIGNALS))::type_id::create("vip_driver", this);
    dut_monitor       = io_mux_monitor#(.NUM_SIGNALS(NUM_DUT_SIGNALS))::type_id::create("dut_monitor", this);
    dut_driver        = io_mux_driver#(.NUM_SIGNALS(NUM_DUT_SIGNALS))::type_id::create("dut_driver", this);
    vip2dut_sequencer = io_mux_sequencer::type_id::create("vip2dut_sqr", this);
    dut2vip_sequencer = io_mux_sequencer::type_id::create("dut2vip_sqr", this);

  endfunction

  function void connect_phase(uvm_phase phase);
    // Attach handle to sequencers to the monitors so they can issue new
    // transactions
    vip_monitor.driving_sqr = vip2dut_sequencer;
    dut_monitor.driving_sqr = dut2vip_sequencer;

    // Connect the other components
    dut_driver.seq_item_port.connect(vip2dut_sequencer.seq_item_export);
    vip_driver.seq_item_port.connect(dut2vip_sequencer.seq_item_export);
  endfunction

endclass
