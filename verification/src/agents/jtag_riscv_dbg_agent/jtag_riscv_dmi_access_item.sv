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

class jtag_riscv_dmi_access_item extends uvm_sequence_item;
  rand bit is_write;
  rand logic [31:0] address;
  rand logic [31:0] data;
  bit               retry; /// Whether or not the transaction should be retried
                           //if the dmi is still busy
  // Respone
  logic [31:0]      rsp_data;
  bit               error;
  bit               pending;

  `uvm_object_utils_begin(jtag_riscv_dmi_access_item)
    `uvm_field_int(address, UVM_DEFAULT)
    `uvm_field_int(data, UVM_DEFAULT)
    `uvm_field_int(retry, UVM_DEFAULT)
    `uvm_field_int(rsp_data, UVM_DEFAULT)
    `uvm_field_int(error, UVM_DEFAULT)
    `uvm_field_int(pending, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
endclass
