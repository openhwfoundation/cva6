//
// Copyright 2020 OpenHW Group
// Copyright 2023 Thales DIS
//
// Licensed under the Solderpad Hardware License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

typedef enum int {
   U_LEVEL        = 0,
   S_LEVEL        = 1,
   RESERVED_LEVEL = 2,
   M_LEVEL        = 3,
   D_LEVEL        = 10
} privilege_level_t;
 
class csr_reg extends uvm_reg;

  local privilege_level_t privilege_level; //CSR Privilege access level 
  
  `uvm_object_utils_begin(csr_reg)
      `uvm_field_enum(privilege_level_t, privilege_level, UVM_DEFAULT)
  `uvm_object_utils_end

  function new (string name = "csr_reg");
    super.new(name, .n_bits(32), .has_coverage(UVM_CVR_ALL));
  endfunction
  
  function  int get_privilege_level(); 
      return privilege_level;
  endfunction

  function  string get_privilege_level_str(privilege_level_t privilege); 
   case (privilege)
      U_LEVEL: return "U";
      S_LEVEL: return "S";
      M_LEVEL: return "M";
      D_LEVEL: return "D";
   endcase
   return "?";
  endfunction

  function void set_privilege_level(privilege_level_t privilege); 
      privilege_level = privilege;
  endfunction

endclass

class reg_mstatus extends csr_reg;
  `uvm_object_utils(reg_mstatus)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field SD;
  rand uvm_reg_field TSR;
  rand uvm_reg_field TW;
  rand uvm_reg_field TVM;
  rand uvm_reg_field MXR;
  rand uvm_reg_field SUM;
  rand uvm_reg_field MPRV;
  rand uvm_reg_field XS;
  rand uvm_reg_field FS;
  rand uvm_reg_field MPP;
  rand uvm_reg_field VS;
  rand uvm_reg_field SPP;
  rand uvm_reg_field MPIE;
  rand uvm_reg_field UBE;
  rand uvm_reg_field SPIE;
  rand uvm_reg_field MIE;
  rand uvm_reg_field SIE;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mstatus__read_cg";
      option.per_instance = 1;
      // SD summarizes a dirty FS: it is only stuck at 0 without an FPU.
      SD: coverpoint data[31:31] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.FpPresent);
      }
      TSR: coverpoint data[22:22] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      TW: coverpoint data[21:21] {
         bins legal_values[] = {0};
         // issue#2228 illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      // TODO : need configuration on these coverpoints
      TVM: coverpoint data[20:20] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MXR: coverpoint data[19:19] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      SUM: coverpoint data[18:18] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MPRV: coverpoint data[17:17] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      XS: coverpoint data[16:15] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      FS: coverpoint data[14:13] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MPP: coverpoint data[12:11] {
         bins legal_values[] = {3};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {3}));
      }
      VS: coverpoint data[10:9] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      SPP: coverpoint data[8:8] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MPIE: coverpoint data[7:7];
      UBE: coverpoint data[6:6] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      SPIE: coverpoint data[5:5] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MIE: coverpoint data[3:3];
      SIE: coverpoint data[1:1] {
         bins legal_values[] = {0};
         ignore_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mstatus.mstatus__write_cp";
      option.per_instance = 1;
      SD: coverpoint data[31:31] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      TSR: coverpoint data[22:22];
      TW: coverpoint data[21:21];
      TVM: coverpoint data[20:20];
      MXR: coverpoint data[19:19];
      SUM: coverpoint data[18:18];
      MPRV: coverpoint data[17:17];
      XS: coverpoint data[16:15]  {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      FS: coverpoint data[14:13] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      MPP: coverpoint data[12:11];
      VS: coverpoint data[10:9]  {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      SPP: coverpoint data[8:8];
      MPIE: coverpoint data[7:7];
      UBE: coverpoint data[6:6] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      SPIE: coverpoint data[5:5];
      MIE: coverpoint data[3:3];
      SIE: coverpoint data[1:1];
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mstatus");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mstatus.mstatus__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mstatus.mstatus__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    SD = uvm_reg_field::type_id::create("SD");   
    SD.configure(.parent(this), .size(1), .lsb_pos(31), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    TSR = uvm_reg_field::type_id::create("TSR");   
    TSR.configure(.parent(this), .size(1), .lsb_pos(22), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    TW = uvm_reg_field::type_id::create("TW");   
    TW.configure(.parent(this), .size(1), .lsb_pos(21), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    TVM = uvm_reg_field::type_id::create("TVM");   
    TVM.configure(.parent(this), .size(1), .lsb_pos(20), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MXR = uvm_reg_field::type_id::create("MXR");   
    MXR.configure(.parent(this), .size(1), .lsb_pos(19), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SUM = uvm_reg_field::type_id::create("SUM");   
    SUM.configure(.parent(this), .size(1), .lsb_pos(18), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MPRV = uvm_reg_field::type_id::create("MPRV");   
    MPRV.configure(.parent(this), .size(1), .lsb_pos(17), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    XS = uvm_reg_field::type_id::create("XS");   
    XS.configure(.parent(this), .size(2), .lsb_pos(15), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    FS = uvm_reg_field::type_id::create("FS");   
    FS.configure(.parent(this), .size(2), .lsb_pos(13), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MPP = uvm_reg_field::type_id::create("MPP");   
    MPP.configure(.parent(this), .size(2), .lsb_pos(11), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    VS = uvm_reg_field::type_id::create("VS");   
    VS.configure(.parent(this), .size(2), .lsb_pos(9), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SPP = uvm_reg_field::type_id::create("SPP");   
    SPP.configure(.parent(this), .size(1), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MPIE = uvm_reg_field::type_id::create("MPIE");   
    MPIE.configure(.parent(this), .size(1), .lsb_pos(7), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    UBE = uvm_reg_field::type_id::create("UBE");   
    UBE.configure(.parent(this), .size(1), .lsb_pos(6), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SPIE = uvm_reg_field::type_id::create("SPIE");   
    SPIE.configure(.parent(this), .size(1), .lsb_pos(5), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MIE = uvm_reg_field::type_id::create("MIE");   
    MIE.configure(.parent(this), .size(1), .lsb_pos(3), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SIE = uvm_reg_field::type_id::create("SIE");   
    SIE.configure(.parent(this), .size(1), .lsb_pos(1), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_misa extends csr_reg;
  `uvm_object_utils(reg_misa)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field MXL;
  rand uvm_reg_field Extensions;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_misa__read_cg";
      option.per_instance = 1;
      // The register model sees the low 32 bits of a CSR: MXL is in them on
      // RV32 only.
      MXL: coverpoint data[31:30] {
         bins legal_values[] = {1};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {1})) iff (RTLCVA6Cfg.IS_XLEN32);
      }
      Extensions: coverpoint data[25:0] {
         bins legal_values[] = {26'h0001106};
         //TODO : Fix issue#1734
         //illegal_bins illegal_values = {[0:$]} with (!(item inside {26'h0001106}));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_misa.misa__write_cp";
      option.per_instance = 1;
      MXL: coverpoint data[31:30] {
         bins legal_values[] = {1};
         bins illegal_values[] = {[0:$]} with (!(item inside {1}));
      }
      Extensions: coverpoint data[25:0] {
         bins legal_values[] = {26'h0001106};
         bins illegal_values[3] = {[0:$]} with (!(item inside {26'h0001106}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_misa");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.misa.misa__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.misa.misa__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    MXL = uvm_reg_field::type_id::create("MXL");   
    MXL.configure(.parent(this), .size(2), .lsb_pos(30), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    Extensions = uvm_reg_field::type_id::create("Extensions");   
    Extensions.configure(.parent(this), .size(26), .lsb_pos(0), .access("RW"), .volatile(0), .reset(26'h0001106), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mie extends csr_reg;
  `uvm_object_utils(reg_mie)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field MEIE;
  rand uvm_reg_field SEIE;
  rand uvm_reg_field UEIE;
  rand uvm_reg_field MTIE;
  rand uvm_reg_field STIE;
  rand uvm_reg_field UTIE;
  rand uvm_reg_field MSIE;
  rand uvm_reg_field SSIE;
  rand uvm_reg_field USIE;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mie__read_cg";
      option.per_instance = 1;
      MEIE: coverpoint data[11:11];
      SEIE: coverpoint data[9:9] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      UEIE: coverpoint data[8:8] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      } 
      MTIE: coverpoint data[7:7];
      STIE: coverpoint data[5:5] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      UTIE: coverpoint data[4:4] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      } 
      MSIE: coverpoint data[3:3];
      SSIE: coverpoint data[1:1] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      USIE: coverpoint data[0:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      } 
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mie.mie__write_cp";
      option.per_instance = 1;
      MEIE: coverpoint data[11:11];
      SEIE: coverpoint data[9:9] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
      UEIE: coverpoint data[8:8] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
      MTIE: coverpoint data[7:7];
      STIE: coverpoint data[5:5] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
      UTIE: coverpoint data[4:4] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
      MSIE: coverpoint data[3:3];
      SSIE: coverpoint data[1:1] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
      USIE: coverpoint data[0:0] {
         bins legal_values[] = {0};
         bins illegal_values[]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mie");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mie.mie__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mie.mie__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    MEIE = uvm_reg_field::type_id::create("MEIE");   
    MEIE.configure(.parent(this), .size(1), .lsb_pos(11), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SEIE = uvm_reg_field::type_id::create("SEIE");   
    SEIE.configure(.parent(this), .size(1), .lsb_pos(9), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    UEIE = uvm_reg_field::type_id::create("UEIE");   
    UEIE.configure(.parent(this), .size(1), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MTIE = uvm_reg_field::type_id::create("MTIE");   
    MTIE.configure(.parent(this), .size(1), .lsb_pos(7), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    STIE = uvm_reg_field::type_id::create("STIE");   
    STIE.configure(.parent(this), .size(1), .lsb_pos(5), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    UTIE = uvm_reg_field::type_id::create("UTIE");   
    UTIE.configure(.parent(this), .size(1), .lsb_pos(4), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MSIE = uvm_reg_field::type_id::create("MSIE");   
    MSIE.configure(.parent(this), .size(1), .lsb_pos(3), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SSIE = uvm_reg_field::type_id::create("SSIE");   
    SSIE.configure(.parent(this), .size(1), .lsb_pos(1), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    USIE = uvm_reg_field::type_id::create("USIE");   
    USIE.configure(.parent(this), .size(1), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mtvec extends csr_reg;
  `uvm_object_utils(reg_mtvec)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field BASE;
  rand uvm_reg_field MODE;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mtvec__read_cg";
      option.per_instance = 1;
      BASE: coverpoint data[31:2] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      MODE: coverpoint data[1:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      } 
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mtvec.mtvec__write_cp";
      option.per_instance = 1;
      BASE: coverpoint data[31:2] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      MODE: coverpoint data[1:0] {
         bins legal_values[] = {0,1};
         bins illegal_values[] = {[0:$]} with (!(item inside {0,1}));
      } 
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mtvec");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mtvec.mtvec__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mtvec.mtvec__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    BASE = uvm_reg_field::type_id::create("BASE");   
    BASE.configure(.parent(this), .size(30), .lsb_pos(2), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MODE = uvm_reg_field::type_id::create("MODE");   
    MODE.configure(.parent(this), .size(2), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mstatush extends csr_reg;
  `uvm_object_utils(reg_mstatush)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field SBE;
  rand uvm_reg_field MBE;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mstatush__read_cg";
      option.per_instance = 1;
      // MBE and SBE select big endian data accesses; SBE is a read-only copy of
      // MBE, which the privileged specification allows.
      SBE: coverpoint data[4:4] {
         bins legal_values[] = {0, 1};
      }
      MBE: coverpoint data[5:5]{
         bins legal_values[] = {0, 1};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mstatush.mstatush__write_cp";
      option.per_instance = 1;
      SBE: coverpoint data[4:4] {
         bins legal_values[] = {0, 1};
      }
      MBE: coverpoint data[5:5] {
         bins legal_values[] = {0, 1};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mstatush");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mstatush.mstatush__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mstatush.mstatush__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    SBE = uvm_reg_field::type_id::create("SBE");   
    SBE.configure(.parent(this), .size(1), .lsb_pos(4), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MBE = uvm_reg_field::type_id::create("MBE");   
    MBE.configure(.parent(this), .size(1), .lsb_pos(5), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent3 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent3)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent3__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent3.mhpmevent3__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent3");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent3.mhpmevent3__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent3.mhpmevent3__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent4 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent4)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent4__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent4.mhpmevent4__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent4");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent4.mhpmevent4__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent4.mhpmevent4__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent5 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent5)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent5__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent5.mhpmevent5__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent5");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent5.mhpmevent5__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent5.mhpmevent5__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent6 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent6)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent6__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent6.mhpmevent6__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent6");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent6.mhpmevent6__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent6.mhpmevent6__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent7 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent7)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent7__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent7.mhpmevent7__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent7");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent7.mhpmevent7__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent7.mhpmevent7__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent8 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent8)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent8__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent8.mhpmevent8__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent8");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent8.mhpmevent8__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent8.mhpmevent8__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent9 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent9)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent9__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent9.mhpmevent9__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0]  {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent9");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent9.mhpmevent9__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent9.mhpmevent9__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent10 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent10)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent10__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent10.mhpmevent10__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent10");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent10.mhpmevent10__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent10.mhpmevent10__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent11 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent11)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent11__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent11.mhpmevent11__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent11");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent11.mhpmevent11__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent11.mhpmevent11__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent12 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent12)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent12__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent12.mhpmevent12__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent12");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent12.mhpmevent12__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent12.mhpmevent12__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent13 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent13)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent13__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent13.mhpmevent13__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent13");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent13.mhpmevent13__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent13.mhpmevent13__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent14 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent14)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent14__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent14.mhpmevent14__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent14");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent14.mhpmevent14__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent14.mhpmevent14__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent15 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent15)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent15__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent15.mhpmevent15__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent15");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent15.mhpmevent15__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent15.mhpmevent15__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent16 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent16)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent16__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent16.mhpmevent16__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent16");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent16.mhpmevent16__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent16.mhpmevent16__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent17 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent17)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent17__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent17.mhpmevent17__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent17");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent17.mhpmevent17__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent17.mhpmevent17__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent18 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent18)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent18__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent18.mhpmevent18__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent18");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent18.mhpmevent18__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent18.mhpmevent18__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent19 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent19)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent19__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent19.mhpmevent19__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent19");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent19.mhpmevent19__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent19.mhpmevent19__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent20 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent20)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent20__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent20.mhpmevent20__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent20");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent20.mhpmevent20__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent20.mhpmevent20__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent21 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent21)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent21__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent21.mhpmevent21__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent21");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent21.mhpmevent21__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent21.mhpmevent21__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent22 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent22)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent22__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent22.mhpmevent22__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent22");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent22.mhpmevent22__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent22.mhpmevent22__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent23 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent23)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent23__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent23.mhpmevent23__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent23");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent23.mhpmevent23__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent23.mhpmevent23__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent24 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent24)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent24__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent24.mhpmevent24__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent24");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent24.mhpmevent24__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent24.mhpmevent24__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent25 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent25)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent25__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent25.mhpmevent25__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent25");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent25.mhpmevent25__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent25.mhpmevent25__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent26 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent26)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent26__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent26.mhpmevent26__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent26");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent26.mhpmevent26__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent26.mhpmevent26__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent27 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent27)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent27__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent27.mhpmevent27__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent27");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent27.mhpmevent27__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent27.mhpmevent27__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent28 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent28)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent28__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent28.mhpmevent28__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent28");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent28.mhpmevent28__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent28.mhpmevent28__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent29 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent29)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent29__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent29.mhpmevent29__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent29");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent29.mhpmevent29__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent29.mhpmevent29__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent30 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent30)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent30__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent30.mhpmevent30__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent30");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent30.mhpmevent30__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent30.mhpmevent30__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmevent31 extends csr_reg;
  `uvm_object_utils(reg_mhpmevent31)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mhpmevent;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent31__read_cg";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmevent31.mhpmevent31__write_cp";
      option.per_instance = 1;
      mhpmevent: coverpoint data[31:0] {
         bins legal_values[] = {0};
         bins illegal_values[3]  = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmevent31");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmevent31.mhpmevent31__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmevent31.mhpmevent31__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mhpmevent = uvm_reg_field::type_id::create("mhpmevent");   
    mhpmevent.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mscratch extends csr_reg;
  `uvm_object_utils(reg_mscratch)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mscratch;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mscratch__read_cg";
      option.per_instance = 1;
      mscratch: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mscratch.mscratch__write_cp";
      option.per_instance = 1;
      mscratch: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mscratch");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mscratch.mscratch__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mscratch.mscratch__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mscratch = uvm_reg_field::type_id::create("mscratch");   
    mscratch.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mepc extends csr_reg;
  `uvm_object_utils(reg_mepc)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mepc;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mepc__read_cg";
      option.per_instance = 1;
      mepc: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mepc.mepc__write_cp";
      option.per_instance = 1;
      mepc: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mepc");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mepc.mepc__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mepc.mepc__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mepc = uvm_reg_field::type_id::create("mepc");   
    mepc.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mcause extends csr_reg;
  `uvm_object_utils(reg_mcause)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field Interrupt;
  rand uvm_reg_field exception_code;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcause__read_cg";
      option.per_instance = 1;
      Interrupt: coverpoint data[31:31];
      exception_code: coverpoint data[30:0] {
         bins legal_values_interrupt[]  = {3,7,11} iff (data[31:31]==1);
         bins other_values_interrupt[3] = {[0:$]} with (!(item inside {3,7,11})) iff (data[31:31]==1);
         bins legal_values_exception[] = {[0:7],11,12,13,15} iff (data[31:31]==0);
         bins other_values_exception[3] = {[0:$]} with (!(item inside {[0:7],11,12,13,15})) iff (data[31:31]==0);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcause.mcause__write_cp";
      option.per_instance = 1;
      Interrupt: coverpoint data[31:31];
      exception_code: coverpoint data[30:0] {
         bins legal_values_interrupt[]  = {3,7,11} iff (data[31:31]==1);
         bins other_values_interrupt[3] = {[0:$]} with (!(item inside {3,7,11})) iff (data[31:31]==1);
         bins legal_values_exception[] = {[0:7],11,12,13,15}  iff (data[31:31]==0);
         bins other_values_exception[3] = {[0:$]} with (!(item inside {[0:7],11,12,13,15} )) iff (data[31:31]==0);
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mcause");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mcause.mcause__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mcause.mcause__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    Interrupt = uvm_reg_field::type_id::create("Interrupt");   
    Interrupt.configure(.parent(this), .size(1), .lsb_pos(31), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    exception_code = uvm_reg_field::type_id::create("exception_code");   
    exception_code.configure(.parent(this), .size(31), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mtval extends csr_reg;
  `uvm_object_utils(reg_mtval)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field mtval;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mtval__read_cg";
      option.per_instance = 1;
      mtval: coverpoint data[31:0] {
         bins reset_value = {0};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mtval__write_cg";
      option.per_instance = 1;
      mtval: coverpoint data[31:0] {
         bins reset_value = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mtval");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mtval.mtval__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mtval.mtval__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    mtval = uvm_reg_field::type_id::create("mtval");   
    mtval.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mip extends csr_reg;
  `uvm_object_utils(reg_mip)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field MEIP;
  rand uvm_reg_field SEIP;
  rand uvm_reg_field UEIP;
  rand uvm_reg_field MTIP;
  rand uvm_reg_field STIP;
  rand uvm_reg_field UTIP;
  rand uvm_reg_field MSIP;
  rand uvm_reg_field SSIP;
  rand uvm_reg_field USIP;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mip__read_cg";
      option.per_instance = 1;
      MEIP: coverpoint data[11:11];
      SEIP: coverpoint data[9:9] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      UEIP: coverpoint data[8:8] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MTIP: coverpoint data[7:7];
      STIP: coverpoint data[5:5] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      UTIP: coverpoint data[4:4] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      MSIP: coverpoint data[3:3];
      SSIP: coverpoint data[1:1] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
      USIP: coverpoint data[0:0] {
         bins legal_values[] = {0};
         illegal_bins illegal_values = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mip.mip__write_cp";
      option.per_instance = 1;
      MEIP: coverpoint data[11:11];
      SEIP: coverpoint data[9:9] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      UEIP: coverpoint data[8:8] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      MTIP: coverpoint data[7:7];
      STIP: coverpoint data[5:5] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      UTIP: coverpoint data[4:4] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      MSIP: coverpoint data[3:3];
      SSIP: coverpoint data[1:1] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
      USIP: coverpoint data[0:0] {
         bins legal_values[] = {0};
         bins illegal_values[] = {[0:$]} with (!(item inside {0}));
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mip");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mip.mip__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mip.mip__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    MEIP = uvm_reg_field::type_id::create("MEIP");   
    MEIP.configure(.parent(this), .size(1), .lsb_pos(11), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SEIP = uvm_reg_field::type_id::create("SEIP");   
    SEIP.configure(.parent(this), .size(1), .lsb_pos(9), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    UEIP = uvm_reg_field::type_id::create("UEIP");   
    UEIP.configure(.parent(this), .size(1), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MTIP = uvm_reg_field::type_id::create("MTIP");   
    MTIP.configure(.parent(this), .size(1), .lsb_pos(7), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    STIP = uvm_reg_field::type_id::create("STIP");   
    STIP.configure(.parent(this), .size(1), .lsb_pos(5), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    UTIP = uvm_reg_field::type_id::create("UTIP");   
    UTIP.configure(.parent(this), .size(1), .lsb_pos(4), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    MSIP = uvm_reg_field::type_id::create("MSIP");   
    MSIP.configure(.parent(this), .size(1), .lsb_pos(3), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    SSIP = uvm_reg_field::type_id::create("SSIP");   
    SSIP.configure(.parent(this), .size(1), .lsb_pos(1), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    USIP = uvm_reg_field::type_id::create("USIP");   
    USIP.configure(.parent(this), .size(1), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpcfg0 extends csr_reg;
  `uvm_object_utils(reg_pmpcfg0)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field pmp3cfg;
  rand uvm_reg_field pmp2cfg;
  rand uvm_reg_field pmp1cfg;
  rand uvm_reg_field pmp0cfg;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg0__read_cg";
      option.per_instance = 1;
      pmp3cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp2cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp1cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp0cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg0.pmpcfg0__write_cp";
      option.per_instance = 1;
      pmp3cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp2cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp1cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp0cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpcfg0");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpcfg0.pmpcfg0__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpcfg0.pmpcfg0__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    pmp3cfg = uvm_reg_field::type_id::create("pmp3cfg");   
    pmp3cfg.configure(.parent(this), .size(8), .lsb_pos(24), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp2cfg = uvm_reg_field::type_id::create("pmp2cfg");   
    pmp2cfg.configure(.parent(this), .size(8), .lsb_pos(16), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp1cfg = uvm_reg_field::type_id::create("pmp1cfg");   
    pmp1cfg.configure(.parent(this), .size(8), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp0cfg = uvm_reg_field::type_id::create("pmp0cfg");   
    pmp0cfg.configure(.parent(this), .size(8), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpcfg1 extends csr_reg;
  `uvm_object_utils(reg_pmpcfg1)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field pmp7cfg;
  rand uvm_reg_field pmp6cfg;
  rand uvm_reg_field pmp5cfg;
  rand uvm_reg_field pmp4cfg;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg1__read_cg";
      option.per_instance = 1;
      pmp7cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp6cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp5cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp4cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg1.pmpcfg1__write_cp";
      option.per_instance = 1;
      pmp7cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp6cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp5cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp4cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpcfg1");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpcfg1.pmpcfg1__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpcfg1.pmpcfg1__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    pmp7cfg = uvm_reg_field::type_id::create("pmp7cfg");   
    pmp7cfg.configure(.parent(this), .size(8), .lsb_pos(24), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp6cfg = uvm_reg_field::type_id::create("pmp6cfg");   
    pmp6cfg.configure(.parent(this), .size(8), .lsb_pos(16), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp5cfg = uvm_reg_field::type_id::create("pmp5cfg");   
    pmp5cfg.configure(.parent(this), .size(8), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp4cfg = uvm_reg_field::type_id::create("pmp4cfg");   
    pmp4cfg.configure(.parent(this), .size(8), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpcfg2 extends csr_reg;
  `uvm_object_utils(reg_pmpcfg2)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field pmp11cfg;
  rand uvm_reg_field pmp10cfg;
  rand uvm_reg_field pmp9cfg;
  rand uvm_reg_field pmp8cfg;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg2__read_cg";
      option.per_instance = 1;
      pmp11cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp10cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp9cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp8cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg2.pmpcfg2__write_cp";
      option.per_instance = 1;
      pmp11cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp10cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp9cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp8cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpcfg2");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpcfg2.pmpcfg2__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpcfg2.pmpcfg2__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    pmp11cfg = uvm_reg_field::type_id::create("pmp11cfg");   
    pmp11cfg.configure(.parent(this), .size(8), .lsb_pos(24), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp10cfg = uvm_reg_field::type_id::create("pmp10cfg");   
    pmp10cfg.configure(.parent(this), .size(8), .lsb_pos(16), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp9cfg = uvm_reg_field::type_id::create("pmp9cfg");   
    pmp9cfg.configure(.parent(this), .size(8), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp8cfg = uvm_reg_field::type_id::create("pmp8cfg");   
    pmp8cfg.configure(.parent(this), .size(8), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpcfg3 extends csr_reg;
  `uvm_object_utils(reg_pmpcfg3)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field pmp15cfg;
  rand uvm_reg_field pmp14cfg;
  rand uvm_reg_field pmp13cfg;
  rand uvm_reg_field pmp12cfg;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg3__read_cg";
      option.per_instance = 1;
      pmp15cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp14cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp13cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
      pmp12cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]} with (((item & 'h3)!=2) && ((item & 'h60) ==0));
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpcfg3.pmpcfg3__write_cp";
      option.per_instance = 1;
      pmp15cfg: coverpoint data[31:24] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp14cfg: coverpoint data[23:16] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp13cfg: coverpoint data[15:8] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      pmp12cfg: coverpoint data[7:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpcfg3");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpcfg3.pmpcfg3__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpcfg3.pmpcfg3__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    pmp15cfg = uvm_reg_field::type_id::create("pmp15cfg");   
    pmp15cfg.configure(.parent(this), .size(8), .lsb_pos(24), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp14cfg = uvm_reg_field::type_id::create("pmp14cfg");   
    pmp14cfg.configure(.parent(this), .size(8), .lsb_pos(16), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp13cfg = uvm_reg_field::type_id::create("pmp13cfg");   
    pmp13cfg.configure(.parent(this), .size(8), .lsb_pos(8), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    pmp12cfg = uvm_reg_field::type_id::create("pmp12cfg");   
    pmp12cfg.configure(.parent(this), .size(8), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr0 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr0)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr0__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr0.pmpaddr0__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr0");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr0.pmpaddr0__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr0.pmpaddr0__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr1 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr1)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr1__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr1.pmpaddr1__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr1");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr1.pmpaddr1__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr1.pmpaddr1__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr2 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr2)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr2__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr2.pmpaddr2__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr2");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr2.pmpaddr2__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr2.pmpaddr2__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr3 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr3)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr3__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr3.pmpaddr3__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr3");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr3.pmpaddr3__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr3.pmpaddr3__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr4 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr4)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr4__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]  {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr4.pmpaddr4__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr4");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr4.pmpaddr4__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr4.pmpaddr4__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr5 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr5)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr5__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr5.pmpaddr5__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr5");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr5.pmpaddr5__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr5.pmpaddr5__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr6 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr6)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr6__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr6.pmpaddr6__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr6");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr6.pmpaddr6__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr6.pmpaddr6__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr7 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr7)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr7__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr7.pmpaddr7__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr7");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr7.pmpaddr7__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr7.pmpaddr7__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr8 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr8)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr8__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr8.pmpaddr8__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr8");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr8.pmpaddr8__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr8.pmpaddr8__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr9 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr9)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr9__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr9.pmpaddr9__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr9");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr9.pmpaddr9__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr9.pmpaddr9__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr10 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr10)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr10__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr10.pmpaddr10__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr10");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr10.pmpaddr10__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr10.pmpaddr10__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr11 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr11)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr11__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr11.pmpaddr11__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0]{
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr11");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr11.pmpaddr11__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr11.pmpaddr11__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr12 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr12)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr12__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr12.pmpaddr12__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr12");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr12.pmpaddr12__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr12.pmpaddr12__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr13 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr13)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr13__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr13.pmpaddr13__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr13");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr13.pmpaddr13__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr13.pmpaddr13__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr14 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr14)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr14__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr14.pmpaddr14__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr14");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr14.pmpaddr14__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr14.pmpaddr14__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_pmpaddr15 extends csr_reg;
  `uvm_object_utils(reg_pmpaddr15)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field address;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr15__read_cg";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_pmpaddr15.pmpaddr15__write_cp";
      option.per_instance = 1;
      address: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_pmpaddr15");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.pmpaddr15.pmpaddr15__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.pmpaddr15.pmpaddr15__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    address = uvm_reg_field::type_id::create("address");   
    address.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_icache extends csr_reg;
  `uvm_object_utils(reg_icache)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field icache;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_icache__read_cg";
      option.per_instance = 1;
      icache: coverpoint data[0:0];
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_icache.icache__write_cp";
      option.per_instance = 1;
      icache: coverpoint data[0:0];
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_icache");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.icache.icache__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.icache.icache__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    icache = uvm_reg_field::type_id::create("icache");   
    icache.configure(.parent(this), .size(1), .lsb_pos(0), .access("RW"), .volatile(0), .reset(1), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mcycle extends csr_reg;
  `uvm_object_utils(reg_mcycle)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcycle__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {[0:10001]};
         bins other_values[3] = {[10001:$]};
      }
      count_overflow: coverpoint data[31:0] {
         bins overflow = ([32'hFFFFFBFF:$] => [0:10000]);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcycle.mcycle__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mcycle");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mcycle.mcycle__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mcycle.mcycle__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_minstret extends csr_reg;
  `uvm_object_utils(reg_minstret)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_minstret__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {[0:1000]};
         bins other_values[3] = {[1001:$]};
      }
      count_overflow: coverpoint data[31:0] {
         bins overflow = ([32'hFFFFFC17:$] => [0:1000]);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_minstret.minstret__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_minstret");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.minstret.minstret__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.minstret.minstret__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mcycleh extends csr_reg;
  `uvm_object_utils(reg_mcycleh)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcycleh__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      count_overflow: coverpoint data[31:0] {
         bins overflow = ([32'hFFFFFBFF:$] => [0:1000]);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mcycleh.mcycleh__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mcycleh");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mcycleh.mcycleh__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mcycleh.mcycleh__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_minstreth extends csr_reg;
  `uvm_object_utils(reg_minstreth)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_minstreth__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
      count_overflow: coverpoint data[31:0] {
         bins overflow = ([32'hFFFFFFEF:$] => [0:10]);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_minstreth.minstreth__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_minstreth");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.minstreth.minstreth__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.minstreth.minstreth__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter3 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter3)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter3__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter3.mhpmcounter3__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter3");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter3.mhpmcounter3__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter3.mhpmcounter3__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter4 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter4)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter4__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter4.mhpmcounter4__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter4");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter4.mhpmcounter4__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter4.mhpmcounter4__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter5 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter5)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter5__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter5.mhpmcounter5__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter5");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter5.mhpmcounter5__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter5.mhpmcounter5__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter6 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter6)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter6__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter6.mhpmcounter6__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter6");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter6.mhpmcounter6__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter6.mhpmcounter6__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter7 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter7)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter7__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter7.mhpmcounter7__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter7");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter7.mhpmcounter7__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter7.mhpmcounter7__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter8 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter8)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter8__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
     }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter8.mhpmcounter8__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter8");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter8.mhpmcounter8__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter8.mhpmcounter8__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter9 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter9)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter9__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter9.mhpmcounter9__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter9");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter9.mhpmcounter9__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter9.mhpmcounter9__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter10 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter10)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter10__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter10.mhpmcounter10__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter10");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter10.mhpmcounter10__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter10.mhpmcounter10__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter11 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter11)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter11__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter11.mhpmcounter11__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter11");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter11.mhpmcounter11__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter11.mhpmcounter11__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter12 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter12)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter12__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter12.mhpmcounter12__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter12");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter12.mhpmcounter12__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter12.mhpmcounter12__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter13 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter13)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter13__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter13.mhpmcounter13__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter13");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter13.mhpmcounter13__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter13.mhpmcounter13__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter14 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter14)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter14__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter14.mhpmcounter14__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter14");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter14.mhpmcounter14__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter14.mhpmcounter14__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter15 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter15)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter15__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter15.mhpmcounter15__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter15");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter15.mhpmcounter15__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter15.mhpmcounter15__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter16 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter16)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter16__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter16.mhpmcounter16__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter16");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter16.mhpmcounter16__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter16.mhpmcounter16__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter17 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter17)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter17__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter17.mhpmcounter17__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter17");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter17.mhpmcounter17__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter17.mhpmcounter17__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter18 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter18)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter18__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter18.mhpmcounter18__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter18");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter18.mhpmcounter18__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter18.mhpmcounter18__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter19 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter19)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter19__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter19.mhpmcounter19__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter19");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter19.mhpmcounter19__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter19.mhpmcounter19__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter20 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter20)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter20__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter20.mhpmcounter20__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter20");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter20.mhpmcounter20__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter20.mhpmcounter20__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter21 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter21)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter21__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter21.mhpmcounter21__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter21");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter21.mhpmcounter21__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter21.mhpmcounter21__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter22 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter22)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter22__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter22.mhpmcounter22__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter22");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter22.mhpmcounter22__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter22.mhpmcounter22__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter23 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter23)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter23__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter23.mhpmcounter23__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter23");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter23.mhpmcounter23__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter23.mhpmcounter23__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter24 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter24)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter24__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter24.mhpmcounter24__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter24");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter24.mhpmcounter24__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter24.mhpmcounter24__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter25 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter25)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter25__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter25.mhpmcounter25__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter25");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter25.mhpmcounter25__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter25.mhpmcounter25__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter26 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter26)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter26__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter26.mhpmcounter26__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter26");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter26.mhpmcounter26__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter26.mhpmcounter26__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter27 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter27)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter27__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter27.mhpmcounter27__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter27");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter27.mhpmcounter27__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter27.mhpmcounter27__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter28 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter28)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter28__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter28.mhpmcounter28__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter28");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter28.mhpmcounter28__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter28.mhpmcounter28__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter29 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter29)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter29__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter29.mhpmcounter29__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter29");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter29.mhpmcounter29__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter29.mhpmcounter29__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter30 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter30)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter30__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter30.mhpmcounter30__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter30");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter30.mhpmcounter30__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter30.mhpmcounter30__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounter31 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounter31)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter31__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounter31.mhpmcounter31__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounter31");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounter31.mhpmcounter31__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounter31.mhpmcounter31__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh3 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh3)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh3__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh3.mhpmcounterh3__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh3");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh3.mhpmcounterh3__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh3.mhpmcounterh3__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh4 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh4)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh4__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh4.mhpmcounterh4__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh4");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh4.mhpmcounterh4__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh4.mhpmcounterh4__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh5 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh5)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh5__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh5.mhpmcounterh5__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh5");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh5.mhpmcounterh5__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh5.mhpmcounterh5__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh6 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh6)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh6__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh6.mhpmcounterh6__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh6");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh6.mhpmcounterh6__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh6.mhpmcounterh6__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh7 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh7)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh7__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh7.mhpmcounterh7__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh7");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh7.mhpmcounterh7__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh7.mhpmcounterh7__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh8 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh8)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh8__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh8.mhpmcounterh8__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh8");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh8.mhpmcounterh8__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh8.mhpmcounterh8__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh9 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh9)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh9__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh9.mhpmcounterh9__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh9");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh9.mhpmcounterh9__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh9.mhpmcounterh9__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh10 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh10)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh10__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh10.mhpmcounterh10__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh10");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh10.mhpmcounterh10__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh10.mhpmcounterh10__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh11 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh11)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh11__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh11.mhpmcounterh11__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh11");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh11.mhpmcounterh11__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh11.mhpmcounterh11__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh12 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh12)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh12__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh12.mhpmcounterh12__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh12");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh12.mhpmcounterh12__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh12.mhpmcounterh12__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh13 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh13)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh13__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
          illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
     }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh13.mhpmcounterh13__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh13");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh13.mhpmcounterh13__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh13.mhpmcounterh13__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh14 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh14)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh14__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh14.mhpmcounterh14__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh14");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh14.mhpmcounterh14__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh14.mhpmcounterh14__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh15 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh15)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh15__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh15.mhpmcounterh15__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh15");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh15.mhpmcounterh15__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh15.mhpmcounterh15__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh16 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh16)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh16__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh16.mhpmcounterh16__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh16");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh16.mhpmcounterh16__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh16.mhpmcounterh16__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh17 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh17)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh17__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh17.mhpmcounterh17__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh17");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh17.mhpmcounterh17__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh17.mhpmcounterh17__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh18 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh18)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh18__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh18.mhpmcounterh18__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh18");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh18.mhpmcounterh18__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh18.mhpmcounterh18__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh19 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh19)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh19__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh19.mhpmcounterh19__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh19");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh19.mhpmcounterh19__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh19.mhpmcounterh19__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh20 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh20)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh20__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh20.mhpmcounterh20__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh20");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh20.mhpmcounterh20__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh20.mhpmcounterh20__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh21 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh21)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh21__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh21.mhpmcounterh21__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh21");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh21.mhpmcounterh21__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh21.mhpmcounterh21__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh22 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh22)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh22__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh22.mhpmcounterh22__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh22");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh22.mhpmcounterh22__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh22.mhpmcounterh22__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh23 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh23)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh23__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh23.mhpmcounterh23__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh23");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh23.mhpmcounterh23__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh23.mhpmcounterh23__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh24 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh24)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh24__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh24.mhpmcounterh24__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh24");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh24.mhpmcounterh24__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh24.mhpmcounterh24__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh25 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh25)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh25__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh25.mhpmcounterh25__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh25");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh25.mhpmcounterh25__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh25.mhpmcounterh25__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh26 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh26)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh26__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh26.mhpmcounterh26__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh26");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh26.mhpmcounterh26__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh26.mhpmcounterh26__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh27 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh27)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh27__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh27.mhpmcounterh27__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh27");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh27.mhpmcounterh27__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh27.mhpmcounterh27__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh28 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh28)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh28__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh28.mhpmcounterh28__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh28");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh28.mhpmcounterh28__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh28.mhpmcounterh28__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh29 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh29)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh29__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh29.mhpmcounterh29__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh29");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh29.mhpmcounterh29__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh29.mhpmcounterh29__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh30 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh30)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh30__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh30.mhpmcounterh30__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh30");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh30.mhpmcounterh30__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh30.mhpmcounterh30__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhpmcounterh31 extends csr_reg;
  `uvm_object_utils(reg_mhpmcounterh31)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field count;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh31__read_cg";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         illegal_bins illegal_values  = {[0:$]} with (!(item inside {0})) iff (!RTLCVA6Cfg.PerfCounterEn);
      }
  endgroup

  covergroup reg_wr_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhpmcounterh31.mhpmcounterh31__write_cp";
      option.per_instance = 1;
      count: coverpoint data[31:0] {
         bins reset_value  = {0};
         bins other_values[3] = {[1:$]};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhpmcounterh31");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhpmcounterh31.mhpmcounterh31__read_cg");
    reg_wr_cg = new();
    reg_wr_cg.set_inst_name("csr_reg_cov.mhpmcounterh31.mhpmcounterh31__write_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    count = uvm_reg_field::type_id::create("count");   
    count.configure(.parent(this), .size(32), .lsb_pos(0), .access("RW"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
      else
         reg_wr_cg.sample(data);
    end     
  endfunction

endclass


class reg_mvendorid extends csr_reg;
  `uvm_object_utils(reg_mvendorid)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field bank;
  rand uvm_reg_field offset;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mvendorid__read_cg";
      option.per_instance = 1;
      bank: coverpoint data[31:7] {
         bins reset_value  = {'hC};
      }
      offset: coverpoint data[6:0]{
         bins reset_value  = {'h2};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mvendorid");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mvendorid.mvendorid__read_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    bank = uvm_reg_field::type_id::create("bank");   
    bank.configure(.parent(this), .size(25), .lsb_pos(7), .access("RO"), .volatile(0), .reset(384), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
   
    offset = uvm_reg_field::type_id::create("offset");   
    offset.configure(.parent(this), .size(7), .lsb_pos(0), .access("RO"), .volatile(0), .reset(64), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
    end     
  endfunction

endclass


class reg_marchid extends csr_reg;
  `uvm_object_utils(reg_marchid)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field architecture_id;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_marchid__read_cg";
      option.per_instance = 1;
      architecture_id: coverpoint data[31:0] {
         bins reset_value  = {'h3};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_marchid");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.marchid.marchid__read_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    architecture_id = uvm_reg_field::type_id::create("architecture_id");   
    architecture_id.configure(.parent(this), .size(32), .lsb_pos(0), .access("RO"), .volatile(0), .reset(3), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
    end     
  endfunction

endclass


class reg_mimpid extends csr_reg;
  `uvm_object_utils(reg_mimpid)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field implementation;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mimpid__read_cg";
      option.per_instance = 1;
      implementation: coverpoint data[31:0] {
         bins reset_value  = {0};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mimpid");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mimpid.mimpid__read_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    implementation = uvm_reg_field::type_id::create("implementation");   
    implementation.configure(.parent(this), .size(32), .lsb_pos(0), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
    end     
  endfunction

endclass


class reg_mhartid extends csr_reg;
  `uvm_object_utils(reg_mhartid)

  //---------------------------------------
  // fields instance 
  //--------------------------------------- 
  rand uvm_reg_field hart_id;
   

  covergroup reg_rd_cg with function sample(uvm_reg_data_t data);
      option.name = "csr_mhartid__read_cg";
      option.per_instance = 1;
      hart_id: coverpoint data[31:0] {
         bins reset_value  = {0};
      }
  endgroup

  //---------------------------------------
  // Constructor 
  //---------------------------------------
  function new (string name = "reg_mhartid");
    super.new(name);
    set_privilege_level(M_LEVEL);
    reg_rd_cg = new();
    reg_rd_cg.set_inst_name("csr_reg_cov.mhartid.mhartid__read_cg");
  endfunction

  //---------------------------------------
  // build_phase - 
  // 1. Create the fields
  // 2. Configure the fields
  //---------------------------------------  
  function void build; 
   
    hart_id = uvm_reg_field::type_id::create("hart_id");   
    hart_id.configure(.parent(this), .size(32), .lsb_pos(0), .access("RO"), .volatile(0), .reset(0), .has_reset(1), .is_rand(1),  .individually_accessible(0));  
  endfunction

  virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en,bit is_read, uvm_reg_map map);
    if (get_coverage(UVM_CVR_FIELD_VALS)) begin
      if (is_read)
         reg_rd_cg.sample(data);
    end     
  endfunction

endclass


