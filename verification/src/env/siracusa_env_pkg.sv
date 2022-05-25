//-----------------------------------------------------------------------------
// Title         : Siracusa Environment package
//-----------------------------------------------------------------------------
// File          : siracusa_env_pkg.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 07.09.2021
//-----------------------------------------------------------------------------
// Description :
// Includes all environment modules
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

`define MAX_WEIGHT

package siracusa_env_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;
  import jtag_chain_agent_pkg::*;
  import jtag_riscv_dbg_agent_pkg::*;
  import i2c_agent_pkg::*;
  import uart_agent_pkg::*;
  import pulp_agents_pkg::*;
  import io_mux_agent_pkg::*;
  import qvip_env_pkg::*;
  import siracusa_ral_pkg::*;
  import tcdm_agent_pkg::*;
  import active_monitor_pkg::*;
  import vstdout_monitor_pkg::*;
  import siracusa_spi_env_pkg::*;

  // Macros include
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  typedef enum logic[1:0] {SPI_FLASH=2'd0, JTAG=2'd1, HYPERFLASH=2'd2, MRAM=2'd3} bootmode_e;
  localparam NCPI = 1;
  localparam NI2C = 2;
  localparam NI3C = 2;
  localparam NUART = 1;
  localparam NSPIM = 1;
  localparam NSPIS = 1;

  // TODO Alfio why do wee need these here?
  localparam NI3CM = 1;
  localparam NI3CS = 1;

  localparam DUT_SIGNAL_COUNT = 43;
  localparam IO_SIGNAL_COUNT = NI2C*2 + NI3C*3 + NUART*2 + NSPIM*9 + NSPIS*6 + DUT_SIGNAL_COUNT; //+DUT_SIGNAL_COUNT for each GPIO signal

  localparam FRAME_LINES = 128;
  localparam LINE_PIXELS = 166;


  // Package sources
  `include "io_mux_mirror.sv"
  `include "siracusa_env_cfg.sv"
  `include "siracusa_vsequencer.sv"
  `include "interleaved_mem_back_door.sv"
  `include "siracusa_env.sv"
  `include "seq_lib/vseq_list.sv"

endpackage
