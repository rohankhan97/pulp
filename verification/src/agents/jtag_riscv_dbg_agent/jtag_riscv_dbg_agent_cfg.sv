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

class jtag_riscv_dbg_agent_cfg extends uvm_object;
  virtual jtag_if mon_jtag_bfm; // Use to wait on JTAG bus signals e.g. waiting
                                // for a number of TCK cycles

  `uvm_object_utils(jtag_riscv_dbg_agent_cfg)
  `uvm_object_new

  task wait_tck(int cycles);
    mon_jtag_bfm.tck_en = 1;
    mon_jtag_bfm.wait_tck(cycles);
    mon_jtag_bfm.tck_en = 0;
  endtask

endclass
