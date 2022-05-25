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

class tcdm_master_driver extends uvm_driver#(tcdm_req_seq_item, tcdm_rsp_seq_item);
  virtual tcdm_if vif;

  `uvm_component_utils(tcdm_master_driver)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual tcdm_if)::get(this, "", "vif", vif))
      `uvm_fatal(`gfn, "Failed to get virtual tcdm interface handle")
  endfunction

  task automatic drive_item_and_get_response(input tcdm_req_seq_item req, output tcdm_rsp_seq_item rsp);
    rsp = tcdm_rsp_seq_item::type_id::create("rsp");
    rsp.set_id_info(req);
    vif.force_req(1'b1);
    vif.force_addr(req.addr);
    vif.force_wen(~req.is_write);
    vif.force_wdata(req.write_data);
    vif.force_be(req.be);
    // Wait for the grant
    while(vif.gnt != 1'b1) begin
      vif.wait_clks(1);
    end
    vif.force_req(1'b0);
    #1;
    // Now wait for the r_valid if not already present
    while (vif.r_valid != 1'b1) begin
      vif.wait_clks(1);
      #1;
    end
    rsp.read_data = vif.r_rdata;
    rsp.r_opc     = vif.r_opc;
  endtask

  task reset_if();
    vif.force_req(1'b0);
    vif.force_addr(32'b0);
    vif.force_wen(1'b0);
    vif.force_wdata(32'b0);
    vif.force_be(3'b0);
  endtask

  task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    reset_if();
  endtask

  task run_phase(uvm_phase phase);
    tcdm_req_seq_item req;
    tcdm_rsp_seq_item rsp;
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(`gfn, $sformatf("Received new item to drie to tcdm if:\n%s", req.sprint()), UVM_HIGH)
      drive_item_and_get_response(req, rsp);
      seq_item_port.item_done(rsp);
    end
  endtask
endclass
