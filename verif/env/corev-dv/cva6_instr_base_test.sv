/*
 * Copyright 2018 Google LLC
 * Copyright 2020 OpenHW Group
 * Copyright 2023 Thales
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//------------------------------------------------------------------------------
// CORE-V instruction generator base test:
//     - extension of the RISC-V instruction generator base test.
//
//------------------------------------------------------------------------------

class cva6_instr_base_test_c extends riscv_instr_base_test;

  `uvm_component_utils(cva6_instr_base_test_c)


  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    override_asm_program_gen();
    override_gen_config();
    override_illegal_instr();
    override_sequence_instr();
    super.build_phase(phase);
  endfunction

  virtual function void override_asm_program_gen();
    `uvm_info("CVA6_DV", $sformatf("Overriding ..."), UVM_LOW)
    uvm_factory::get().set_type_override_by_type(riscv_asm_program_gen::get_type(),
                                                 cva6_asm_program_gen_c::get_type());
    `uvm_info("CVA6_DV", $sformatf("Override done "), UVM_LOW)
  endfunction

  virtual function void override_gen_config();
    `uvm_info("CVA6_DV", $sformatf("Overriding ..."), UVM_LOW)
    uvm_factory::get().set_type_override_by_type(riscv_instr_gen_config::get_type(),
                                                 cva6_instr_gen_config_c::get_type());
    `uvm_info("CVA6_DV", $sformatf("Override done "), UVM_LOW)
  endfunction

  virtual function void override_illegal_instr();
    `uvm_info("CVA6_DV", $sformatf("Overriding ..."), UVM_LOW)
    uvm_factory::get().set_type_override_by_type(riscv_illegal_instr::get_type(),
                                                 cva6_illegal_instr_c::get_type());
    `uvm_info("CVA6_DV", $sformatf("Override done "), UVM_LOW)
  endfunction

  virtual function void override_sequence_instr();
    `uvm_info("CVA6_DV", $sformatf("Overriding ..."), UVM_LOW)
    uvm_factory::get().set_type_override_by_type(riscv_instr_sequence::get_type(),
                                                 cva6_instr_sequence_c::get_type());
    `uvm_info("CVA6_DV", $sformatf("Override done "), UVM_LOW)
  endfunction

endclass : cva6_instr_base_test_c
