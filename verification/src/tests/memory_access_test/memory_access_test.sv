//-----------------------------------------------------------------------------
// Title         : Siracusa Memory Access Test
//-----------------------------------------------------------------------------
// File          : memory_access_test.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 20.10.2021
//-----------------------------------------------------------------------------
// Description :
//
// This uses UVM RAL to verify the accesibility of all peripheral configuration
// registers and memories throught the data port of the fabric controler using
// UVM RAL.
//
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

class v_seq_memory_access_test extends siracusa_vseq_base;
  `uvm_object_utils(v_seq_memory_access_test)
  `uvm_object_new

    localparam logic[19:0] FC_HART_ID = 20'd992;

  virtual task do_body();
    // dm_halt_hart_seq halt_hart_seq;
    uvm_reg_access_seq access_seq;
    uvm_reg_bit_bash_seq bit_bash_seq;
    uvm_mem_walk_seq mem_walk_seq;
    uvm_mem_single_access_seq mem_access_seq;

    // Debug memory access to l2 memory
    // mem_access_seq       = uvm_mem_single_access_seq::type_id::create("mem_access_seq");
    // mem_access_seq.mem = regmodel.soc.l2_ram;
    // mem_access_seq.start(regmodel.top_map.get_sequencer());

    // Start bit bash sequence
    `uvm_info(`gfn, "Applying register rw bit-bash sequence...", UVM_MEDIUM)
    bit_bash_seq       = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
    bit_bash_seq.model = regmodel.soc.soc_peripherals.i3c0;
    bit_bash_seq.start(regmodel.top_map.get_sequencer());

    // Start memory access sequence
    `uvm_info(`gfn, "Applying register accessibility sequence...", UVM_MEDIUM)
    access_seq = uvm_reg_access_seq::type_id::create("access_seq");
    access_seq.model = regmodel;
    access_seq.start(regmodel.top_map.get_sequencer());

    // Start the memory walk sequence
    `uvm_info(`gfn, "Applying memory walk sequence...", UVM_MEDIUM)
    mem_walk_seq       = uvm_mem_walk_seq::type_id::create("mem_walk_seq");
    mem_walk_seq.model = regmodel;
    // mem_walk_seq.start(regmodel.top_map.get_sequencer());
  endtask
endclass

// This implementation of the memory walk sequence has a customizable random
// skip in the address test logic. Instead of testing every address which can be
// very slow for large memories, the sequence can be customized to skip
// addresses randomly. The amount of skipping is randomly chosen within a
// per-memory adjustable range. The adjustement happens via the uvm_config_db.
// By default, the range is zero, so no address is skpped. Users can change it
// by setting a config db entry of type 'int' as follows:
//
// uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::", my_mem.get_full_name()}, "MAX_SKIP", <max_skip>)
//
// The skip value is a random variable with uniform distribution in the range
// (0, max_skip)
class custom_memory_walk_seq extends uvm_mem_single_walk_seq;
  `uvm_object_utils(custom_memory_walk_seq)
  `uvm_object_new

  virtual task body();
    uvm_reg_map maps[$];
    int max_skip;
    int n_bits;

    if (mem == null) begin
      `uvm_error("uvm_mem_walk_seq", "No memory specified to run sequence on");
      return;
    end

    // Memories with some attributes are not to be tested
    if (uvm_resource_db#(bit)::get_by_name({"REG::",mem.get_full_name()},
                                           "NO_REG_TESTS", 0) != null ||
        uvm_resource_db#(bit)::get_by_name({"REG::",mem.get_full_name()},
                                           "NO_MEM_TESTS", 0) != null ||
	      uvm_resource_db#(bit)::get_by_name({"REG::",mem.get_full_name()},
                                           "NO_MEM_WALK_TEST", 0) != null )
      return;
    // Get the skip
    if (!uvm_config_db#(int)::get(null, {"CUSTOM_MEM_WALK::", mem.get_full_name()}, "MAX_SKIP", max_skip))
      max_skip = 0; // By default we do not skip any addresses
    n_bits = mem.get_n_bits();

    // Memories may be accessible from multiple physical interfaces (maps)
    mem.get_maps(maps);


    // Walk the memory via each map
    foreach (maps[j]) begin
      int prev_k = 0;
      uvm_status_e status;
      uvm_reg_data_t  val, exp, v;

      // Only deal with RW memories
      if (mem.get_access(maps[j]) != "RW") continue;

      `uvm_info("uvm_mem_walk_seq", $sformatf("Walking memory %s in map \"%s\" with max address skip of %0d...",
                                              mem.get_full_name(), maps[j].get_full_name(), max_skip), UVM_LOW);

      // The walking process is, for address k:
      // - Write ~k
      // - Read prev_k and expect ~(prev_k) if k > 0
      // - Write prev_k at prev_k
      // - Read k and expect ~k if k == last address
      for (int k = 0; k < mem.get_size(); k+= $urandom_range(max_skip)+1) begin

        mem.write(status, k, ~k, UVM_FRONTDOOR, maps[j], this);

        if (status != UVM_IS_OK) begin
          `uvm_error("uvm_mem_walk_seq", $sformatf("Status was %s when writing \"%s[%0d]\" through map \"%s\".",
                                                   status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
        end

        if (k > 0) begin
          mem.read(status, prev_k, val, UVM_FRONTDOOR, maps[j], this);
          if (status != UVM_IS_OK) begin
            `uvm_error("uvm_mem_walk_seq", $sformatf("Status was %s when reading \"%s[%0d]\" through map \"%s\".",
                                                     status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
          end
          else begin
            exp = ~(prev_k) & ((1'b1<<n_bits)-1);
            if (val !== exp) begin
              `uvm_error("uvm_mem_walk_seq", $sformatf("\"%s[%0d-1]\" read back as 'h%h instead of 'h%h.",
                                                       mem.get_full_name(), k, val, exp));

            end
          end

          mem.write(status, prev_k, prev_k, UVM_FRONTDOOR, maps[j], this);
          if (status != UVM_IS_OK) begin
            `uvm_error("uvm_mem_walk_seq", $sformatf("Status was %s when writing \"%s[%0d-1]\" through map \"%s\".",
                                                     status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
          end
        end

        if (k == mem.get_size() - 1) begin
          mem.read(status, k, val, UVM_FRONTDOOR, maps[j], this);
          if (status != UVM_IS_OK) begin
            `uvm_error("uvm_mem_walk_seq", $sformatf("Status was %s when reading \"%s[%0d]\" through map \"%s\".",
                                                     status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
          end
          else begin
            exp = ~(k) & ((1'b1<<n_bits)-1);
            if (val !== exp) begin
              `uvm_error("uvm_mem_walk_seq", $sformatf("\"%s[%0d]\" read back as 'h%h instead of 'h%h.",
                                                       mem.get_full_name(), k, val, exp));

            end
          end
        end
        prev_k = k;
      end
    end
  endtask
endclass

class memory_access_test extends pulp_sw_base_test#(IO_SIGNAL_COUNT, DUT_SIGNAL_COUNT);
  `uvm_component_utils(memory_access_test)
  `uvm_component_new

    tcdm_adapter reg2tcdm;

  virtual function string get_test_shortname();
    return "Exhaustive Memory Access Test via FC data port";
  endfunction

  virtual function void build_phase(uvm_phase phase);
    //Override Factory to use custom mem walk test
    uvm_factory factory = uvm_factory::get();
    factory.set_type_override_by_type(uvm_mem_single_walk_seq::get_type(), custom_memory_walk_seq::get_type());
    super.build_phase(phase);
  endfunction

  virtual function void configure_env();
    super.configure_env();
    // Put the TCDM agent on the FC's data port into active mode and disable
    // attaching the default ral adapter
    cfg.fc_data_port_agent_cfg.is_active = UVM_ACTIVE;
    cfg.attach_default_ral_adapter       = 0;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Create a new regadapter for the RAL model that connects to the fc data
    // port tcdm agent
    reg2tcdm = tcdm_adapter::type_id::create("reg2tcdm");
    env.regmodel.default_map.set_sequencer(env.fc_data_port_a.sequencer, reg2tcdm);
    env.regmodel.default_map.set_auto_predict(1);
  endfunction

  virtual task main_phase(uvm_phase phase);
    v_seq_memory_access_test seq;
    phase.raise_objection(this);
    // Configure the address skip values for the large memories so the test
    // finishes faster
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.soc.private_bank0.get_full_name()}, "MAX_SKIP", 10);
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.soc.private_bank1.get_full_name()}, "MAX_SKIP", 10);
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.soc.l2_ram.get_full_name()}, "MAX_SKIP", 100);
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.cluster.l1_ram.get_full_name()}, "MAX_SKIP", 500);
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.cluster.weight_mem.weights_mram.get_full_name()}, "MAX_SKIP", 1000);
    uvm_config_db#(int)::set(null, {"CUSTOM_MEM_WALK::",env.regmodel.cluster.weight_mem.weights_sram.get_full_name()}, "MAX_SKIP", 1000);
    seq = v_seq_memory_access_test::type_id::create("seq");

    // Disable access testing on soc and cluster pll since that would interfere
    // with the clock that drives the whole test
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.soc_pll.get_full_name()}, "NO_REG_ACCESS_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.cluster_pll.get_full_name()}, "NO_REG_ACCESS_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.siracusa_ctrl.get_full_name()}, "NO_REG_ACCESS_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.soc.soc_peripherals.i3c0.ctrl.get_full_name()}, "NO_REG_ACCESS_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.soc.soc_peripherals.i3c1.ctrl.get_full_name()}, "NO_REG_ACCESS_TEST", 1);


    uvm_resource_db #(bit)::set({"REG::", env.regmodel.soc_pll.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.cluster_pll.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
    uvm_resource_db #(bit)::set({"REG::", env.regmodel.siracusa_ctrl.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
    seq.start(env.v_sqr);
    phase.drop_objection(this);
  endtask

  virtual task post_main_phase(uvm_phase phase);
    // Do nothing, just prevent the usual end of computation check inmplemented
    // in the base class
  endtask

endclass
