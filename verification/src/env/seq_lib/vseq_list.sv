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

`include "siracusa_vseq_base.sv"
`include "v_seq_siracusa_hard_reset.sv"
`include "v_seq_siracusa_boot_jtag.sv"
`include "v_seq_siracusa_boot_backdoor.sv"
`include "v_seq_siracusa_wait_eoc.sv"
`include "v_seq_siracusa_check_CPI_frame.sv"
