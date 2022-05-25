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


class tcdm_slave_agent extends uvm_agent;
  tcdm_slave_agent_cfg cfg;
  tcdm_monitor monitor;
  tcdm_slave_driver  driver;
  tcdm_slave_sequencer sequencer;

  `uvm_component_utils_begin(tcdm_slave_agent)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = tcdm_monitor::type_id::create("monitor", this);
    if (cfg.is_active == UVM_ACTIVE) begin
      sequencer = tcdm_slave_sequencer::type_id::create("sequencer", this);
      driver = tcdm_slave_driver::type_id::create("driver", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      monitor.m_req_port.connect(sequencer.m_request_export);
    end
  endfunction
endclass
