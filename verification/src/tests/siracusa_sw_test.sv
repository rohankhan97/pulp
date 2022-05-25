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


class siracusa_sw_test
  extends pulp_sw_base_test#(.NUM_IO_SIGNALS(IO_SIGNAL_COUNT), .NUM_DUT_SIGNALS(DUT_SIGNAL_COUNT));

  `uvm_component_utils(siracusa_sw_test)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    cfg                   = new("cfg", NCPI, NI2C, NUART);
    cfg.cpi_agent_number  = NCPI;
    cfg.i2c_agent_number  = NI2C;
    cfg.uart_agent_number = NUART;
    if (!uvm_config_db#(virtual jtag_if)::get(this, "env.jtag_chain_agent.jtag_agent", "vif", cfg.riscv_dbg_cfg.mon_jtag_bfm))
        `uvm_fatal(`gfn, "Failed to get jtag_if VIF handle from jtag_chain agent.")
    `uvm_info(`gfn, $sformatf("Env config:\n%s", cfg.sprint()), UVM_HIGH)
    // Add io signals
`define map_io_signal(name, gpio_idx) cfg.io_mux_agent_cfg.add_io_signal(name, gpio_idx);
    for (int i = 0; i < NCPI; i++) begin
      `map_io_signal($sformatf("cpi%0d.vref", i), 4);
      `map_io_signal($sformatf("cpi%0d.href", i), 5);
      `map_io_signal($sformatf("cpi%0d.pclk", i), 6);
      for (int j = 0; j < 10; j++) begin
        `map_io_signal($sformatf("cpi%0d.data%0d", i, j), 13+j);
      end
    end
    uvm_config_db#(siracusa_env_cfg#(IO_SIGNAL_COUNT, DUT_SIGNAL_COUNT))::set(this, "env", "cfg", cfg);
    super.build_phase(phase);
  endfunction

endclass
