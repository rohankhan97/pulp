//-----------------------------------------------------------------------------
// Title         : Virtual Stdout Monitor
//-----------------------------------------------------------------------------
// File          : vstdout_monitor.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 08.10.2021
//-----------------------------------------------------------------------------
// Description :
//
// This uvm component implements a translation montior component that subscribes
// to TCDM transations originatig from e.g. the Fabric controllers data port and
// filters them for write transactions to the virtual stdout address. The
// monitor assembles the complete string (terminated by the newline characters)
// and sends the result through his Analsys port.
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

class vstdout_monitor extends uvm_subscriber#(tcdm_transaction);
  vstdout_monitor_cfg cfg;
  uvm_analysis_port#(vstdout_seq_item) ap;
  byte channel_buffers[string][$];

  `uvm_component_utils(vstdout_monitor)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vstdout_monitor_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn,"Failed to obtain vstdout configuration object from config db.")
    ap = new("ap", this);
  endfunction

  function void write(tcdm_transaction t);
    string channel_name;
    byte   channel_buffer[$];
    vstdout_seq_item item;
    // Check if it is a write transaction and the target address is in the map of registered channels
    if (t.req.is_write && cfg.address_to_channel_name_map.exists(t.req.addr)) begin
      channel_name = cfg.address_to_channel_name_map[t.req.addr];
      `uvm_info(`gfn, $sformatf("Received new character 0x%02h on channel %s",t.req.write_data, channel_name),UVM_HIGH)
      // Check if the value is the newline character (0x0a)
      if (32'h0a != t.req.write_data) begin
        channel_buffers[channel_name].push_back(t.req.write_data);
      end else begin
        item              = vstdout_seq_item::type_id::create("vstdout_item");
        item.channel_name = channel_name;
        item.message      = "";
        channel_buffer = channel_buffers[channel_name];
        foreach(channel_buffer[i]) begin
          item.message = {item.message, string'(channel_buffers[channel_name][i])};
        end
        `uvm_info($sformatf("Stdout [%s]", item.channel_name), item.message, UVM_MEDIUM)
        channel_buffers[channel_name].delete();
        ap.write(item);
      end
    end
  endfunction
endclass
