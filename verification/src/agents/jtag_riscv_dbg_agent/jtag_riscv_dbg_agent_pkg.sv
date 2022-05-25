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

package jtag_riscv_dbg_agent_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;

  import jtag_chain_agent_pkg::*;
  import dmi_jtag_ral_pkg::*;
  import dm_ral_pkg::*;

  localparam logic[4:0] IDCODE_REG = 5'h01;
  localparam logic[4:0] DTM_REG = 5'h10;
  localparam logic [4:0] DMI_REG = 5'h11;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  `define check_status(status, error_msg) \
  begin \
    if (status != UVM_IS_OK) \
      `uvm_error(`gfn, error_msg) \
  end

  `define check_status_fatal(status, error_msg) \
  begin \
    if (status != UVM_IS_OK) \
      `uvm_fatal(`gfn, error_msg) \
  end

  `include "jtag_riscv_dmi_access_item.sv"
  `include "reg2dmi_adapter.sv"
  `include "reg2jtag_adapter.sv"
  `include "jtag_riscv_dbg_agent_cfg.sv"
  `include "dmi_access_translation_seq.sv"
  `include "dm_seq_lib.sv"
  `include "dmi_seq_lib.sv"
  `include "reg2dm_translation_seq.sv"
  `include "jtag_riscv_dbg_agent.sv"
endpackage
