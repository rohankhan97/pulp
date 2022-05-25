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

interface boot_dbg_if (
  inout boot_mode0,
  inout boot_mode1,
  inout debug_en,
  inout clk_byp_en
);
  import siracusa_env_pkg::bootmode_e;

  bit   drive_boot_mode = 1;
  logic o_boot_mode0 = 1, o_boot_mode1 = 0;

  bit   drive_debug_en = 1;
  logic o_debug_en = 0;

  bit   drive_clk_byp_en = 1;
  logic o_clk_byp_en = 0;

  task automatic set_boot_mode(bootmode_e mode);
    drive_boot_mode = 1;
    o_boot_mode0 = mode[0];
    o_boot_mode1 = mode[1];
  endtask

  task automatic set_debug_en(bit en);
    drive_debug_en = 1;
    o_debug_en = en;
  endtask

  task automatic set_clk_byp_en(bit en);
    drive_clk_byp_en = 1;
    o_clk_byp_en = en;
  endtask

  assign boot_mode0 = (drive_boot_mode)? o_boot_mode0 : 1'bz;
  assign boot_mode1 = (drive_boot_mode)? o_boot_mode1 : 1'bz;

  assign debug_en = (drive_debug_en)? o_debug_en : 1'bz;

  assign clk_byp_en = (drive_clk_byp_en)? o_clk_byp_en : 1'bz;
endinterface
