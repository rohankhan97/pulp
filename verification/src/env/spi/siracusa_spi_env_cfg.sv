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

class siracusa_spi_env_cfg extends uvm_object;
  spi_vip_config#(1) spi_slave_cfg[4];
  spi_vip_config#(1) spi_master_cfg;

  `uvm_object_utils_begin(siracusa_spi_env_cfg)
    `uvm_field_sarray_object(spi_slave_cfg, UVM_DEFAULT)
    `uvm_field_object(spi_master_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="spi_env_cfg");
    super.new(name);
    spi_master_cfg = spi_vip_config#(1)::type_id::create("spi_master_cfg");
    foreach(spi_slave_cfg[i]) begin
      spi_slave_cfg[i] = spi_vip_config#(1)::type_id::create($sformatf("spi_slave_cfg%0d", i));
    end
  endfunction

endclass
