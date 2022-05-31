// -----------------------------------------------------------------------------
// Title      : Siracus UVM Testbench
// Project    : Siracusa
// -----------------------------------------------------------------------------
// File       : tb.sv<src>
// Author     : Manuel Eggimann <meggimann@iis.ee.ethz.ch>
// Company    : Integrated Systems Laboratory, ETH Zurich
// Created    : 06.09.2021
// -----------------------------------------------------------------------------
// Description: UVM based testbench for the Siracusa SoC
// -----------------------------------------------------------------------------
// Copyright (c) 2021 Integrated Systems Laboratory, ETH Zurich
// -----------------------------------------------------------------------------

module tb;
  import uvm_pkg::*;
  import siracusa_tests_pkg::*;
  import siracusa_env_pkg::*;

`include "uvm_macros.svh"
`include "i3c_defs.svh"

  int error_count = 1;


  // Choose your Fabric Controller core: 
   // 0 for RISCY, 1 for IBEX RV32IMC (formerly ZERORISCY), 2 for IBEX RV32EC (formerly MICRORISCY)
   parameter CORE_TYPE_FC         = 0;
   // if RISCY is instantiated (CORE_TYPE == 0), RISCY_FPU enables the FPU
   parameter RISCY_FPU            = 1;

   parameter USE_HWPE             = 0; // HWPE in SoC

   // Choose your Cluster core: 
   // 0 for RISCY, 1 for IBEX RV32IMC (formerly ZERORISCY), 2 for IBEX RV32EC (formerly MICRORISCY)
   parameter CORE_TYPE_CL         = 0;

   parameter USE_HWPE_CL          = 0; // HWPE in Cluster


  ///////////////////////////////////////////////
  // Instantiate interfaces and wiring signals //
  ///////////////////////////////////////////////

  // I3C signals
  wire i3c_sda[NI3C];
  wire i3c_scl[NI3C];
  wire i3c_puc[NI3C];
  // Bus Keeper signal and strong pull-up
  for (genvar i = 0; i < NI3C; i++) begin
    assign (weak1, highz0) i3c_sda[i] = 1'b1;
    assign (weak1, highz0) i3c_scl[i] = 1'b1;
    assign (strong1, highz0) i3c_sda[i] = i3c_puc[i]? 1'b1 : 1'bz;
  end


  // Globals clocks and chip control signals
  wire clk, clk_byp, debug_en, boot_mode0, boot_mode1, rst_n, jtag_tck, jtag_trst_n;

  // Clock/reset interface
  clk_rst_if ref_clk_if(.clk(clk), .rst_n(rst_n));
  // JTAG interface
  jtag_if jtag_if();
  // Boot/Debug interface
  boot_dbg_if boot_dbg_vif(
    .boot_mode0(boot_mode0),
    .boot_mode1(boot_mode1),
    .debug_en(debug_en),
    .clk_byp_en(clk_byp)
  );
  assign jtag_tck = jtag_if.tck;
  assign jtag_trst_n = jtag_if.trst_n;

  // CPI IF
  wire cpi_rclk;
  wire dummy_cpi_rst;
  cpi_if#(.DW(10)) cpi_if[NCPI](.rclk(cpi_rclk));
  clk_rst_if cpi_clk_if(.clk(cpi_rclk), .rst_n(dummy_cpi_rst));

  // I2C IF
  i2c_if i2c_if[NI2C]();

  // UART IF
  uart_if uart_if[NUART]();

  // SPIM signals
  wire spim_csn[4];
  wire spim_sck;
  wire spim_sd0;
  wire spim_sd1;
  wire spim_sd2;
  wire spim_sd3;

  // SPIS signals
  wire spis_cs;
  wire spis_sck;
  wire spis_sd0;
  wire spis_sd1;
  wire spis_sd2;
  wire spis_sd3;

  // GPIO IF
  pins_if#(.Width(DUT_SIGNAL_COUNT)) gpio_signals_if();

/*
  // IO-mux agent to DUT IF
  pins_if#(.Width(IO_SIGNAL_COUNT)) vip2io_mux_agent_if();
  pins_if#(.Width(DUT_SIGNAL_COUNT)) io_mux_agent2dut_if();
*/

  wire pad_clk_byp;
  wire pad_debug_en;
  wire pad_bootsel0;
  wire pad_bootsel1;
  wire pad_hyper_csn0;
  wire pad_hyper_csn1;
  wire pad_hyper_reset_n;
  wire pad_hyper_ck;
  wire pad_hyper_ckn;
  wire pad_hyper_dq0;
  wire pad_hyper_dq1;
  wire pad_hyper_dq2;
  wire pad_hyper_dq3;
  wire pad_hyper_dq4;
  wire pad_hyper_dq5;
  wire pad_hyper_dq6;
  wire pad_hyper_dq7;
  wire pad_hyper_rwds;


/*
  // Connect vip interfaces to io_mux_agent interface. Make sure you don't
  // forget to add the IO signals to the io_mux_agent's configuration file IN
  // THE SAME ORDER.
  //
  // Attach the GPIOs
  for (genvar i = 0; i < DUT_SIGNAL_COUNT; i++) begin
    alias vip2io_mux_agent_if.pins[i] = gpio_signals_if.pins[i];
  end
  // assign gpio_signals_if.pins[15:8] = gpio_signals_if.pins[7:0];

  // Attach I2C
  for (genvar i = 0; i < NI2C; i++) begin
    localparam offset = DUT_SIGNAL_COUNT;
    localparam num_sigs = 2; // 2 Signals are used per I2C peripheral
    assign vip2io_mux_agent_if.pins[offset+i*num_sigs] = i2c_if[i].scl_o;
    assign i2c_if[i].scl_i = vip2io_mux_agent_if.pins[offset+i*num_sigs];
    assign vip2io_mux_agent_if.pins[offset+i*num_sigs+1] = i2c_if[i].sda_o;
    assign i2c_if[i].sda_i = vip2io_mux_agent_if.pins[offset+i*num_sigs+1];
  end
  // Attach I3C
  for (genvar i = 0; i < NI3C; i++) begin
    localparam offset = DUT_SIGNAL_COUNT + NI2C*2;
    localparam num_sigs = 3; // 3 Signals are used per I3C peripheral
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs] = i3c_scl[i];
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 1] = i3c_sda[i];
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 2] = i3c_puc[i];
  end
  // Attach UART
  for (genvar i = 0; i < NUART; i++) begin
    localparam offset = DUT_SIGNAL_COUNT + NI2C*2 + NI3C*3;
    localparam num_sigs = 2;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs] = uart_if[i].uart_tx;
    //assign vip2io_mux_agent_if.pins[offset + i*num_sigs + 1] = uart_if[i].uart_rx;
    assign vip2io_mux_agent_if.pins[offset + i*num_sigs + 1] = uart_if[i].uart_tx;
  end

  // Attach SPIM
  for (genvar i = 0; i < NSPIM; i++) begin
    localparam offset = DUT_SIGNAL_COUNT + NI2C*2 + NI3C*3 + NUART*2;
    localparam num_sigs = 9;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs]     = spim_sck;
    for (genvar j = 0; j < 4; j++) begin
      alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 1 + j] = spim_csn[j];
    end
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 5]     = spim_sd0;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 5 + 1] = spim_sd1;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 5 + 2] = spim_sd2;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 5 + 3] = spim_sd3;
  end
  for (genvar i = 0; i < NSPIS; i++) begin
    localparam offset = DUT_SIGNAL_COUNT + NI2C*2 + NI3C*3 + NUART*2 + NSPIM*9;
    localparam num_sigs = 6;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs]     = spis_sck;
    assign vip2io_mux_agent_if.pins[offset + i*num_sigs + 1] = ~spis_cs;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 2] = spim_sd0;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 3] = spim_sd1;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 4] = spim_sd2;
    alias vip2io_mux_agent_if.pins[offset + i*num_sigs + 5] = spim_sd3;
  end
  */


  assign pad_clk_byp = 1'b0;
  assign pad_debug_en = 1'b0;
  assign pad_bootsel0 = 1'b0;
  assign pad_bootsel1 = 1'b0;
  assign pad_hyper_csn0 = 1'b0;
  assign pad_hyper_csn1 = 1'b0;
  assign pad_hyper_reset_n = 1'b0;
  assign pad_hyper_ck = 1'b0;
  assign pad_hyper_ckn = 1'b0;
  assign pad_hyper_dq0 = 1'b0;
  assign pad_hyper_dq1 = 1'b0;
  assign pad_hyper_dq2 = 1'b0;
  assign pad_hyper_dq3 = 1'b0;
  assign pad_hyper_dq4 = 1'b0;
  assign pad_hyper_dq5 = 1'b0;
  assign pad_hyper_dq6 = 1'b0;
  assign pad_hyper_dq7 = 1'b0;
  assign pad_hyper_rwds = 1'b0;

  /////////////////////////
  // Instantiate the DUT //
  /////////////////////////
  pulp i_dut (
    .pad_ref_clk(clk),
    .pad_clk_byp(clk_byp),
    .pad_reset_n(rst_n),

    .pad_bootsel0(boot_mode0),
    .pad_bootsel1(boot_mode1),

    .pad_debug_en(debug_en),

    .pad_jtag_tck (jtag_tck   ),  
    .pad_jtag_tms (jtag_if.tms),
    .pad_jtag_tdi (jtag_if.tdi),
    .pad_jtag_tdo (jtag_if.tdo),
    .pad_jtag_trst(jtag_trst_n),

    .pad_hyper_csn0(pad_hyper_csn0),
    .pad_hyper_csn1(pad_hyper_csn1),
    .pad_hyper_reset_n(pad_hyper_reset_n),
    .pad_hyper_ck(pad_hyper_ck),
    .pad_hyper_ckn(pad_hyper_ckn),
    .pad_hyper_dq0(pad_hyper_dq0),
    .pad_hyper_dq1(pad_hyper_dq1),
    .pad_hyper_dq2(pad_hyper_dq2),
    .pad_hyper_dq3(pad_hyper_dq3),
    .pad_hyper_dq4(pad_hyper_dq4),
    .pad_hyper_dq5(pad_hyper_dq5),
    .pad_hyper_dq6(pad_hyper_dq6),
    .pad_hyper_dq7(pad_hyper_dq7),
    .pad_hyper_rwds(pad_hyper_rwds),

    .pad_gpio00(io_mux_agent2dut_if.pins[0]),
    .pad_gpio01(io_mux_agent2dut_if.pins[1]),
    .pad_gpio02(io_mux_agent2dut_if.pins[2]),
    .pad_gpio03(io_mux_agent2dut_if.pins[3]),
    .pad_gpio04(io_mux_agent2dut_if.pins[4]),
    .pad_gpio05(io_mux_agent2dut_if.pins[5]),
    .pad_gpio06(io_mux_agent2dut_if.pins[6]),
    .pad_gpio07(io_mux_agent2dut_if.pins[7]),
    .pad_gpio08(io_mux_agent2dut_if.pins[8]),
    .pad_gpio09(io_mux_agent2dut_if.pins[9]),
    .pad_gpio10(io_mux_agent2dut_if.pins[10]),
    .pad_gpio11(io_mux_agent2dut_if.pins[11]),
    .pad_gpio12(io_mux_agent2dut_if.pins[12]),
    .pad_gpio13(io_mux_agent2dut_if.pins[13]),
    .pad_gpio14(io_mux_agent2dut_if.pins[14]),
    .pad_gpio15(io_mux_agent2dut_if.pins[15]),
    .pad_gpio16(io_mux_agent2dut_if.pins[16]),
    .pad_gpio17(io_mux_agent2dut_if.pins[17]),
    .pad_gpio18(io_mux_agent2dut_if.pins[18]),
    .pad_gpio19(io_mux_agent2dut_if.pins[19]),
    .pad_gpio20(io_mux_agent2dut_if.pins[20]),
    .pad_gpio21(io_mux_agent2dut_if.pins[21]),
    .pad_gpio22(io_mux_agent2dut_if.pins[22]),
    .pad_gpio23(io_mux_agent2dut_if.pins[23]),
    .pad_gpio24(io_mux_agent2dut_if.pins[24]),
    .pad_gpio25(io_mux_agent2dut_if.pins[25]),
    .pad_gpio26(io_mux_agent2dut_if.pins[26]),
    .pad_gpio27(io_mux_agent2dut_if.pins[27]),
    .pad_gpio28(io_mux_agent2dut_if.pins[28]),
    .pad_gpio29(io_mux_agent2dut_if.pins[29]),
    .pad_gpio30(io_mux_agent2dut_if.pins[30]),
    .pad_gpio31(io_mux_agent2dut_if.pins[31]),
    .pad_gpio32(io_mux_agent2dut_if.pins[32]),
    .pad_gpio33(io_mux_agent2dut_if.pins[33]),
    .pad_gpio34(io_mux_agent2dut_if.pins[34]),
    .pad_gpio35(io_mux_agent2dut_if.pins[35]),
    .pad_gpio36(io_mux_agent2dut_if.pins[36]),
    .pad_gpio37(io_mux_agent2dut_if.pins[37]),
    .pad_gpio38(io_mux_agent2dut_if.pins[38]),
    .pad_gpio39(io_mux_agent2dut_if.pins[39]),
    .pad_gpio40(io_mux_agent2dut_if.pins[40]),
    .pad_gpio41(io_mux_agent2dut_if.pins[41]),
    .pad_gpio42(io_mux_agent2dut_if.pins[42]),
    .pad_gpio43(cpi_if[0].pclk),
    .pad_gpio44(cpi_if[0].href),
    .pad_gpio45(cpi_if[0].vref),
    .pad_gpio46(cpi_if[0].data[0]),
    .pad_gpio47(cpi_if[0].data[1]),
    .pad_gpio48(cpi_if[0].data[2]),
    .pad_gpio49(cpi_if[0].data[3]),
    .pad_gpio50(cpi_if[0].data[4]),
    .pad_gpio51(cpi_if[0].data[5]),
    .pad_gpio52(cpi_if[0].data[6]),
    .pad_gpio53(cpi_if[0].data[7]),
    .pad_gpio54(cpi_if[0].data[8]),
    .pad_gpio55(cpi_if[0].data[9])
 );

// PULP chip (design under test)
   pulp #(
      .CORE_TYPE_FC ( CORE_TYPE_FC ),
      .CORE_TYPE_CL ( CORE_TYPE_CL ),
      .USE_FPU      ( RISCY_FPU    ),
      .USE_HWPE     ( USE_HWPE     ),
      .USE_HWPE_CL  ( USE_HWPE_CL  )
   )
   i_dut (
      .pad_spim_sdio0     ( spim_sd0   ),  // done
      .pad_spim_sdio1     ( spim_sd1   ),  // done
      .pad_spim_sdio2     ( spim_sd2   ),  // done
      .pad_spim_sdio3     ( spim_sd3   ),  // done
      .pad_spim_csn0      ( spim_csn[0]),  // done
      .pad_spim_csn1      ( spim_csn[1]),  // done
      .pad_spim_sck       ( spim_sck   ),  // done

      .pad_uart_rx        ( uart_if[0].uart_rx ),  // done
      .pad_uart_tx        ( uart_if[0].uart_tx ),  // done

      .pad_cam_pclk       ( cpi_if[0].pclk         ),   // done
      .pad_cam_hsync      ( cpi_if[0].href         ),   // done
      .pad_cam_data0      ( cpi_if[0].data[0]      ),   // done
      .pad_cam_data1      ( cpi_if[0].data[1]      ),   // done
      .pad_cam_data2      ( cpi_if[0].data[2]      ),   // done
      .pad_cam_data3      ( cpi_if[0].data[3]      ),   // done
      .pad_cam_data4      ( cpi_if[0].data[4]      ),   // done
      .pad_cam_data5      ( cpi_if[0].data[5]      ),   // done
      .pad_cam_data6      ( cpi_if[0].data[6]      ),   // done
      .pad_cam_data7      ( cpi_if[0].data[7]      ),   // done
      .pad_cam_vsync      ( cpi_if[0].vref         ),   // done

      .pad_sdio_clk       (                    ),
      .pad_sdio_cmd       (                    ),
      .pad_sdio_data0     ( w_sdio_data0       ),
      .pad_sdio_data1     (                    ),
      .pad_sdio_data2     (                    ),
      .pad_sdio_data3     (                    ),

      .pad_i2c0_sda       ( i2c_if[0].sda_o         ),   // done
      .pad_i2c0_scl       ( i2c_if[0].scl_o         ),   // done

      .pad_gpios          ( gpio_signals_if.pins    ),   // done

      .pad_i2c1_sda       ( i2c_if[1].sda_o         ),   // done
      .pad_i2c1_scl       ( i2c_if[1].scl_o         ),   // done

      .pad_i2s0_sck       ( w_i2s0_sck         ),
      .pad_i2s0_ws        ( w_i2s0_ws          ),
      .pad_i2s0_sdi       ( w_i2s0_sdi         ),
      .pad_i2s1_sdi       ( w_i2s1_sdi         ),

      .pad_hyper_dq0     ( pad_hyper_dq0         ),   // done
      .pad_hyper_dq1     ( pad_hyper_dq1         ),   // done
      .pad_hyper_ck      ( pad_hyper_ck          ),   // done
      .pad_hyper_ckn     ( pad_hyper_ckn         ),   // done
      .pad_hyper_csn0    ( pad_hyper_csn0        ),   // done
      .pad_hyper_csn1    ( pad_hyper_csn1        ),   // done
      .pad_hyper_rwds0   ( pad_hyper_rwds        ),   // done
      .pad_hyper_rwds1   ( w_hyper_rwds1         ),   
      .pad_hyper_reset   ( pad_hyper_reset_n     ),   // done

      .pad_reset_n        ( rst_n            ),   // done    
      .pad_bootsel0       ( boot_mode0       ),   // done
      .pad_bootsel1       ( boot_mode1       ),   // done


      .pad_jtag_tck       ( jtag_tck          ),   // done
      .pad_jtag_tms       ( jtag_if.tms       ),   // done
      .pad_jtag_tdi       ( jtag_if.tdi       ),   // done
      .pad_jtag_tdo       ( jtag_if.tdo       ),   // done
      .pad_jtag_trst      ( jtag_trst_n       ),   // done

      .pad_xtal_in        ( clk          )   // done
   );

  /////////////////////////////////////////////////////
  // Bind internal agent BFM interfaces into the DUT //
  /////////////////////////////////////////////////////
  bind tb.i_dut.soc_domain_i.pulp_soc_i.fc_subsystem_i tcdm_if s_uvm_bind_fc_data_if(
    .clk(clk_i),
    .rst_n(rst_ni),
    .req(l2_data_master.req),
    .addr(l2_data_master.add),
    .wen(l2_data_master.wen),
    .wdata(l2_data_master.wdata),
    .be(l2_data_master.be),
    .gnt(l2_data_master.gnt),
    .r_opc(l2_data_master.r_opc),
    .r_rdata(l2_data_master.r_rdata),
    .r_valid(l2_data_master.r_valid)
    );

  //////////////////////////////////////////////////////////////////////////////
  // Initial block to activate the clock and start the CLI specified UVM test //
  //////////////////////////////////////////////////////////////////////////////
  initial begin
    uvm_report_server server;
    ref_clk_if.set_active();
    cpi_clk_if.set_active();
    jtag_if.tck_period_ns = 50;
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif", ref_clk_if);
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "cpi_clk_rst_vif", cpi_clk_if);
    uvm_config_db#(virtual boot_dbg_if)::set(null, "*.env", "boot_dbg_vif", boot_dbg_vif);
    uvm_config_db#(virtual pins_if#(DUT_SIGNAL_COUNT))::set(null, "*.env", "gpios_vif", gpio_signals_if);
    uvm_config_db#(virtual jtag_if)::set(null, "*.env.jtag_chain_agent.jtag_agent", "vif", jtag_if);
    /*
    uvm_config_db#(virtual pins_if#(IO_SIGNAL_COUNT))::set(null, "*.env.io_mux_a.vip_driver", "vif", vip2io_mux_agent_if);
    uvm_config_db#(virtual pins_if#(IO_SIGNAL_COUNT))::set(null, "*.env.io_mux_a.vip_monitor", "vif", vip2io_mux_agent_if);
    uvm_config_db#(virtual pins_if#(DUT_SIGNAL_COUNT))::set(null, "*.env.io_mux_a.dut_driver", "vif", io_mux_agent2dut_if);
    uvm_config_db#(virtual pins_if#(DUT_SIGNAL_COUNT))::set(null, "*.env.io_mux_a.dut_monitor", "vif", io_mux_agent2dut_if);
    */
    uvm_config_db#(virtual tcdm_if)::set(null, "*.env.fc_data_port_a.driver", "vif", tb.i_dut.soc_domain_i.pulp_soc_i.fc_subsystem_i.s_uvm_bind_fc_data_if);
    uvm_config_db#(virtual tcdm_if)::set(null, "*.env.fc_data_port_a.monitor", "vif", tb.i_dut.soc_domain_i.pulp_soc_i.fc_subsystem_i.s_uvm_bind_fc_data_if);

    // Disable assertions in fabric controller since it will get confused by all
    // of the forced toggling on the data interface.
    $assertoff(0, i_dut.soc_domain_i.pulp_soc_i.fc_subsystem_i.FC_CORE.lFC_CORE);


    // Setup configuration for the siracusa environment
    run_test("");
    server      = uvm_report_server::get_server();
    error_count = server.get_severity_count(UVM_ERROR);
    error_count += server.get_severity_count(UVM_FATAL);
  end

  ////////////////////////////
  // Tie-off virtual stdout //
  ////////////////////////////
  assign tb.i_dut.soc_domain_i.pulp_soc_i.soc_peripherals_i.s_virtual_stdout_slave.pready = 1'b1;

  initial begin
    #100ns;
    ref_clk_if.start_clk();
    ref_clk_if.apply_reset(.rst_n_scheme(2), .reset_width_clks(10));

    // Alfio: delaying the CPI clock activation, as it is not yet controlled by the DUT
    #5.5ms;
    cpi_clk_if.start_clk();
    cpi_clk_if.apply_reset(.rst_n_scheme(2), .reset_width_clks(1));
  end

  // hooking each cpi interface to the respective agent
  for (genvar i = 0; i < NCPI; i++) begin
    initial begin
      uvm_config_db#(virtual cpi_if#(.DW(10)))::set(null, $sformatf("*.env.cpi_agent%0d.vip_driver",i), "vif", cpi_if[i]);
      uvm_config_db#(virtual cpi_if#(.DW(10)))::set(null, $sformatf("*.env.cpi_agent%0d.vip_monitor",i), "vif", cpi_if[i]);
    end
  end
  // hooking each i2c interface to the respective agent
  for (genvar i = 0; i < NI2C; i++) begin
    initial begin
      uvm_config_db#(virtual i2c_if)::set(null, $sformatf("*.env.i2c_agent%0d*",i), "vif", i2c_if[i]);
    end
  end
  // hooking each uart interface to the respective agent
  for (genvar i = 0; i < NUART; i++) begin
    initial begin
      uvm_config_db#(virtual uart_if)::set(null, $sformatf("*.env.uart_agent%0d*",i), "vif", uart_if[i]);
    end
  end

  /////////////////////////////////////////////
  // Instantiate Siemens VIP Harness Modules //
  /////////////////////////////////////////////
  // I3C
  `ifdef TLM_MASTER
    i3c_device # (.IF_NAME("I3C_MAIN_MASTER_IF"))
      dev_main_mstr  (.sda(i3c_sda[1]),
                      .scl(i3c_scl[1]),
                      .reset(rst_n));
  `endif

  `ifdef MIXED_FAST_BUS
    i3c_device # (.IF_NAME("I3C_LEGACY_I2C_SLAVE_IF"))
      dev_legacy_i2c_slv  (.sda(i3c_sda[0]),
                           .scl(i3c_scl[0]),
                           .reset(rst_n));
  `endif

  `ifdef MULTIPLE_SLAVE
    i3c_device # (.IF_NAME("I3C_SCND_MSTR_IF"))
      dev_sec_mstr(.sda(i3c_sda[0]),
                   .scl(i3c_scl[0]),
                   .reset(rst_n));

    i3c_device # (.IF_NAME("I3C_HOT_JOIN_SLAVE_IF"))
      dev_hot_join_slv  (.sda(i3c_sda[0]),
                         .scl(i3c_scl[0]),
                         .reset(rst_n));

  i3c_device # (.IF_NAME("I3C_STATIC_SLAVE_IF"))
      dev_static_slv  (.sda(i3c_sda[0]),
                       .scl(i3c_scl[0]),
                       .reset(rst_n));
  `endif


  i3c_device # (.IF_NAME("I3C_DYNAMIC_SLAVE_IF"))
    dev_i3c_dynamic_slv  (.sda(i3c_sda[0]),
                          .scl(i3c_scl[0]),
                          .reset(rst_n));


  localparam string spis_interface_names[4] = {"spi_slave0_vif", "spi_slave1_vif", "spi_slave2_vif", "spi_slave3_vif"};

  wire              spi_sys_clk, spi_sys_reset_n;
  clk_rst_if spi_vip_clk(.clk(spi_sys_clk), .rst_n(spi_sys_reset_n));
  initial begin
    spi_vip_clk.set_active();
    spi_vip_clk.set_freq_mhz(2);
    spi_vip_clk.apply_reset(.rst_n_scheme(2), .reset_width_clks(3));
    spi_vip_clk.start_clk();
  end


  // SPI Slaves
  for (genvar i = 0; i < 4; i++) begin : gen_spi_slaves
    spi_slave #        (
      .SPI_SS_WIDTH ( 1                       ),
      .IF_NAME      ( spis_interface_names[i] ),
      .PATH_NAME    ( "*env"                  )
    ) i_spi_slave_vif (
      .sys_clk ( spi_sys_clk        ),
      .reset   ( ~spi_sys_reset_n   ),
      .SS      ( ~spim_csn[i]       ),
      .SCK     ( spim_sck           ),
      .MOSI    ( spim_sd0           ),
      .MOSI1   ( spim_sd1           ),
      .MOSI2   ( spim_sd2           ),
      .MOSI3   ( spim_sd3           ),
      .MISO    ( spim_sd0           ),
      .MISO1   ( spim_sd1           ),
      .MISO2   ( spim_sd2           ),
      .MISO3   ( spim_sd3           )
    );
  end
  // SPI Master
  spi_master #(
    .SPI_SS_WIDTH(1),
    .IF_NAME("spi_master_vif"),
    .PATH_NAME("*env")
  ) i_spi_master_vif (
    .sys_clk (  spi_sys_clk       ),
    .reset   ( ~spi_sys_reset_n   ),
    .SS      ( spis_cs            ),
    .SCK     ( spis_sck           ),
    .MOSI    ( spis_sd0           ),
    .MOSI1   ( spis_sd1           ),
    .MOSI2   ( spis_sd2           ),
    .MOSI3   ( spis_sd3           ),
    .MISO    ( spis_sd0           ),
    .MISO1   ( spis_sd1           ),
    .MISO2   ( spis_sd2           ),
    .MISO3   ( spis_sd3           )
  );



endmodule
