//-----------------------------------------------------------------------------
// Title         : Siracusa UVM Environmentb
//-----------------------------------------------------------------------------
// File          : siracusa_env.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 06.09.2021
//-----------------------------------------------------------------------------
// Description :
// UVM Environment for the Siracus Chip
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
`include "i3c_defs.svh"

class siracusa_i3c_env extends uvm_env;

  uvm_factory factory;
  uvm_coreservice_t cs = uvm_coreservice_t::get();

  // Variable: env_cfg
  // 
  // Instance of top level configuration. It contains the configuration objects 
  // for device and device. 
  siracusa_i3c_env_cfg env_cfg;

  `ifdef TLM_MASTER
    // Variable: dev_main_mstr_agent
    //
    // Instance of an i3c_agent, acting as I3C device. 
    i3c_agent dev_main_mstr_agent;
  `endif

  `ifdef MIXED_FAST_BUS
    // Variable: dev_legacy_i2c_slv_agent
    //
    // Instance of an i3c_agent, acting as I3C device. 
    i3c_agent dev_legacy_i2c_slv_agent;
  `endif

  `ifdef MULTIPLE_SLAVE
    // Variable: dev_sec_mstr_agent
    //
    // Instance of an i3c_agent, acting as I3C device. 
    i3c_agent dev_sec_mstr_agent;

    // Variable: dev_hot_join_slv_agent
    //
    // Instance of an i3c_agent, acting as I3C device. 
    i3c_agent dev_hot_join_slv_agent;
    
    // Variable: dev_static_slv_agent
    //
    // Instance of an i3c_agent, acting as I3C device. 
    i3c_agent dev_static_slv_agent;
  `endif

  // Variable: dev_i3c_slv_agent
  //
  // Instance of an i3c_agent, acting as I3C device. 
  i3c_agent dev_i3c_slv_agent;

  `uvm_component_utils_begin(siracusa_i3c_env)
    `uvm_field_object(env_cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get the env config
    if (env_cfg == null)
      `uvm_fatal("ENV/CFG/NOT_FOUND","The env requires an env_config object")

    // Build agents
    `ifdef TLM_MASTER
      dev_main_mstr_agent          = i3c_agent::type_id::create("dev_main_mstr_agent", this);
      dev_main_mstr_agent.cfg      = env_cfg.dev_main_mstr_cfg;
    `endif
    dev_i3c_slv_agent              = i3c_agent::type_id::create("dev_i3c_slv_agent", this);
    `ifdef MIXED_FAST_BUS
    dev_legacy_i2c_slv_agent       = i3c_agent::type_id::create("dev_legacy_i2c_slv_agent", this);
    dev_legacy_i2c_slv_agent.cfg   = env_cfg.dev_legacy_i2c_slv_cfg;
    `endif

    `ifdef MULTIPLE_SLAVE
      dev_sec_mstr_agent           = i3c_agent::type_id::create("dev_sec_mstr_agent", this);
      dev_hot_join_slv_agent       = i3c_agent::type_id::create("dev_hot_join_slv_agent", this);
      dev_static_slv_agent         = i3c_agent::type_id::create("dev_static_slv_agent", this);
      dev_sec_mstr_agent.cfg       = env_cfg.dev_sec_mstr_cfg;
      dev_hot_join_slv_agent.cfg   = env_cfg.dev_hot_join_slv_cfg;
      dev_static_slv_agent.cfg     = env_cfg.dev_static_slv_cfg;
    `endif
    dev_i3c_slv_agent.cfg          = env_cfg.dev_i3c_slv_cfg;

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

endclass
