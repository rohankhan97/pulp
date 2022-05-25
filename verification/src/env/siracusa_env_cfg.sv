class siracusa_env_cfg #(
  parameter int unsigned NUM_IO_SIGNALS=0,
  parameter int unsigned NUM_DUT_SIGNALS=0
) extends uvm_object;

  bit [31:0] cpi_agent_number;
  bit [31:0] i2c_agent_number;
  bit [31:0] uart_agent_number;

  bit        attach_default_ral_adapter;

  // jtag chain configuration
  jtag_chain_agent_cfg jtag_chain_cfg;
  jtag_riscv_dbg_agent_cfg riscv_dbg_cfg;
  jtag_tap riscv_dbg_tap;
  jtag_tap adv_dbg_tap;

  // IO Mux Agent Configuration
  io_mux_agent_cfg io_mux_agent_cfg;
  io_mux_mirror_cfg io_mux_mirror_cfg;

  // peripheral configurations
  cpi_agent_cfg cpi_agent_cfg[];
  i2c_agent_cfg i2c_agent_cfg[];
  uart_agent_cfg uart_agent_cfg[];

  // Sub-environment configuration
  siracusa_spi_env_cfg spi_env_cfg;

  // Virtual Stdout Monitor Configuration
  vstdout_monitor_cfg vstdout_mon_cfg;

  // internal agents configuration
  tcdm_master_agent_cfg fc_data_port_agent_cfg;

  //---------------------------------------------------------------------------
  // UVM Automation Macros.
  //---------------------------------------------------------------------------
  `uvm_object_param_utils_begin(siracusa_env_cfg#(NUM_IO_SIGNALS, NUM_DUT_SIGNALS))
    `uvm_field_int(attach_default_ral_adapter, UVM_DEFAULT)
  	`uvm_field_int(cpi_agent_number, UVM_DEFAULT)
  	`uvm_field_int(i2c_agent_number, UVM_DEFAULT)
  	`uvm_field_int(uart_agent_number, UVM_DEFAULT)
    `uvm_field_object(jtag_chain_cfg, UVM_DEFAULT)
    `uvm_field_object(riscv_dbg_cfg, UVM_DEFAULT)
    `uvm_field_object(io_mux_agent_cfg, UVM_DEFAULT)
    `uvm_field_object(io_mux_mirror_cfg, UVM_DEFAULT)
    `uvm_field_object(vstdout_mon_cfg, UVM_DEFAULT)
    `uvm_field_array_object(cpi_agent_cfg, UVM_DEFAULT)
    `uvm_field_array_object(i2c_agent_cfg, UVM_DEFAULT)
    `uvm_field_array_object(uart_agent_cfg, UVM_DEFAULT)
    `uvm_field_object(spi_env_cfg, UVM_DEFAULT)
    `uvm_field_object(fc_data_port_agent_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="", int num_cpi_agents=1, int num_i2c_agents=1, int num_uart_agents=1);
    super.new(name);
    this.cpi_agent_number  = num_cpi_agents;
    this.i2c_agent_number  = num_i2c_agents;
    this.uart_agent_number = num_uart_agents;
    // Configure Siracusa's JTAG chain
    this.jtag_chain_cfg    = configure_jtag_chain();
    this.riscv_dbg_cfg     = jtag_riscv_dbg_agent_cfg::type_id::create("riscv_dbg_cfg");

    this.io_mux_agent_cfg  = io_mux_agent_pkg::io_mux_agent_cfg::type_id::create("io_mux_agent_cfg");
    this.io_mux_mirror_cfg = siracusa_env_pkg::io_mux_mirror_cfg::type_id::create("io_mux_mirror_cfg");

    this.cpi_agent_cfg     = new [num_cpi_agents];
    for (int i = 0; i < num_cpi_agents; i++) begin
      this.cpi_agent_cfg[i] = pulp_agents_pkg::cpi_agent_cfg::type_id::create($sformatf("cpi_agent_cfg%0d", i));
    end
    this.i2c_agent_cfg = new[num_i2c_agents];
    for (int i = 0; i < num_i2c_agents; i++) begin
      this.i2c_agent_cfg[i] = i2c_agent_pkg::i2c_agent_cfg::type_id::create($sformatf("i2c_agent_cfg%0d", i));
    end
    this.uart_agent_cfg = new[num_uart_agents];
    for (int i = 0; i < num_uart_agents; i++) begin
      this.uart_agent_cfg[i] = uart_agent_pkg::uart_agent_cfg::type_id::create($sformatf("uart_agent_cfg%0d", i));
    end

    this.spi_env_cfg = siracusa_spi_env_cfg::type_id::create("spi_env_cfg");

    this.fc_data_port_agent_cfg = tcdm_master_agent_cfg::type_id::create("fc_data_port_agent_cfg");
    this.vstdout_mon_cfg        = vstdout_monitor_cfg::type_id::create("vstdout_mon_cfg");
    this.vstdout_mon_cfg.add_channel("FC", 32'h1a10_ff80);
    this.vstdout_mon_cfg.add_channel("UVM TB COMM", 32'h1a10_ff88);
    this.attach_default_ral_adapter = 1;
  endfunction

  virtual function jtag_chain_agent_cfg configure_jtag_chain();
    jtag_chain_agent_cfg chain_cfg = jtag_chain_agent_cfg::type_id::create("jtag_chain_cfg");
    riscv_dbg_tap         = jtag_tap::type_id::create("riscv_dbg_tap");
    adv_dbg_tap      = jtag_tap::type_id::create("adv_dbg_tap");
    riscv_dbg_tap.tap_name         = "riscv_dbg";
    riscv_dbg_tap.ir_length        = 5;
    riscv_dbg_tap.id_code          = 0; // TODO replace with real ID-code
    chain_cfg.add_jtag_tap(riscv_dbg_tap);
    adv_dbg_tap.tap_name  = "adv_dbg";
    adv_dbg_tap.ir_length = 5;
    riscv_dbg_tap.id_code      = 0; // TODO replace with real ID-code
    chain_cfg.add_jtag_tap(adv_dbg_tap);
    return chain_cfg;
  endfunction

endclass
