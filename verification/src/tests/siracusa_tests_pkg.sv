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

package siracusa_tests_pkg;
  import uvm_pkg::*;
  import siracusa_env_pkg::*;
  import jtag_riscv_dbg_agent_pkg::*;
  import i2c_agent_pkg::*;
  import uart_agent_pkg::*;
  import pulp_agents_pkg::*;
  import qvip_env_pkg::*;
  import siracusa_i3c_env_pkg::*;
  import siracusa_i3c_sequence_pkg::*;
  import tcdm_agent_pkg::*;
  // Import Siemens QVIP packages
  import mvc_pkg::*;
  import mgc_i3c_pkg::*;
  import mgc_i3c_sdr_seq_pkg::*;
  import mgc_i3c_hdr_seq_pkg::*;
  import mgc_i3c_legacy_i2c_seq_pkg::*;
  import mgc_spi_v1_0_pkg::*;

  typedef virtual        mgc_spi    #(1) spi_if_t;


  // Macros include
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  // Package sources
  `include "pulp_sw_base_test.sv"
  `include "siracusa_sw_test.sv"
  `include "pulp_sw_jtag_boot_test.sv"
  `include "pulp_sw_backdoor_boot_test.sv"
  `include "siracusa_sw_sanity_i3c_test.sv"
  `include "siracusa_sw_cpi_test.sv"
  `include "uart_test/siracusa_uart_test.sv"
  `include "memory_access_test/memory_access_test.sv"
  `include "debug_mode_test.sv"
endpackage
