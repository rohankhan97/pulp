//-----------------------------------------------------------------------------
// Title         : Siracusa UVM Environmentb
//-----------------------------------------------------------------------------
// File          : siracusa_env.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 06.09.2021
//-----------------------------------------------------------------------------
// Description :
// UVM Environment for the Siracus Chip
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

class siracusa_env #(
  parameter int unsigned NUM_IO_SIGNALS=0,
  parameter int unsigned NUM_DUT_SIGNALS=0
) extends uvm_env;


  // BFM handles
  virtual                clk_rst_if clk_rst_vif;
  virtual                clk_rst_if cpi_clk_rst_vif;
  virtual                boot_dbg_if boot_dbg_vif;
  virtual                pins_if#(NUM_DUT_SIGNALS) gpios_vif;
  // env configuration object
  siracusa_env_cfg#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS) cfg;
  // Memory Model
  siracusa_top_block regmodel;
  // env agents
  jtag_chain_agent jtag_chain_a;
  jtag_riscv_dbg_agent riscv_dbg_a;
  io_mux_agent#(.NUM_IO_SIGNALS(NUM_IO_SIGNALS), .NUM_DUT_SIGNALS(NUM_DUT_SIGNALS)) io_mux_a;
  io_mux_mirror#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS) m_io_mux_mirror;
  vstdout_monitor vstdout_mon;
  // env parametric agents
  cpi_agent#(.DW(10)) cpi_a[];
  i2c_agent i2c_a[];
  uart_agent uart_a[];
  // Sub-environments
  siracusa_spi_env spi_env;

  // TCDM master agent on FC data port
  tcdm_master_agent fc_data_port_a;
  siracusa_vsequencer v_sqr;

  `uvm_component_param_utils_begin(siracusa_env#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))
    `uvm_field_object(cfg, UVM_DEFAULT)
    `uvm_field_object(jtag_chain_a,UVM_DEFAULT)
    `uvm_field_object(riscv_dbg_a,UVM_DEFAULT)
    `uvm_field_array_object(cpi_a, UVM_DEFAULT)
    `uvm_field_array_object(i2c_a, UVM_DEFAULT)
    `uvm_field_array_object(uart_a, UVM_DEFAULT)
    `uvm_field_object(spi_env, UVM_DEFAULT)
  `uvm_component_utils_end

  uvm_factory factory;
  uvm_coreservice_t cs = uvm_coreservice_t::get();

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //`uvm_component_new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get the env config
    if (cfg == null && !uvm_config_db#(siracusa_env_cfg#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NULL", {"reference must be set for: ", get_full_name(), ".cfg"});
    end

    if (!uvm_config_db#(virtual clk_rst_if)::get(this, "", "clk_rst_vif", clk_rst_vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to clk_rst_vif.")

    if (!uvm_config_db#(virtual clk_rst_if)::get(this, "", "cpi_clk_rst_vif", cpi_clk_rst_vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to cpi_clk_rst_vif.")

    if (!uvm_config_db#(virtual boot_dbg_if)::get(this, "", "boot_dbg_vif", boot_dbg_vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to boot_dbg_vif")

    if (!uvm_config_db#(virtual pins_if#(NUM_DUT_SIGNALS))::get(this, "", "gpios_vif", gpios_vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to gpios_vif")

    //create agents, create agent configs and add them to config_db
    // JTAG Chain Agent
    uvm_config_db#(jtag_chain_agent_cfg)::set(this, "jtag_chain_agent", "cfg", cfg.jtag_chain_cfg);
    jtag_chain_a = jtag_chain_agent::type_id::create("jtag_chain_agent", this);

    // RISC-V debug module Agent
    uvm_config_db#(jtag_riscv_dbg_agent_cfg)::set(this, cfg.riscv_dbg_tap.tap_name, "cfg", cfg.riscv_dbg_cfg);
    riscv_dbg_a = jtag_riscv_dbg_agent::type_id::create(cfg.riscv_dbg_tap.tap_name, this); // We need to use the name declared as the tap name so the jtag chain agent knows with which TAP we want to communicate
    riscv_dbg_a.chain_agent = jtag_chain_a;

    // IO Multiplexer Agent and IO Mux config mirror
    uvm_config_db#(io_mux_agent_cfg)::set(this, "io_mux_a", "cfg", cfg.io_mux_agent_cfg); // Use uvm_object type so UVM auto-config works
    io_mux_a        = io_mux_agent#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS)::type_id::create("io_mux_a", this);
    uvm_config_db#(io_mux_mirror_cfg)::set(this, "m_io_mux_mirror", "cfg", cfg.io_mux_mirror_cfg);
    m_io_mux_mirror = io_mux_mirror#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS)::type_id::create("m_io_mux_mirror", this);
    m_io_mux_mirror.io_mux_a = io_mux_a;

    // CPI Agents
    cpi_a           = new[cfg.cpi_agent_number];
    for (int i = 0; i < cfg.cpi_agent_number; i++) begin
      uvm_config_db#(cpi_agent_cfg)::set(this, $sformatf("cpi_agent%0d",i), "cfg", cfg.cpi_agent_cfg[i]);
      cpi_a[i] = cpi_agent#(.DW(10))::type_id::create($sformatf("cpi_agent%0d",i), this);
    end

    // I2C Agents
    i2c_a = new[cfg.i2c_agent_number];
    for (int i = 0; i < cfg.i2c_agent_number; i++) begin
      uvm_config_db#(i2c_agent_cfg)::set(this, $sformatf("i2c_agent%0d",i), "cfg", cfg.i2c_agent_cfg[i]);
      i2c_a[i] = i2c_agent::type_id::create($sformatf("i2c_agent%0d",i), this);
    end

    // UART Agents
    uart_a = new[cfg.uart_agent_number];
    for (int i = 0; i < cfg.uart_agent_number; i++) begin
      uvm_config_db#(uart_agent_cfg)::set(this, $sformatf("uart_agent%0d",i), "cfg", cfg.uart_agent_cfg[i]);
      uart_a[i] = uart_agent::type_id::create($sformatf("uart_agent%0d",i), this);
    end

    // SPI Environment
    uvm_config_db#(siracusa_spi_env_cfg)::set(this, "spi_env", "cfg", cfg.spi_env_cfg);
    spi_env = siracusa_spi_env::type_id::create("spi_env", this);

    // Virtual Stdout Monitor
    uvm_config_db#(vstdout_monitor_cfg)::set(this, "vstdout_mon", "cfg", cfg.vstdout_mon_cfg);
    vstdout_mon = vstdout_monitor::type_id::create("vstdout_mon", this);

    // Internal bus agents
    uvm_config_db#(tcdm_master_agent_cfg)::set(this, "fc_data_port_a", "cfg", cfg.fc_data_port_agent_cfg);
    fc_data_port_a = tcdm_master_agent::type_id::create("fc_data_port_a", this);

    // Create the virtual sequencer
    v_sqr          = siracusa_vsequencer::type_id::create("v_sqr", this);

    // Create the register model
    if (regmodel == null) begin
      regmodel                      = siracusa_top_block::type_id::create("regmodel", this);
      regmodel.build();
      regmodel.lock_model();
      // Register interleaved memory backdoors
      register_backdoors(regmodel);
      // Register the model with the config db
      uvm_config_db#(siracusa_top_block)::set(this, "", "regmodel", regmodel);
    end
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    v_sqr.jtag_dmi_access_sqr = riscv_dbg_a.dmi_access_sequencer;
    v_sqr.jtag_chain_sqr      = riscv_dbg_a.chain_agent.sequencer;

    // Connect reg model to riscv debug agent's dm tranlation sequencer (we
    // don't use a regadapter here but a translation sequence that runs within
    // the jtag_riscv_dbg agent)
    if (regmodel.get_parent() == null && cfg.attach_default_ral_adapter) begin
      regmodel.top_map.set_sequencer(riscv_dbg_a.system_bus_access_sequencer, null); // Don't suply an adpater. We translate with a translation sequencer directly on the reg_items
    end

    // connect the virtual stdout monitor to the tcdm_agents analysis port
    fc_data_port_a.monitor.m_bus_port.connect(vstdout_mon.analysis_export);
    fc_data_port_a.monitor.m_bus_port.connect(m_io_mux_mirror.analysis_export);
  endfunction : connect_phase

  // Register custom memory backdoors with support for await for change and
  // interleaved memories
  function void register_backdoors(ref siracusa_top_block regmodel);
    active_monitor_backdoor default_backdoor;
    interleaved_mem_backdoor#(.LOG2_NUM_MEMORIES(4)) l1_backdoor;
    interleaved_mem_backdoor#(.LOG2_NUM_MEMORIES(2)) l2_backdoor;
    uvm_hdl_path_slice slice;
    default_backdoor = active_monitor_backdoor::type_id::create("default_backdoor");
    l2_backdoor = interleaved_mem_backdoor#(2)::type_id::create("l2_backdoor");
    l1_backdoor = interleaved_mem_backdoor#(4)::type_id::create("l1_backdoor");

    slice.offset = -1;
    slice.size   = -1;
    // L2 backdoor
    for (int i = 0; i < 4; i++) begin
      slice.path = $sformatf("CUTS[%0d].bank_i.sram", i);
      l2_backdoor.add_bank_path_segment(slice);
      l2_backdoor.lsb_idx = 0;
    end
    regmodel.soc.l2_ram.set_backdoor(l2_backdoor);

    // L1 backdoor
    for (int i = 0; i < 16; i++) begin
      slice.path = $sformatf("banks_gen[%0d].i_bank.sram", i);
      l1_backdoor.add_bank_path_segment(slice);
      l1_backdoor.lsb_idx = 0;
    end
    regmodel.cluster.l1_ram.set_backdoor(l1_backdoor);
    regmodel.set_backdoor(default_backdoor);
  endfunction

endclass
