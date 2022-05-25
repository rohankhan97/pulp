//-----------------------------------------------------------------------------
// Title         : Virtual Base Sequence for Siracusa
//-----------------------------------------------------------------------------
// File          : siracusa_vseq_base.sv
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
`include "dv_macros.svh"

class siracusa_vseq_base extends uvm_sequence;
  `uvm_object_utils(siracusa_vseq_base)
  `uvm_declare_p_sequencer(siracusa_vsequencer);

  function new(string name="vseq_base");
    super.new(name);
  endfunction : new

  uvm_sequencer#(jtag_riscv_dmi_access_item) jtag_dmi_access_sqr;
  uvm_sequencer#(jtag_chain_item) jtag_chain_sqr;
  siracusa_top_block regmodel;

  virtual task body();
    jtag_dmi_access_sqr = p_sequencer.jtag_dmi_access_sqr;
    jtag_chain_sqr      = p_sequencer.jtag_chain_sqr;
    if (!uvm_config_db#(siracusa_top_block)::get(m_sequencer.get_parent(), "", "regmodel", regmodel))
      `uvm_fatal(`gfn, "Failed to obtain register model. From enivronment")
    // Call the actual body task that derived classes should override
    do_body();
  endtask

  virtual task do_body();
    `uvm_fatal(`gfn, "Derived classes should implement the do_body task instead of using the body() task directly.");
  endtask
endclass
