//-----------------------------------------------------------------------------
// Title         : Sequence to wait for end of computation
//-----------------------------------------------------------------------------
// File          : v_seq_siracusa_wait_eoc.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 07.10.2021
//-----------------------------------------------------------------------------
// Description :
//
// This sequence monitors the eoc register in APB SoC control using through
// hiearchy active monitoring and issues an error if main did not return with
// exit code 0.
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


class v_seq_siracusa_wait_eoc extends siracusa_vseq_base;
  `uvm_object_utils(v_seq_siracusa_wait_eoc)
  `uvm_object_new

  logic[30:0] expected_exit_code = 0;

  virtual task do_body();
    uvm_status_e status;
    active_monitor_backdoor bkdr;
    apb_soc_ctrl_corestatus corestatus;
    `uvm_info(`gfn, "Waiting for end of computation...", UVM_MEDIUM);
    corestatus = regmodel.soc.soc_peripherals.apb_soc_ctrl.corestatus;
    if (!$cast(bkdr, corestatus.get_backdoor()))
      `uvm_fatal(`gfn, "Wrong memory backdoor type. The memory backdoor registered with the corestatus register must be of type active_monitor_backdoor.")
    corestatus.mirror(status, .parent(this), .path(UVM_BACKDOOR));
    while(corestatus.eoc.get() != 1'b1) begin
      bkdr.wait_for_change(corestatus);
      corestatus.mirror(status, .parent(this), .path(UVM_BACKDOOR));
      if (status != UVM_IS_OK) begin
        `uvm_error(`gfn, "Failed to mirror the corestatus register using backdoor mechanism")
      end
    end
    if (corestatus.exit_code.get()   != expected_exit_code)
      `uvm_error(`gfn, $sformatf("Software execution on the fabric controller terminated with wrong exit code: %0d", corestatus.exit_code.get()))
    else
      `uvm_info(`gfn, $sformatf("Software execution on the fabric controller terminated with correct exit code: %0d", corestatus.exit_code.get()), UVM_MEDIUM)
  endtask
endclass
