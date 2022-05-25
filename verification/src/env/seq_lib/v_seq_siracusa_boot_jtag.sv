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

class v_seq_siracusa_boot_jtag extends siracusa_vseq_base;
  string stimuli_file;
  logic [31:0] entry_point;
  `uvm_object_utils_begin(v_seq_siracusa_boot_jtag)
    `uvm_field_string(stimuli_file, UVM_DEFAULT)
    `uvm_field_int(entry_point, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

  localparam logic[19:0] FC_HART_ID = 20'd992;
  localparam logic [15:0] REG_DPC_NR = 16'h7b1;

  virtual task do_body();
    // Create subsequences
    jtag_riscv_dbg_agent_pkg::dm_halt_hart_seq halt_hart_seq;
    jtag_riscv_dbg_agent_pkg::dm_write_reg_seq set_dpc_seq;
    jtag_riscv_dbg_agent_pkg::dm_resume_hart_seq resume_hart_seq;

    `uvm_info(`gfn, "Starting JTAG boot sequence...", UVM_MEDIUM)
    halt_hart_seq         = jtag_riscv_dbg_agent_pkg::dm_halt_hart_seq::type_id::create("halt_hart");
    set_dpc_seq           = jtag_riscv_dbg_agent_pkg::dm_write_reg_seq::type_id::create("set_dpc");
    resume_hart_seq       = jtag_riscv_dbg_agent_pkg::dm_resume_hart_seq::type_id::create("resume_hart");

    // Halt the fabric controller
    halt_hart_seq.hart_id = FC_HART_ID;
    halt_hart_seq.start(jtag_dmi_access_sqr);

    // Preloading the elf binary
    preload_stim_file();



    // Program ELF entry_point to FC's PC
    set_dpc_seq.hart_id     = FC_HART_ID;
    set_dpc_seq.reg_nr      = REG_DPC_NR;
    set_dpc_seq.data        = entry_point;
    set_dpc_seq.start(jtag_dmi_access_sqr);
    // Resume the hart
    resume_hart_seq.hart_id = FC_HART_ID;
    resume_hart_seq.start(jtag_dmi_access_sqr);
  endtask

  virtual task preload_stim_file();
    logic[95:0] stimuli[];
    uvm_reg_addr_t prev_addr, current_addr;
    uvm_reg_addr_t burst_start_addr;
    uvm_reg_data_t burst_data[$];

    uvm_reg prev_reg, current_reg;
    uvm_mem prev_mem, current_mem;

    $readmemh(stimuli_file, stimuli);
    `uvm_info(`gfn, $sformatf("Read a total of %0d 32-bit words of stimuli from file %s", 2*stimuli.size(), stimuli_file), UVM_MEDIUM)
    // Start the first burst
    current_addr     = stimuli[0][95:64];
    current_reg      = regmodel.top_map.get_reg_by_offset(current_addr, .read(0));
    current_mem      = regmodel.top_map.get_mem_by_offset(current_addr);
    burst_start_addr = current_addr;
    burst_data.push_back(stimuli[0][31:0]);
    burst_data.push_back(stimuli[0][63:32]);
    foreach(stimuli[i]) begin
      prev_addr    = current_addr;
      current_addr = stimuli[i][95:64];
      // Check if we have to start a new burst or can push data on top of the
      // existing one. There are two conditions for that to happen:
      // 1. The access must be pointing to a memory (individual peripheral
      // registers are always written with single transactions).
      // 2. The addresses are consecutive. Since there are 64-bits in each
      // stimuli file line we check if the assign address is 8 bytes larger than
      // the previous address.
      // 3. The addresses do not cross memory boundaries (otherwise backdoor
      // access will fail since we try burst writing to multiple memories)
      prev_reg     = current_reg;
      prev_mem     = current_mem;
      current_reg  = regmodel.top_map.get_reg_by_offset(current_addr, .read(0));
      current_mem  = regmodel.top_map.get_mem_by_offset(current_addr);
      if (current_addr == prev_addr+8 && current_reg == null && prev_reg == null && current_mem == prev_mem) begin
        // Push the current datum on top of the burst data queue.
        burst_data.push_back(stimuli[i][31:0]);
        burst_data.push_back(stimuli[i][63:32]);
      end else begin
        // we need to start a new burst. Send the previous one...
        send_burst(burst_start_addr, burst_data);
        // Now start the new burst
        burst_start_addr = current_addr;
        burst_data.delete();
        burst_data.push_back(stimuli[i][31:0]);
        burst_data.push_back(stimuli[i][63:32]);
      end
    end
    // Send the last open burst
    send_burst(burst_start_addr, burst_data);
    `uvm_info(`gfn, "Preloading of stimuli file finished.", UVM_MEDIUM)
  endtask

  virtual task send_burst(uvm_reg_addr_t burst_start_addr, uvm_reg_data_t burst_data[]);
    uvm_reg burst_target_reg;
    uvm_mem burst_target_mem;
    uvm_reg_addr_t mem_offset;
    uvm_status_e status;

    burst_target_mem     = regmodel.top_map.get_mem_by_offset(burst_start_addr);
    if (burst_target_mem != null) begin
      mem_offset = burst_target_mem.get_address(.offset(0), .map(regmodel.top_map));
      `uvm_info(`gfn, $sformatf("Writing burst of size %0d to 0x%08h which is in %s", burst_data.size(), burst_start_addr, burst_target_mem.get_full_name()), UVM_MEDIUM);
      burst_target_mem.burst_write(status, burst_start_addr-mem_offset, burst_data, .parent(this));
      if (status != UVM_IS_OK)
        `uvm_error(`gfn, "Burst write failed!")
    end else begin
      burst_target_reg = regmodel.top_map.get_reg_by_offset(burst_start_addr, .read(0));
      if (burst_target_reg != null) begin
        `uvm_info(`gfn, $sformatf("Writing burst of size %0d to 0x%08h which is in %s", burst_data.size(), burst_start_addr, burst_target_reg.get_full_name()), UVM_MEDIUM);
        if (burst_data.size() != 1)
          `uvm_fatal(`gfn, "Control flow error. The burst size for register writes must not be larger than 1. Something went wrong in the burst splitting logic.")
        burst_target_reg.write(status, burst_data[0], .parent(this));
        if (status != UVM_IS_OK)
          `uvm_error(`gfn, "Register write failed!")
      end else begin
        `uvm_fatal(`gfn, $sformatf("The target address %08h found in the stimuli file is not mapped within the Siracusa register model.", burst_start_addr))
      end
    end
  endtask


endclass
