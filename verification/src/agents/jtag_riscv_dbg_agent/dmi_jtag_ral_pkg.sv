//----------------------------------------------------------------------
//   THIS IS AUTOMATICALLY GENERATED CODE
//   Generated by Mentor Graphics' Register Assistant UVM V2021.2 (Build 1)
//   UVM Register Kit version 1.1
//----------------------------------------------------------------------
// Project         : jtag_riscv_dbg_agent
// Unit            : dmi_jtag_ral_pkg
// File            : dmi_jtag_ral_pkg.sv
//----------------------------------------------------------------------
// Created by      : meggiman
// Creation Date   : 9/24/21 9:23 PM
//----------------------------------------------------------------------
// Title           : jtag_riscv_dbg_agent
//
// Description     : 
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// dmi_jtag_ral_pkg
//----------------------------------------------------------------------
package dmi_jtag_ral_pkg;

   import uvm_pkg::*;

   `include "uvm_macros.svh"

   /* DEFINE REGISTER CLASSES */



   //--------------------------------------------------------------------
   // Class: BYPASS0_reg
   // 
   // BYPASS
   //--------------------------------------------------------------------

   class BYPASS0_reg extends uvm_reg;
      `uvm_object_utils(BYPASS0_reg)

      rand uvm_reg_field F;


      // Function: new
      // 
      function new(string name = "BYPASS0_reg");
         super.new(name, 1, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         F = uvm_reg_field::type_id::create("F");
         F.configure(this, 1, 0, "RW", 1, 1'b0, 0, 1, 1);
      endfunction
   endclass



   //--------------------------------------------------------------------
   // Class: BYPASS_reg
   // 
   // BYPASS
   //--------------------------------------------------------------------

   class BYPASS_reg extends uvm_reg;
      `uvm_object_utils(BYPASS_reg)

      rand uvm_reg_field F;


      // Function: new
      // 
      function new(string name = "BYPASS_reg");
         super.new(name, 1, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         F = uvm_reg_field::type_id::create("F");
         F.configure(this, 1, 0, "RW", 1, 1'b0, 0, 1, 1);
      endfunction
   endclass



   //--------------------------------------------------------------------
   // Class: IDCODE_reg
   // 
   // IDCODE
   //--------------------------------------------------------------------

   class IDCODE_reg extends uvm_reg;
      `uvm_object_utils(IDCODE_reg)

      uvm_reg_field Version; 
      uvm_reg_field PartNumber; 
      uvm_reg_field ManufId; 


      // Function: new
      // 
      function new(string name = "IDCODE_reg");
         super.new(name, 32, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         Version = uvm_reg_field::type_id::create("Version");
         PartNumber = uvm_reg_field::type_id::create("PartNumber");
         ManufId = uvm_reg_field::type_id::create("ManufId");

         Version.configure(this, 4, 28, "RO", 0, 4'h0, 0, 0, 0);
         PartNumber.configure(this, 16, 12, "RO", 0, 16'h0000, 0, 0, 0);
         ManufId.configure(this, 11, 1, "RO", 0, 11'b00000000000, 0, 0, 0);
      endfunction
   endclass



   //--------------------------------------------------------------------
   // Class: dmi_reg
   // 
   // Debug Module Interface Access
   //--------------------------------------------------------------------

   class dmi_reg extends uvm_reg;
      `uvm_object_utils(dmi_reg)

      rand uvm_reg_field address; 
      rand uvm_reg_field data; 
      rand uvm_reg_field op; 


      // Function: new
      // 
      function new(string name = "dmi_reg");
         super.new(name, 41, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         address = uvm_reg_field::type_id::create("address");
         data = uvm_reg_field::type_id::create("data");
         op = uvm_reg_field::type_id::create("op");

         address.configure(this, 7, 34, "RW", 0, 7'b0000000, 1, 1, 0);
         data.configure(this, 32, 2, "RW", 1, 32'h00000000, 1, 1, 0);
         op.configure(this, 2, 0, "RW", 1, 2'b00, 1, 1, 0);
      endfunction
   endclass



   //--------------------------------------------------------------------
   // Class: dtmcs_reg
   // 
   // DTM Control and Status
   //--------------------------------------------------------------------

   class dtmcs_reg extends uvm_reg;
      `uvm_object_utils(dtmcs_reg)

      rand uvm_reg_field dmihardreset; 
      rand uvm_reg_field dmireset; 
      uvm_reg_field idle; 
      uvm_reg_field dmistat; 
      uvm_reg_field abits; 
      uvm_reg_field version; 


      // Function: new
      // 
      function new(string name = "dtmcs_reg");
         super.new(name, 32, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         dmihardreset = uvm_reg_field::type_id::create("dmihardreset");
         dmireset = uvm_reg_field::type_id::create("dmireset");
         idle = uvm_reg_field::type_id::create("idle");
         dmistat = uvm_reg_field::type_id::create("dmistat");
         abits = uvm_reg_field::type_id::create("abits");
         version = uvm_reg_field::type_id::create("version");

         dmihardreset.configure(this, 1, 17, "WO", 1, 1'b0, 0, 1, 0);
         dmireset.configure(this, 1, 16, "WO", 1, 1'b0, 0, 1, 0);
         idle.configure(this, 3, 12, "RO", 1, 3'b000, 0, 0, 0);
         dmistat.configure(this, 2, 10, "RO", 1, 2'b00, 1, 0, 0);
         abits.configure(this, 6, 4, "RO", 0, 6'b000000, 0, 0, 0);
         version.configure(this, 4, 0, "RO", 0, 4'h1, 1, 0, 0);
      endfunction
   endclass




   /* BLOCKS */



   //--------------------------------------------------------------------
   // Class: dmi_jtag_regs
   // 
   //--------------------------------------------------------------------

   class dmi_jtag_regs extends uvm_reg_block;
      `uvm_object_utils(dmi_jtag_regs)

      rand BYPASS0_reg BYPASS0; // BYPASS
      rand IDCODE_reg IDCODE; // IDCODE
      rand dtmcs_reg dtmcs; // DTM Control and Status
      rand dmi_reg dmi; // Debug Module Interface Access
      rand BYPASS_reg BYPASS; // BYPASS

      uvm_reg_map dmi_jtag_regs_map; 


      // Function: new
      // 
      function new(string name = "dmi_jtag_regs");
         super.new(name, UVM_NO_COVERAGE);
      endfunction


      // Function: build
      // 
      virtual function void build();
         BYPASS0 = BYPASS0_reg::type_id::create("BYPASS0");
         BYPASS0.configure(this);
         BYPASS0.build();

         IDCODE = IDCODE_reg::type_id::create("IDCODE");
         IDCODE.configure(this);
         IDCODE.build();

         dtmcs = dtmcs_reg::type_id::create("dtmcs");
         dtmcs.configure(this);
         dtmcs.build();

         dmi = dmi_reg::type_id::create("dmi");
         dmi.configure(this);
         dmi.build();

         BYPASS = BYPASS_reg::type_id::create("BYPASS");
         BYPASS.configure(this);
         BYPASS.build();

         dmi_jtag_regs_map = create_map("dmi_jtag_regs_map", 'h0, 6, UVM_LITTLE_ENDIAN, 1);
         default_map = dmi_jtag_regs_map;

         dmi_jtag_regs_map.add_reg(BYPASS0, 'h0, "RW");
         dmi_jtag_regs_map.add_reg(IDCODE, 'h1, "RW");
         dmi_jtag_regs_map.add_reg(dtmcs, 'h10, "RW");
         dmi_jtag_regs_map.add_reg(dmi, 'h11, "RW");
         dmi_jtag_regs_map.add_reg(BYPASS, 'h1f, "RW");

         lock_model();
      endfunction
   endclass


endpackage
