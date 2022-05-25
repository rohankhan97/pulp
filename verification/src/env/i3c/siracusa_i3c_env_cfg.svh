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

// CLASS: siracusa_i3c_env_cfg
//
// This class models the configuration for the testbench in order to make it a 
// reusable component for the tests. 

class siracusa_i3c_env_cfg extends uvm_object;
 
  typedef i3c_vip_config   i3c_vip_cfg_t;

  // UVM Factory Registration
  `uvm_object_utils(siracusa_i3c_env_cfg)
  
  `ifdef TLM_MASTER
    // Variable: dev_main_mstr_cfg
    //
    // The configuration object of type <i3c_vip_config> for the device end of
    // the interface.
    i3c_vip_cfg_t dev_main_mstr_cfg;
  `endif
  
  `ifdef MIXED_FAST_BUS
  // Variable: dev_legacy_i2c_slv_cfg
  //
  // The configuration object of type <i3c_vip_config> for the device end of
  // the interface.
  i3c_vip_cfg_t dev_legacy_i2c_slv_cfg;
  `endif

  `ifdef MULTIPLE_SLAVE
    // Variable: dev_sec_mstr_cfg
    //
    // The configuration object of type <i3c_vip_config> for the device end of
    // the interface.
    i3c_vip_cfg_t dev_sec_mstr_cfg;

    // Variable: dev_hot_join_slv_cfg
    //
    // The configuration object of type <i3c_vip_config> for the device end of
    // the interface.
    i3c_vip_cfg_t dev_hot_join_slv_cfg;

    // Variable: dev_static_slv_cfg
    // 
    // The configuration object of type <i3c_vip_config> for the device end of
    // the interface.     
    i3c_vip_cfg_t dev_static_slv_cfg;
  `endif
  
  // Variable: dev_i3c_slv_cfg
  // 
  // The configuration object of type <i3c_vip_config> for the device end of
  // the interface.     
  i3c_vip_cfg_t dev_i3c_slv_cfg;

  function new( string name = "" );
    super.new( name );
    `ifdef TLM_MASTER
      dev_main_mstr_cfg       = new();
    `endif
    `ifdef MIXED_FAST_BUS
      dev_legacy_i2c_slv_cfg  = new();
    `endif
    `ifdef MULTIPLE_SLAVE
      dev_sec_mstr_cfg      = new();
      dev_hot_join_slv_cfg  = new();
      dev_static_slv_cfg      = new();
    `endif
    dev_i3c_slv_cfg         = new();
  endfunction : new

  // Function: get_config
  //
  // This important static method hides the dynamic casting implicit in 
  // the UVM config mechanism. It also prints out useful messages when
  // either there is no uvm_object associated with this id and this 
  // component or there is an uvm_object but it is not of the correct
  // type.
  static function siracusa_i3c_env_cfg get_config( uvm_component c );
    uvm_object o;
    siracusa_i3c_env_cfg t;

    if(!(uvm_config_db #(siracusa_i3c_env_cfg)::get(c, "" ,s_tb_env_cfg_id, t))) begin
      `uvm_error(s_no_cfg_err_id ,
                   $sformatf("this component has no config with id %s",
                   s_tb_env_cfg_id ))
      return null;
    end

    return t;
  endfunction : get_config
endclass : siracusa_i3c_env_cfg             
