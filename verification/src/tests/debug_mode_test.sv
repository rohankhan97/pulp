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

class debug_mode_test extends pulp_sw_backdoor_boot_test;
  `uvm_component_utils(debug_mode_test)
  `uvm_component_new

  virtual task pre_reset_phase(uvm_phase phase);
    `uvm_info(`gfn, "Enabling debug mode, bypassing plls and reset the system....", UVM_MEDIUM)
    phase.raise_objection(this);

    env.boot_dbg_vif.set_clk_byp_en(1);
    env.boot_dbg_vif.set_debug_en(1);
    //Set debug signals via gpio interface
    env.gpios_vif.drive_pin(14, 0); // soc clk bypass
    env.gpios_vif.drive_pin(16, 0); // per clk bypass
    env.gpios_vif.drive_pin(18, 0); // cluster clk bypass
    // mram debug input signals
    env.gpios_vif.drive_pin(9, 0);  // tm2
    env.gpios_vif.drive_pin(10, 0); // tm1
    env.gpios_vif.drive_pin(11, 0); // tm0
    env.gpios_vif.drive_pin(3, 0); //mdc
    env.gpios_vif.drive_pin(4, 0); //mdin
    env.gpios_vif.drive_pin(6, 0); // se
    env.gpios_vif.drive_pin(7, 0); // si
    env.gpios_vif.drive_pin(0, 0); // bist run

    env.clk_rst_vif.set_freq_mhz(100); // apply a 100MHz external clock
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

  virtual function void configure_io_mux_mirror();
    // Dummy function. We don't want the IO mux mirror to be configured for this test.
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Override default connection in IO mux. Only the gpios shall be connected
    for (int i = 0; i < DUT_SIGNAL_COUNT; i++) begin
      cfg.io_mux_agent_cfg.change_io_signal_connection($sformatf("GPIO%02d", i), i);
    end
  endfunction

endclass
