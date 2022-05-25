//-----------------------------------------------------------------------------
// Title         : Virtual Sequencer for PULP
//-----------------------------------------------------------------------------
// File          : siracusa_vseqr.sv
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

class siracusa_vsequencer extends uvm_sequencer;
  `uvm_component_utils(siracusa_vsequencer)

  uvm_sequencer#(jtag_riscv_dmi_access_item) jtag_dmi_access_sqr;
  uvm_sequencer#(jtag_chain_item) jtag_chain_sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
endclass
