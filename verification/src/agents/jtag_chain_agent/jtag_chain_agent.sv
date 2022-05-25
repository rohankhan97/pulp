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


class jtag_chain_agent extends uvm_component;

  jtag_chain_sequencer sequencer;
  jtag_chain_agent_cfg cfg;
  jtag_agent jtag_agent;

  `uvm_component_utils_begin(jtag_chain_agent)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(jtag_chain_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn, "Failed to obtain config from uvm_config_db");
    // set configuration for sub-components
    uvm_config_db#(jtag_agent_cfg)::set(this, "jtag_agent", "cfg", cfg.jtag_agent_cfg);

    sequencer = uvm_sequencer#(jtag_chain_item)::type_id::create("jtag_chain_sqr", this);
    jtag_agent = jtag_agent_pkg::jtag_agent::type_id::create("jtag_agent", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    jtag_chain_translation_seq translate_seq;

    translate_seq                  = jtag_chain_translation_seq::type_id::create("translate_seq");
    translate_seq.up_sequencer     = sequencer;
    translate_seq.chain            = cfg.chain;
    translate_seq.tap_name_tap_map = cfg.tap_name_tap_map;

    // Start the translation sequence
    fork
      translate_seq.start(jtag_agent.sequencer);
    join_none
  endtask
endclass
