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

class io_mux_seq_item extends uvm_sequence_item;
  rand int signal_idx; // Index of the signal on which the drive transaction occured
  rand logic value; // Logic value of the signal
  rand bit   tx_en; // Drive the signal onto the pin
  rand bit   pu_en; // Enable pull-up on the pin
  rand bit   pd_en; // Enable pull-down on the pin

  `uvm_object_utils_begin(io_mux_seq_item)
    `uvm_field_int(signal_idx, UVM_DEFAULT)
    `uvm_field_int(value, UVM_DEFAULT)
    `uvm_field_int(tx_en, UVM_DEFAULT)
    `uvm_field_int(pu_en, UVM_DEFAULT)
    `uvm_field_int(pd_en, UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new
endclass
