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

// A custom backdoor that uses verilab's signal_probe utility package to wait on
// signal changes. So execpt for supporting the wait_for_change task, the rest
// of the backdoor behavior is identical to the default backdoor implementation.

class active_monitor_backdoor extends uvm_reg_backdoor;
  string backdoor_kind = "RTL";
  string hdl_separator = ".";

  `uvm_object_utils_begin(active_monitor_backdoor)
    `uvm_field_string(backdoor_kind, UVM_DEFAULT)
    `uvm_field_string(hdl_separator, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

  signal_probe signal_probes[string]; //Contains all observed signal probes by
                                      //element's full backdoor hdl path

  virtual task write(uvm_reg_item rw);
    uvm_mem memory;
    uvm_reg register;
    // Get a handle to the reg_field or memory to forward the backdoor write to
    // the default implementation in UVM.
    case (rw.element_kind)
      UVM_MEM: begin
        $cast(memory, rw.element);
        memory.backdoor_write(rw);
      end

      UVM_REG: begin
        $cast(register, rw.element);
        register.backdoor_write(rw);
      end

      default: begin
        `uvm_fatal(`gfn, "Unknown element kind for backdoor access. Only uvm_reg, uvm_mem are supported.")
      end
    endcase
  endtask

  virtual function void read_func(uvm_reg_item rw);
    uvm_mem memory;
    uvm_reg register;
    // Get a handle to the reg_field or memory to forward the backdoor read to
    // the default implementation in UVM.
    case (rw.element_kind)
      UVM_MEM: begin
        $cast(memory, rw.element);
        rw.status = memory.backdoor_read_func(rw);
      end

      UVM_REG: begin
        $cast(register, rw.element);
        rw.status = register.backdoor_read_func(rw);
      end

      default: begin
        `uvm_fatal(`gfn, "Unknown element kind for backdoor access. Only uvm_reg, uvm_mem are supported.")
      end
    endcase
  endfunction

  virtual function bit is_auto_updated(uvm_reg_field field);
    // Return true since we support every field with a valid hdl path
    return 1;
  endfunction

  virtual task wait_for_change(uvm_object element);
    uvm_reg rg;
    uvm_reg_field rg_field;
    uvm_mem mem;
    uvm_hdl_path_concat paths[$];
    string full_hdl_path;
    if ($cast(rg, element)) begin
      rg.get_full_hdl_path(paths, .kind(backdoor_kind), .separator(hdl_separator));
    end else if ($cast(rg_field, element)) begin
      mem.get_full_hdl_path(paths, .kind(backdoor_kind), .separator(hdl_separator));
    end else begin
      `uvm_error(`gfn, "Only regs and memories (if implemented as packed arrays!) are supported at the moment.")
    end
    // We only use the path of the first slice within the first path provided to
    // do the monitoring
    full_hdl_path = paths[0].slices[0].path;
    // Check if there already is a signal probe in the associative array
    if (!signal_probes.exists(full_hdl_path)) begin
      // Create a new signal probe
      signal_probes[full_hdl_path] = signal_probe::create(full_hdl_path);
    end
    // Wait for change
    signal_probes[full_hdl_path].waitForChange();
  endtask

endclass
