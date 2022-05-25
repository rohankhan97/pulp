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

class tcdm_slave_driver extends uvm_driver#(tcdm_rsp_seq_item);
  virtual tcdm_if vif;

  `uvm_component_utils(tcdm_slave_driver)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual tcdm_if)::get(this, "", "vif", vif))
      `uvm_fatal(`gfn, "Failed to obtain virtual tcdm interface handle")
  endfunction

  task reset_if();
    vif.force_gnt(1'b0);
    vif.force_r_opc(1'b0);
    vif.force_r_rdata(32'b0);
    vif.force_r_valid(1'b0);
  endtask

  task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    reset_if();
  endtask

  task automatic drive_item(tcdm_rsp_seq_item item);
    // Check if there is indeed a pending request
    if (vif.req != 1'b1)
      `uvm_warning(`gfn, "Received TCDM response item although there is no pending request on this interface!")
    vif.wait_clks(item.gnt_delay);
    vif.force_gnt(1'b1);
    vif.wait_clks(1);
    vif.force_gnt(1'b0);
    vif.wait_clks(item.r_valid_delay);
    vif.force_r_rdata(item.read_data);
    vif.force_r_opc(item.r_opc);
    vif.force_r_valid(1'b1);
    vif.wait_clks(1'b1);
    reset_if();
  endtask

  task run_phase(uvm_phase phase);
    tcdm_rsp_seq_item item;
    forever begin
      seq_item_port.get_next_item(item);
      `uvm_info(`gfn, $sformatf("Received new response item to drive to tcdm if:\n%s", req.sprint()), UVM_HIGH)
      drive_item(item);
      seq_item_port.item_done(item);
    end
  endtask
endclass
