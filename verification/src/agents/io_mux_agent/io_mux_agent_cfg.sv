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
class io_mux_agent_cfg extends uvm_object;
  int io_signal_name_idx_map [string];
  string io_signal_names[$];
  io_mux_driver_cfg dut_driver_cfg;
  io_mux_driver_cfg vip_driver_cfg;

  `uvm_object_utils_begin(io_mux_agent_cfg)
    `uvm_field_aa_int_string(io_signal_name_idx_map, UVM_DEFAULT)
    `uvm_field_queue_string(io_signal_names, UVM_DEFAULT)
  `uvm_object_utils_end

  function  new(string name="");
    super.new(name);
    dut_driver_cfg = io_mux_driver_cfg::type_id::create("dut_driver_cfg");
    vip_driver_cfg = io_mux_driver_cfg::type_id::create("vip_driver_cfg");
  endfunction

  // Add a new IO signal from an external verification IP to the IO multiplex
  // agent. use dut_signal_idx = -1 if you want to add an IO signal but leaving
  // it unconnected to the DUT for the moment.
  function void add_io_signal(string signal_name, int dut_signal_idx=-1);
    int  idx = io_signal_names.size();
    io_signal_names.push_back(signal_name);
    io_signal_name_idx_map[signal_name]      = idx;
    this.dut_driver_cfg.signal_mapping[idx] = dut_signal_idx;
    this.vip_driver_cfg.signal_mapping[dut_signal_idx] = idx;
  endfunction

  // Calling this function will connect the IO signal with the provided name to
  // the given DUT signal idx (e.g. pad nr). The previously connected IO signal
  // will be disconnected (pointing to signal_idx -1 wich is ignored by the driver).
  function void change_io_signal_connection(string signal_name, int dut_signal_idx);
    int  prev_io_idx;
    int  io_idx;
    if (!io_signal_name_idx_map.exists(signal_name))
      `uvm_fatal(`gfn, $sformatf("Tried to change connection of unknown signal '%s'.", signal_name))
    io_idx                                             = io_signal_name_idx_map[signal_name];
    if (vip_driver_cfg.signal_mapping.exists(dut_signal_idx)) begin
      prev_io_idx                                        = this.vip_driver_cfg.signal_mapping[dut_signal_idx];
      // Map the previous io signal to -1 so vip2dut traffic will be ignored.
      this.dut_driver_cfg.signal_mapping[prev_io_idx]    = -1;
    end
    this.dut_driver_cfg.signal_mapping[io_idx]         = dut_signal_idx;
    this.vip_driver_cfg.signal_mapping[dut_signal_idx] = io_idx;
  endfunction

  function void disconnect_dut_signal(int dut_signal_idx);
    int prev_io_idx;
    prev_io_idx                                = vip_driver_cfg.signal_mapping[dut_signal_idx];
    dut_driver_cfg.signal_mapping[prev_io_idx] = -1;
    vip_driver_cfg.signal_mapping[dut_signal_idx] = -1;
  endfunction

endclass
