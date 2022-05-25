/*****************************************************************************
 *
 * Copyright 2007-2021 Mentor Graphics Corporation
 * All Rights Reserved.
 *
 * THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE
 * PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT
 * TO LICENSE TERMS.
 *
 *****************************************************************************/

// Package: siracusa_i3c_sequence_pkg
//
// This package imports uvm_pkg, mvc_pkg, mgc_i3c_pkg.
// It includes all the required sequences.

package siracusa_i3c_sequence_pkg;
  `include "i3c_defs.svh"
  `include "uvm_macros.svh"
  
  import uvm_pkg::*;
  import mvc_pkg::*;
  import QUESTA_MVC::*;
  import mgc_i3c_pkg::*;
  import mgc_i3c_sdr_seq_pkg::*;
  import mgc_i3c_hdr_seq_pkg::*;
  import mgc_i3c_legacy_i2c_seq_pkg::*;
  import siracusa_i3c_env_pkg::*;

  typedef enum int { FAIL, PASS, SKIP } result_t;
  
  `define I3C_QVIP_CTS_ERR(x)   \
  begin                     \
    `uvm_error(test_num, x) \
    $fdisplay(mcd, x);      \
    ++num_err;              \
  end                       

  `include "../cts_structure.txt"

  `include "slave/slv_base_seq.svh"
  `include "slave/slv_ibi_seq.svh"
  `include "slave/slv_virtual_seq.svh"
  `ifdef TLM_MASTER
    `include "dummy_master_dut/bus_operation_tests/mst_bus_start_seq.svh"
    `include "dummy_master_dut/bus_operation_tests/mst_bus_repeated_start_seq.svh"
    `include "dummy_master_dut/bus_operation_tests/mst_bus_stop_seq.svh"
    `include "dummy_master_dut/bus_operation_tests/mst_wr_rd_tbit_seq.svh"
    `include "dummy_master_dut/bus_operation_tests/mst_sda_arbitration_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_bcst_enec_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_bcst_disec_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_bcst_rstdaa_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_bcst_entdaa_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_enec_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_disec_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_rstdaa_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_setdasa_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_setnewda_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_getpid_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_getbcr_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_getdcr_seq.svh"
    `include "dummy_master_dut/ccc_tests/mst_dird_getstatus_seq.svh"
  `endif
  `include "slave/bus_operation_tests/slv_bus_start_seq.svh"
  `include "slave/bus_operation_tests/slv_bus_repeated_start_seq.svh"
  `include "slave/bus_operation_tests/slv_bus_stop_seq.svh"
  `include "slave/bus_operation_tests/slv_wr_rd_tbit_seq.svh"
  `include "slave/ccc_tests/slv_bcst_rstdaa_seq.svh"
  `include "slave/ccc_tests/slv_bcst_entdaa_seq.svh"
  `include "slave/ccc_tests/slv_dird_rstdaa_seq.svh"
  `include "slave/ccc_tests/slv_dird_setnewda_vseq.svh"
  `include "slave/ccc_tests/slv_dird_getpid_vseq.svh"
  `include "slave/ccc_tests/slv_dird_getbcr_vseq.svh"
  `include "slave/ccc_tests/slv_dird_getdcr_vseq.svh"
  `include "slave/ccc_tests/slv_dird_getstatus_vseq.svh"
  `ifdef MULTIPLE_SLAVE
    `include "slave/bus_operation_tests/slv_sda_arbitration_seq.svh"
    `include "slave/ccc_tests/slv_bcst_enec_seq.svh"
    `include "slave/ccc_tests/slv_bcst_disec_seq.svh"
    `include "slave/ccc_tests/slv_dird_enec_vseq.svh"
    `include "slave/ccc_tests/slv_dird_disec_vseq.svh"
    `include "slave/ccc_tests/slv_dird_setdasa_vseq.svh"
  `endif

endpackage
