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


class jtag_chain_translation_seq extends uvm_sequence #(jtag_item);
  jtag_tap chain[$];
  jtag_tap tap_name_tap_map[string];

  jtag_chain_sequencer up_sequencer;


  `uvm_object_utils(jtag_chain_translation_seq)
  `uvm_object_new

  virtual task body();
    jtag_chain_item chain_item;
    jtag_chain_item chain_rsp;
    jtag_item item;
    jtag_item rsp;
    int selected_tap_idx                      = -1;
    logic [JTAG_MAX_IR_WIDTH-1:0] selected_ir = 0;
    int                           new_tap_idx;
    `uvm_info(`gfn, "JTAG chain translations sequence started", UVM_HIGH)
    forever begin
      up_sequencer.get_next_item(chain_item);
      $cast(chain_rsp, chain_item.clone());
      chain_rsp.set_id_info(chain_item);
      if (!tap_name_tap_map.exists(chain_item.tap_name))
        `uvm_fatal(`gfn, $sformatf("Unknown TAP name %s.", chain_item.tap_name));

      `uvm_info(`gfn, $sformatf("Received JTAG chain transaction: %s", chain_item.sprint()), UVM_HIGH)
      item        = jtag_item::type_id::create("jtag_item");
      item.ir_len = 0;
      item.ir     = '0;

      foreach(chain[i]) begin
        item.ir_len                         += chain[i].ir_length;
        item.ir                             <<= chain[i].ir_length;
        if (chain[i].tap_name == chain_item.tap_name) begin
          item.dr_len += chain_item.dr_len;
          item.dr     <<= chain_item.dr_len;
          // Only constant expression allowed for array slice assignments so we need a for loop
          for (int j = 0; j < chain_item.dr_len; j++) begin
            item.dr[j] = chain_item.dr[j];
          end
          for (int j = 0; j < chain[i].ir_length; j++) begin
            item.ir[j] = chain_item.ir[j];
          end
          new_tap_idx = i;
        end else begin
          item.dr_len += 1;
          item.dr     <<= 1;
          item.dr[0]   = 1'b0;
          // Select bypass register
          for (int j = 0; j < chain[i].ir_length; j++) begin
            item.ir[j] = 1'b1;
          end
        end
      end
      if (item.ir_len > JTAG_MAX_IR_WIDTH)
        `uvm_fatal(`gfn, $sformatf("Total IR length of the configured JTAG chain is larger then the maximum (%0d)", JTAG_MAX_IR_WIDTH));
      // Scan-in the IR if necessary
      if (chain_item.force_select_ir || new_tap_idx != selected_tap_idx || chain_item.ir != selected_ir) begin
        item.select_ir = 1;
        `uvm_send(item)
        item.select_ir = 0;
        get_response(rsp, item.get_transaction_id); // We ignore the response
                                // from the select_ir operation
      end
      selected_ir      = chain_item.ir;
      selected_tap_idx = new_tap_idx;
      `uvm_send(item)
      get_response(rsp, item.get_transaction_id);
      for (int j = 0; j < chain_item.dr_len; j++) begin
        chain_rsp.dout[j] = rsp.dout[chain.size()-new_tap_idx-1+j];
      end
      up_sequencer.item_done(chain_rsp);
    end
  endtask
endclass
