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


class pulp_sw_backdoor_boot_test extends pulp_sw_base_test#(.NUM_IO_SIGNALS(IO_SIGNAL_COUNT), .NUM_DUT_SIGNALS(DUT_SIGNAL_COUNT));
  `uvm_component_utils(pulp_sw_backdoor_boot_test)
  `uvm_component_new

  string stimuli_file;
  logic [31:0] entry_point;

  virtual function string get_test_shortname();
    return "Generic Sofware Test using Backdoor Boot Mechanism";
  endfunction

  virtual task configure_phase(uvm_phase phase);
    v_seq_siracusa_boot_backdoor boot_seq = v_seq_siracusa_boot_backdoor::type_id::create("boot_seq");
    super.configure_phase(phase);
    phase.raise_objection(this);
    // Parse the stimuli file path and ELF entrypoint from the plusargs
    if ($value$plusargs("ENTRY_POINT=%h", entry_point)) begin
      `uvm_info(`gfn, $sformatf("Using user provided execution entrypoint %08h.", entry_point), UVM_MEDIUM)
    end else begin
      `uvm_warning(`gfn, "No ENTRY_POINT plusarg provided. Using the default entrypoint 0x1c008080.")
      entry_point = 32'h1C008080;
    end
    if ($value$plusargs("stimuli=%s", stimuli_file)) begin
      `uvm_info(`gfn, $sformatf("Using user provided stimuli file %s for binary preloading via JTAG.", stimuli_file), UVM_MEDIUM)
    end else begin
      `uvm_warning(`gfn, "No stimuli plusarg provided. Using default stimuli file path ./vectors/stim.txt")
      stimuli_file = "./vectors/stim.txt";
    end
    boot_seq.stimuli_file             = stimuli_file;
    boot_seq.entry_point              = entry_point;
    `uvm_info(`gfn, "Booting Siracusa via backdoor access...", UVM_MEDIUM)
    boot_seq.start(env.v_sqr);
    `uvm_info(`gfn, "Boot procedure finished.", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask


endclass
