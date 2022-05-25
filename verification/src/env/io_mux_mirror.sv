//-----------------------------------------------------------------------------
// Title : IO-MUX Mirror Component
// -----------------------------------------------------------------------------
// File : io_mux_mirror.sv Author : Manuel Eggimann <meggimann@iis.ee.ethz.ch>
// Created : 09.10.2021
// -----------------------------------------------------------------------------
// Description :
//
// The IO Multiplexer mirror component subscribes to the fabric controllers TCDM
// port to sniff for any reconfiguration attempts on the SoC IO multiplex
// module. Once it detects that the FC tries to change the IO mapping, it
// mirrors the configuration in the IO mux agent. The effect is that the TB
// automatically reconnects the VIPs to the DUT pins. E.g. the FC configures the
// IO-mux to route the I2C0.sck signal to pad 20 -> the IO-MUX mirror component
// detects the intent in the TCDM transaction stream and configures the IO-mux
// agent to connect the I2C0 slave VIP's sck port to DUT pin 20. (To learn more
// about the magic behind these dynamic connections checkout the sourcecode of
// the io-mux agent).
//
//-----------------------------------------------------------------------------
// Copyright (C) 2021 ETH Zurich, University of Bologna Copyright and related
// rights are licensed under the Solderpad Hardware License, Version 0.51 (the
// "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law or
// agreed to in writing, software, hardware and materials distributed under this
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the specific
// language governing permissions and limitations under the License.
// SPDX-License-Identifier: SHL-0.51
// -----------------------------------------------------------------------------

class io_mux_mirror_cfg extends uvm_object;
  int cfg_addr_to_dut_signal_idx_map[uvm_reg_addr_t];
  string cfg_value_to_io_signal_name_map[$][uvm_reg_data_t]; // One map for each dut signal

  `uvm_object_utils_begin(io_mux_mirror_cfg)
    `uvm_field_aa_int_int(cfg_addr_to_dut_signal_idx_map, UVM_DEFAULT)
  `uvm_object_utils_end
  `uvm_object_new

endclass

class io_mux_mirror #(
  parameter int unsigned NUM_IO_SIGNALS,
  parameter int unsigned NUM_DUT_SIGNALS
) extends uvm_subscriber#(tcdm_transaction);
  io_mux_mirror_cfg cfg;
  io_mux_agent#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS) io_mux_a;

  `uvm_component_param_utils_begin(io_mux_mirror#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(io_mux_mirror_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(`gfn, "Failed to obtain config object for io_mux_mirror_cfg.")
  endfunction

  function void write(tcdm_transaction t);
    // Ignore all read transaction and transactions not pointing to the
    // register-of-interest
    if (t.req.is_write && cfg.cfg_addr_to_dut_signal_idx_map.exists(t.req.addr)) begin
      int target_dut_signal_idx;
      string target_io_signal_name;
      int    target_io_signal_idx;
      `uvm_info(`gfn, $sformatf("Detected write transaction to IO mux configuration register: %s", t.sprint()), UVM_HIGH)
      target_dut_signal_idx = cfg.cfg_addr_to_dut_signal_idx_map[t.req.addr];
      if (!cfg.cfg_value_to_io_signal_name_map[target_dut_signal_idx].exists(t.req.write_data)) begin
        `uvm_warning(`gfn, $sformatf("Disconnecting pad idx %0d. Unknown config value %0h.", target_dut_signal_idx, t.req.write_data))
        io_mux_a.cfg.disconnect_dut_signal(target_dut_signal_idx);
      end else begin
        target_io_signal_name = cfg.cfg_value_to_io_signal_name_map[target_dut_signal_idx][t.req.write_data];
        target_io_signal_idx = io_mux_a.cfg.io_signal_name_idx_map[target_io_signal_name];
        `uvm_info(`gfn, $sformatf("The DUT changed the IO multiplex configuration of pad %0d. Now signal '%s' is connected to pad %0d. Updating the IO-MUX agent configuraiton accordingly.", target_dut_signal_idx, target_io_signal_name, target_dut_signal_idx), UVM_MEDIUM)
        io_mux_a.cfg.change_io_signal_connection(target_io_signal_name, target_dut_signal_idx);
        // Put both sides (VIP & DUT) in high-impedance mode by sending appropriate sequence
        // to the IO MUX agent's sequencers and force update the IO
        io_mux_a.dut_driver.vif.drive_en_pin(target_dut_signal_idx, 0);
        io_mux_a.vip_driver.vif.drive_en_pin(target_io_signal_idx, 0);
        io_mux_a.vip_monitor.force_update();
        io_mux_a.dut_monitor.force_update();
      end
    end
  endfunction
endclass
