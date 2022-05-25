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


class siracusa_sw_cpi_test extends pulp_sw_backdoor_boot_test;

  `uvm_component_utils(siracusa_sw_cpi_test)

  // virtual interface typedefs 
  virtual cpi_if#(10) cpi_if;

  extern function new( string name , uvm_component parent );
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

endclass: siracusa_sw_cpi_test

// Function definition
function siracusa_sw_cpi_test :: new(string name , uvm_component parent);
  super.new(name, parent);
endfunction : new

function void siracusa_sw_cpi_test :: build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task siracusa_sw_cpi_test :: run_phase(uvm_phase phase);
  v_seq_siracusa_check_CPI_frame vseq_CPI_check = v_seq_siracusa_check_CPI_frame::type_id::create("v_seq_siracusa_check_CPI_frame");

  phase.raise_objection(this);

  vseq_CPI_check.frame_addr = 32'h1C0100f0;
  // the cpi sequencer is not part of the virtual sequencer, therefore, I created a handle to the sequencer in the sequence, 
  // and I am assigning it here
  vseq_CPI_check.cpi_sequencer =  env.cpi_a[0].vip_sequencer;
  // this is starting all the sequencers
  vseq_CPI_check.start(env.v_sqr);
  `uvm_info(`gfn, "Frame check finished.", UVM_MEDIUM);

  phase.drop_objection(this);
endtask : run_phase
