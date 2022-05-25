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

class tcdm_req_seq_item extends uvm_sequence_item;
  rand logic[31:0] addr;
  rand logic [31:0] write_data;
  rand logic [3:0]  be; //Byte enable
  rand bit is_write;

  `uvm_object_utils_begin(tcdm_req_seq_item)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(write_data, UVM_DEFAULT)
    `uvm_field_int(be, UVM_DEFAULT)
    `uvm_field_int(is_write , UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

endclass

class tcdm_rsp_seq_item extends uvm_sequence_item;
  rand logic [31:0] read_data;
  rand logic          r_opc;
  rand int unsigned gnt_delay;
  rand int unsigned r_valid_delay;

  `uvm_object_utils_begin(tcdm_rsp_seq_item)
    `uvm_field_int(read_data, UVM_DEFAULT)
    `uvm_field_int(r_opc, UVM_DEFAULT)
    `uvm_field_int(r_valid_delay, UVM_DEFAULT)
    `uvm_field_int(gnt_delay, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

endclass

class tcdm_transaction extends uvm_sequence_item;
  tcdm_req_seq_item req;
  tcdm_rsp_seq_item rsp;

  `uvm_object_utils_begin(tcdm_transaction)
    `uvm_field_object(req, UVM_DEFAULT)
    `uvm_field_object(rsp, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

endclass
