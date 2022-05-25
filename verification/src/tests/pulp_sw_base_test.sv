//-----------------------------------------------------------------------------
// Title         : Base UVM test for SW based tests on Siracusa
//-----------------------------------------------------------------------------
// File          : base_sw_test.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 06.09.2021
//-----------------------------------------------------------------------------
// Description :
//
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

`include "uvm_macros.svh"

class pulp_sw_base_test #(
  parameter int unsigned NUM_IO_SIGNALS=-1,
  parameter int unsigned NUM_DUT_SIGNALS=-1
) extends uvm_test;

  siracusa_env#(.NUM_IO_SIGNALS(NUM_IO_SIGNALS), .NUM_DUT_SIGNALS(NUM_DUT_SIGNALS)) env;
  siracusa_env_cfg#(.NUM_IO_SIGNALS(NUM_IO_SIGNALS), .NUM_DUT_SIGNALS(NUM_DUT_SIGNALS)) cfg;
  siracusa_vseq_base seq;

  `uvm_component_param_utils(pulp_sw_base_test#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))

  uvm_factory factory;
  uvm_coreservice_t cs = uvm_coreservice_t::get();

  function new(string name = "pulp_sw_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  virtual function string get_test_shortname();
    return "Generic Software Test";
  endfunction

  // Helper macro to reduce verbosity of IO mux configuration
`define map_io_signal(name, gpio_idx) cfg.io_mux_agent_cfg.add_io_signal(name, gpio_idx);

  virtual function void configure_io_mux();
    // Add all GPIOs to pads
    for (int i = 0; i < 43; i++) begin
      `map_io_signal($sformatf("GPIO%02d", i), i);
    end
    // Add all peripheral signals but leave them unconnected for now
    for (int i = 0; i < NI2C; i++) begin
      `map_io_signal($sformatf("i2c%0d_scl", i), -1);
      `map_io_signal($sformatf("i2c%0d_sda", i), -1);
    end
    for (int i = 0; i < NI3C; i++) begin
      `map_io_signal($sformatf("i3c%0d_scl", i), -1);
      `map_io_signal($sformatf("i3c%0d_sda", i), -1);
      `map_io_signal($sformatf("i3c%0d_puc", i), -1);
    end
    for (int i = 0; i < NUART; i++) begin
      `map_io_signal($sformatf("uart%0d_tx", i), -1);
      `map_io_signal($sformatf("uart%0d_rx", i), -1);
    end
    for (int i = 0; i < NSPIM; i++) begin
      `map_io_signal($sformatf("spim%0d_sck", i), -1);
      for (int j = 0; j < 4; j++) begin
        `map_io_signal($sformatf("spim%0d_csn%0d", i, j), -1);
      end
      for (int j = 0; j < 4; j++) begin
        `map_io_signal($sformatf("spim%0d_sdio%0d", i, j), -1);
      end
    end
    for (int i = 0; i < NSPIS; i++) begin
      `map_io_signal($sformatf("spis%0d_sck", i), -1);
      `map_io_signal($sformatf("spis%0d_csn", i), -1);
      for (int j = 0; j < 4; j++) begin
        `map_io_signal($sformatf("spis%0d_sdio%0d", i, j), -1);
      end
    end
  endfunction

  virtual function void configure_spi_env();
    spi_vip_config#(1) mstr_cfg = cfg.spi_env_cfg.spi_master_cfg;
    mstr_cfg.agent_cfg.is_active   = 1;
    mstr_cfg.agent_cfg.agent_type  = SPI_MSTR;
    mstr_cfg.agent_cfg.spi_mode    = SPI_MOTO;
    mstr_cfg.agent_cfg.ext_clock   = 1;
    mstr_cfg.m_bfm.config_LSBFE    = 1;
    mstr_cfg.m_bfm.config_CPOL     = 0;
    mstr_cfg.m_bfm.config_CPHA     = 0;

    // Slaves
    foreach(cfg.spi_env_cfg.spi_slave_cfg[i]) begin
      spi_vip_config#(1) slave_cfg     = cfg.spi_env_cfg.spi_slave_cfg[i];
      slave_cfg.agent_cfg.is_active    = 1;
      slave_cfg.agent_cfg.agent_type   = SPI_SLV;
      slave_cfg.agent_cfg.spi_mode     = SPI_MOTO;
      slave_cfg.agent_cfg.ext_clock    = 1;
      slave_cfg.m_bfm.config_LSBFE     = 1;
      slave_cfg.m_bfm.config_CPOL      = 0;
      slave_cfg.m_bfm.config_CPHA      = 0;
    end

  endfunction

  // This function configure the IO mux mirror to sniff for configuration
  // attempts to the IO select registers in Siracusa.
  virtual function void configure_io_mux_mirror();
    io_mux_mirror_cfg mirror_cfg = cfg.io_mux_mirror_cfg;
    uvm_reg_addr_t start_addr                                      = 32'h1a14_0004; // Padctrl gpio0_sel addr
    // Register all padsel registers
    for (int gpio_idx = 0; gpio_idx < NUM_DUT_SIGNALS; gpio_idx++) begin
      string val_map[uvm_reg_data_t];
      mirror_cfg.cfg_addr_to_dut_signal_idx_map[start_addr + 8*gpio_idx] = gpio_idx;
      //Register all padsel enum values
      val_map[1]                                                         = $sformatf("GPIO%02d", gpio_idx);
      val_map[2]                                                         = "i2c0_scl";
      val_map[3]                                                         = "i2c0_sda";
      val_map[4]                                                         = "i3c0_puc";
      val_map[5]                                                         = "i3c0_scl";
      val_map[6]                                                         = "i3c0_sda";
      val_map[7]                                                         = "i3c1_puc";
      val_map[8]                                                         = "i3c1_scl";
      val_map[9]                                                         = "i3c1_sda";
      val_map[10]                                                        = "spim0_csn0";
      val_map[11]                                                        = "spim0_csn1";
      val_map[12]                                                        = "spim0_csn2";
      val_map[13]                                                        = "spim0_csn3";
      val_map[14]                                                        = "spim0_sck";
      val_map[15]                                                        = "spim0_sdio0";
      val_map[16]                                                        = "spim0_sdio1";
      val_map[17]                                                        = "spim0_sdio2";
      val_map[18]                                                        = "spim0_sdio3";
      val_map[19]                                                        = "spis0_csn";
      val_map[20]                                                        = "spis0_sck";
      val_map[21]                                                        = "spis0_sdio0";
      val_map[22]                                                        = "spis0_sdio1";
      val_map[23]                                                        = "spis0_sdio2";
      val_map[24]                                                        = "spis0_sdio3";
      val_map[25]                                                        = "uart0_rx";
      val_map[26]                                                        = "uart0_tx";
      mirror_cfg.cfg_value_to_io_signal_name_map[gpio_idx]               = val_map;
    end

  endfunction

  // Extract the bfm from the config DB and attach them to the spi_env config object
  virtual function void attach_qvip_bfms();
    if (!uvm_config_db#(spi_if_t)::get(this, "env", "spi_master_vif", cfg.spi_env_cfg.spi_master_cfg.m_bfm))
      `uvm_fatal(`gfn, "Failed to get handle for SPI master vif")
    for (int i = 0; i < 4; i++) begin
      if (!uvm_config_db#(spi_if_t)::get(this, "env", $sformatf("spi_slave%0d_vif", i), cfg.spi_env_cfg.spi_slave_cfg[i].m_bfm))
        `uvm_fatal(`gfn, $sformatf("Failed to get handle for SPI slave%0d vif", i))
    end
  endfunction

  virtual function void configure_env();
    cfg.fc_data_port_agent_cfg.is_active = UVM_PASSIVE;
    configure_io_mux();
    configure_io_mux_mirror();
    attach_qvip_bfms();
    configure_spi_env();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg                                  = siracusa_env_cfg#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS)::type_id::create("cfg");
    // Make the TCDM agent at the FC data port passive for normal software tests.
    configure_env();
    uvm_config_db#(siracusa_env_cfg#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))::set(this, "env", "cfg", cfg);
    env                            = siracusa_env#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS)::type_id::create("env", this);
    seq                            = siracusa_vseq_base::type_id::create("seq");
    factory                        = cs.get_factory();
  endfunction : build_phase


  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(`gfn, $sformatf("Starting %s", get_test_shortname()), UVM_MEDIUM)
    `uvm_info(`gfn, $sformatf("UVM Topology:\n%s", this.sprint()), UVM_HIGH)
  endfunction

  virtual task pre_reset_phase(uvm_phase phase);
    `uvm_info(`gfn, "Starting clocks and applyting hard resets.", UVM_MEDIUM)
    phase.raise_objection(this);
    env.clk_rst_vif.set_freq_khz(32);
    #100ns;
    `uvm_info(`gfn, "Starting the reference clock at 32kHz...", UVM_MEDIUM);
    `uvm_info(`gfn, "Applying hard reset for 10 refernce clock cycles", UVM_MEDIUM);
    fork
      env.clk_rst_vif.start_clk();
      env.clk_rst_vif.apply_reset(.rst_n_scheme(2), .reset_width_clks(10));
    join;
    // Alfio: delaying the CPI clock activation, as it is not yet controlled by the DUT
    // #2ms;
    // `uvm_info(`gfn, "Starting CPI clock at 10MHz and applying CPI reset", UVM_MEDIUM)
    // env.cpi_clk_rst_vif.set_freq_mhz(10);
    // env.cpi_clk_rst_vif.start_clk();
    // env.cpi_clk_rst_vif.apply_reset(.rst_n_scheme(2), .reset_width_clks(10));
    phase.drop_objection(this);
  endtask

  virtual task reset_phase(uvm_phase phase);
    v_seq_siracusa_hard_reset vseq = v_seq_siracusa_hard_reset::type_id::create("vseq_siracusa_reset");
    phase.raise_objection(this);
    `uvm_info(`gfn, "Resettting the system...", UVM_MEDIUM)
    vseq.start(env.v_sqr);
    `uvm_info(`gfn, "Reset Done", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask : reset_phase

  virtual task post_main_phase(uvm_phase phase);
    v_seq_siracusa_wait_eoc vseq = v_seq_siracusa_wait_eoc::type_id::create("v_seq_siracusa_wait_eoc");
    vseq.expected_exit_code = 0;
    phase.raise_objection(this);
    vseq.start(env.v_sqr);
    `uvm_info(`gfn, "Software execution finished.", UVM_MEDIUM);
    phase.drop_objection(this);
  endtask

endclass
