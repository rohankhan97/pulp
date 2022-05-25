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

class siracusa_spi_env extends uvm_env;
  siracusa_spi_env_cfg cfg;
  typedef siracusa_spi_env_cfg env_config_t;
  typedef spi_agent  #(1) spi_agent_t;
  `uvm_component_utils_begin(siracusa_spi_env)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
  `uvm_component_new

  spi_agent_t spi_master_agent;
  spi_agent_t spi_slave_agents[4];


  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(env_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn,"Failed to obtain spi_env configuration object.")
    spi_master_agent = spi_agent_t::type_id::create("spi_master_agent", this);
    uvm_config_db #(uvm_object)::set(this,"*spi_master_agent*",mvc_config_base_id, cfg.spi_master_cfg);
    spi_master_agent.cfg = cfg.spi_master_cfg;
    for (int i = 0; i < 4; i++) begin
      spi_slave_agents[i] = spi_agent_t::type_id::create($sformatf("spi_slave_agent%0d",i), this);
      uvm_config_db #(uvm_object)::set(this,$sformatf("*spi_slave_agent%0d*",i),mvc_config_base_id, cfg.spi_slave_cfg[i]);
      spi_slave_agents[i].cfg = cfg.spi_slave_cfg[i];
    end
  endfunction

endclass
