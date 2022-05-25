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

typedef class dmi_reset_seq; ///< Resets the jtag DMI interface

class riscv_dbg_dmi_base_seq extends uvm_reg_sequence;
  `uvm_object_utils(riscv_dbg_dmi_base_seq)
  dmi_jtag_regs model;

  function  new(string name="riscv_dbg_dmi_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    if (!uvm_config_db#(dmi_jtag_regs)::get(m_sequencer.get_parent(), "", "dmi_regs", model))
      `uvm_fatal(`gfn, "Failed to obtain handle to dmi register model.")
  endtask

endclass

class dmi_reset_seq extends riscv_dbg_dmi_base_seq;
  `uvm_object_utils(dmi_reset_seq)
  `uvm_object_new

    virtual task body();
      uvm_status_e status;
      `uvm_info(`gfn, "Resetting DMI...", UVM_HIGH)
      model.dtmcs.dmihardreset.set(1);
      model.dtmcs.update(status, .parent(this));
      `check_status_fatal(status, "Failed to hard-reset DMI when starting translation sequence. ")
      model.dtmcs.dmihardreset.set(0);
      model.dtmcs.mirror(status, .parent(this));
      if (model.dtmcs.dmistat.get() != 0)
        `uvm_error(`gfn, "JTAG DMI was not idle after dmihardreset.")
    endtask
endclass
