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

class jtag_chain_item extends uvm_sequence_item;
  string                             tap_name;
  rand bit                           force_select_ir; ///< Forces the jtag_chain driver to scan update
                                     ///< the IR register. By default, the
                                     ///< driver only thus this if it isn't already
                                     ///< selected.
  rand logic [JTAG_MAX_IR_WIDTH-1:0] ir;
  rand logic [JTAG_MAX_DR_WIDTH-1:0] dr;
  rand int unsigned                  dr_len;
  rand logic [JTAG_MAX_DR_WIDTH-1:0] dout;

  `uvm_object_utils_begin(jtag_chain_item)
    `uvm_field_string(tap_name, UVM_DEFAULT)
    `uvm_field_int(force_select_ir, UVM_DEFAULT)
    `uvm_field_int(ir, UVM_DEFAULT)
    `uvm_field_int(dr, UVM_DEFAULT)
    `uvm_field_int(dr_len, UVM_DEFAULT)
    `uvm_field_int(dout, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
endclass
