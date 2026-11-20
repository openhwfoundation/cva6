// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technologies
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


`ifndef __UVMT_CVA6_BASE_TEST_SV__
`define __UVMT_CVA6_BASE_TEST_SV__


/**
 * Abstract component from which all other CVA6 test cases must
 * ultimately extend.
 * Subclasses must provide stimulus via the virtual sequencer by implementing
 * UVM runtime phases.
 */
class uvmt_cva6_base_test_c extends uvm_test;

   // Objects
   rand uvmt_cva6_test_cfg_c   test_cfg ;
   rand uvme_cva6_cfg_c        env_cfg  ;
   uvme_cva6_cntxt_c           env_cntxt;
   uvml_logs_rs_text_c             rs       ;
   uvml_logs_reg_logger_cbs_c      reg_cbs  ;

   // Components
   uvme_cva6_env_c   env       ;
   uvme_cva6_vsqr_c  vsequencer;

   typedef enum {
      UVMA_AXI_VERSION_1P1,
      UVMA_AXI_VERSION_1P2,
      UVMA_AXI_VERSION_1P3
   } uvma_axi_version_enum;

   // Handles testbench interfaces
   virtual uvmt_tb_exit_if tb_exit_vif;                // Exit vif
//   virtual uvmt_cva6_core_cntrl_if   core_cntrl_vif; // control inputs to the core

   // Default sequences
   rand uvme_cva6_reset_vseq_c  reset_vseq;

   // Variable can be modified from command line, to change the AXI agent mode
   int force_axi_mode = -1;

   uvm_factory             factory;


   `uvm_component_utils_begin(uvmt_cva6_base_test_c)
      `uvm_field_object(test_cfg , UVM_DEFAULT)
      `uvm_field_object(env_cfg  , UVM_DEFAULT)
      `uvm_field_object(env_cntxt, UVM_DEFAULT)
      `uvm_field_int (force_axi_mode , UVM_DEFAULT)
   `uvm_component_utils_end


   constraint env_cfg_cons {
      env_cfg.enabled         == 1;
      env_cfg.is_active       == UVM_ACTIVE;
      if (!env_cfg.performance_mode) {
         env_cfg.trn_log_enabled == 1;
      } else {
         env_cfg.trn_log_enabled           == 0;
         env_cfg.cov_model_enabled         == 0;
         env_cfg.force_disable_csr_checks  == 1;
         env_cfg.scoreboard_enabled        == 0;
         env_cfg.zero_obi_stall            == 1;
      }
   }

   constraint axi_agent_cfg_cons {
      force_axi_mode == -1  -> env_cfg.axi_cfg.is_active  == UVM_ACTIVE;
      force_axi_mode != -1  -> env_cfg.axi_cfg.is_active  == uvm_active_passive_enum'(force_axi_mode);
   }

   constraint test_type_default_cons {
     soft test_cfg.tpt == NO_TEST_PROGRAM;
   }

   constraint memory_region_cfg {
      env_cfg.axi_cfg.axi_region_enabled == 0;
      env_cfg.axi_cfg.axi_prot_enabled == 0;
      env_cfg.axi_cfg.m_addr_start == 64'h0;
      env_cfg.axi_cfg.m_addr_end == 64'h7fffffffffffffff;
      env_cfg.axi_cfg.m_num_part == 1;
      env_cfg.axi_cfg.m_part_st[0].axi_prot_type_access == 0;
      env_cfg.axi_cfg.m_part_st[0].m_type_access == 3;
   }


   /**
    * 1. Replaces default report server with rs.
    * 2. Creates reset_vseq.
    */
   extern function new(string name="uvmt_cva6_base_test", uvm_component parent=null);

   /**
    * 1. Builds test_cfg & env_cfg via create_cfg()
    * 2. Randomizes entire test class via randomize_test()
    * 3. Passes env_cfg to env via uvm_config_db via assign_cfg()
    * 4. Builds env_cntxt via create_cntxt()
    * 5. Passes env_cntxt to env using UVM Configuration Database via assign_cntxt()
    * 6. Builds env via create_env()
    * 7. Builds the rest of the components/objects via create_components()
    */
   extern virtual function void build_phase(uvm_phase phase);

   /**
    * 1. Assigns environment's virtual sequencer handle to vsequencer.
    * 2. Add register callback (reg_cbs) to all registers & fields.
    */
   extern virtual function void connect_phase(uvm_phase phase);

   /**
    * 1. Triggers the start of clock generation via start_clk()
    * 2. Starts the watchdog timeout via watchdog_timeout()
    */
   extern virtual task run_phase(uvm_phase phase);

   /**
    * Runs reset_vseq.
    */
   extern virtual task reset_phase(uvm_phase phase);

   /**
    * In a typical UVM env, this task writes contents of RAL to the DUT.
    * Here, test_cfg is used to determine if the test program is loaded into
    * the TB's instruction memory.
    */
   extern virtual task configure_phase(uvm_phase phase);

   /**
    * Prints out start of phase banners.
    */
   extern virtual function void phase_started(uvm_phase phase);

   /**
    * Indicates to the test bench (uvmt_cva6_tb) that the test has completed.
    * This is done by checking the properties of the phase argument.
    */
   extern virtual function void phase_ended(uvm_phase phase);

   /**
    * Retrieves virtual interfaces from UVM configuration database.
    */
   extern function void retrieve_vifs();

   /**
    * Creates test_cfg and env_cfg. Assigns ral handle to env_cfg's.
    */
   extern virtual function void create_cfg();

   extern virtual function void pkg_to_cfg();

   /**
    * 1. Calls test_cfg's process_cli_args()
    * 2. Calls randomize on 'this' and fatals out if it fails.
    */
   extern virtual function void randomize_test();

   /**
    * Configures uvml_default_hrtbt_monitor.
    */
   extern function void cfg_hrtbt_monitor();

   /**
    * Assigns environment configuration (env_cfg) handle to environment (env)
    * using UVM Configuration Database.
    */
   extern virtual function void assign_cfg();

   /**
    * Creates env_cntxt.
    */
   extern virtual function void create_cntxt();

   /**
    * Assigns environment context (env_cntxt) handle to environment (env) using
    * UVM Configuration Database.
    */
   extern virtual function void assign_cntxt();

   /**
    * Creates env.
    */
   extern virtual function void create_env();

   /**
    * Creates additional (non-environment) components (and objects).
    */
   extern virtual function void create_components();

   /**
    * Prints overlined and underlined text in uppercase.
    */
   extern function void print_banner(string text);

   /**
    * Fatals out after watchdog_timeout has elapsed.
    */
   extern virtual task watchdog_timer();

endclass : uvmt_cva6_base_test_c


function uvmt_cva6_base_test_c::new(string name="uvmt_cva6_base_test", uvm_component parent=null);

   super.new(name, parent);

   // Replaces default report server
   // Gives you short-and-sweet logger messages like this:
   //        UVM_INFO @ 9.750 ns : uvmt_cva6_dut_wrap.sv(79) reporter [DUT_WRAP] load_instr_mem asserted!
   rs = new("rs");


   // Terminate simulation after a "reasonable" number of errors
   uvm_report_server::set_server(rs);
   reset_vseq = uvme_cva6_reset_vseq_c::type_id::create("reset_vseq");
endfunction : new


function void uvmt_cva6_base_test_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   rs.set_max_quit_count(.count(5), .overridable(1));

   retrieve_vifs    ();
   create_cfg       ();
   randomize_test   ();
   pkg_to_cfg       ();
   cfg_hrtbt_monitor();
   assign_cfg       ();

   if (test_cfg.mem_vp_enabled == 1) begin
     set_type_override_by_type(uvml_mem_c#(cva6_config_pkg::CVA6ConfigAxiAddrWidth)::get_type(),
                               uvml_mem_vp_c#(cva6_config_pkg::CVA6ConfigAxiAddrWidth)::get_type());
   end

   create_cntxt     ();
   assign_cntxt     ();
   create_env       ();
   create_components();

   factory = uvm_factory::get();

   if(env_cfg.axi_cfg.version == 1) begin
      factory.set_type_override_by_name("uvma_axi_synchronizer_c", "uvma_axi_amo_synchronizer_c");
      `uvm_info("BASE TEST", $sformatf("AXI AMO SYNCHRONIZER"), UVM_LOW)
   end

   if(!env_cfg.axi_cfg.preload_mem) begin
      factory.set_type_override_by_name("uvma_axi_fw_preload_seq_c", "uvme_axi_fw_preload_seq_c");
      factory.set_type_override_by_name("uvma_obi_memory_fw_preload_seq_c", "uvme_obi_fw_preload_seq_c");
      factory.set_type_override_by_name("uvma_obi_memory_slv_seq_c", "uvme_obi_slv_seq_c");
   end

endfunction : build_phase


function void uvmt_cva6_base_test_c::connect_phase(uvm_phase phase);

   super.connect_phase(phase);

   vsequencer = env.vsequencer;
   uvm_reg_cb::add(null, reg_cbs);

endfunction : connect_phase


task uvmt_cva6_base_test_c::run_phase(uvm_phase phase);

   super.run_phase(phase);

   watchdog_timer();

endtask : run_phase


task uvmt_cva6_base_test_c::reset_phase(uvm_phase phase);

   super.reset_phase(phase);

   phase.raise_objection(this);

   `uvm_info("BASE TEST", $sformatf("Starting reset virtual sequence:\n%s", reset_vseq.sprint()), UVM_NONE)
   reset_vseq.start(vsequencer);
   `uvm_info("BASE TEST", $sformatf("Finished reset virtual sequence:\n%s", reset_vseq.sprint()), UVM_NONE)

   phase.drop_objection(this);

endtask : reset_phase


task uvmt_cva6_base_test_c::configure_phase(uvm_phase phase);

   uvm_status_e status;

   //super.configure_phase(phase);

   //`uvm_info("BASE TEST", $sformatf("Starting to update DUT with RAL contents:\n%s", ral.sprint()), UVM_NONE)
   //ral.update(status);
   //`uvm_info("BASE TEST", "Finished updating DUT with RAL contents", UVM_NONE)

   //TODO: is this OK?!?
   super.configure_phase(phase);
   `uvm_info("BASE TEST", "configure_phase() complete", UVM_HIGH)

endtask : configure_phase


function void uvmt_cva6_base_test_c::phase_started(uvm_phase phase);

   string  phase_name = phase.get_name();

   super.phase_started(phase);

   print_banner($sformatf("start of %s phase", phase_name));

endfunction : phase_started


function void uvmt_cva6_base_test_c::phase_ended(uvm_phase phase);

   super.phase_ended(phase);

   if (phase.is(uvm_final_phase::get())) begin
     // Set sim_finished (otherwise tb will flag that sim was aborted)
     uvm_config_db#(bit)::set(null, "", "sim_finished", 1);

     print_banner("test finished");
   end

endfunction : phase_ended


function void uvmt_cva6_base_test_c::retrieve_vifs();

   if (!uvm_config_db#(virtual uvmt_tb_exit_if)::get(this, "", "tb_exit_vif", tb_exit_vif)) begin
      `uvm_fatal("VIF", $sformatf("Could not find tb_exit_vif handle of type %s in uvm_config_db", $typename(tb_exit_vif)))
   end
   else begin
      `uvm_info("VIF", $sformatf("Found tb_exit_vif handle of type %s in uvm_config_db", $typename(tb_exit_vif)), UVM_DEBUG)
   end

endfunction : retrieve_vifs


function void uvmt_cva6_base_test_c::create_cfg();

   test_cfg = uvmt_cva6_test_cfg_c::type_id::create("test_cfg");
   env_cfg  = uvme_cva6_cfg_c     ::type_id::create("env_cfg" );
   //ral      = env_cfg.ral;

endfunction : create_cfg

function void uvmt_cva6_base_test_c::pkg_to_cfg();

    st_core_cntrl_cfg st = env_cfg.to_struct();
    st = cva6pkg_to_core_cntrl_cfg(st);

    env_cfg.from_struct(st);

    env_cfg.post_randomize();

endfunction : pkg_to_cfg

function void uvmt_cva6_base_test_c::randomize_test();

   test_cfg.process_cli_args();
   if (!this.randomize()) begin
      `uvm_fatal("BASE TEST", "Failed to randomize test");
   end
   `uvm_info("BASE TEST", $sformatf("Top-level environment configuration:\n%s", env_cfg.sprint()), UVM_HIGH)
   `uvm_info("BASE TEST", $sformatf("Testcase configuration:\n%s", test_cfg.sprint()), UVM_HIGH)

endfunction : randomize_test


function void uvmt_cva6_base_test_c::cfg_hrtbt_monitor();

   uvml_default_hrtbt.enabled = 0;
   //`uvml_hrtbt_set_cfg(startup_timeout , test_cfg.startup_timeout)
   uvml_default_hrtbt.startup_timeout = test_cfg.startup_timeout; // TODO DOP: Fix heartbeat macros
   //`uvml_hrtbt_set_cfg(heartbeat_period, test_cfg.heartbeat_period)
   uvml_default_hrtbt.startup_timeout = test_cfg.heartbeat_period; // TODO DOP: Fix heartbeat macros

endfunction : cfg_hrtbt_monitor


function void uvmt_cva6_base_test_c::assign_cfg();

   uvm_config_db#(uvme_cva6_cfg_c)::set(this, "env", "cfg", env_cfg);

endfunction : assign_cfg


function void uvmt_cva6_base_test_c::create_cntxt();

   env_cntxt = uvme_cva6_cntxt_c::type_id::create("env_cntxt");

endfunction : create_cntxt


function void uvmt_cva6_base_test_c::assign_cntxt();

   uvm_config_db#(uvme_cva6_cntxt_c)::set(this, "env", "cntxt", env_cntxt);

endfunction : assign_cntxt


function void uvmt_cva6_base_test_c::create_env();

   env = uvme_cva6_env_c::type_id::create("env", this);

endfunction : create_env


function void uvmt_cva6_base_test_c::create_components();

   reg_cbs = uvml_logs_reg_logger_cbs_c::type_id::create("reg_cbs");

endfunction : create_components


function void uvmt_cva6_base_test_c::print_banner(string text);

  if (test_cfg != null) begin
    if (test_cfg.print_uvm_runflow_banner) begin
      $display("");
      $display("*******************************************************************************");
      $display(text.toupper());
      $display("*******************************************************************************");
    end
    else begin
      `uvm_info("BASE_TEST", "Printing of UVM run-flow banner disabled", UVM_HIGH)
    end
  end

endfunction : print_banner


task uvmt_cva6_base_test_c::watchdog_timer();

   fork
      begin
         #(test_cfg.watchdog_timeout * 1ns);
         `uvm_fatal("TIMEOUT", $sformatf("Global timeout after %0dns. Heartbeat list:\n%s", test_cfg.watchdog_timeout, uvml_default_hrtbt.print_comp_names()))
      end
   join_none

endtask : watchdog_timer


`endif // __UVMT_CVA6_BASE_TEST_SV__
