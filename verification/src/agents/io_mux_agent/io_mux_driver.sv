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

class io_mux_driver #(parameter int unsigned NUM_SIGNALS=0)  extends uvm_driver#(io_mux_seq_item);
  io_mux_driver_cfg cfg;
  io_mux_seq_item s_item;
  virtual pins_if #(.Width(NUM_SIGNALS)) vif;

  `uvm_component_param_utils_begin(io_mux_driver#(NUM_SIGNALS))
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pins_if #(.Width(NUM_SIGNALS)))::get(this, "", "vif", vif))
      `uvm_fatal(`gfn, "Failed to get pins_if handle from uvm_config_db");
    if (!uvm_config_db#(io_mux_driver_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn, "Faield to obtain cfg from uvm_config_db")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(s_item);
      `uvm_info(`gfn, $sformatf("Received new item to drive to pins:\n%s", s_item.sprint()), UVM_HIGH);
      drive_item(s_item);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(input io_mux_seq_item item);
    int output_idx;
    if (cfg.signal_mapping.exists(item.signal_idx)) begin
      output_idx = cfg.signal_mapping[item.signal_idx];
    end else begin
      `uvm_info(`gfn, $sformatf("Ignoring drive from unmapped signal idx %0d.", item.signal_idx), UVM_HIGH)
      return;
    end
    if (output_idx >= 0 && output_idx < NUM_SIGNALS) begin
      if (!item.tx_en) begin
        vif.drive_en_pin(output_idx, 0);
      end else begin
        `uvm_info(`gfn, $sformatf("Driving %0b to pin (idx: %0d).", item.value, output_idx), UVM_HIGH)
        vif.drive_pin(output_idx, item.value);
      end
      vif.set_pulldown_en_pin(output_idx, item.pd_en);
      vif.set_pullup_en_pin(output_idx, item.pu_en);
    end else begin
      `uvm_info(`gfn, $sformatf("Ignoring toggle on pin idx %0d since the signal is disconnected (target idx %0d).", item.signal_idx, output_idx), UVM_HIGH)
    end
  endtask

endclass
