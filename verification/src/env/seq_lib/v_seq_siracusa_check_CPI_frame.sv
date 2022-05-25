// -----------------------------------------------------------------------------
// Copyright (C) 2021 ETH Zurich
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
//                http://solderpad.org/licenses/SHL-0.51. 
// Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// -----------------------------------------------------------------------------
// Author : Alfio Di Mauro (adimauro) adimauro@ethz.ch
// File   : v_seq_siracusa_check_CPI_frame.sv
// Create : 2021-10-21 15:00:30
// Revise : 2021-10-21 23:45:40
// Editor : sublime text3
// -----------------------------------------------------------------------------
// Description:
// -----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Title         : Sequence to verify a CPI frame into the memory
//-----------------------------------------------------------------------------
// File          : v_seq_siracusa_check_CPI_frame.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
//               : Alfio Di Mauro <adimauro@iis.ee.ethz.ch>
// Created       : 07.10.2021
//-----------------------------------------------------------------------------
// Description :
//
// This sequence monitors the status register of the CPI and then check a certain memory region
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


class v_seq_siracusa_check_CPI_frame extends siracusa_vseq_base;
  `uvm_object_utils(v_seq_siracusa_check_CPI_frame)
  `uvm_object_new

  cpi_sequencer cpi_sequencer;

  logic [31:0] frame_addr = 0;
  logic [FRAME_LINES*LINE_PIXELS/2:0][31:0] golden_frame;
  uvm_event FRAME_EVT = uvm_event_pool::get_global("FRAME_EVT");

  uvm_reg_data_t rd_space;

  virtual task do_body();
    uvm_status_e status;
    active_monitor_backdoor bkdr;
    udma_cpi_rx_size rx_size;
    uvm_mem burst_target_mem;
    uvm_reg_addr_t mem_offset;
    cpi_base_seq cpi_frame_seq = cpi_base_seq::type_id::create("cpi_frame_seq");
    cpi_frame_item frame_item = cpi_frame_item::type_id::create("cpi_frame_item");
    logic [31:0] pixel_pair;
    int errors;

    rx_size = regmodel.soc.soc_peripherals.pulp_io.rx_size;
    // rd_space = new[FRAME_LINES*LINE_PIXELS/2];

    fork
      begin: CPI_frame_start
        `uvm_info(`gfn, "CPI frame sequence start...", UVM_MEDIUM)
        cpi_frame_seq.start(cpi_sequencer);
      end

      begin: Backdoor_access

        if (!$cast(bkdr, rx_size.get_backdoor()))
          `uvm_fatal(`gfn, "Wrong memory backdoor type. The memory backdoor registered with the rx_size register must be of type active_monitor_backdoor.")
        rx_size.mirror(status, .parent(this), .path(UVM_BACKDOOR));

        // this has to be repeated as many times as the frames
        for (int i = 0; i < TRANSACTIONS; i++) begin
          errors = FRAME_LINES*LINE_PIXELS/2;
          `uvm_info(`gfn, "Sending the trigger event", UVM_MEDIUM);
          FRAME_EVT.trigger();
          // get the current item value
          `uvm_info(`gfn, "Waiting for the off trigger event", UVM_MEDIUM);
          FRAME_EVT.wait_off();
          `uvm_info(`gfn, "Received off trigger event", UVM_MEDIUM)
          frame_item = cpi_frame_seq.current_item;
          if (frame_item == null) begin
            `uvm_error(`gfn, "Failed to retrieve the current frame item")
          end

          // wait for the firmware to program the uDMA CPI rn channel, backdor monitoring it...
          `uvm_info(`gfn, "Waiting for size register to change...", UVM_MEDIUM);
          while(rx_size.get() <= 4) begin
            bkdr.wait_for_change(rx_size);
            rx_size.mirror(status, .parent(this), .path(UVM_BACKDOOR));
            if (status != UVM_IS_OK) begin
              `uvm_error(`gfn, "Failed to mirror the corestatus register using backdoor mechanism")
            end
          end
          // detected the uDMA CPI channel programming, now waiting for the "byte_left" register to go back to 0 (< 4 as transfers are 32 bit aligned)
          `uvm_info(`gfn, "uDMA programmed for frame transfer, waiting for size regiter to become 0...", UVM_MEDIUM);
          while(rx_size.get() > 4) begin
            bkdr.wait_for_change(rx_size);
            rx_size.mirror(status, .parent(this), .path(UVM_BACKDOOR));
            if (status != UVM_IS_OK) begin
              `uvm_error(`gfn, "Failed to mirror the corestatus register using backdoor mechanism")
            end
          end
          // transfer end detected
          `uvm_info(`gfn, "Detected uDMA frame transmission end", UVM_LOW);

          // checking the memory content through the backdor access
          burst_target_mem = regmodel.top_map.get_mem_by_offset(frame_addr);
          mem_offset = burst_target_mem.get_address(.offset(0), .map(regmodel.top_map));
          for (int i = 0; i < FRAME_LINES*LINE_PIXELS/2; i++) begin
            burst_target_mem.read(status, (frame_addr-mem_offset)/4 + i, rd_space, .parent(this), .path(UVM_BACKDOOR));
            // `uvm_info(`gfn,$sformatf("pixel %0d: expected %0b, got %0b",i,{6'b000000,frame_item.pdata[i/LINE_PIXELS][i*2],6'b000000,frame_item.pdata[i/LINE_PIXELS][2*i+1]},rd_space),UVM_LOW)
            pixel_pair = {6'b000000,frame_item.pdata[i/LINE_PIXELS][i*2],6'b000000,frame_item.pdata[i/LINE_PIXELS][2*i+1]};
            if (pixel_pair != rd_space) begin
              `uvm_error(`gfn,$sformatf("pixels [%0d][%0d,%0d]: expected %0x, got %0x",i/LINE_PIXELS,i*2,i*2+1,pixel_pair,rd_space))
            end else begin
              errors = errors-1;
            end
          end
          if (status != UVM_IS_OK)
            `uvm_error(`gfn, "Burst Read failed!")

          if (errors != 0)
            `uvm_error(`gfn, $sformatf("errors = %0d, possible mismatch between sent and received lines.",errors))
        end
      end
    join




    //if (corestatus.exit_code.get()   != expected_exit_code)
    //  `uvm_error(`gfn, $sformatf("Software execution on the fabric controller terminated with wrong exit code: %0d", corestatus.exit_code.get()))
    //else
    //  `uvm_info(`gfn, $sformatf("Software execution on the fabric controller terminated with correct exit code: %0d", corestatus.exit_code.get()), UVM_MEDIUM)
  endtask
endclass
