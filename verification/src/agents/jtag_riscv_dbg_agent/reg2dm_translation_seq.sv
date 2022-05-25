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

class reg2dm_translation_seq extends uvm_reg_sequence;
  `uvm_object_utils(reg2dm_translation_seq)
  `uvm_object_new

  uvm_sequencer#(uvm_reg_item) up_sequencer;
  dm_regs model;

  task wait_sb_finished(inout uvm_reg_item item);
    uvm_status_e status;
    `uvm_info(`gfn, "Check sbcs to see if sb operation finished.", UVM_HIGH)
    do begin
      mirror_reg(model.sbcs, status);
      `check_status(status, "Failed to reads status from sbcs reg. DMI Operation failed")
    end while(model.sbcs.sbbusy.get() != 0 && model.sbcs.sberror.get() == 0);
    case (model.sbcs.sberror.get())
      0: begin
        `uvm_info(`gfn, "System Bus operation success.", UVM_HIGH)
        if (item.status != UVM_NOT_OK) begin
          item.status = UVM_IS_OK;
        end
      end

      1: begin
        `uvm_error(`gfn, "SB transaction timeout error (code 1). Operation failed.")
        item.status = UVM_NOT_OK;
      end

      2: begin
        `uvm_error(`gfn, "SB bad address error (code 2). Operation failed.")
        item.status = UVM_NOT_OK;
      end

      3: begin
        `uvm_error(`gfn, "SB alignment error (code 3). Operation failed.")
        item.status = UVM_NOT_OK;
      end

      4: begin
        `uvm_error(`gfn, "SB access with unsupported size error (code 4). Operation failed.")
        item.status = UVM_NOT_OK;
      end

      default: begin
        `uvm_error(`gfn, $sformatf("SB unknown error (code %0d). Operation failed.", model.sbcs.sberror.get()))
        item.status = UVM_NOT_OK;
      end
    endcase
  endtask

  virtual task body();
    uvm_status_e status;
    uvm_reg_item item;
    uvm_reg target_reg;
    uvm_mem target_mem;
    uvm_reg_addr_t addr;

    forever begin
      up_sequencer.get_next_item(item);
      if (item.element_kind == UVM_REG) begin
        $cast(target_reg, item.element);
        addr = target_reg.get_address(item.map);
      end else begin
        $cast(target_mem, item.element);
        addr = target_mem.get_address(.map(item.map)) + item.offset;
      end
      item.status = UVM_IS_OK; // will be updated by wait_sb_finished.
      m_sequencer.lock(this);
      `uvm_info(`gfn, $sformatf("Received new system bus access item: \n%s", item.sprint()), UVM_HIGH)
      // Handle the different access kinds
      case (item.kind)
        UVM_READ: begin
          // Setup sbcs to auto-read on write to sbaddress0
          model.sbcs.reset();
          model.sbcs.sbaccess.set(2); // 32-bit transaction size
          model.sbcs.sbreadonaddr.set(1);
          update_reg(model.sbcs, status);
          `check_status(status, "Failed to setup sbcs for single element read. DMI operation failed")
          // Write address to sbaddress0
          write_reg(model.sbaddress0, status, addr);
          `check_status(status, "Failed to  write read addr to sbaddress0. DMI operation failed.")
          wait_sb_finished(item);
          // Read result from sbdata0
          read_reg(model.sbdata0, status, item.value[0]);
          `check_status(status, "Failed to read the sb read response data. DMI operation failed")
        end

        UVM_WRITE: begin
          model.sbcs.reset();
          update_reg(model.sbcs, status);
          `check_status(status, "Failed to setup SBCS for single element write")
          write_reg(model.sbaddress0, status, addr);
          `check_status(status, "Failed to write address to sbaddress0. DMI operation failed")
          write_reg(model.sbdata0, status, item.value[0]);
          `check_status(status, "Failed to write data to sbdata0. DMI operation failed")
          wait_sb_finished(item);
        end

        UVM_BURST_READ: begin
          model.sbcs.reset();
          model.sbcs.sbaccess.set(2);
          model.sbcs.sbreadonaddr.set(1);
          model.sbcs.sbreadondata.set(1);
          model.sbcs.sbautoincrement.set(1);
          update_reg(model.sbcs, status);
          `check_status(status, "Failed to setup sbcs for burst read. DMI operation failed")
          // Write start address to sbaddress0
          write_reg(model.sbaddress0, status, addr);
          `check_status(status, "Failed to write start address to sbaddress0 for burst read. DMI operation failed")
          wait_sb_finished(item);
          // Perform burst read
          foreach(item.value[i]) begin
            read_reg(model.sbdata0, status, item.value[i]);
            `check_status(status, $sformatf("Failed to read beat %0d of read burst. DMI operation failed", i))
            wait_sb_finished(item);
          end
        end

        UVM_BURST_WRITE: begin
          model.sbcs.reset();
          model.sbcs.sbaccess.set(2);
          model.sbcs.sbautoincrement.set(1);
          update_reg(model.sbcs, status);
          `check_status(status, "Failed to setup sbcs for burst write. DMI operation failed")
          // Write start address to sbaddress0
          write_reg(model.sbaddress0, status, addr);
          `check_status(status, "Failed to write start address to sbaddress0 for burst write. DMI operation failed")
          wait_sb_finished(item);
          // Perform burst write
          foreach(item.value[i]) begin
            write_reg(model.sbdata0, status, item.value[i]);
            `check_status(status, $sformatf("Failed on write beat %0d of write burst. DMI operation failed", i))
            wait_sb_finished(item);
          end
        end
      endcase
      m_sequencer.unlock(this);
      up_sequencer.item_done(item);
    end
  endtask


endclass
