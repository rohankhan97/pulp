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

// This interface makes use of port-coercion to drive signals in both
// directions. SystemVerilog allows input ports to be coerced to an output port
// if the port is driven from the inside. We leverage this detail to achieve
// bidirectional interface ports.
interface tcdm_if(
  input logic        clk,
  input logic        rst_n,
  ref logic          req,
  ref logic [31:0] addr,
  ref logic        wen,
  ref logic [31:0] wdata,
  ref logic [3:0]  be,
  ref logic        gnt,
  ref logic        r_opc,
  ref logic [31:0] r_rdata,
  ref logic        r_valid
);

  clocking cb @(posedge clk);
  endclocking

  clocking cbn @(negedge clk);
  endclocking

  // Wait for 'n' clocks based of postive clock edge
  task automatic wait_clks(int num_clks);
    repeat (num_clks) @(posedge clk);
  endtask

  // Wait for 'n' clocks based of negative clock edge
  task automatic wait_n_clks(int num_clks);
    repeat (num_clks) @cbn;
  endtask

  // wait for rst_n to assert and then deassert
  task automatic wait_for_reset(bit wait_negedge = 1'b1, bit wait_posedge = 1'b1);
    if (wait_negedge && ($isunknown(rst_n) || rst_n === 1'b1)) @(negedge rst_n);
    if (wait_posedge && (rst_n === 1'b0)) @(posedge rst_n);
  endtask

  task force_req(logic value);
    force req = value;
  endtask

  task release_req();
    release req;
  endtask

  task force_addr(logic[31:0] value);
    force addr = value;
  endtask

  task release_add();
    release addr;
  endtask

  task force_wen(logic value);
    force wen = value;
  endtask

  task release_wen();
    release wen;
  endtask

  task force_wdata(logic [31:0] value);
    force wdata = value;
  endtask

  task release_wdata();
    release wdata;
  endtask

  task force_be(logic [3:0] value);
    force be = value;
  endtask

  task release_be();
    release be;
  endtask

  task force_gnt(logic value);
    force gnt = value;
  endtask

  task release_gnt();
    release gnt;
  endtask

  task force_r_opc(logic value);
    force r_opc = value;
  endtask

  task release_r_opc();
    release r_opc;
  endtask

  task force_r_rdata(logic [31:0] value);
    force r_rdata = value;
  endtask

  task release_r_rdata();
    release r_rdata;
  endtask

  task force_r_valid(logic value) ;
    force r_valid = value;
  endtask

  task release_r_valid();
    release r_valid;
  endtask

endinterface
