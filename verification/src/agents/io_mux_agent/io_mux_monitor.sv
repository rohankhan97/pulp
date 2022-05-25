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

class io_mux_monitor #(parameter int unsigned NUM_SIGNALS=0) extends uvm_monitor;
  uvm_analysis_port #(io_mux_activity_item) item_collected_port;
  io_mux_sequencer driving_sqr;
  event e_force_update;

  virtual pins_if #(.Width(NUM_SIGNALS)) vif;

  `uvm_component_param_utils(io_mux_monitor#(NUM_SIGNALS))
  function new (string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pins_if #(.Width(NUM_SIGNALS)))::get(this, "", "vif", vif))
      `uvm_fatal(`gfn, "Failed to obtain handle to vif from config_db");
  endfunction

  virtual task run_phase(uvm_phase phase);
    for (int i = 0; i < NUM_SIGNALS; i++) begin
      automatic int j = i;
      fork
        process_pin_change(j);
      join_none
    end
    wait fork;
  endtask

  function void force_update();
    ->e_force_update;
  endfunction

  virtual task automatic process_pin_change(int pin_idx);
    io_mux_activity_item item;
    io_mux_simple_drive_seq#(NUM_SIGNALS) drive_seq;
    io_mux_no_drive_seq#(NUM_SIGNALS) no_drive_seq;
    forever begin
      @(vif.pins[pin_idx], e_force_update);
      // Only react if the change was not caused by the IO mux agent itself. We
      // can distinguish the two cases by the value of the out enable signal. It
      // is asserted if the pin value change was caused by the IO-mux agent.
      if (!vif.pins_oe[pin_idx]) begin
        `uvm_info(`gfn, $sformatf("Pin %0d changed or was force updated. Sending item to analysis port.", pin_idx), UVM_HIGH)
        item            = io_mux_activity_item::type_id::create("pin_monitor_item", this);
        item.signal_idx = pin_idx;
        item.value      = vif.pins[pin_idx];
        item_collected_port.write(item);
        `uvm_info(`gfn, "Sending the item to the driving sequencer...", UVM_HIGH)
        if (vif.pins[pin_idx] === 1'bz) begin
          no_drive_seq = io_mux_no_drive_seq#(NUM_SIGNALS)::type_id::create($sformatf("pin%0d_no_drive_seq", pin_idx));
          no_drive_seq.signal_idx = pin_idx;
          no_drive_seq.start(driving_sqr);
        end else begin
          drive_seq = io_mux_simple_drive_seq#(NUM_SIGNALS)::type_id::create($sformatf("pin%0d_drive_seq", pin_idx));
          drive_seq.signal_idx = pin_idx;
          drive_seq.value      = vif.pins[pin_idx];
          drive_seq.start(driving_sqr);
        end
        `uvm_info(`gfn, "Done sending item.", UVM_HIGH);
      end
    end
  endtask

endclass
