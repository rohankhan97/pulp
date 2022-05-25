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

class tcdm_monitor extends uvm_monitor;
  virtual tcdm_if vif;

  uvm_analysis_port #(tcdm_transaction) m_bus_port; // Full transaction
  uvm_analysis_port #(tcdm_req_seq_item) m_req_port; // requests

  `uvm_component_utils(tcdm_monitor)

  function new(string name="tcdm_monitor", uvm_component parent);
    super.new(name, parent);
    m_bus_port = new("m_bus_port", this);
    m_req_port = new("m_req_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual tcdm_if)::get(this, "", "vif", vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to virtual TCDM interface")
  endfunction

  task run_phase(uvm_phase phase);
    tcdm_req_seq_item req;
    tcdm_rsp_seq_item rsp;
    tcdm_transaction tx;
    forever begin
      @vif.cb;
      if (vif.req) begin
        // new pending request
        req            = tcdm_req_seq_item::type_id::create("req");
        req.addr       = vif.addr;
        req.write_data = vif.wdata;
        req.is_write   = ~vif.wen;
        req.be         = vif.be;
        `uvm_info(`gfn, $sformatf("New TCDM request:\n%s", req.sprint()), UVM_HIGH)
        rsp               = tcdm_rsp_seq_item::type_id::create("rsp");
        rsp.gnt_delay     = 0;
        rsp.r_valid_delay = 0;
        m_req_port.write(req);
        // Wait for the gnt on the bus
        while (vif.gnt != 1'b1) begin
          @vif.cb;
          rsp.gnt_delay++;
        end
        // Now wait for the r_valid
        do begin
          @vif.cb;
          rsp.r_valid_delay++;
          end while(vif.r_valid != 1'b1);
        rsp.r_opc               = vif.r_opc;
        rsp.read_data           = vif.r_rdata;
        tx                      = tcdm_transaction::type_id::create("tx");
        tx.req                  = req;
        tx.rsp                  = rsp;
        `uvm_info(`gfn, $sformatf("TCDM transaction:\n%s", tx.sprint()), UVM_HIGH)
        m_bus_port.write(tx);
      end
    end
  endtask
endclass
