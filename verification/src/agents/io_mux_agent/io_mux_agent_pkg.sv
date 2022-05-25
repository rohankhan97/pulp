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

package io_mux_agent_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;

`include "uvm_macros.svh"
`include "dv_macros.svh"

  // package sources

`include "io_mux_seq_item.sv"
`include "io_mux_activity_item.sv"
`include "io_mux_sequencer.sv"
`include "io_mux_seq_lib.sv"
`include "io_mux_driver_cfg.sv"
`include "io_mux_driver.sv"
`include "io_mux_monitor.sv"
`include "io_mux_agent_cfg.sv"
`include "io_mux_agent.sv"

endpackage
