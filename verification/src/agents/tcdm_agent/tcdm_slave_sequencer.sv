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

class tcdm_slave_sequencer extends uvm_sequencer#(tcdm_rsp_seq_item);
  uvm_analysis_export #(tcdm_req_seq_item) m_request_export;
  uvm_tlm_analysis_fifo #(tcdm_req_seq_item) m_request_fifo;

  `uvm_component_utils(tcdm_slave_sequencer)

  function new(string name="tcdm_slave_sequencer", uvm_component parent);
    super.new(name, parent);
    m_request_export = new("m_request_export", this);
    m_request_fifo = new("m_request_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_request_export.connect(m_request_fifo.analysis_export);
  endfunction

endclass
