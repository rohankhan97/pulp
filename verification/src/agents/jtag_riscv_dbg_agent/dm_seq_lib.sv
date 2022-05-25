typedef class dm_reset_seq; ///< Resets the debug module
typedef class dm_halt_hart_seq; ///< Halts the give hart
typedef class dm_write_reg_seq; ///< Write to register using abstract command


class riscv_dbg_dm_base_seq extends uvm_reg_sequence;
  `uvm_object_utils(riscv_dbg_dm_base_seq)
  dm_regs model;

  function  new(string name="riscv_dbg_dm_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    if (!uvm_config_db#(dm_ral_pkg::dm_regs)::get(m_sequencer.get_parent(), "", "dm_regs", model))
      `uvm_fatal(`gfn, "Failed to obtain handle to dm register model.")
  endtask
endclass

class dm_reset_seq extends riscv_dbg_dm_base_seq;
  `uvm_object_utils(dm_reset_seq)
  `uvm_object_new

  virtual task body();
    uvm_status_e status;
    uvm_reg_data_t data;

    `uvm_info(`gfn, "Resseting the debug module... ", UVM_MEDIUM);
    `uvm_info(`gfn, "Asserting dmactive", UVM_HIGH);
    model.dmcontrol.dmactive.set(0);
    update_reg(model.dmcontrol, status);
    `check_status(status, "Resetting debug modul failed. Error during DMI transaction.");
    `uvm_info(`gfn, "De-asserting dmactive", UVM_MEDIUM);
    model.dmcontrol.dmactive.set(1);
    update_reg(model.dmcontrol, status);
    `check_status(status, "Resetting debug modul failed. Error during DMI transaction.");
    `uvm_info(`gfn, "DMI reset finished", UVM_HIGH);
  endtask
endclass

class dm_halt_hart_seq extends riscv_dbg_dm_base_seq;
  rand logic [19:0] hart_id;

  `uvm_object_utils_begin(dm_halt_hart_seq)
    `uvm_field_int(hart_id, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

  virtual task body();
    uvm_status_e status;

    `uvm_info(`gfn, $sformatf("Halting hart %0d", hart_id), UVM_MEDIUM)
    model.dmcontrol.hartselhi.set(hart_id[19:10]);
    model.dmcontrol.hartsello.set(hart_id[9:0]);
    model.dmcontrol.haltreq.set(1'b1);
    update_reg(model.dmcontrol, status);
    `check_status(status, "Error writing to dmcontrol. DMI transaction failed")
    `uvm_info(`gfn, "Polling dmstatus until all harts are halted", UVM_HIGH)
    do begin
      `uvm_info(`gfn, "Polling dmstatus...", UVM_HIGH)
      mirror_reg(model.dmstatus, status);
      `check_status(status, "Failed to read dmstatus. DMI transaction failed")
    end while(model.dmstatus.allhalted.get() != 1'b1);
    `uvm_info(`gfn, "Success. All harts are halted.", UVM_MEDIUM)
    // Clear the halt req bit
    model.dmcontrol.haltreq.set(1'b0); // Resume model value
    update_reg(model.dmcontrol, status);
    `check_status(status, "Failed to clear the haltreq bit in dmcontrol. DMI transaction failed")
  endtask
endclass

class dm_resume_hart_seq extends riscv_dbg_dm_base_seq;
  rand logic [19:0] hart_id;

  `uvm_object_utils_begin(dm_resume_hart_seq)
    `uvm_field_int(hart_id, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

    virtual task body();
      uvm_status_e status;

      `uvm_info(`gfn, $sformatf("Halting hart %0d", hart_id), UVM_MEDIUM)
      model.dmcontrol.hartselhi.set(hart_id[19:10]);
      model.dmcontrol.hartsello.set(hart_id[9:0]);
      model.dmcontrol.resumereq.set(1'b1);
      update_reg(model.dmcontrol, status);
      `check_status(status, "Error writing to dmcontrol. DMI transaction failed")
      `uvm_info(`gfn, "Polling dmstatus until all harts are resumed", UVM_HIGH)
      do begin
        `uvm_info(`gfn, "Polling dmstatus...", UVM_HIGH)
        mirror_reg(model.dmstatus, status);
        `check_status(status, "Failed to read dmstatus. DMI transaction failed")
      end while(model.dmstatus.allresumeack.get() != 1'b1);
      // Clear the resume req
      model.dmcontrol.resumereq.set(1'b0); // Restore the value in the model
      update_reg(model.dmcontrol, status);
      `check_status(status, "Failed to clear the resumereq bit in dmcontorl. DMI transaction failed")
      `uvm_info(`gfn, "Success. All harts are resumed.", UVM_MEDIUM)

    endtask
endclass

class dm_write_reg_seq extends riscv_dbg_dm_base_seq;
  rand logic [19:0] hart_id;
  rand logic [31:0] data;
  rand logic [15:0] reg_nr;

  typedef struct packed {
    logic [2:0]  aarsize;
    logic        aarpostincrement;
    logic        postexec;
    logic        transfer;
    logic        write;
    logic [15:0] regno;
  } access_reg_ctrl_field_t;

  `uvm_object_utils_begin(dm_write_reg_seq)
    `uvm_field_int(hart_id, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

    virtual task body();
      uvm_status_e status;
      access_reg_ctrl_field_t ctrl_field;

      `uvm_info(`gfn, $sformatf("Writing register %0d in hart %0d", reg_nr, hart_id), UVM_MEDIUM)
      model.dmcontrol.hartselhi.set(hart_id[19:10]);
      model.dmcontrol.hartsello.set(hart_id[9:0]);
      update_reg(model.dmcontrol, status);
      `check_status(status, "Error writing to dmcontrol. DMI transaction failed")
      `uvm_info(`gfn, "Setup arguments for abstract command...", UVM_HIGH)
      model.data0.set(data);
      update_reg(model.data0, status);
      `check_status(status, "Error while writing abstract command argument to data0. DMI transaction failed")
      `uvm_info(`gfn, "Sending abstract command to write DPC register", UVM_HIGH)
      model.command.cmdtype.set(0); // Access Register command
      ctrl_field.aarsize          = 2; // 32-bit access
      ctrl_field.aarpostincrement = 0;
      ctrl_field.postexec         = 0;
      ctrl_field.transfer         = 1; // Actually do the transfer
      ctrl_field.write            = 1;
      ctrl_field.regno            = reg_nr;
      model.command.control.set(ctrl_field);
      update_reg(model.command, status);
      `check_status(status, "Error while writing to command register. DMI transaction failed")
      `uvm_info(`gfn, "Polling abstractcs for abstract command completion", UVM_HIGH)
      do begin
        `uvm_info(`gfn, "Polling abstractcs...", UVM_HIGH)
        mirror_reg(model.abstractcs, status);
        `check_status(status, "Failed to read abstractcs. DMI transaction failed")
      end while(model.abstractcs.busy.get() == 1'b1);
      `uvm_info(`gfn, "Successfully wrote register.", UVM_MEDIUM)
    endtask

endclass
