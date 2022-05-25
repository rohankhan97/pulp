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

class tcdm_adapter extends uvm_reg_adapter;
  `uvm_object_utils(tcdm_adapter)

  function new(string name = "tcdm_adapter");
    super.new(name);
    supports_byte_enable = 1;
    provides_responses   = 1;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    tcdm_req_seq_item item          = tcdm_req_seq_item::type_id::create("tcdm_request");
    item.addr                       = rw.addr;
    item.be                         = rw.byte_en;
    if (rw.kind == UVM_WRITE) begin
      item.write_data = rw.data;
      item.is_write   = 1'b1;
    end else begin
      item.is_write = 1'b0;
    end
    return item;
  endfunction


  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    tcdm_rsp_seq_item rsp;
    if (!$cast(rsp, bus_item))
      `uvm_fatal(`gfn, "Provided bus_item is not of type tcdm_transaction!")
    if (rw.kind == UVM_READ) begin
      rw.data   = rsp.read_data;
    end
    rw.status = (rsp.r_opc != '0)? UVM_NOT_OK : UVM_IS_OK;
  endfunction
endclass
