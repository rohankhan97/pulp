//-----------------------------------------------------------------------------
// Title         : Config Object for the Virtual Stdout Monitor
//-----------------------------------------------------------------------------
// File          : vstdout_monitor_cfg.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 08.10.2021
//-----------------------------------------------------------------------------
// Description :
//
// This class acts as the configuration object for the virtual stdout monitor.
// It allows customization of the stdout address block to monitor.
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

class vstdout_monitor_cfg extends uvm_object;
  string address_to_channel_name_map[logic[31:0]];
  `uvm_object_utils(vstdout_monitor_cfg)
  `uvm_object_new

  function void add_channel(string channel_name, logic[31:0] address);
    address_to_channel_name_map[address] = channel_name;
  endfunction
endclass
