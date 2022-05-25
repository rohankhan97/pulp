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


class siracusa_sw_spi_test extends pulp_sw_backdoor_boot_test;
  `uvm_component_utils(siracusa_sw_spi_test)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    configure_spi();
  endfunction

  function void configure_spi();

  endfunction


endclass
