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

package siracusa_spi_env_pkg;
  import uvm_pkg::*;
  import dv_lib_pkg::*;

  import mvc_pkg::*;
  import mgc_spi_v1_0_pkg::*;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  `include "siracusa_spi_env_cfg.sv"
  `include "siracusa_spi_env.sv"

endpackage : siracusa_spi_env_pkg
