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


class v_seq_siracusa_boot_backdoor extends v_seq_siracusa_boot_jtag;
  `uvm_object_utils(v_seq_siracusa_boot_backdoor)
  `uvm_object_new

  virtual task preload_stim_file();
    `uvm_info(`gfn, "Preloading stimuli file using backdoor access. Don't use this boot sequence to verify boot behavior!!!", UVM_LOW)
    super.preload_stim_file();
  endtask

  virtual task send_burst(uvm_reg_addr_t burst_start_addr, uvm_reg_data_t burst_data[]);
    uvm_reg burst_target_reg;
    uvm_mem burst_target_mem;
    uvm_reg_addr_t mem_offset;
    uvm_status_e status;

    burst_target_mem = regmodel.top_map.get_mem_by_offset(burst_start_addr);
    if (burst_target_mem != null) begin
      mem_offset = burst_target_mem.get_address(.offset(0), .map(regmodel.top_map));
      `uvm_info(`gfn, $sformatf("Writing burst of size %0d to 0x%08h which is in %s using backdoor access.", burst_data.size(), burst_start_addr, burst_target_mem.get_full_name()), UVM_MEDIUM);
      burst_target_mem.burst_write(status, burst_start_addr-mem_offset, burst_data, .parent(this), .path(UVM_BACKDOOR));
      if (status != UVM_IS_OK)
        `uvm_error(`gfn, "Burst write failed!")
    end else begin
      burst_target_reg = regmodel.top_map.get_reg_by_offset(burst_start_addr, .read(0));
      if (burst_target_reg != null) begin
        `uvm_info(`gfn, $sformatf("Writing burst of size %0d to 0x%08h which is in %s", burst_data.size(), burst_start_addr, burst_target_reg.get_full_name()), UVM_MEDIUM);
        if (burst_data.size() != 1)
          `uvm_fatal(`gfn, "Control flow error. The burst size for register writes must not be larger than 1. Something went wrong in the burst splitting logic.")
          burst_target_reg.write(status, burst_data[0], .parent(this), .path(UVM_BACKDOOR));
        if (status != UVM_IS_OK)
          `uvm_error(`gfn, "Register write failed!")
      end else begin
        `uvm_fatal(`gfn, $sformatf("The target address %08h found in the stimuli file is not mapped within the Siracusa register model.", burst_start_addr))
      end
    end
  endtask

endclass
