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

package jtag_chain_agent_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;

  import jtag_agent_pkg::*;

`include "uvm_macros.svh"
`include "dv_macros.svh"

  localparam int unsigned JTAG_MAX_IR_WIDTH = jtag_agent_pkg::JTAG_IRW;
  localparam int unsigned JTAG_MAX_DR_WIDTH = jtag_agent_pkg::JTAG_DRW;


  class jtag_tap extends uvm_object;
    string                tap_name;
    int                   ir_length;
    int                   id_code;

    `uvm_object_utils_begin(jtag_tap)
      `uvm_field_string(tap_name, UVM_DEFAULT)
      `uvm_field_int(ir_length, UVM_DEFAULT)
      `uvm_field_int(id_code, UVM_DEFAULT)
    `uvm_object_utils_end
    `uvm_object_new
  endclass

`include "jtag_chain_item.sv"
 typedef uvm_sequencer#(jtag_chain_item) jtag_chain_sequencer;
`include "jtag_chain_agent_cfg.sv"
`include "jtag_chain_translation_seq.sv"
`include "jtag_chain_agent.sv"

endpackage
