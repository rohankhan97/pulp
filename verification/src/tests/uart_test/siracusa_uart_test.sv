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

class siracusa_uart_test extends pulp_sw_backdoor_boot_test;
  string expected_string = "Stay at home!!!";
  `uvm_component_utils_begin(siracusa_uart_test)
    `uvm_field_string(expected_string, UVM_DEFAULT)
  `uvm_component_utils_end
  `uvm_component_new

  uvm_in_order_class_comparator#(uart_item) uart_scoreboard;
  uvm_analysis_port#(uart_item) expected_uart_traffic_port;

  virtual function string get_test_shortname();
    return "UART peripheral Test using backdoor boot mechnism";
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uart_scoreboard = new("uart_scoreboard", this);
    expected_uart_traffic_port = new("expected_uart_traffic_port", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    env.uart_a[0].monitor.tx_analysis_port.connect(uart_scoreboard.after_export);
    expected_uart_traffic_port.connect(uart_scoreboard.before_export);
  endfunction

  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.reset_phase(phase);
    cfg.uart_agent_cfg[0].reset_asserted();
    phase.drop_objection(this);
  endtask

  virtual task post_reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.post_reset_phase(phase);
    cfg.uart_agent_cfg[0].reset_deasserted();
    phase.drop_objection(this);
  endtask

  virtual task pre_configure_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.pre_configure_phase(phase);
    `uvm_info(`gfn, $sformatf("Configuring scoreboard for expected string '%s' over UART0 using 8N1 at 1 Mbaud config.", expected_string), UVM_MEDIUM)
    // Configure the uart agent for 8N1 operation @ 115200 baud
    cfg.uart_agent_cfg[0].set_baud_rate(BaudRate115200);
    cfg.uart_agent_cfg[0].set_parity(0, 0);
    // Write expected UART transmit data to the scoreboard port
    foreach(expected_string[i]) begin
      uart_item item;
      item      = uart_item::type_id::create("item");
      item.data = expected_string[i];
      expected_uart_traffic_port.write(item);
    end
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    int characters_received_count = uart_scoreboard.m_matches+uart_scoreboard.m_mismatches;
    super.report_phase(phase);
    `uvm_info(`gfn, $sformatf("UART scoreboard stats: %0d missmatches, %0d matches.", uart_scoreboard.m_mismatches, uart_scoreboard.m_matches), UVM_MEDIUM)
    if (characters_received_count != expected_string.len()) begin
      `uvm_error(`gfn, $sformatf("Did not receive all characters from UART monitor. Was %0d instead of %0d.", characters_received_count, expected_string.len()))
    end
  endfunction

endclass
