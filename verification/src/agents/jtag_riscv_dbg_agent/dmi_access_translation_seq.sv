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

`define dmi_check(status) `check_status(status, "DMI Operation failed")

class dmi_access_translation_seq extends uvm_reg_sequence;
  `uvm_object_utils(dmi_access_translation_seq)
  dmi_jtag_regs model;
  uvm_sequencer#(jtag_riscv_dmi_access_item) up_sequencer;
  jtag_chain_agent_cfg cfg_handle;

  `uvm_object_new

    task clear_dmi_status();
      uvm_status_e status;
      model.dtmcs.reset();
      model.dtmcs.dmireset.set(1);
      model.dtmcs.update(status, .parent(this));
      `check_status(status, "Failed to clear the the sticky status bit")
    endtask

  task automatic send_dmi(input jtag_riscv_dmi_access_item item, output jtag_riscv_dmi_access_item rsp);
    uvm_status_e status;
    $cast(rsp, item.clone());
    rsp.set_id_info(item);
    `uvm_info(`gfn, "Write to DMI access Jtag register to start dmi operation...", UVM_HIGH)
    model.dmi.address.set(item.address);
    if (item.is_write) begin
      model.dmi.data.set(item.data);
      model.dmi.op.set(2); // DMI write
      model.dmi.update(status, .parent(this));
      `uvm_info(`gfn, "Check for completion of write operation...", UVM_HIGH)
      model.dmi.mirror(status, .parent(this));
      `dmi_check(status)
      model.dtmcs.mirror(status,  .parent(this));
      `dmi_check(status)
      while(item.retry && model.dtmcs.dmistat.get() == 2'h3) begin
        `uvm_info(`gfn, "DMI operation is still pending. Resetting the pending op error state and trying again...", UVM_HIGH);
        model.dtmcs.reset();
        model.dtmcs.dmireset.set(1);
        model.dtmcs.update(status, .parent(this));
        `dmi_check(status)
        model.dmi.mirror(status, .parent(this));
        `dmi_check(status)
        model.dtmcs.mirror(status,  .parent(this));
        `dmi_check(status)
      end
    end else begin
      model.dmi.op.set(1); // DMI read
      model.dmi.update(status, .parent(this));
      `uvm_info(`gfn, "Wait for dmi read response...", UVM_HIGH)
      model.dmi.mirror(status, .parent(this));
      `dmi_check(status)
      while(item.retry && model.dmi.op.get() == 2'h3) begin
        `uvm_info(`gfn, "DMI read operation still pending. Resetting the pending op error and trying again...", UVM_HIGH)
        model.dtmcs.reset();
        model.dtmcs.dmireset.set(1);
        model.dtmcs.update(status, .parent(this));
        `dmi_check(status)
        model.dmi.mirror(status, .parent(this));
        `dmi_check(status);
      end
      rsp.rsp_data = model.dmi.data.get();
    end
    case (model.dmi.op.get())
      2'h0: begin
        `uvm_info(`gfn, "DMI operation completed successfully.", UVM_HIGH);
        rsp.error = 0;
        rsp.pending = 0;
      end

      2'h1: begin
        `uvm_error(`gfn, "DMI operation results in reserved/unknown status code 1.")
        rsp.error = 1;
        rsp.pending = 0;
      end

      2'h2: begin
        `uvm_error(`gfn, "DMI operation resulted in an error. Status code 2.")
        rsp.error = 1;
        rsp.pending = 0;
      end

      2'h3: begin
        `uvm_error(`gfn, "DMI operation failed since it remained pending. Status code 3.")
        rsp.error = 1;
        rsp.pending = 1;
      end
    endcase
  endtask

  virtual task body();
    uvm_status_e status;
    uvm_reg_data_t data;
    jtag_riscv_dmi_access_item item;
    jtag_riscv_dmi_access_item rsp;

    // Obtain a handle to the agent configuration object to insert wait cycles
    // on the TCK signal. The agent config object has a handle to the jtag BFM
    // for this purpose.
    if (!uvm_config_db#(jtag_chain_agent_cfg)::get(m_sequencer.get_parent(), "", "cfg", cfg_handle))
      `uvm_fatal(`gfn, "Failed to obtain handle to jtag_riscv_dbg agent config.")

    `uvm_info(`gfn, "DMI Access to JTAG translation sequence started", UVM_HIGH)
    forever begin
      up_sequencer.get_next_item(item);
      `uvm_info(`gfn, $sformatf("Received new item: \n %s", item.sprint()), UVM_HIGH)
      m_sequencer.lock(this);
      send_dmi(item, rsp);
      m_sequencer.unlock(this);
      up_sequencer.item_done(rsp);
    end
  endtask

endclass
