//-----------------------------------------------------------------------------
// Title         : JTAG Boot Virtual Sequence
//-----------------------------------------------------------------------------
// File          : v_seq_siracusa_jtag_boot.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 06.09.2021
//-----------------------------------------------------------------------------
// Description :
// This sequence boots Siracusa using JTAG.
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
`include "dv_macros.svh"

class v_seq_siracusa_hard_reset extends siracusa_vseq_base;
  `uvm_object_utils(v_seq_siracusa_hard_reset)
  virtual clk_rst_if clk_rst_vif;

  function new(string name="v_seq_siracusa_hard_reset");
    super.new(name);
  endfunction

  virtual task do_body ();
    // Create subsequences
    jtag_riscv_dbg_agent_pkg::dm_reset_seq dm_reset_seq;
    jtag_riscv_dbg_agent_pkg::dmi_reset_seq dmi_reset_seq;
    if (!uvm_config_db#(virtual clk_rst_if)::get(m_sequencer.get_parent(), "", "clk_rst_vif", clk_rst_vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to clk_rst bfm.")

    `uvm_info(`gfn, "Starting RISC-V DBG Module Reset Sequence...", UVM_MEDIUM)
    `uvm_info(`gfn, "Waiting for 25 ref clock cycles...", UVM_MEDIUM)
    clk_rst_vif.wait_clks(25);
    // send subsequence
    `uvm_info(`gfn, "Resetting DM Interface...", UVM_MEDIUM)
    dmi_reset_seq = jtag_riscv_dbg_agent_pkg::dmi_reset_seq::type_id::create("dmi_reset");
    dmi_reset_seq.start(jtag_chain_sqr);
    `uvm_info(`gfn, "Resetting DM", UVM_MEDIUM)
    dm_reset_seq = jtag_riscv_dbg_agent_pkg::dm_reset_seq::type_id::create("dm_reset");
    dm_reset_seq.start(jtag_dmi_access_sqr);
    `uvm_info(`gfn, "Finsihed hard reset sequence.", UVM_MEDIUM)
  endtask
endclass
