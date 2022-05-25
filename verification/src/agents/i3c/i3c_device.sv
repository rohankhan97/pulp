module i3c_device
(
  inout sda,        // SDA signal
  inout scl,        // SCL signal
  inout reset       // Active high reset signal
);

  import uvm_pkg::*;
  
  parameter string IF_NAME   = "null";
  parameter string PATH_NAME = "uvm_test_top*";
  
  mgc_i3c i3c_bfm(1'bz);
  
  assign (strong0, pull1) sda = i3c_bfm.TX_SDA;
  assign (strong0, pull1) scl = i3c_bfm.TX_SCL;

  tran rst (i3c_bfm.RESET, reset);

  assign (strong0, pull1) i3c_bfm.RSLVD_SCL    = scl;
  assign (strong0, pull1) i3c_bfm.RSLVD_SDA    = sda;
  assign (strong0, pull1) i3c_bfm.RSLVD_ML_SDA[0] = sda;
  
  initial begin

    // Put the interface into the UVM configuration structure, for retrieval in 
    // the UVM test build method
    uvm_config_db #(virtual mgc_i3c)::set(null, PATH_NAME, IF_NAME, i3c_bfm);
  end
endmodule