package siracusa_i3c_env_pkg;

  localparam string s_tb_env_cfg_id = "tb_env_cfg";
  localparam string s_no_cfg_err_id = "no config error";
  localparam string s_cfg_type_err  = "config type error";

  `include "i3c_defs.svh"
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_i3c_pkg::*;
  // import siracusa_env_pkg::*;
  
  `include "siracusa_i3c_env_cfg.svh"
  `include "siracusa_i3c_env.svh"
  `include "siracusa_i3c_error_reporter.sv"
endpackage : siracusa_i3c_env_pkg 