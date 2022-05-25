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

class jtag_riscv_dbg_agent extends uvm_component;
  jtag_riscv_dbg_agent_cfg cfg;

  `uvm_component_utils_begin(jtag_riscv_dbg_agent)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
  `uvm_component_new

  uvm_sequencer#(uvm_reg_item) system_bus_access_sequencer;
  dm_regs dm_regs;
  reg2dmi_adapter reg2dmi;
  uvm_sequencer#(jtag_riscv_dmi_access_item) dmi_access_sequencer;
  dmi_jtag_regs dmi_regs;
  reg2jtag_adapter reg2jtag;
  jtag_chain_agent chain_agent;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(jtag_riscv_dbg_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn, "Failed to obtain handle to agent config.")
    dmi_regs = dmi_jtag_regs::type_id::create("dmi_regs");
    dmi_access_sequencer = uvm_sequencer#(jtag_riscv_dmi_access_item)::type_id::create("dmi_access_sequencer", this);
    dmi_regs.build();
    dm_regs = dm_ral_pkg::dm_regs::type_id::create("dm_regs");
    dm_regs.build();
    // Register the reg_blocks in the config_db
    uvm_config_db#(dmi_jtag_regs)::set(chain_agent, "", "dmi_regs", dmi_regs);
    uvm_config_db#(dm_ral_pkg::dm_regs)::set(this, "", "dm_regs", dm_regs);
    // Create the reg_item sequencer that translates from system bus RAL
    // transaction to dm operations using the sb registers
    system_bus_access_sequencer = uvm_sequencer#(uvm_reg_item)::type_id::create("system_bus_sequencer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Create adapter that converts access to the DMI jtag registers to jtag transactions
    reg2jtag = reg2jtag_adapter::type_id::create("reg2jtag");
    reg2jtag.tap_name = this.get_name();
    dmi_regs.default_map.set_sequencer(chain_agent.sequencer, reg2jtag);
    dmi_regs.default_map.set_auto_predict(1);
    // Create adapter that converts access to the DM register to DMI
    // transactions
    reg2dmi = reg2dmi_adapter::type_id::create("reg2dmi");
    dm_regs.default_map.set_sequencer(dmi_access_sequencer, reg2dmi);
    dm_regs.default_map.set_auto_predict(1);
  endfunction

  task run_phase(uvm_phase phase);
    reg2dm_translation_seq reg2dm_seq;
    dmi_access_translation_seq dmi_access2jtag_translate_seq;

    reg2dm_seq                     = reg2dm_translation_seq::type_id::create("reg2dm_translation_seq");
    reg2dm_seq.up_sequencer        = system_bus_access_sequencer;
    reg2dm_seq.model               = dm_regs;

    dmi_access2jtag_translate_seq              = dmi_access_translation_seq::type_id::create("dmi_acces2jtag_translation_seq");
    dmi_access2jtag_translate_seq.up_sequencer = dmi_access_sequencer;
    dmi_access2jtag_translate_seq.model        = dmi_regs;

    /// Start the translations sequences
    fork
      dmi_access2jtag_translate_seq.start(chain_agent.sequencer);
      reg2dm_seq.start(dmi_access_sequencer);
    join_none
  endtask
endclass
