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


class reg2dmi_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg2dmi_adapter)

  function new(string name = "reg2dmi_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses = 1;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op  rw);
    jtag_riscv_dmi_access_item item = jtag_riscv_dmi_access_item::type_id::create("dmi_access");
    item.address                    = rw.addr;
    item.is_write                   = (rw.kind == UVM_READ)? 0: 1;
    item.data                       = rw.data;
    item.retry                      = 1;
    return item;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    jtag_riscv_dmi_access_item item;
    if (!$cast(item, bus_item)) begin
      `uvm_fatal(`gfn, "Provided bus_item is not of type jtag_chain_item");
      return;
    end
    rw.kind   = item.is_write? UVM_WRITE: UVM_READ;
    rw.addr   = item.address;
    rw.data   = item.rsp_data;
    rw.status = item.error? UVM_NOT_OK: UVM_IS_OK;
  endfunction

endclass
