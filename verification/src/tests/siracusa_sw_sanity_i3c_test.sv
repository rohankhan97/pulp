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


class siracusa_sw_sanity_i3c_test
  extends pulp_sw_base_test#(.NUM_IO_SIGNALS(IO_SIGNAL_COUNT), .NUM_DUT_SIGNALS(DUT_SIGNAL_COUNT));

  `uvm_component_utils(siracusa_sw_sanity_i3c_test)
  // `uvm_component_new

  // virtual interface typedefs 
  typedef virtual  mgc_i3c i3c_if_t;

  // Variable: i3c_env
  //
  // This variable is the handle to the environment class.
  siracusa_i3c_env i3c_env;

  // Variable: env_cfg
  // 
  // Instance of top level configuration. It contains the configuration objects 
  // for device and device. 
  siracusa_i3c_env_cfg env_cfg;

  // Variable: static_device_num
  //
  // Holds the number of static devices instantiated. 
  int static_device_num;

  error_reporter rep_source;

  extern function void init_virtual_seq(i3c_slv_virtual_seq vseq);

  extern function new( string name , uvm_component parent );


  `ifdef TLM_MASTER
    // Function: dev_main_mst_config
    //
    // This function configures and initializes the I3C device.
    extern virtual function void dev_main_mstr_config();
  `endif

  `ifdef MIXED_FAST_BUS
    // Function: dev_legacy_i2c_config
    //
    // This function configures and initializes the I3C device.
    extern function void dev_legacy_i2c_slv_config();
  `endif

  `ifdef MULTIPLE_SLAVE
      // Function: dev_scnd_mst_config
      //
      // This function configures and initializes the I3C device.
      extern function void dev_sec_mstr_config();

      // Function: dev_hot_join_config
      //
      // This function configures and initializes the I3C device.
      extern function void dev_hot_join_slv_config();
      //
      // Function: dev_static_slv_config
      //
      // This function configures and initializes the I3C device.
      extern function void dev_static_slv_config();

  `endif

  // Function: dev_i3c_slv_config
  //
  // This function configures and initializes the I3C device.
  extern function void dev_i3c_slv_config();

  extern function void build_phase(uvm_phase phase);

  // Task:- run_phase
  // 
  extern task run_phase(uvm_phase phase);

endclass: siracusa_sw_sanity_i3c_test

// Function definition

function siracusa_sw_sanity_i3c_test :: new(string name , uvm_component parent);
  super.new(name, parent);
endfunction : new

task siracusa_sw_sanity_i3c_test :: run_phase(uvm_phase phase);

  int total_slave_seq;
  int total_master_seq;
  string dev_main_mstr_seq_names[$];
  string dev_i3c_dynamic_slv_seq_names[$];
  string virtual_seq_name;

  uvm_sequence_base      dev_main_mstr_seq_lib[];
  uvm_sequence_base      dev_i3c_dynamic_slv_seq_lib[];
  i3c_slv_virtual_seq    virtual_seq;

  `ifdef MIXED_FAST_BUS
    string dev_legacy_i2c_slv_seq_names[$];
    uvm_sequence_base dev_legacy_i2c_slv_seq_lib[];
  `endif

  `ifdef MULTIPLE_SLAVE
    string dev_sec_mstr_seq_names[$];
    string dev_hot_join_slv_seq_names[$];
    string dev_static_slv_seq_names[$];
    uvm_sequence_base dev_sec_mstr_seq_lib[];
    uvm_sequence_base dev_hot_join_slv_seq_lib[];
    uvm_sequence_base dev_static_slv_seq_lib[];
  `endif

  uvm_factory factory = uvm_factory::get();
  uvm_cmdline_processor clp;
  
  // Getting the handle of command-line processor
  clp = uvm_cmdline_processor::get_inst();
  
  // Getting argument of sequence name given during simulation.
  `ifdef TLM_MASTER
    total_master_seq = clp.get_arg_values("+DEV1_SEQ=", dev_main_mstr_seq_names);
  `endif
  total_slave_seq = total_slave_seq + clp.get_arg_values("+DEV2_SEQ=", dev_i3c_dynamic_slv_seq_names);
  `ifdef MIXED_FAST_BUS
    total_slave_seq = total_slave_seq + clp.get_arg_values("+DEV3_SEQ=", dev_legacy_i2c_slv_seq_names);
  `endif

  `ifdef MULTIPLE_SLAVE
    total_slave_seq = total_slave_seq + clp.get_arg_values("+DEV4_SEQ=", dev_sec_mstr_seq_names);
    total_slave_seq = total_slave_seq + clp.get_arg_values("+DEV5_SEQ=", dev_hot_join_slv_seq_names);
    total_slave_seq = total_slave_seq + clp.get_arg_values("+DEV6_SEQ=", dev_static_slv_seq_names);
  `endif
  total_slave_seq = total_slave_seq + clp.get_arg_value("+SLV_VIRTUAL_SEQ=", virtual_seq_name);
  
  `ifdef TLM_MASTER
    if(total_master_seq == 0)
    begin
      `uvm_fatal("TEST/SEQ/ARG_MISSING",
                 "You must specify at least one master sequence for device \
                  to run using the +DEV1_SEQ ")
                  
    end
  `endif
  
  if(total_slave_seq == 0) 
  begin
    `uvm_fatal("TEST/SEQ/ARG_MISSING",
               "You must specify at least one slave sequence for device \
                to run using the +DEV2_SEQ or +DEV3_SEQ or +DEV4_SEQ or \
                +DEV5_SEQ or +DEV6_SEQ or +SLV_VIRTUAL_SEQ ")
                
  end

  `ifdef TLM_MASTER
    dev_main_mstr_seq_lib = new[dev_main_mstr_seq_names.size()];
  `endif
  `ifdef MIXED_FAST_BUS
    dev_legacy_i2c_slv_seq_lib = new[dev_legacy_i2c_slv_seq_names.size()];
  `endif

  `ifdef MULTIPLE_SLAVE
    dev_sec_mstr_seq_lib = new[dev_sec_mstr_seq_names.size()];
    dev_hot_join_slv_seq_lib = new[dev_hot_join_slv_seq_names.size()];
    dev_static_slv_seq_lib = new[dev_static_slv_seq_names.size()];
  `endif
  dev_i3c_dynamic_slv_seq_lib = new[dev_i3c_dynamic_slv_seq_names.size()];

  // Qualify that each +SEQ specifies a sequence.
  `ifdef TLM_MASTER
    foreach (dev_main_mstr_seq_names[i]) 
    begin
      uvm_object obj;

      obj = factory.create_object_by_name(dev_main_mstr_seq_names[i]);

      if (obj == null)
        `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
          {"Sequence '",dev_main_mstr_seq_names[i],"' not found in factory"})

      if (!$cast(dev_main_mstr_seq_lib[i], obj))
        `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
          {"Sequence '",dev_main_mstr_seq_names[i],"' is not a sequence"})
    end
  `endif

  `ifdef MIXED_FAST_BUS
    foreach (dev_legacy_i2c_slv_seq_names[i]) 
    begin
      uvm_object obj;

      obj = factory.create_object_by_name(dev_legacy_i2c_slv_seq_names[i]);

      if (obj == null)
        `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
          {"Sequence '",dev_legacy_i2c_slv_seq_names[i],"' not found in factory"})

      if (!$cast(dev_legacy_i2c_slv_seq_lib[i], obj))
        `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
          {"Sequence '",dev_legacy_i2c_slv_seq_names[i],"' is not a sequence"})
    end
  `endif

  `ifdef MULTIPLE_SLAVE
      foreach (dev_sec_mstr_seq_names[i]) 
      begin
        uvm_object obj;

        obj = factory.create_object_by_name(dev_sec_mstr_seq_names[i]);

        if (obj == null)
          `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
            {"Sequence '",dev_sec_mstr_seq_names[i],"' not found in factory"})

        if (!$cast(dev_sec_mstr_seq_lib[i], obj))
          `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
            {"Sequence '",dev_sec_mstr_seq_names[i],"' is not a sequence"})
      end

      foreach (dev_hot_join_slv_seq_names[i]) 
      begin
        uvm_object obj;

        obj = factory.create_object_by_name(dev_hot_join_slv_seq_names[i]);

        if (obj == null)
          `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
            {"Sequence '",dev_hot_join_slv_seq_names[i],"' not found in factory"})

        if (!$cast(dev_hot_join_slv_seq_lib[i], obj))
          `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
            {"Sequence '",dev_hot_join_slv_seq_names[i],"' is not a sequence"})
      end

      foreach (dev_static_slv_seq_names[i]) 
      begin
        uvm_object obj;

        obj = factory.create_object_by_name(dev_static_slv_seq_names[i]);

        if (obj == null)
          `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
            {"Sequence '",dev_static_slv_seq_names[i],"' not found in factory"})

        if (!$cast(dev_static_slv_seq_lib[i], obj))
          `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
            {"Sequence '",dev_static_slv_seq_names[i],"' is not a sequence"})
      end
  `endif
    

  foreach (dev_i3c_dynamic_slv_seq_names[i]) 
  begin
    uvm_object obj;

    obj = factory.create_object_by_name(dev_i3c_dynamic_slv_seq_names[i]);

    if (obj == null)
      `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
        {"Sequence '",dev_i3c_dynamic_slv_seq_names[i],"' not found in factory"})

    if (!$cast(dev_i3c_dynamic_slv_seq_lib[i], obj))
      `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
        {"Sequence '",dev_i3c_dynamic_slv_seq_names[i],"' is not a sequence"})
  end

  if (virtual_seq_name.len() != 0)
  begin
    uvm_object obj;

    obj = factory.create_object_by_name(virtual_seq_name);

    if (obj == null)
      `uvm_fatal("TEST/SEQ/NOT_IN_FACTORY",
        {"Sequence '",virtual_seq_name,"' not found in factory"})

    if (!$cast(virtual_seq, obj))
      `uvm_fatal("TEST/SEQ/NOT_A_SEQ",
        {"Sequence '",virtual_seq_name,"' is not derived from i3c_virtual_seq"})

    init_virtual_seq(virtual_seq);

  end

  phase.raise_objection(this, "Started I3C sequence");

  fork
    begin
      
      fork
        `ifdef TLM_MASTER 
          foreach(dev_main_mstr_seq_lib[seq_no])
          begin
            `uvm_info("TEST/SEQ/RUN", 
                      {"Running sequence '", dev_main_mstr_seq_names[seq_no],"'"}, 
                      UVM_LOW)
            dev_main_mstr_seq_lib[seq_no].start(i3c_env.dev_main_mstr_agent.m_sequencer);
          end
        `endif

        `ifdef MIXED_FAST_BUS
          foreach(dev_legacy_i2c_slv_seq_lib[seq_no])
          begin
            `uvm_info("TEST/SEQ/RUN", 
                      {"Running sequence '", dev_legacy_i2c_slv_seq_names[seq_no],"'"}, 
                      UVM_LOW)
            dev_legacy_i2c_slv_seq_lib[seq_no].start(i3c_env.dev_legacy_i2c_slv_agent.m_sequencer);
          end
        `endif

        `ifdef MULTIPLE_SLAVE
            foreach(dev_sec_mstr_seq_lib[seq_no])
            begin
              `uvm_info("TEST/SEQ/RUN", 
                        {"Running sequence '", dev_sec_mstr_seq_names[seq_no],"'"}, 
                        UVM_LOW)
              dev_sec_mstr_seq_lib[seq_no].start(i3c_env.dev_sec_mstr_agent.m_sequencer);
            end

            foreach(dev_hot_join_slv_seq_lib[seq_no])
            begin
              `uvm_info("TEST/SEQ/RUN", 
                        {"Running sequence '", dev_hot_join_slv_seq_names[seq_no],"'"}, 
                        UVM_LOW)
              dev_hot_join_slv_seq_lib[seq_no].start(i3c_env.dev_hot_join_slv_agent.m_sequencer);
            end

            foreach(dev_static_slv_seq_lib[seq_no])
            begin
              `uvm_info("TEST/SEQ/RUN", 
                        {"Running sequence '", dev_static_slv_seq_names[seq_no],"'"}, 
                        UVM_LOW)
              dev_static_slv_seq_lib[seq_no].start(i3c_env.dev_static_slv_agent.m_sequencer);
            end
        `endif

        foreach(dev_i3c_dynamic_slv_seq_lib[seq_no])
        begin
          `uvm_info("TEST/SEQ/RUN", 
                    {"Running sequence '", dev_i3c_dynamic_slv_seq_names[seq_no],"'"}, 
                    UVM_LOW)
          dev_i3c_dynamic_slv_seq_lib[seq_no].start(i3c_env.dev_i3c_slv_agent.m_sequencer);
        end
      
        if (virtual_seq != null)
        begin
          `uvm_info("TEST/SEQ/RUN", 
                    {"Running sequence '", virtual_seq_name,"'"}, 
                    UVM_LOW)
          virtual_seq.start(null);
       end
      join
    
    end
    
    begin
      `ifndef MODEL_TECH
      #200us;
      `else
      #1000ms;
      `uvm_error("Test",$psprintf("Time out occured"));
      `endif
    end
  
  join_any
  phase.drop_objection(this, "Completed I3C sequence"); 
endtask : run_phase

`ifdef TLM_MASTER
  function void siracusa_sw_sanity_i3c_test :: dev_main_mstr_config();
  
    // Setting the I3C standard configurations for I3C device.
    env_cfg.dev_main_mstr_cfg.agent_cfg.is_active  = 1;
    env_cfg.dev_main_mstr_cfg.agent_cfg.agent_type = I3C_MAIN_MST;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dev_class  = I3C_DYNAMIC_DEVICE;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.hdr_cap       = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.bridge_dev    = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.offline_cap   = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.ibi_payload   = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.ibi_req_cap   = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.max_scl_cap   = 0;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.dcr           = 8'b0000_1111;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.pid           = 48'h000000_FFFFFF;
    env_cfg.dev_main_mstr_cfg.agent_cfg.dynamic_i3c_dev.dar           = 7'h0F;
    env_cfg.dev_main_mstr_cfg.agent_cfg.static_dev_list = new[static_device_num];
  `ifdef MULTIPLE_SLAVE
    env_cfg.dev_main_mstr_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
  `endif
  `ifdef MIXED_FAST_BUS
    env_cfg.dev_main_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
    env_cfg.dev_main_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
    env_cfg.dev_main_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
  `endif
    env_cfg.dev_main_mstr_cfg.m_bfm.cfg_en_system_slv = 1;
    env_cfg.dev_main_mstr_cfg.m_bfm.cfg_en_auto_init = 0;
  endfunction : dev_main_mstr_config
`endif

`ifdef MIXED_FAST_BUS
  function void siracusa_sw_sanity_i3c_test :: dev_legacy_i2c_slv_config();
    // Setting the I3C standard configurations for I3C device.
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.is_active     = 1;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.agent_type    = I3C_I2C_SLV;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.dev_class  = I3C_I2C_DEVICE;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.legacy_i2c_dev.sar    = 7'h09;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.legacy_i2c_dev.lvr    = 8'hAA;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.static_dev_list = new[static_device_num];
    `ifdef MULTIPLE_SLAVE
      env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
    `endif
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
    env_cfg.dev_legacy_i2c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
    env_cfg.dev_legacy_i2c_slv_cfg.m_bfm.cfg_en_system_slv = 1;
    env_cfg.dev_legacy_i2c_slv_cfg.m_bfm.cfg_disable_bus_free_rx_item = 1;
  endfunction : dev_legacy_i2c_slv_config
`endif

`ifdef MULTIPLE_SLAVE
  function void siracusa_sw_sanity_i3c_test :: dev_sec_mstr_config();
    // Setting the I3C standard configurations for I3C device.
    env_cfg.dev_sec_mstr_cfg.agent_cfg.is_active  = 1;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.agent_type = I3C_SCND_MST;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dev_class  = I3C_DYNAMIC_DEVICE;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.hdr_cap       = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.bridge_dev    = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.offline_cap   = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.ibi_payload   = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.ibi_req_cap   = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.max_scl_cap   = 0;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.dcr           = 8'b0011_0000;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.dynamic_i3c_dev.pid           = 48'h0000F_0FFFFF;
    env_cfg.dev_sec_mstr_cfg.agent_cfg.static_dev_list = new[static_device_num];
    env_cfg.dev_sec_mstr_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
    `ifdef MIXED_FAST_BUS
      env_cfg.dev_sec_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
      env_cfg.dev_sec_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
      env_cfg.dev_sec_mstr_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
    `endif
    env_cfg.dev_sec_mstr_cfg.m_bfm.cfg_en_system_slv = 1;
    env_cfg.dev_sec_mstr_cfg.m_bfm.cfg_disable_bus_free_rx_item = 1;
  endfunction : dev_sec_mstr_config

  function void siracusa_sw_sanity_i3c_test :: dev_hot_join_slv_config();
    // Setting the I3C standard configurations for I3C device.
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.is_active  = 1;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.agent_type = I3C_COMP_SLV;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dev_class  = I3C_DYNAMIC_DEVICE;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.is_hotjoin    = 1;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.hdr_cap       = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.bridge_dev    = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.offline_cap   = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.ibi_payload   = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.ibi_req_cap   = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.max_scl_cap   = 0;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.dcr           = 8'b0001_0011;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.dynamic_i3c_dev.pid           = 48'h000000_000FFF;
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.static_dev_list = new[static_device_num];
    env_cfg.dev_hot_join_slv_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
    `ifdef MIXED_FAST_BUS
      env_cfg.dev_hot_join_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
      env_cfg.dev_hot_join_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
      env_cfg.dev_hot_join_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
    `endif
    env_cfg.dev_hot_join_slv_cfg.m_bfm.cfg_en_system_slv = 1;
    env_cfg.dev_hot_join_slv_cfg.m_bfm.cfg_disable_bus_free_rx_item = 1;
  endfunction : dev_hot_join_slv_config

  function void siracusa_sw_sanity_i3c_test :: dev_static_slv_config();
    // Setting the I3C standard configurations for I3C device.
    env_cfg.dev_static_slv_cfg.agent_cfg.is_active  = 1;
    env_cfg.dev_static_slv_cfg.agent_cfg.agent_type = I3C_COMP_SLV;
    env_cfg.dev_static_slv_cfg.agent_cfg.dev_class  = I3C_STATIC_DEVICE;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.hdr_cap       = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.bridge_dev    = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.offline_cap   = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.ibi_payload   = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.ibi_req_cap   = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.max_scl_cap   = 0;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_i3c_dev.sar           = 7'b000_1100;
    env_cfg.dev_static_slv_cfg.agent_cfg.static_dev_list = new[static_device_num];
    env_cfg.dev_static_slv_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
    `ifdef MIXED_FAST_BUS
      env_cfg.dev_static_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
      env_cfg.dev_static_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
      env_cfg.dev_static_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
    `endif
    env_cfg.dev_static_slv_cfg.m_bfm.cfg_en_system_slv = 1;
    env_cfg.dev_static_slv_cfg.m_bfm.cfg_disable_bus_free_rx_item = 1;
  endfunction : dev_static_slv_config
`endif

function void siracusa_sw_sanity_i3c_test :: dev_i3c_slv_config();

  rep_source = new("rep_source");
  env_cfg.dev_i3c_slv_cfg.m_bfm.register_interface_reporter(rep_source);
  uvm_config_db #( error_reporter )::set( null, "*", "REP_SRC", rep_source);

  // Setting the I3C standard configurations for I3C device.
  env_cfg.dev_i3c_slv_cfg.agent_cfg.is_active  = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.agent_type = I3C_COMP_SLV;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dev_class  = I3C_DYNAMIC_DEVICE;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.hdr_cap       = 0;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.is_hotjoin    = 0;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.bridge_dev    = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.offline_cap   = 0;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.ibi_payload   = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.ibi_req_cap   = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.max_scl_cap   = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.dcr           = 8'b0101_0011;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.dynamic_i3c_dev.pid           = 48'h000F00_000FFF;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.static_dev_list = new[static_device_num];
`ifdef MULTIPLE_SLAVE
  env_cfg.dev_i3c_slv_cfg.agent_cfg.static_dev_list[0].sar = 7'b000_1100;
`endif
`ifdef MIXED_FAST_BUS
  env_cfg.dev_i3c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].i2c_dev = 1;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].sar = 7'h09;
  env_cfg.dev_i3c_slv_cfg.agent_cfg.static_dev_list[static_device_num-1].lvr = 8'hAA;
`endif
  env_cfg.dev_i3c_slv_cfg.m_bfm.cfg_en_system_slv = 1;
  env_cfg.dev_i3c_slv_cfg.m_bfm.cfg_disable_bus_free_rx_item = 1;
endfunction : dev_i3c_slv_config

function void siracusa_sw_sanity_i3c_test::init_virtual_seq(i3c_slv_virtual_seq vseq);

  `ifdef MULTIPLE_SLAVE  
    vseq.i3c_sec_mstr        = i3c_env.dev_sec_mstr_agent.m_sequencer;
    vseq.i3c_hot_join_slv    = i3c_env.dev_hot_join_slv_agent.m_sequencer;
    vseq.i3c_static_slv      = i3c_env.dev_static_slv_agent.m_sequencer;
  `endif
  `ifdef MIXED_FAST_BUS
    vseq.i3c_legacy_i2c_slv  = i3c_env.dev_legacy_i2c_slv_agent.m_sequencer;
  `endif
    vseq.i3c_dynamic_slv     = i3c_env.dev_i3c_slv_agent.m_sequencer;

endfunction: init_virtual_seq

function void siracusa_sw_sanity_i3c_test :: build_phase(uvm_phase phase);
  super.build_phase(phase);

  // configure the i3c environment
  i3c_env  = siracusa_i3c_env_pkg::siracusa_i3c_env::type_id::create("i3c_env",this);
  env_cfg  = siracusa_i3c_env_pkg::siracusa_i3c_env_cfg::type_id::create("env_cfg");

  `ifdef TLM_MASTER
    if(!uvm_config_db #(i3c_if_t) ::
      get(null, "uvm_test_top", "I3C_MAIN_MASTER_IF", env_cfg.dev_main_mstr_cfg.m_bfm))
    `uvm_error("ENV/ENV_CFG Error", 
               {"uvm_config_db #(i3c_if_t)::",
               "get cannot find resource I3C_MAIN_MASTER_IF"})
  `endif

  `ifdef MIXED_FAST_BUS
    static_device_num++;

    if(!uvm_config_db #(i3c_if_t) :: 
      get(null, "uvm_test_top", "I3C_LEGACY_I2C_SLAVE_IF", env_cfg.dev_legacy_i2c_slv_cfg.m_bfm))
    `uvm_error("ENV/ENV_CFG Error", 
               {"uvm_config_db #(i3c_if_t) :: ",
                "get cannot find resource I3C_LEGACY_I2C_SLAVE_IF"})
  `endif

  `ifdef MULTIPLE_SLAVE
      static_device_num++;

      if(!uvm_config_db #(i3c_if_t) :: 
        get(null, "uvm_test_top", "I3C_SCND_MSTR_IF", env_cfg.dev_sec_mstr_cfg.m_bfm))
      `uvm_error("ENV/ENV_CFG Error", 
                 {"uvm_config_db #(i3c_if_t) :: ",
                  "get cannot find resource I3C_SCND_MSTR_IF"})

      if(!uvm_config_db #(i3c_if_t) :: 
        get(null, "uvm_test_top", "I3C_HOT_JOIN_SLAVE_IF", env_cfg.dev_hot_join_slv_cfg.m_bfm))
      `uvm_error("ENV/ENV_CFG Error", 
                 {"uvm_config_db #(i3c_if_t) :: ",
                  "get cannot find resource I3C_HOT_JOIN_SLAVE_IF"})

      if(!uvm_config_db #(i3c_if_t) :: 
        get(null, "uvm_test_top", "I3C_STATIC_SLAVE_IF", env_cfg.dev_static_slv_cfg.m_bfm))
      `uvm_error("ENV/ENV_CFG Error", 
                 {"uvm_config_db #(i3c_if_t) :: ",
                  "get cannot find resource I3C_STATIC_SLAVE_IF"})
  `endif

  if(!uvm_config_db #(i3c_if_t) :: 
    get(null, "uvm_test_top", "I3C_DYNAMIC_SLAVE_IF", env_cfg.dev_i3c_slv_cfg.m_bfm))
  `uvm_error("ENV/ENV_CFG Error", 
             {"uvm_config_db #(i3c_if_t) :: ",
              "get cannot find resource I3C_DYNAMIC_SLAVE_IF"})

  `ifdef TLM_MASTER
    dev_main_mstr_config();
  `endif
  `ifdef MIXED_FAST_BUS
    dev_legacy_i2c_slv_config();
  `endif
  `ifdef MULTIPLE_SLAVE
    dev_sec_mstr_config();
    dev_hot_join_slv_config();
    dev_static_slv_config();
  `endif
  dev_i3c_slv_config();

  i3c_env.env_cfg = env_cfg;
  // Setting environment configuration of the entire test_base-bench. User can get
  // this configuration if he wants to get the handle of the configurations of
  // I3C device and I3C device, use case is if want to get the handle of the 
  // BFM. 
  uvm_config_db #(siracusa_i3c_env_cfg) :: set(this, "*" , s_tb_env_cfg_id, env_cfg);

endfunction : build_phase
