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

class interleaved_mem_backdoor#(
  parameter int unsigned  LOG2_NUM_MEMORIES = 0
) extends active_monitor_backdoor;
  localparam int unsigned NUM_MEMORIES = 2**LOG2_NUM_MEMORIES;

  uvm_hdl_path_slice interleaved_mem_hdl_paths[$];
  int lsb_idx;

  `uvm_object_param_utils(interleaved_mem_backdoor#(LOG2_NUM_MEMORIES))
  `uvm_object_new

  function void add_bank_path_segment(uvm_hdl_path_slice path);
    interleaved_mem_hdl_paths.push_back(path);
  endfunction

  function uvm_hdl_path_slice get_target_bank_path_segment (uvm_reg_item rw, int idx);
    uvm_reg_addr_t addr;
    addr = rw.offset + idx;
    if (interleaved_mem_hdl_paths.size() != NUM_MEMORIES)
      `uvm_fatal(`gfn, $sformatf("Not all memory hdl paths for the given mem_backdoor instance were registered. Should be %0d but was %0d.", NUM_MEMORIES, interleaved_mem_hdl_paths.size()))
    if(LOG2_NUM_MEMORIES == 0) begin
      return interleaved_mem_hdl_paths[0];
    end else begin
      return interleaved_mem_hdl_paths[addr[lsb_idx+:LOG2_NUM_MEMORIES]];
    end
  endfunction

  virtual task write(uvm_reg_item rw);
    uvm_hdl_path_concat paths[$];
    uvm_hdl_path_slice target_bank_path;
    uvm_mem memory;
    bit ok = 1;

    if (rw.element_kind != UVM_MEM)
      `uvm_fatal(`gfn, "Cannot use interleaved_mem_backdoor instance as a backdoor for registers. Only uvm_memories are allowed")
    $cast(memory, rw.element);
    memory.get_full_hdl_path(paths, rw.bd_kind);

    do_pre_write(rw);
    // Iterate over each burst value to write
    foreach (rw.value[mem_idx]) begin
      string word_idx;
      uvm_reg_addr_t addr;
      addr = rw.offset + mem_idx*4;
      word_idx.itoa(addr >> (LOG2_NUM_MEMORIES));
      target_bank_path = get_target_bank_path_segment(rw, mem_idx);
      // Iterate over each backdoor path
      foreach (paths[i]) begin
        uvm_hdl_path_concat hdl_concat = paths[i];
        // Iterate over the slices in the target bank
        `uvm_info("RegModel", $sformatf("backdoor_write to %s ",{hdl_concat.slices[0].path, ".", target_bank_path.path}),UVM_DEBUG);

        if (target_bank_path.offset < 0) begin
          ok &= uvm_hdl_deposit({hdl_concat.slices[0].path,".", target_bank_path.path, "[", word_idx, "]"},rw.value[mem_idx]);
          continue;
        end else begin
          `uvm_fatal(`gfn, "Interleaved custom backdoor does not support bit slices. Offet and size must be -1")
        end
      end
    end
    rw.status = (ok ? UVM_IS_OK : UVM_NOT_OK);
    do_post_write(rw);
  endtask

  virtual function void read_func(uvm_reg_item rw);
    uvm_hdl_path_concat paths[$];
    uvm_hdl_path_slice target_bank_path;
    uvm_hdl_data_t val;
    uvm_mem memory;
    bit   ok=1;

    if (rw.element_kind != UVM_MEM)
      `uvm_fatal(`gfn, "Cannot use interleaved_mem_backdoor instance as a backdoor for registers. Only uvm_memories are allowed")
    $cast(memory, rw.element);
    memory.get_full_hdl_path(paths, rw.bd_kind);

    foreach (rw.value[mem_idx]) begin
      string word_idx;
      uvm_reg_addr_t    addr;
      addr = rw.offset + mem_idx;
      word_idx.itoa(addr >>( LOG2_NUM_MEMORIES));
      target_bank_path = get_target_bank_path_segment(rw, mem_idx);
      foreach (paths[i]) begin
        uvm_hdl_path_concat hdl_concat = paths[i];
        string hdl_path = {hdl_concat.slices[0].path, ".", target_bank_path.path, "[", word_idx, "]"};
        val = 0;

        `uvm_info("RegModel", {"backdoor_read from ",hdl_path},UVM_DEBUG)

        if (target_bank_path.offset < 0) begin
          ok &= uvm_hdl_read(hdl_path, val);
        end else begin
          `uvm_fatal(`gfn, "Interleaved custom backdoor does not support bit slices. offset and size must -1")
        end

        val &= (1 << memory.get_n_bits())-1;

        if (i == 0)
          rw.value[mem_idx] = val;

        if (val != rw.value[mem_idx]) begin
          `uvm_error("RegModel", $sformatf("Backdoor read of register %s with multiple HDL copies: values are not the same: %0h at path '%s', and %0h at path '%s'. Returning first value.",
                                           get_full_name(), rw.value[mem_idx], uvm_hdl_concat2string(paths[0]),
                                           val, uvm_hdl_concat2string(paths[i])));
          ok = 0;
        end
      end
    end

    rw.status = (ok) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction

endclass
