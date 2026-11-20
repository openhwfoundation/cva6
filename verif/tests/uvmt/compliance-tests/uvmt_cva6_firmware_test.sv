// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
// Copyright 2021 Thales DIS Design Services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
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


`ifndef __UVMT_CVA6_FIRMWARE_TEST_SV__
`define __UVMT_CVA6_FIRMWARE_TEST_SV__


/**
 *  CVA6 "firmware" test.
 *  This class relies on a pre-existing "firmware" file written in C and/or
 *  RISC-V assembly code.  This class will invoke the riscv-gcc-toolchain to
 *  translate the firmware into a "hexfile" that is read into the CVA6
 *  instruction memory in the testbench module.
 *
 *  This class doesn't care what the firmware does, it merely compiles it.
 *
 */
class uvmt_cva6_firmware_test_c extends uvmt_cva6_base_test_c;

   //constraint env_cfg_cons {
   //   env_cfg.enabled         == 1;
   //   env_cfg.is_active       == UVM_ACTIVE;
   //   env_cfg.trn_log_enabled == 1;
   //}

   constraint test_type_cons {
     test_cfg.tpt == PREEXISTING_SELFCHECKING;
   }


   `uvm_component_utils(uvmt_cva6_firmware_test_c)

   /**
    */
   extern function new(string name="uvmt_cva6_firmware_test", uvm_component parent=null);

   /**
    * Runs reset_vseq.
    */
   extern virtual task reset_phase(uvm_phase phase);

   /**
    * Loads the test program (the "firmware") into memory.
    */
   extern virtual task configure_phase(uvm_phase phase);

   /**
    *  Override types with the UVM Factory
    */
   extern virtual function void build_phase(uvm_phase phase);

   /**
    *  Enable program execution, wait for completion.
    */
   extern virtual task run_phase(uvm_phase phase);

endclass : uvmt_cva6_firmware_test_c


function uvmt_cva6_firmware_test_c::new(string name="uvmt_cva6_firmware_test", uvm_component parent=null);

   super.new(name, parent);
   `uvm_info("TEST", "This is the FIRMWARE TEST", UVM_NONE)

endfunction : new


task uvmt_cva6_firmware_test_c::reset_phase(uvm_phase phase);
   super.reset_phase(phase);

endtask : reset_phase

function void uvmt_cva6_firmware_test_c::build_phase(uvm_phase phase);
   super.build_phase(phase);

   `uvm_info("firmware_test", "Overriding Reference Model with Spike", UVM_NONE)
   set_type_override_by_type(uvmc_rvfi_reference_model::get_type(),uvmc_rvfi_spike::get_type());

endfunction : build_phase


task uvmt_cva6_firmware_test_c::configure_phase(uvm_phase phase);

   //string firmware;
   //int    fd;

   super.configure_phase(phase);

   /*
   ** Moved to uvmt_cva6_dut_wrap.sv to avoid XMRs across packages.
   ** TODO: delete all this once you are confident of the approach.
   **
    // Load the pre-compiled firmware
    if($value$plusargs("firmware=%s", firmware)) begin
      // First, check if it exists...
      fd = $fopen (firmware, "r");
      if (fd)  `uvm_info("TEST", $sformatf("%s was opened successfully : (fd=%0d)", firmware, fd), UVM_NONE)
      else     `uvm_fatal("TEST", $sformatf("%s was NOT opened successfully : (fd=%0d)", firmware, fd))
      $fclose(fd);
      // Now load it...
      `uvm_info("TEST", $sformatf("loading firmware %0s", firmware), UVM_NONE)
      $readmemh(firmware, uvmt_cva6_tb.dut_wrap.ram_i.dp_ram_i.mem);
    end
    else begin
      `uvm_error("TEST", "No firmware specified!")
    end
   */

endtask : configure_phase


task uvmt_cva6_firmware_test_c::run_phase(uvm_phase phase);

   // start_clk() and watchdog_timer() are called in the base_test
   super.run_phase(phase);

   phase.raise_objection(this);
   @(posedge env_cntxt.clknrst_cntxt.vif.reset_n);
   repeat (33) @(posedge env_cntxt.clknrst_cntxt.vif.clk);
   `uvm_info("TEST", "Started RUN", UVM_NONE)
   // The firmware is expected to write exit status and pass/fail indication to the Virtual Peripheral.
   // The format of rvfi_vif.tb_exit_o is { wire[31:1] exit_code, wire test_finished }.
   wait (
          (tb_exit_vif.tb_exit_o[0]  == 1'b1)
        );
   `uvm_info("TEST", "Test FINISHED", UVM_NONE)
   // Set sim_finished (otherwise tb will flag that sim was aborted)
   uvm_config_db#(bit)::set(null, "", "sim_finished", 1);
   uvm_config_db#(int)::set(null, "", "test_exit_code", { 1'b0, tb_exit_vif.tb_exit_o[31:1] });
   // Let the termination-triggering instruction appear in the log.
   @(posedge env_cntxt.clknrst_cntxt.vif.clk);
   // Let all pending AXI requests settle.
   // FIXME TODO: Insert this delay in AXI agent rather than here,
   // based on AXI state and latency setting.
   if (RTLCVA6Cfg.MemSubsystem != config_pkg::MEM_OBI) begin
      `uvm_info("TEST", "Running a 100-cycle delay to settle AXI requests...", UVM_NONE);
      repeat (100) @(posedge env_cntxt.clknrst_cntxt.vif.clk);
      `uvm_info("TEST", "Running a 100-cycle delay to settle AXI requests... DONE", UVM_NONE);
   end
   // Allow termination from now on.
   phase.drop_objection(this);

endtask : run_phase

`endif // __UVMT_CVA6_FIRMWARE_TEST_SV__
