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

class jtag_chain_agent_cfg extends uvm_object;
  jtag_tap chain[$];
  jtag_tap tap_name_tap_map[string];

  jtag_agent_pkg::jtag_agent_cfg jtag_agent_cfg;

  `uvm_object_utils_begin(jtag_chain_agent_cfg)
    `uvm_field_aa_object_string(tap_name_tap_map, UVM_DEFAULT)
    `uvm_field_queue_object(chain, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "");
    super.new(name);
    jtag_agent_cfg = jtag_agent_pkg::jtag_agent_cfg::type_id::create("jtag_agent_cfg");
  endfunction

  /// Adds a new jtag tap configuration to the JTAG chain. You should add jtag
  /// taps in the order they are attached to the JTAG chain, i.e. the TAP that is
  /// first connected to the TDI signal shall be added first and the TAP driving
  /// the final TDO signal should be added last.
  function void add_jtag_tap(jtag_tap tap);
    if (tap_name_tap_map.exists(tap.tap_name))
      `uvm_fatal(`gfn, $sformatf("A tap with the name %s, already exists in the current chain configuration. You must use unique TAP names.", tap.tap_name))
    chain.push_back(tap);
    tap_name_tap_map[tap.tap_name] = tap;
  endfunction

  task wait_tck(int cycles);
    jtag_agent_cfg.vif.tck_en = 1;
    jtag_agent_cfg.vif.wait_tck(cycles);
    jtag_agent_cfg.vif.tck_en = 0;
  endtask

endclass
