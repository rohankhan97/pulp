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

package vstdout_monitor_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;

  import tcdm_agent_pkg::tcdm_transaction;

`include "uvm_macros.svh"
`include "dv_macros.svh"

`include "vstdout_seq_item.sv"
`include "vstdout_monitor_cfg.sv"
`include "vstdout_monitor.sv"

endpackage : vstdout_monitor_pkg