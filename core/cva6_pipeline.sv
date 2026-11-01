// Copyright 2017-2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: CVA6 Core module

`include "ypb_types.svh"
`include "rvfi_types.svh"
`include "cvxif_types.svh"

module cva6_pipeline
  import ariane_pkg::*;
#(
    // CVA6 config
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,

    // RVFI PROBES
    parameter type rvfi_probes_t = logic,

    // YPB Types
    parameter type ypb_fetch_req_t = logic,
    parameter type ypb_fetch_rsp_t = logic,
    parameter type ypb_store_req_t = logic,
    parameter type ypb_store_rsp_t = logic,
    parameter type ypb_amo_req_t = logic,
    parameter type ypb_amo_rsp_t = logic,
    parameter type ypb_load_req_t = logic,
    parameter type ypb_load_rsp_t = logic,
    parameter type ypb_mmu_ptw_req_t = logic,
    parameter type ypb_mmu_ptw_rsp_t = logic,
    parameter type ypb_zcmt_req_t = logic,
    parameter type ypb_zcmt_rsp_t = logic,

    // CVXIF Types
    parameter type readregflags_t = logic,
    parameter type writeregflags_t = logic,
    parameter type id_t = logic,
    parameter type hartid_t = logic,
    parameter type x_compressed_req_t = logic,
    parameter type x_compressed_resp_t = logic,
    parameter type x_issue_req_t = logic,
    parameter type x_issue_resp_t = logic,
    parameter type x_register_t = logic,
    parameter type x_commit_t = logic,
    parameter type x_result_t = logic,
    parameter type cvxif_req_t = logic,
    parameter type cvxif_resp_t = logic,

    // DCLS
    parameter type regfile_inputs_t = logic,
    parameter type bht_inputs_t = logic,
    parameter type dcls_common_modules_ctrl_t = logic,
    parameter type dcls_common_modules_data_t = logic

) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Reset boot address - SUBSYSTEM
    input logic [CVA6Cfg.VLEN-1:0] boot_addr_i,
    // Hard ID reflected as CSR - SUBSYSTEM
    input logic [CVA6Cfg.XLEN-1:0] hart_id_i,
    // Level sensitive (async) interrupts - SUBSYSTEM
    input logic [1:0] irq_i,
    // Inter-processor (async) interrupt - SUBSYSTEM
    input logic ipi_i,
    // Timer (async) interrupt - SUBSYSTEM
    input logic time_irq_i,
    // Debug (async) request - SUBSYSTEM
    input logic debug_req_i,
    // Probes to build RVFI, can be left open when not used - RVFI
    output rvfi_probes_t rvfi_probes_o,
    // CVXIF request - SUBSYSTEM
    output cvxif_req_t cvxif_req_o,
    // CVXIF response - SUBSYSTEM
    input cvxif_resp_t cvxif_resp_i,

    // I$
    // Instruction cache enable - CSR_REGFILE
    output logic icache_enable_o,
    // Flush the instruction cache - CONTROLLER
    output logic icache_flush_o,
    // instruction cache miss - PERF_COUNTERS
    input  logic icache_miss_i,

    // D$
    // Data cache enable - CSR_REGFILE
    output logic dcache_enable_o,
    // Data cache scrubber enable - CSR_REGFILE
    output logic dcache_scrub_enable_o,
    // Data cache scrubber period - CSR_REGFILE
    output logic [5:0] dcache_scrub_period_o,
    // Data cache scrubber completed a cycle - CACHES
    input logic dcache_scrub_cycle_i,
    // Data cache data error corrected - CACHES
    input logic dcache_dat_cor_err_i,
    // Data cache data error detected but not corrected - CACHES
    input logic dcache_dat_unc_err_i,
    // Data cache tag error corrected - CACHES
    input logic dcache_dir_cor_err_i,
    // Data cache tag error detected but not corrected - CACHES
    input logic dcache_dir_unc_err_i,
    // Data cache flush (high until acknowledged)- CONTROLLER
    output logic dcache_flush_o,
    // Flush acknowledge (send a single cycle acknowledge signal when the cache is flushed) - CONTROLLER
    input logic dcache_flush_ack_i,
    // Load or store miss - PERF_COUNTERS
    input logic dcache_miss_i,

    // Memory interfaces
    // Fetch YPB request ports - FRONTEND
    output ypb_fetch_req_t ypb_fetch_req_o,
    // Fetch YPB response ports - FRONTEND
    input  ypb_fetch_rsp_t ypb_fetch_rsp_i,

    // Store YPB request ports - EX_STAGE
    output ypb_store_req_t ypb_store_req_o,
    // Store YPB response ports - EX_STAGE
    input  ypb_store_rsp_t ypb_store_rsp_i,

    // AMO YPB request - EX_STAGE
    output ypb_amo_req_t ypb_amo_req_o,
    // AMO YPB response - EX_STAGE
    input  ypb_amo_rsp_t ypb_amo_rsp_i,

    // Load YPB request ports - EX_STAGE
    output ypb_load_req_t ypb_load_req_o,
    // Load YPB response ports - EX_STAGE
    input  ypb_load_rsp_t ypb_load_rsp_i,

    // MMU Page table walker YPB request ports - EX_STAGE
    output ypb_mmu_ptw_req_t ypb_mmu_ptw_req_o,
    // MMU Page table walker YPB response ports - EX_STAGE
    input  ypb_mmu_ptw_rsp_t ypb_mmu_ptw_rsp_i,

    // Zcmt YPB request ports - ID_STAGE
    output ypb_zcmt_req_t ypb_zcmt_req_o,
    // Zcmt YPB response ports - ID_STAGE
    input  ypb_zcmt_rsp_t ypb_zcmt_rsp_i,

    // Write buffer status to know if empty - EX_STAGE
    input logic dcache_wbuffer_empty_i,
    // Write buffer status to know if not non idempotent - EX_STAGE
    input logic dcache_wbuffer_not_ni_i,
    // DCLS
    input dcls_common_modules_data_t dcls_from_common_i,
    output dcls_common_modules_ctrl_t dcls_to_common_o
);

  localparam type rvfi_probes_instr_t = `RVFI_PROBES_INSTR_T(CVA6Cfg);
  localparam type rvfi_probes_csr_t = `RVFI_PROBES_CSR_T(CVA6Cfg);

  localparam type exception_t = struct packed {
    logic [CVA6Cfg.XLEN-1:0] cause;  // cause of exception
    logic [CVA6Cfg.XLEN-1:0] tval;  // additional information of causing exception (e.g.: instruction causing it),
    // address of LD/ST fault
    logic [CVA6Cfg.GPLEN-1:0] tval2;  // additional information when the causing exception in a guest exception
    logic [31:0] tinst;  // transformed instruction information
    logic gva;  // signals when a guest virtual address is written to tval
    logic valid;
    // Timing of the exception. 0 breaks on the instruction itself, 1 breaks
    // immediately after it, letting that one instruction commit first. Only
    // the mcontrol6 load data trigger needs the latter: the value it compares
    // does not exist until the load has returned.
    logic timing;
  };

  // Fetch  address translation requests
  localparam type fetch_areq_t = struct packed {
    logic                    fetch_req;    // address translation request
    logic [CVA6Cfg.VLEN-1:0] fetch_vaddr;  // virtual address out
  };

  localparam type fetch_arsp_t = struct packed {
    exception_t              fetch_exception;  // exception occurred during fetch
    logic                    fetch_valid;      // address translation valid
    logic [CVA6Cfg.PLEN-1:0] fetch_paddr;      // physical address in
  };

  // branchpredict scoreboard entry
  // this is the struct which we will inject into the pipeline to guide the various
  // units towards the correct branch decision and resolve
  localparam type branchpredict_sbe_t = struct packed {
    logic                    valid;            // valid control flow prediction
    cf_t                     cf;               // type of control flow prediction
    logic [CVA6Cfg.VLEN-1:0] predict_address;  // target address at which to jump, or not
  };

  // IF/ID Stage
  // store the decompressed instruction
  localparam type fetch_entry_t = struct packed {
    logic [CVA6Cfg.VLEN-1:0] address;  // the address of the instructions from below
    logic [31:0] instruction;  // instruction word
    branchpredict_sbe_t     branch_predict; // this field contains branch prediction information regarding the forward branch path
    exception_t             ex;             // this field contains exceptions which might have happened earlier, e.g.: fetch exceptions
  };

  //JVT struct{base,mode}
  localparam type jvt_t = struct packed {
    logic [CVA6Cfg.XLEN-7:0] base;
    logic [5:0] mode;
  };

  // ID/EX/WB Stage
  localparam type scoreboard_entry_t = struct packed {
    logic [CVA6Cfg.VLEN-1:0] pc;  // PC of instruction
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;      // this can potentially be simplified, we could index the scoreboard entry
    // with the transaction id in any case make the width more generic
    fu_t fu;  // functional unit to use
    fu_op op;  // operation to perform in each functional unit
    logic [REG_ADDR_SIZE-1:0] rs1;  // register source address 1
    logic [REG_ADDR_SIZE-1:0] rs2;  // register source address 2
    logic [REG_ADDR_SIZE-1:0] rd;  // register destination address
    logic [CVA6Cfg.XLEN-1:0] result;  // for unfinished instructions this field also holds the immediate,
    // for unfinished floating-point that are partly encoded in rs2, this field also holds rs2
    // for unfinished floating-point fused operations (FMADD, FMSUB, FNMADD, FNMSUB)
    // this field holds the address of the third operand from the floating-point register file
    logic valid;  // is the result valid
    logic use_imm;  // should we use the immediate as operand b?
    logic use_zimm;  // use zimm as operand a
    logic use_pc;  // set if we need to use the PC as operand a, PC from exception
    exception_t ex;  // exception has occurred
    branchpredict_sbe_t bp;  // branch predict scoreboard data structure
    logic                     is_compressed; // signals a compressed instructions, we need this information at the commit stage if
                                             // we want jump accordingly e.g.: +4, +2
    logic is_macro_instr;  // is an instruction executed as predefined sequence of instructions called macro definition
    logic is_last_macro_instr;  // is last decoded 32bit instruction of macro definition
    logic is_double_rd_macro_instr;  // is double move decoded 32bit instruction of macro definition
    logic is_zcmt;  //is a zcmt instruction
  };
  localparam type writeback_t = struct packed {
    logic valid;  // wb data is valid
    logic [CVA6Cfg.XLEN-1:0] data;  //wb data
    logic ex_valid;  // exception from WB
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;  //transaction ID
  };

  // branch-predict
  // this is the struct we get back from ex stage and we will use it to update
  // all the necessary data structures
  // bp_resolve_t
  localparam type bp_resolve_t = struct packed {
    logic                    valid;           // prediction with all its values is valid
    logic [CVA6Cfg.VLEN-1:0] pc;              // PC of predict or mis-predict
    logic [CVA6Cfg.VLEN-1:0] target_address;  // target address at which to jump, or not
    logic                    is_mispredict;   // set if this was a mis-predict
    logic                    is_taken;        // branch is taken
    cf_t                     cf_type;         // Type of control flow change
  };

  // All information needed to determine whether we need to associate an interrupt
  // with the corresponding instruction or not.
  localparam type irq_ctrl_t = struct packed {
    logic [CVA6Cfg.XLEN-1:0] mie;
    logic [CVA6Cfg.XLEN-1:0] mip;
    logic [CVA6Cfg.XLEN-1:0] mideleg;
    logic [CVA6Cfg.XLEN-1:0] hideleg;
    logic                    sie;
    logic                    global_enable;
  };

  localparam type lsu_ctrl_t = struct packed {
    logic                             valid;
    logic [CVA6Cfg.VLEN-1:0]          vaddr;
    logic [31:0]                      tinst;
    logic                             hs_ld_st_inst;
    logic                             hlvx_inst;
    logic                             overflow;
    logic                             g_overflow;
    logic [CVA6Cfg.XLEN-1:0]          data;
    logic [(CVA6Cfg.XLEN/8)-1:0]      be;
    fu_t                              fu;
    fu_op                             operation;
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;
  };

  localparam type fu_data_t = struct packed {
    fu_t                              fu;
    fu_op                             operation;
    logic [CVA6Cfg.XLEN-1:0]          operand_a;
    logic [CVA6Cfg.XLEN-1:0]          operand_b;
    logic [CVA6Cfg.XLEN-1:0]          imm;
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;
  };


  // ------------------------------------------
  // Global Signals
  // Signals connecting more than one module
  // ------------------------------------------
  riscv::priv_lvl_t                               priv_lvl;
  logic                                           mbe;  // data endianness of the processor
  logic                                           v;
  exception_t                                     ex_commit;  // exception from commit stage
  bp_resolve_t                                    resolved_branch;
  logic               [         CVA6Cfg.VLEN-1:0] pc_commit;
  logic                                           eret;
  logic               [CVA6Cfg.NrCommitPorts-1:0] commit_ack;
  logic               [CVA6Cfg.NrCommitPorts-1:0] commit_macro_ack;

  // CVXIF
  cvxif_req_t                                     cvxif_req;
  // CVXIF OUTPUTS
  logic                                           x_compressed_valid;
  x_compressed_req_t                              x_compressed_req;
  logic                                           x_issue_valid;
  x_issue_req_t                                   x_issue_req;
  logic                                           x_register_valid;
  x_register_t                                    x_register;
  logic                                           x_commit_valid;
  x_commit_t                                      x_commit;
  logic                                           x_result_ready;
  // CVXIF INPUTS
  logic                                           x_compressed_ready;
  x_compressed_resp_t                             x_compressed_resp;
  logic                                           x_issue_ready;
  x_issue_resp_t                                  x_issue_resp;
  logic                                           x_register_ready;
  logic                                           x_result_valid;
  x_result_t                                      x_result;

  // --------------
  // PCGEN <-> CSR
  // --------------
  logic               [         CVA6Cfg.VLEN-1:0] trap_vector_base_commit_pcgen;
  logic               [         CVA6Cfg.VLEN-1:0] epc_commit_pcgen;
  // --------------
  // IF <-> ID
  // --------------
  fetch_entry_t       [ CVA6Cfg.NrIssuePorts-1:0] fetch_entry_if_id;
  logic               [ CVA6Cfg.NrIssuePorts-1:0] fetch_valid_if_id;
  logic               [ CVA6Cfg.NrIssuePorts-1:0] fetch_ready_id_if;

  // --------------
  // ID <-> ISSUE
  // --------------
  scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] issue_entry_id_issue, issue_entry_id_issue_prev;
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] orig_instr_id_issue;
  logic [CVA6Cfg.NrIssuePorts-1:0] was_compressed;
  logic [CVA6Cfg.NrIssuePorts-1:0] issue_entry_valid_id_issue;
  logic [CVA6Cfg.NrIssuePorts-1:0] is_ctrl_fow_id_issue;
  logic [CVA6Cfg.NrIssuePorts-1:0] issue_instr_issue_id;

  // --------------
  // ISSUE <-> EX
  // --------------
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.VLEN-1:0] rs1_forwarding_id_ex;  // unregistered version of fu_data_o.operanda
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.VLEN-1:0] rs2_forwarding_id_ex;  // unregistered version of fu_data_o.operandb
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rvfi_rs1;
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rvfi_rs2;

  fu_data_t [CVA6Cfg.NrIssuePorts-1:0] fu_data_id_ex;
  alu_bypass_t alu_bypass_id_ex;
  logic [CVA6Cfg.VLEN-1:0] pc_id_ex;
  logic zcmt_id_ex;
  logic is_compressed_instr_id_ex;
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] tinst_ex;
  // fixed latency units
  logic flu_ready_ex_id;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] flu_trans_id_ex_id;
  logic flu_valid_ex_id;
  logic [CVA6Cfg.XLEN-1:0] flu_result_ex_id;
  exception_t flu_exception_ex_id;
  // ALU
  logic [CVA6Cfg.NrIssuePorts-1:0] alu_valid_id_ex;
  logic [5:0] orig_instr_aes;
  logic [CVA6Cfg.NrIssuePorts-1:0] aes_valid_id_ex;
  // Branches and Jumps
  logic [CVA6Cfg.NrIssuePorts-1:0] branch_valid_id_ex;

  branchpredict_sbe_t branch_predict_id_ex;
  logic resolve_branch_ex_id;
  // LSU
  logic [CVA6Cfg.NrIssuePorts-1:0] lsu_valid_id_ex;
  logic lsu_ready_ex_id;

  logic [CVA6Cfg.TRANS_ID_BITS-1:0] load_trans_id_ex_id;
  logic [CVA6Cfg.XLEN-1:0] load_result_ex_id;
  logic load_valid_ex_id;
  exception_t load_exception_ex_id;

  logic [CVA6Cfg.XLEN-1:0] store_result_ex_id;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] store_trans_id_ex_id;
  logic store_valid_ex_id;
  exception_t store_exception_ex_id;
  // MULT
  logic [CVA6Cfg.NrIssuePorts-1:0] mult_valid_id_ex;
  // FPU
  logic fpu_ready_ex_id;
  logic fpu_early_valid_ex_id;
  logic [CVA6Cfg.NrIssuePorts-1:0] fpu_valid_id_ex;
  logic [1:0] fpu_fmt_id_ex;
  logic [2:0] fpu_rm_id_ex;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] fpu_trans_id_ex_id;
  logic [CVA6Cfg.XLEN-1:0] fpu_result_ex_id;
  logic fpu_valid_ex_id;
  exception_t fpu_exception_ex_id;
  // ALU2
  logic [CVA6Cfg.NrIssuePorts-1:0] alu2_valid_id_ex;
  // CSR
  logic [CVA6Cfg.NrIssuePorts-1:0] csr_valid_id_ex;
  logic csr_hs_ld_st_inst_ex;
  // CVXIF
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] x_trans_id_ex_id;
  logic [CVA6Cfg.XLEN-1:0] x_result_ex_id;
  logic x_valid_ex_id;
  exception_t x_exception_ex_id;
  logic x_we_ex_id;
  logic [4:0] x_rd_ex_id;
  logic [CVA6Cfg.NrIssuePorts-1:0] x_issue_valid_id_ex;
  logic x_issue_ready_ex_id;
  logic [31:0] x_off_instr_id_ex;
  logic x_transaction_rejected;
  // --------------
  // EX <-> COMMIT
  // --------------
  // CSR Commit
  logic csr_commit_commit_ex;
  logic dirty_fp_state;
  // LSU Commit
  logic lsu_commit_commit_ex;
  logic lsu_commit_ready_ex_commit;
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] lsu_commit_trans_id;
  logic no_st_pending_ex;
  logic no_st_pending_commit;
  logic shared_tlb_flush_busy_ex;
  logic amo_valid_commit;
  // --------------
  // ID <-> COMMIT
  // --------------
  scoreboard_entry_t [CVA6Cfg.NrCommitPorts-1:0] commit_instr_id_commit;
  logic [CVA6Cfg.NrCommitPorts-1:0] commit_drop_id_commit;
  logic [CVA6Cfg.NrCommitPorts-1:0] commit_ack_commit_id;

  // --------------
  // RVFI
  // --------------
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] rvfi_issue_pointer;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] rvfi_commit_pointer;
  // --------------
  // COMMIT <-> ID
  // --------------
  logic [CVA6Cfg.NrCommitPorts-1:0][4:0] waddr_commit_id;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] wdata_commit_id;
  logic [CVA6Cfg.NrCommitPorts-1:0] we_gpr_commit_id;
  logic [CVA6Cfg.NrCommitPorts-1:0] we_fpr_commit_id;
  // --------------
  // CSR <-> *
  // --------------
  logic [4:0] fflags_csr_commit;
  riscv::xs_t fs;
  riscv::xs_t vfs;
  logic [2:0] frm_csr_id_issue_ex;
  logic [6:0] fprec_csr_ex;
  logic enable_translation_csr_ex;
  logic enable_g_translation_csr_ex;
  logic en_ld_st_translation_csr_ex;
  logic en_ld_st_g_translation_csr_ex;
  riscv::priv_lvl_t ld_st_priv_lvl_csr_ex;
  logic ld_st_v_csr_ex;
  logic sum_csr_ex;
  logic vs_sum_csr_ex;
  logic mxr_csr_ex;
  logic vmxr_csr_ex;
  logic [CVA6Cfg.PPNW-1:0] satp_ppn_csr_ex;
  logic [CVA6Cfg.ASID_WIDTH-1:0] asid_csr_ex;
  logic [CVA6Cfg.PPNW-1:0] vsatp_ppn_csr_ex;
  logic [CVA6Cfg.ASID_WIDTH-1:0] vs_asid_csr_ex;
  logic [CVA6Cfg.PPNW-1:0] hgatp_ppn_csr_ex;
  logic [CVA6Cfg.VMID_WIDTH-1:0] vmid_csr_ex;
  logic [11:0] csr_addr_ex_csr;
  fu_op csr_op_commit_csr;
  logic [CVA6Cfg.XLEN-1:0] csr_wdata_commit_csr;
  logic [CVA6Cfg.XLEN-1:0] csr_rdata_csr_commit;
  exception_t csr_exception_csr_commit;
  logic tvm_csr_id;
  logic tw_csr_id;
  logic vtw_csr_id;
  logic tsr_csr_id;
  logic hu;
  riscv::cbie_t mcbie, scbie, hcbie;
  logic mcbcfe, scbcfe, hcbcfe;
  irq_ctrl_t irq_ctrl_csr_id;
  logic dcache_en_csr_nbdcache;
  logic csr_write_fflags_commit_cs;
  logic icache_en_csr;
  logic debug_mode;
  logic single_step_csr_commit;
  riscv::pmpcfg_t [avoid_neg(CVA6Cfg.NrPMPEntries-1):0] pmpcfg;
  logic [avoid_neg(CVA6Cfg.NrPMPEntries-1):0][CVA6Cfg.PLEN-3:0] pmpaddr;
  logic [31:0] mcountinhibit_csr_perf;
  //jvt
  jvt_t jvt;
  // trigger module
  logic
      sdtrig_commit_std_exception_valid,
      sdtrig_sb_std_exception_valid,
      sdtrig_load_cancel,
      sdtrig_store_stall;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_decoder_action[CVA6Cfg.NrIssuePorts];
  logic [CVA6Cfg.XLEN-1:0] sdtrig_load_action, sdtrig_store_action, sdtrig_commit_action;
  // Load data trigger: data of the load retiring in the load unit, and the break
  logic sdtrig_load_data_valid;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_load_data, sdtrig_load_data_action;
  logic [CVA6Cfg.VLEN-1:0] sdtrig_lsu_inputs_operand_a;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_lsu_inputs_operand_c;
  logic sdtrig_lsu_inputs_we, sdtrig_lsu_inputs_valid;
  logic sdtrig_commit_icount_valid;
  logic [(CVA6Cfg.NrCommitPorts > 1 ? $clog2(
CVA6Cfg.NrCommitPorts
) : 1)-1:0] sdtrig_commit_icount_nr_instr;
  // ----------------------------
  // Performance Counters <-> *
  // ----------------------------
  logic [11:0] addr_csr_perf;
  logic [CVA6Cfg.XLEN-1:0] data_csr_perf, data_perf_csr;
  logic we_csr_perf;

  logic icache_flush_ctrl_cache;
  logic itlb_miss_ex_perf;
  logic dtlb_miss_ex_perf;
  logic dcache_miss_cache_perf;
  logic icache_miss_cache_perf;
  logic stall_issue;
  // --------------
  // CTRL <-> *
  // --------------
  logic set_pc_ctrl_pcgen;
  logic flush_csr_ctrl;
  logic flush_unissued_instr_ctrl_id;
  logic flush_ctrl_if;
  logic flush_ctrl_id;
  logic flush_ctrl_ex;
  logic flush_ctrl_bp;
  logic flush_tlb_ctrl_ex;
  logic flush_tlb_vvma_ctrl_ex;
  logic flush_tlb_gvma_ctrl_ex;
  logic fence_i_commit_controller;
  logic fence_commit_controller;
  logic sfence_vma_commit_controller;
  logic hfence_vvma_commit_controller;
  logic hfence_gvma_commit_controller;
  logic halt_ctrl;
  logic halt_frontend_ctrl;
  logic halt_csr_ctrl;
  logic dcache_flush_ctrl_cache;
  logic dcache_flush_ack_cache_ctrl;
  logic set_debug_pc;
  logic flush_commit;

  fetch_arsp_t fetch_arsp_ex_frontend;
  fetch_areq_t fetch_areq_frontend_ex;

  logic sb_full;

  //RVFI
  lsu_ctrl_t rvfi_lsu_ctrl;
  logic [CVA6Cfg.PLEN-1:0] rvfi_mem_paddr;
  logic [CVA6Cfg.NrIssuePorts-1:0] rvfi_is_compressed;
  rvfi_probes_csr_t rvfi_csr;

  // --------------
  // Frontend
  // --------------
  bht_inputs_t bht_to_common;
  bht_prediction_t [CVA6Cfg.INSTR_PER_FETCH-1:0] bht_from_common;

  frontend #(
      .CVA6Cfg(CVA6Cfg),
      .bp_resolve_t(bp_resolve_t),
      .fetch_entry_t(fetch_entry_t),
      .fetch_areq_t(fetch_areq_t),
      .fetch_arsp_t(fetch_arsp_t),
      .ypb_fetch_req_t(ypb_fetch_req_t),
      .ypb_fetch_rsp_t(ypb_fetch_rsp_t),
      .bht_inputs_t(bht_inputs_t)
  ) i_frontend (
      .clk_i,
      .rst_ni,
      .boot_addr_i           (boot_addr_i[CVA6Cfg.VLEN-1:0]),
      .flush_bp_i            ((CVA6Cfg.RVU || CVA6Cfg.RVS) ? flush_ctrl_bp : 1'b0),
      .flush_i               (flush_ctrl_if),
      .halt_i                (halt_ctrl),
      .halt_frontend_i       (halt_frontend_ctrl),
      .set_pc_commit_i       (set_pc_ctrl_pcgen),
      .pc_commit_i           (pc_commit),
      .ex_valid_i            (ex_commit.valid),
      .resolved_branch_i     (resolved_branch),
      .eret_i                (eret),
      .epc_i                 (epc_commit_pcgen),
      .trap_vector_base_i    (trap_vector_base_commit_pcgen),
      .set_debug_pc_i        (set_debug_pc),
      .debug_mode_i          (debug_mode),
      .areq_o                (fetch_areq_frontend_ex),
      .arsp_i                (fetch_arsp_ex_frontend),
      .ypb_fetch_req_o       (ypb_fetch_req_o),
      .ypb_fetch_rsp_i       (ypb_fetch_rsp_i),
      .fetch_entry_o         (fetch_entry_if_id),
      .fetch_entry_valid_o   (fetch_valid_if_id),
      .fetch_entry_ready_i   (fetch_ready_id_if),
      .dcls_common_bht_data_i(bht_from_common),
      .dcls_common_bht_ctrl_o(bht_to_common)
  );

  if (CVA6Cfg.DclsEn & CVA6Cfg.DclsCommonBHT) begin
    assign bht_from_common = dcls_from_common_i.bht_prediction;
    assign dcls_to_common_o.bht_inputs = bht_to_common;
  end else begin
    assign bht_from_common = '0;
  end

  // ---------
  // ID
  // ---------
  id_stage #(
      .CVA6Cfg(CVA6Cfg),
      .branchpredict_sbe_t(branchpredict_sbe_t),
      .ypb_zcmt_req_t(ypb_zcmt_req_t),
      .ypb_zcmt_rsp_t(ypb_zcmt_rsp_t),
      .exception_t(exception_t),
      .fetch_entry_t(fetch_entry_t),
      .jvt_t(jvt_t),
      .irq_ctrl_t(irq_ctrl_t),
      .scoreboard_entry_t(scoreboard_entry_t),
      .x_compressed_req_t(x_compressed_req_t),
      .x_compressed_resp_t(x_compressed_resp_t)
  ) id_stage_i (
      .clk_i,
      .rst_ni,
      .flush_i(flush_ctrl_if),
      .debug_req_i,

      .fetch_entry_i          (fetch_entry_if_id),
      .sdtrig_decoder_action_i(sdtrig_decoder_action),
      .fetch_entry_valid_i    (fetch_valid_if_id),
      .fetch_entry_ready_o    (fetch_ready_id_if),

      .issue_entry_o       (issue_entry_id_issue),
      .issue_entry_o_prev  (issue_entry_id_issue_prev),
      .orig_instr_o        (orig_instr_id_issue),
      .was_compressed_o    (was_compressed),
      .issue_entry_valid_o (issue_entry_valid_id_issue),
      .is_ctrl_flow_o      (is_ctrl_fow_id_issue),
      .issue_instr_ack_i   (issue_instr_issue_id),
      .rvfi_is_compressed_o(rvfi_is_compressed),
      .priv_lvl_i          (priv_lvl),
      .v_i                 (v),
      .fs_i                (fs),
      .vfs_i               (vfs),
      .frm_i               (frm_csr_id_issue_ex),
      .irq_i               (irq_i),
      .irq_ctrl_i          (irq_ctrl_csr_id),
      .debug_mode_i        (debug_mode),
      .tvm_i               (tvm_csr_id),
      .tw_i                (tw_csr_id),
      .vtw_i               (vtw_csr_id),
      .tsr_i               (tsr_csr_id),
      .hu_i                (hu),
      .mcbie_i             (mcbie),
      .scbie_i             (scbie),
      .hcbie_i             (hcbie),
      .mcbcfe_i            (mcbcfe),
      .scbcfe_i            (scbcfe),
      .hcbcfe_i            (hcbcfe),
      .hart_id_i           (hart_id_i),
      .jvt_i               (jvt),
      .compressed_ready_i  (x_compressed_ready),
      .compressed_resp_i   (x_compressed_resp),
      .compressed_valid_o  (x_compressed_valid),
      .compressed_req_o    (x_compressed_req),
      // ZCMT interfaces
      .ypb_zcmt_req_o      (ypb_zcmt_req_o),
      .ypb_zcmt_rsp_i      (ypb_zcmt_rsp_i)

  );

  logic [CVA6Cfg.NrWbPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] trans_id_ex_id;
  logic [CVA6Cfg.NrWbPorts-1:0][CVA6Cfg.XLEN-1:0] wbdata_ex_id;
  exception_t [CVA6Cfg.NrWbPorts-1:0] ex_ex_ex_id;  // exception from execute, ex_stage to id_stage
  logic [CVA6Cfg.NrWbPorts-1:0] wt_valid_ex_id;

  assign trans_id_ex_id[FLU_WB] = flu_trans_id_ex_id;
  assign wbdata_ex_id[FLU_WB]   = flu_result_ex_id;
  assign ex_ex_ex_id[FLU_WB]    = flu_exception_ex_id;
  assign wt_valid_ex_id[FLU_WB] = flu_valid_ex_id;

  assign trans_id_ex_id[STORE_WB] = store_trans_id_ex_id;
  assign wbdata_ex_id[STORE_WB]   = store_result_ex_id;
  assign ex_ex_ex_id[STORE_WB]    = store_exception_ex_id;
  assign wt_valid_ex_id[STORE_WB] = store_valid_ex_id;

  assign trans_id_ex_id[LOAD_WB] = load_trans_id_ex_id;
  assign wbdata_ex_id[LOAD_WB]   = load_result_ex_id;
  assign ex_ex_ex_id[LOAD_WB]    = load_exception_ex_id;
  assign wt_valid_ex_id[LOAD_WB] = load_valid_ex_id;

  assign trans_id_ex_id[FPU_WB] = fpu_trans_id_ex_id;
  assign wbdata_ex_id[FPU_WB]   = fpu_result_ex_id;
  assign ex_ex_ex_id[FPU_WB]    = fpu_exception_ex_id;
  assign wt_valid_ex_id[FPU_WB] = fpu_valid_ex_id;

  always_comb begin : gen_cvxif_input_assignment
    x_compressed_ready = cvxif_resp_i.compressed_ready;
    x_compressed_resp  = cvxif_resp_i.compressed_resp;
    x_issue_ready      = cvxif_resp_i.issue_ready;
    x_issue_resp       = cvxif_resp_i.issue_resp;
    x_register_ready   = cvxif_resp_i.register_ready;
    x_result_valid     = cvxif_resp_i.result_valid;
    x_result           = cvxif_resp_i.result;
  end
  if (CVA6Cfg.CvxifEn) begin
    always_comb begin : gen_cvxif_output_assignment
      cvxif_req.compressed_valid = x_compressed_valid;
      cvxif_req.compressed_req   = x_compressed_req;
      cvxif_req.issue_valid      = x_issue_valid;
      cvxif_req.issue_req        = x_issue_req;
      cvxif_req.register_valid   = x_register_valid;
      cvxif_req.register         = x_register;
      cvxif_req.commit_valid     = x_commit_valid;
      cvxif_req.commit           = x_commit;
      cvxif_req.result_ready     = x_result_ready;
    end
    assign trans_id_ex_id[X_WB] = x_trans_id_ex_id;
    assign wbdata_ex_id[X_WB]   = x_result_ex_id;
    assign ex_ex_ex_id[X_WB]    = x_exception_ex_id;
    assign wt_valid_ex_id[X_WB] = x_valid_ex_id;
  end else begin
    assign cvxif_req = '0;
  end
  assign cvxif_req_o = cvxif_req;

  // ---------
  // Issue
  // ---------

  regfile_inputs_t common_regfile_ctrl;
  logic [CVA6Cfg.NrRgprPorts-1:0][CVA6Cfg.XLEN-1:0] common_regfile_rdata;

  issue_stage #(
      .CVA6Cfg            (CVA6Cfg),
      .bp_resolve_t       (bp_resolve_t),
      .branchpredict_sbe_t(branchpredict_sbe_t),
      .exception_t        (exception_t),
      .fu_data_t          (fu_data_t),
      .scoreboard_entry_t (scoreboard_entry_t),
      .writeback_t        (writeback_t),
      .x_issue_req_t      (x_issue_req_t),
      .x_issue_resp_t     (x_issue_resp_t),
      .x_register_t       (x_register_t),
      .x_commit_t         (x_commit_t),
      .regfile_inputs_t   (regfile_inputs_t)
  ) issue_stage_i (
      .clk_i,
      .rst_ni,
      .sb_full_o               (sb_full),
      .flush_unissued_instr_i  (flush_unissued_instr_ctrl_id),
      .flush_i                 (flush_ctrl_id),
      // ID Stage
      .decoded_instr_i         (issue_entry_id_issue),
      .decoded_instr_i_prev    (issue_entry_id_issue_prev),
      .orig_instr_i            (orig_instr_id_issue),
      .decoded_instr_valid_i   (issue_entry_valid_id_issue),
      .is_ctrl_flow_i          (is_ctrl_fow_id_issue),
      .decoded_instr_ack_o     (issue_instr_issue_id),
      // Functional Units
      .rs1_forwarding_o        (rs1_forwarding_id_ex),
      .rs2_forwarding_o        (rs2_forwarding_id_ex),
      .fu_data_o               (fu_data_id_ex),
      .alu_bypass_o            (alu_bypass_id_ex),
      .pc_o                    (pc_id_ex),
      .is_zcmt_o               (zcmt_id_ex),
      .is_compressed_instr_o   (is_compressed_instr_id_ex),
      .tinst_o                 (tinst_ex),
      // fixed latency unit ready
      .flu_ready_i             (flu_ready_ex_id),
      // ALU
      .alu_valid_o             (alu_valid_id_ex),
      .aes_valid_o             (aes_valid_id_ex),
      // Branches and Jumps
      .branch_valid_o          (branch_valid_id_ex),            // branch is valid
      .branch_predict_o        (branch_predict_id_ex),          // branch predict to ex
      .resolve_branch_i        (resolve_branch_ex_id),          // in order to resolve the branch
      // LSU
      .lsu_ready_i             (lsu_ready_ex_id),
      .lsu_valid_o             (lsu_valid_id_ex),
      // Multiplier
      .mult_valid_o            (mult_valid_id_ex),
      // FPU
      .fpu_ready_i             (fpu_ready_ex_id),
      .fpu_early_valid_i       (fpu_early_valid_ex_id),
      .fpu_valid_o             (fpu_valid_id_ex),
      .fpu_fmt_o               (fpu_fmt_id_ex),
      .fpu_rm_o                (fpu_rm_id_ex),
      // ALU2
      .alu2_valid_o            (alu2_valid_id_ex),
      // CSR
      .csr_valid_o             (csr_valid_id_ex),
      // CVXIF
      .xfu_valid_o             (x_issue_valid_id_ex),
      .xfu_ready_i             (x_issue_ready_ex_id),
      .x_off_instr_o           (x_off_instr_id_ex),
      .hart_id_i               (hart_id_i),
      .x_issue_ready_i         (x_issue_ready),
      .x_issue_resp_i          (x_issue_resp),
      .x_issue_valid_o         (x_issue_valid),
      .x_issue_req_o           (x_issue_req),
      .x_register_ready_i      (x_register_ready),
      .x_register_valid_o      (x_register_valid),
      .x_register_o            (x_register),
      .x_commit_valid_o        (x_commit_valid),
      .x_commit_o              (x_commit),
      .x_transaction_rejected_o(x_transaction_rejected),
      // Commit
      .trans_id_i              (trans_id_ex_id),
      .resolved_branch_i       (resolved_branch),
      .wbdata_i                (wbdata_ex_id),
      .ex_ex_i                 (ex_ex_ex_id),
      .wt_valid_i              (wt_valid_ex_id),
      .x_we_i                  (x_we_ex_id),
      .x_rd_i                  (x_rd_ex_id),

      .waddr_i                   (waddr_commit_id),
      .wdata_i                   (wdata_commit_id),
      .we_gpr_i                  (we_gpr_commit_id),
      .we_fpr_i                  (we_fpr_commit_id),
      .commit_instr_o            (commit_instr_id_commit),
      .commit_drop_o             (commit_drop_id_commit),
      .commit_ack_i              (commit_ack_commit_id),
      // Performance Counters
      .stall_issue_o             (stall_issue),
      //RVFI
      .rvfi_issue_pointer_o      (rvfi_issue_pointer),
      .rvfi_commit_pointer_o     (rvfi_commit_pointer),
      .rvfi_rs1_o                (rvfi_rs1),
      .rvfi_rs2_o                (rvfi_rs2),
      .orig_instr_aes_bits       (orig_instr_aes),
      .dcls_common_regfile_data_i(common_regfile_rdata),
      .dcls_common_regfile_ctrl_o(common_regfile_ctrl)
  );

  if (CVA6Cfg.DclsEn & CVA6Cfg.DclsCommonRegfile) begin
    assign dcls_to_common_o.regfile_inputs = common_regfile_ctrl;
    assign common_regfile_rdata = dcls_from_common_i.regfile_rdata;
  end else begin
    assign common_regfile_rdata = '0;
  end

  // ---------
  // EX
  // ---------
  ex_stage #(
      .CVA6Cfg            (CVA6Cfg),
      .bp_resolve_t       (bp_resolve_t),
      .branchpredict_sbe_t(branchpredict_sbe_t),
      .ypb_store_req_t    (ypb_store_req_t),
      .ypb_store_rsp_t    (ypb_store_rsp_t),
      .ypb_amo_req_t      (ypb_amo_req_t),
      .ypb_amo_rsp_t      (ypb_amo_rsp_t),
      .ypb_load_req_t     (ypb_load_req_t),
      .ypb_load_rsp_t     (ypb_load_rsp_t),
      .ypb_mmu_ptw_req_t  (ypb_mmu_ptw_req_t),
      .ypb_mmu_ptw_rsp_t  (ypb_mmu_ptw_rsp_t),
      .exception_t        (exception_t),
      .fu_data_t          (fu_data_t),
      .fetch_areq_t       (fetch_areq_t),
      .fetch_arsp_t       (fetch_arsp_t),
      .lsu_ctrl_t         (lsu_ctrl_t),
      .x_result_t         (x_result_t)
  ) ex_stage_i (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .debug_mode_i(debug_mode),
      .flush_i(flush_ctrl_ex),
      .rs1_forwarding_i(rs1_forwarding_id_ex),
      .rs2_forwarding_i(rs2_forwarding_id_ex),
      .fu_data_i(fu_data_id_ex),
      .alu_bypass_i(alu_bypass_id_ex),
      .pc_i(pc_id_ex),
      .is_zcmt_i(zcmt_id_ex),
      .is_compressed_instr_i(is_compressed_instr_id_ex),
      .tinst_i(tinst_ex),
      // fixed latency units
      .flu_result_o(flu_result_ex_id),
      .flu_trans_id_o(flu_trans_id_ex_id),
      .flu_valid_o(flu_valid_ex_id),
      .flu_exception_o(flu_exception_ex_id),
      .flu_ready_o(flu_ready_ex_id),
      // ALU
      .alu_valid_i(alu_valid_id_ex),
      .orig_instr_aes_i(orig_instr_aes),
      .aes_valid_i(aes_valid_id_ex),
      // Branches and Jumps
      .branch_valid_i(branch_valid_id_ex),
      .branch_predict_i(branch_predict_id_ex),  // branch predict to ex
      .resolved_branch_o(resolved_branch),
      .resolve_branch_o(resolve_branch_ex_id),
      // CSR
      .csr_valid_i(csr_valid_id_ex),
      .csr_addr_o(csr_addr_ex_csr),
      .csr_commit_i(csr_commit_commit_ex),  // from commit
      .csr_hs_ld_st_inst_o(csr_hs_ld_st_inst_ex),  // signals a Hypervisor Load/Store Instruction
      // MULT
      .mult_valid_i(mult_valid_id_ex),
      // LSU
      .lsu_ready_o(lsu_ready_ex_id),
      .lsu_valid_i(lsu_valid_id_ex),

      .load_result_o   (load_result_ex_id),
      .load_trans_id_o (load_trans_id_ex_id),
      .load_valid_o    (load_valid_ex_id),
      .load_exception_o(load_exception_ex_id),

      .store_result_o   (store_result_ex_id),
      .store_trans_id_o (store_trans_id_ex_id),
      .store_valid_o    (store_valid_ex_id),
      .store_exception_o(store_exception_ex_id),

      .lsu_commit_i            (lsu_commit_commit_ex),           // from commit
      .lsu_commit_ready_o      (lsu_commit_ready_ex_commit),     // to commit
      .commit_tran_id_i        (lsu_commit_trans_id),            // from commit
      .commit_drop_i           (commit_drop_id_commit[0]),       // from scoreboard
      .no_st_pending_o         (no_st_pending_ex),               //
      .mbe_i                   (mbe),                            // from CSR
      .shared_tlb_flush_busy_o (shared_tlb_flush_busy_ex),
      // FPU
      .fpu_ready_o             (fpu_ready_ex_id),
      .fpu_early_valid_o       (fpu_early_valid_ex_id),
      .fpu_valid_i             (fpu_valid_id_ex),
      .fpu_fmt_i               (fpu_fmt_id_ex),
      .fpu_rm_i                (fpu_rm_id_ex),
      .fpu_frm_i               (frm_csr_id_issue_ex),
      .fpu_prec_i              (fprec_csr_ex),
      .fpu_trans_id_o          (fpu_trans_id_ex_id),
      .fpu_result_o            (fpu_result_ex_id),
      .fpu_valid_o             (fpu_valid_ex_id),
      .fpu_exception_o         (fpu_exception_ex_id),
      // ALU2
      .alu2_valid_i            (alu2_valid_id_ex),
      .amo_valid_commit_i      (amo_valid_commit),
      // CoreV-X-Interface
      .x_valid_i               (x_issue_valid_id_ex),
      .x_ready_o               (x_issue_ready_ex_id),
      .x_off_instr_i           (x_off_instr_id_ex),
      .x_transaction_rejected_i(x_transaction_rejected),
      .x_trans_id_o            (x_trans_id_ex_id),
      .x_exception_o           (x_exception_ex_id),
      .x_result_o              (x_result_ex_id),
      .x_valid_o               (x_valid_ex_id),
      .x_we_o                  (x_we_ex_id),
      .x_rd_o                  (x_rd_ex_id),
      .x_result_valid_i        (x_result_valid),
      .x_result_i              (x_result),
      .x_result_ready_o        (x_result_ready),
      // Performance counters
      .itlb_miss_o             (itlb_miss_ex_perf),
      .dtlb_miss_o             (dtlb_miss_ex_perf),
      // Memory Management
      .enable_translation_i    (enable_translation_csr_ex),      // from CSR
      .enable_g_translation_i  (enable_g_translation_csr_ex),    // from CSR
      .en_ld_st_translation_i  (en_ld_st_translation_csr_ex),
      .en_ld_st_g_translation_i(en_ld_st_g_translation_csr_ex),
      .flush_tlb_i             (flush_tlb_ctrl_ex),
      .flush_tlb_vvma_i        (flush_tlb_vvma_ctrl_ex),
      .flush_tlb_gvma_i        (flush_tlb_gvma_ctrl_ex),
      .priv_lvl_i              (priv_lvl),                       // from CSR
      .v_i                     (v),                              // from CSR
      .ld_st_priv_lvl_i        (ld_st_priv_lvl_csr_ex),          // from CSR
      .ld_st_v_i               (ld_st_v_csr_ex),                 // from CSR
      .sum_i                   (sum_csr_ex),                     // from CSR
      .vs_sum_i                (vs_sum_csr_ex),                  // from CSR
      .mxr_i                   (mxr_csr_ex),                     // from CSR
      .vmxr_i                  (vmxr_csr_ex),                    // from CSR
      .satp_ppn_i              (satp_ppn_csr_ex),                // from CSR
      .asid_i                  (asid_csr_ex),                    // from CSR
      .vsatp_ppn_i             (vsatp_ppn_csr_ex),               // from CSR
      .vs_asid_i               (vs_asid_csr_ex),                 // from CSR
      .hgatp_ppn_i             (hgatp_ppn_csr_ex),               // from CSR
      .vmid_i                  (vmid_csr_ex),                    // from CSR
      .fetch_areq_i            (fetch_areq_frontend_ex),
      .fetch_arsp_o            (fetch_arsp_ex_frontend),
      // DCACHE interfaces
      .ypb_store_req_o         (ypb_store_req_o),
      .ypb_store_rsp_i         (ypb_store_rsp_i),
      .ypb_amo_req_o           (ypb_amo_req_o),
      .ypb_amo_rsp_i           (ypb_amo_rsp_i),
      .ypb_load_req_o          (ypb_load_req_o),
      .ypb_load_rsp_i          (ypb_load_rsp_i),
      .ypb_mmu_ptw_req_o       (ypb_mmu_ptw_req_o),
      .ypb_mmu_ptw_rsp_i       (ypb_mmu_ptw_rsp_i),

      .dcache_wbuffer_empty_i       (dcache_wbuffer_empty_i),
      .dcache_wbuffer_not_ni_i      (dcache_wbuffer_not_ni_i),
      // PMP
      .pmpcfg_i                     (pmpcfg),
      .pmpaddr_i                    (pmpaddr),
      //RVFI
      .rvfi_lsu_ctrl_o              (rvfi_lsu_ctrl),
      .rvfi_mem_paddr_o             (rvfi_mem_paddr),
      //Trigger module
      .sdtrig_lsu_inputs_operand_a_o(sdtrig_lsu_inputs_operand_a),
      .sdtrig_lsu_inputs_operand_c_o(sdtrig_lsu_inputs_operand_c),
      .sdtrig_lsu_inputs_we_o       (sdtrig_lsu_inputs_we),
      .sdtrig_lsu_inputs_valid_o    (sdtrig_lsu_inputs_valid),
      .sdtrig_load_cancel_i         (sdtrig_load_cancel),
      .sdtrig_load_action_i         (sdtrig_load_action),
      .sdtrig_load_data_valid_o     (sdtrig_load_data_valid),
      .sdtrig_load_data_o           (sdtrig_load_data),
      .sdtrig_load_data_action_i    (sdtrig_load_data_action),
      .sdtrig_store_stall_i         (sdtrig_store_stall),
      .sdtrig_store_action_i        (sdtrig_store_action)
  );

  // ---------
  // Commit
  // ---------

  // we have to make sure that the whole write buffer path is empty before
  // used e.g. for fence instructions.
  assign no_st_pending_commit = no_st_pending_ex & dcache_wbuffer_empty_i;

  commit_stage #(
      .CVA6Cfg(CVA6Cfg),
      .exception_t(exception_t),
      .scoreboard_entry_t(scoreboard_entry_t),
      .ypb_amo_rsp_t(ypb_amo_rsp_t)
  ) commit_stage_i (
      .clk_i,
      .rst_ni,
      .halt_i(halt_ctrl),
      .flush_dcache_i(dcache_flush_o),
      .exception_o(ex_commit),
      .dirty_fp_state_o(dirty_fp_state),
      .single_step_i(single_step_csr_commit),
      .commit_instr_i(commit_instr_id_commit),
      .commit_drop_i(commit_drop_id_commit),
      .commit_ack_o(commit_ack_commit_id),
      .commit_macro_ack_o(commit_macro_ack),
      .waddr_o(waddr_commit_id),
      .wdata_o(wdata_commit_id),
      .we_gpr_o(we_gpr_commit_id),
      .we_fpr_o(we_fpr_commit_id),
      .ypb_amo_rsp_i(ypb_amo_rsp_i),
      .pc_o(pc_commit),
      .csr_op_o(csr_op_commit_csr),
      .csr_wdata_o(csr_wdata_commit_csr),
      .csr_rdata_i(csr_rdata_csr_commit),
      .csr_write_fflags_o(csr_write_fflags_commit_cs),
      .csr_exception_i(csr_exception_csr_commit),
      .commit_lsu_o(lsu_commit_commit_ex),
      .commit_lsu_ready_i(lsu_commit_ready_ex_commit),
      .commit_tran_id_o(lsu_commit_trans_id),
      .amo_valid_commit_o(amo_valid_commit),
      .no_st_pending_i(no_st_pending_commit),
      .shared_tlb_flush_busy_i(shared_tlb_flush_busy_ex),
      .commit_csr_o(csr_commit_commit_ex),
      .fence_i_o(fence_i_commit_controller),
      .fence_o(fence_commit_controller),
      .flush_commit_o(flush_commit),
      .sfence_vma_o(sfence_vma_commit_controller),
      .hfence_vvma_o(hfence_vvma_commit_controller),
      .hfence_gvma_o(hfence_gvma_commit_controller),
      //Trigger module
      .sdtrig_commit_icount_valid_i(sdtrig_commit_icount_valid),
      .sdtrig_commit_icount_nr_instr_i(sdtrig_commit_icount_nr_instr),
      .sdtrig_commit_action_i(sdtrig_commit_action),
      .sdtrig_commit_std_exception_valid_i(sdtrig_commit_std_exception_valid)
  );

  if (CVA6Cfg.SpeculativeSb) begin
    assign commit_ack = commit_macro_ack & ~commit_drop_id_commit;
  end else begin
    assign commit_ack = commit_macro_ack;
  end

  // ---------
  // CSR
  // ---------
  //Trigger Module assignments
  logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.VLEN-1:0] fetch_sdtrig_pc;
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] fetch_sdtrig_instr;
  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; ++i) begin : gen_fetch_sdtrig
    assign fetch_sdtrig_pc[i] = CVA6Cfg.SdtrigMcontrol6ExecAddr ? fetch_entry_if_id[i].address : '0;
    assign fetch_sdtrig_instr[i] = CVA6Cfg.SdtrigMcontrol6ExecData ? fetch_entry_if_id[i].instruction : '0;
  end

  csr_regfile #(
      .CVA6Cfg           (CVA6Cfg),
      .exception_t       (exception_t),
      .jvt_t             (jvt_t),
      .irq_ctrl_t        (irq_ctrl_t),
      .scoreboard_entry_t(scoreboard_entry_t),
      .rvfi_probes_csr_t (rvfi_probes_csr_t),
      .MHPMCounterNum    (MHPMCounterNum)
  ) csr_regfile_i (
      .clk_i,
      .rst_ni,
      .time_irq_i,
      .flush_o                            (flush_csr_ctrl),
      .halt_csr_o                         (halt_csr_ctrl),
      .commit_instr_i                     (commit_instr_id_commit[0]),
      .commit_ack_i                       (commit_ack),
      .boot_addr_i                        (boot_addr_i[CVA6Cfg.VLEN-1:0]),
      .hart_id_i                          (hart_id_i[CVA6Cfg.XLEN-1:0]),
      .ex_i                               (ex_commit),
      .csr_op_i                           (csr_op_commit_csr),
      .csr_addr_i                         (csr_addr_ex_csr),
      .csr_wdata_i                        (csr_wdata_commit_csr),
      .csr_rdata_o                        (csr_rdata_csr_commit),
      .dirty_fp_state_i                   (dirty_fp_state),
      .csr_write_fflags_i                 (csr_write_fflags_commit_cs),
      .pc_i                               (pc_commit),
      .csr_exception_o                    (csr_exception_csr_commit),
      .epc_o                              (epc_commit_pcgen),
      .eret_o                             (eret),
      .trap_vector_base_o                 (trap_vector_base_commit_pcgen),
      .priv_lvl_o                         (priv_lvl),
      .mbe_o                              (mbe),
      .v_o                                (v),
      .fs_o                               (fs),
      .vfs_o                              (vfs),
      .fflags_o                           (fflags_csr_commit),
      .frm_o                              (frm_csr_id_issue_ex),
      .fprec_o                            (fprec_csr_ex),
      .irq_ctrl_o                         (irq_ctrl_csr_id),
      .en_translation_o                   (enable_translation_csr_ex),
      .en_g_translation_o                 (enable_g_translation_csr_ex),
      .en_ld_st_translation_o             (en_ld_st_translation_csr_ex),
      .en_ld_st_g_translation_o           (en_ld_st_g_translation_csr_ex),
      .ld_st_priv_lvl_o                   (ld_st_priv_lvl_csr_ex),
      .ld_st_v_o                          (ld_st_v_csr_ex),
      .csr_hs_ld_st_inst_i                (csr_hs_ld_st_inst_ex),
      .sum_o                              (sum_csr_ex),
      .vs_sum_o                           (vs_sum_csr_ex),
      .mxr_o                              (mxr_csr_ex),
      .vmxr_o                             (vmxr_csr_ex),
      .satp_ppn_o                         (satp_ppn_csr_ex),
      .asid_o                             (asid_csr_ex),
      .vsatp_ppn_o                        (vsatp_ppn_csr_ex),
      .vs_asid_o                          (vs_asid_csr_ex),
      .hgatp_ppn_o                        (hgatp_ppn_csr_ex),
      .vmid_o                             (vmid_csr_ex),
      .irq_i,
      .ipi_i,
      .debug_req_i,
      .set_debug_pc_o                     (set_debug_pc),
      .tvm_o                              (tvm_csr_id),
      .tw_o                               (tw_csr_id),
      .vtw_o                              (vtw_csr_id),
      .tsr_o                              (tsr_csr_id),
      .hu_o                               (hu),
      .debug_mode_o                       (debug_mode),
      .single_step_o                      (single_step_csr_commit),
      .icache_en_o                        (icache_enable_o),
      .dcache_en_o                        (dcache_enable_o),
      .dcache_scrub_en_o                  (dcache_scrub_enable_o),
      .dcache_scrub_period_o              (dcache_scrub_period_o),
      .dcache_scrub_cycle_i               (dcache_scrub_cycle_i),
      .dcache_dat_cor_err_i               (dcache_dat_cor_err_i),
      .dcache_dat_unc_err_i               (dcache_dat_unc_err_i),
      .dcache_dir_cor_err_i               (dcache_dir_cor_err_i),
      .dcache_dir_unc_err_i               (dcache_dir_unc_err_i),
      .perf_addr_o                        (addr_csr_perf),
      .perf_data_o                        (data_csr_perf),
      .perf_data_i                        (data_perf_csr),
      .perf_we_o                          (we_csr_perf),
      .pmpcfg_o                           (pmpcfg),
      .pmpaddr_o                          (pmpaddr),
      .mcountinhibit_o                    (mcountinhibit_csr_perf),
      .mcbie_o                            (mcbie),
      .scbie_o                            (scbie),
      .hcbie_o                            (hcbie),
      .mcbcfe_o                           (mcbcfe),
      .scbcfe_o                           (scbcfe),
      .hcbcfe_o                           (hcbcfe),
      .jvt_o                              (jvt),
      //RVFI
      .rvfi_csr_o                         (rvfi_csr),
      // Trigger Signals
      .sdtrig_commit_std_exception_valid_o(sdtrig_commit_std_exception_valid),
      //Decoder/FE <-> Trigger Module
      .fetch_sdtrig_pc_i                  (fetch_sdtrig_pc),
      .fetch_sdtrig_instr_i               (fetch_sdtrig_instr),
      .sdtrig_decoder_action_o            (sdtrig_decoder_action),
      //Load/Store Unit <-> Trigger Module
      .sdtrig_lsu_inputs_vaddr_i          (sdtrig_lsu_inputs_operand_a),
      .sdtrig_lsu_inputs_data_i           (sdtrig_lsu_inputs_operand_c),
      .sdtrig_lsu_inputs_fu_i             (sdtrig_lsu_inputs_we),
      .sdtrig_lsu_inputs_valid_i          (sdtrig_lsu_inputs_valid),
      .sdtrig_load_data_i                 (sdtrig_load_data),
      .sdtrig_load_valid_i                (sdtrig_load_data_valid),
      .sdtrig_load_data_action_o          (sdtrig_load_data_action),
      .sdtrig_load_cancel_o               (sdtrig_load_cancel),
      .sdtrig_load_action_o               (sdtrig_load_action),
      .sdtrig_store_stall_o               (sdtrig_store_stall),
      .sdtrig_store_action_o              (sdtrig_store_action),
      //Commit <- Trigger module
      .sdtrig_commit_icount_valid_o       (sdtrig_commit_icount_valid),
      .sdtrig_commit_action_o             (sdtrig_commit_action),
      .sdtrig_commit_icount_nr_instr_o    (sdtrig_commit_icount_nr_instr)
  );

  // ------------------------
  // Performance Counters
  // ------------------------
  if (CVA6Cfg.PerfCounterEn) begin : gen_perf_counter
    perf_counters #(
        .CVA6Cfg           (CVA6Cfg),
        .bp_resolve_t      (bp_resolve_t),
        .exception_t       (exception_t),
        .scoreboard_entry_t(scoreboard_entry_t),
        .ypb_fetch_req_t   (ypb_fetch_req_t),
        .ypb_store_req_t   (ypb_store_req_t),
        .ypb_amo_req_t     (ypb_amo_req_t),
        .ypb_load_req_t    (ypb_load_req_t),
        .ypb_mmu_ptw_req_t (ypb_mmu_ptw_req_t),
        .ypb_zcmt_req_t    (ypb_zcmt_req_t),
        .NumMissPorts      (1  /*FIXME*/)         //WT cache only ??
    ) perf_counters_i (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .debug_mode_i  (debug_mode),
        .addr_i        (addr_csr_perf),
        .we_i          (we_csr_perf),
        .data_i        (data_csr_perf),
        .data_o        (data_perf_csr),
        .commit_instr_i(commit_instr_id_commit),
        .commit_ack_i  (commit_ack),

        .l1_icache_miss_i   (icache_miss_i),
        .l1_dcache_miss_i   (dcache_miss_i),
        .itlb_miss_i        (itlb_miss_ex_perf),
        .dtlb_miss_i        (dtlb_miss_ex_perf),
        .sb_full_i          (sb_full),
        // TODO this is more complex that that
        // If superscalar then we additionally have to check [1] when transaction 0 succeeded
        .if_empty_i         (~fetch_valid_if_id[0]),
        .ex_i               (ex_commit),
        .eret_i             (eret),
        .resolved_branch_i  (resolved_branch),
        .branch_exceptions_i(flu_exception_ex_id),

        .ypb_fetch_req_i  (ypb_fetch_req_o),
        .ypb_store_req_i  (ypb_store_req_o),
        .ypb_amo_req_i    (ypb_amo_req_o),
        .ypb_load_req_i   (ypb_load_req_o),
        .ypb_mmu_ptw_req_i(ypb_mmu_ptw_req_o),
        .ypb_zcmt_req_i   (ypb_zcmt_req_o),
        .miss_vld_bits_i  ('0  /*FIXME*/),          //WT cache only ??
        .i_tlb_flush_i    (flush_tlb_ctrl_ex),
        .stall_issue_i    (stall_issue),
        .mcountinhibit_i  (mcountinhibit_csr_perf)
    );
  end : gen_perf_counter
  else begin : gen_no_perf_counter
    assign data_perf_csr = '0;
  end : gen_no_perf_counter

  // ------------
  // Controller
  // ------------
  controller #(
      .CVA6Cfg(CVA6Cfg),
      .bp_resolve_t(bp_resolve_t)
  ) controller_i (
      .clk_i,
      .rst_ni,
      // virtualization mode
      .v_i                   (v),
      // flush ports
      .set_pc_commit_o       (set_pc_ctrl_pcgen),
      .flush_if_o            (flush_ctrl_if),
      .flush_unissued_instr_o(flush_unissued_instr_ctrl_id),
      .flush_id_o            (flush_ctrl_id),
      .flush_ex_o            (flush_ctrl_ex),
      .flush_bp_o            (flush_ctrl_bp),
      .flush_icache_o        (icache_flush_o),
      .flush_dcache_o        (dcache_flush_o),
      .flush_dcache_ack_i    (dcache_flush_ack_i),
      .flush_tlb_o           (flush_tlb_ctrl_ex),
      .flush_tlb_vvma_o      (flush_tlb_vvma_ctrl_ex),
      .flush_tlb_gvma_o      (flush_tlb_gvma_ctrl_ex),
      .halt_csr_i            (halt_csr_ctrl),
      .halt_o                (halt_ctrl),
      .halt_frontend_o       (halt_frontend_ctrl),
      // control ports
      .eret_i                (eret),
      .ex_valid_i            (ex_commit.valid),
      .set_debug_pc_i        (set_debug_pc),
      .resolved_branch_i     (resolved_branch),
      .flush_csr_i           (flush_csr_ctrl),
      .fence_i_i             (fence_i_commit_controller),
      .fence_i               (fence_commit_controller),
      .sfence_vma_i          (sfence_vma_commit_controller),
      .hfence_vvma_i         (hfence_vvma_commit_controller),
      .hfence_gvma_i         (hfence_gvma_commit_controller),
      .flush_commit_i        (flush_commit)
  );

  // -------------------
  // Instruction Tracer
  // -------------------

  //pragma translate_off
`ifdef PITON_ARIANE
  localparam PC_QUEUE_DEPTH = 16;

  logic                                               piton_pc_vld;
  logic [         CVA6Cfg.VLEN-1:0]                   piton_pc;
  logic [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.VLEN-1:0] pc_data;
  logic [CVA6Cfg.NrCommitPorts-1:0] pc_pop, pc_empty;

  for (genvar i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin : gen_pc_fifo
    fifo_v3 #(
        .DATA_WIDTH(64),
        .DEPTH(PC_QUEUE_DEPTH),
        .FPGA_EN(CVA6Cfg.FpgaEn)
    ) i_pc_fifo (
        .clk_i     (clk_i),
        .rst_ni    (rst_ni),
        .flush_i   ('0),
        .testmode_i('0),
        .full_o    (),
        .empty_o   (pc_empty[i]),
        .usage_o   (),
        .data_i    (commit_instr_id_commit[i].pc),
        .push_i    (commit_ack[i] & ~commit_instr_id_commit[i].ex.valid),
        .data_o    (pc_data[i]),
        .pop_i     (pc_pop[i])
    );
  end

  rr_arb_tree #(
      .NumIn(CVA6Cfg.NrCommitPorts),
      .DataWidth(64)
  ) i_rr_arb_tree (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .flush_i('0),
      .rr_i   ('0),
      .req_i  (~pc_empty),
      .gnt_o  (pc_pop),
      .data_i (pc_data),
      .gnt_i  (piton_pc_vld),
      .req_o  (piton_pc_vld),
      .data_o (piton_pc),
      .idx_o  ()
  );
`endif  // PITON_ARIANE

`ifndef VERILATOR

  logic [                     31:0]       fetch_instructions     [CVA6Cfg.NrIssuePorts-1:0];
  logic [CVA6Cfg.NrCommitPorts-1:0][63:0] wdata_commit_id_padded;

  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; ++i) begin
    assign fetch_instructions[i] = fetch_entry_if_id[i].instruction;
  end

  for (genvar i = 0; i < CVA6Cfg.NrCommitPorts; ++i) begin
    assign wdata_commit_id_padded[i] = {{(64 - CVA6Cfg.XLEN) {1'b0}}, wdata_commit_id[i]};
  end

  instr_tracer #(
      .CVA6Cfg(CVA6Cfg),
      .bp_resolve_t(bp_resolve_t),
      .scoreboard_entry_t(scoreboard_entry_t),
      .exception_t(exception_t)
  ) instr_tracer_i (
      // .tracer_if(tracer_if),
      .pck(clk_i),
      .rstn(rst_ni),
      .flush_unissued(flush_unissued_instr_ctrl_id),
      .flush_all(flush_ctrl_ex),
      .instruction(fetch_instructions),
      .fetch_valid(id_stage_i.fetch_entry_valid_i),
      .fetch_ack(id_stage_i.fetch_entry_ready_o),
      .issue_ack(issue_stage_i.i_scoreboard.issue_ack_i),
      .issue_sbe(issue_stage_i.i_scoreboard.issue_instr_o),
      .waddr(waddr_commit_id),
      .wdata(wdata_commit_id_padded),
      .we_gpr(we_gpr_commit_id),
      .we_fpr(we_fpr_commit_id),
      .commit_instr(commit_instr_id_commit),
      .commit_ack(commit_ack_commit_id),
      .commit_drop(commit_drop_id_commit),
      .st_valid(ex_stage_i.lsu_i.i_store_unit.store_buffer_i.valid_i),
      .st_paddr(ex_stage_i.lsu_i.i_store_unit.store_buffer_i.paddr_i),
      .ld_valid(ex_stage_i.lsu_i.i_load_unit.ypb_load_req_o.preq),
      .ld_kill(ex_stage_i.lsu_i.i_load_unit.ypb_load_req_o.kill_req),
      .ld_paddr(ex_stage_i.lsu_i.i_load_unit.paddr_i),
      .resolve_branch(resolved_branch),
      .commit_exception(commit_stage_i.exception_o),
      .priv_lvl(priv_lvl),
      .debug_mode(debug_mode),
      .hart_id_i(hart_id_i)
  );

  // mock tracer for Verilator, to be used with spike-dasm
`else

  int f;
  logic [63:0] cycles;

  initial begin
    string fn;
    $sformat(fn, "trace_hart_%0.0f.dasm", hart_id_i);
    f = $fopen(fn, "w");
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      cycles <= 0;
    end else begin
      byte mode = "";
      if (CVA6Cfg.DebugEn && debug_mode) mode = "D";
      else begin
        case (priv_lvl)
          riscv::PRIV_LVL_M: mode = "M";
          riscv::PRIV_LVL_S: if (CVA6Cfg.RVS) mode = "S";
          riscv::PRIV_LVL_U: mode = "U";
          default: ;  // Do nothing
        endcase
      end
      for (int i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
        if (commit_ack[i] && !commit_instr_id_commit[i].ex.valid) begin
          $fwrite(f, "%d 0x%0h %s (0x%h) DASM(%h)\n", cycles, commit_instr_id_commit[i].pc, mode,
                  commit_instr_id_commit[i].ex.tval[31:0], commit_instr_id_commit[i].ex.tval[31:0]);
        end else if (commit_ack[i] && commit_instr_id_commit[i].ex.valid) begin
          if (commit_instr_id_commit[i].ex.cause == 2) begin
            $fwrite(f, "Exception Cause: Illegal Instructions, DASM(%h) PC=%h\n",
                    commit_instr_id_commit[i].ex.tval[31:0], commit_instr_id_commit[i].pc);
          end else begin
            if (CVA6Cfg.DebugEn && debug_mode) begin
              $fwrite(f, "%d 0x%0h %s (0x%h) DASM(%h)\n", cycles, commit_instr_id_commit[i].pc,
                      mode, commit_instr_id_commit[i].ex.tval[31:0],
                      commit_instr_id_commit[i].ex.tval[31:0]);
            end else begin
              $fwrite(f, "Exception Cause: %5d, DASM(%h) PC=%h\n",
                      commit_instr_id_commit[i].ex.cause, commit_instr_id_commit[i].ex.tval[31:0],
                      commit_instr_id_commit[i].pc);
            end
          end
        end
      end
      cycles <= cycles + 1;
    end
  end

  final begin
    $fclose(f);
  end
`endif  // VERILATOR
  //pragma translate_on


  //RVFI INSTR
  logic [CVA6Cfg.NrIssuePorts-1:0][31:0] rvfi_fetch_instr;
  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
    assign rvfi_fetch_instr[i] = fetch_entry_if_id[i].instruction;
  end

  cva6_rvfi_probes #(
      .CVA6Cfg            (CVA6Cfg),
      .exception_t        (exception_t),
      .scoreboard_entry_t (scoreboard_entry_t),
      .lsu_ctrl_t         (lsu_ctrl_t),
      .bp_resolve_t       (bp_resolve_t),
      .rvfi_probes_instr_t(rvfi_probes_instr_t),
      .rvfi_probes_csr_t  (rvfi_probes_csr_t),
      .rvfi_probes_t      (rvfi_probes_t)
  ) i_cva6_rvfi_probes (

      .flush_i            (flush_ctrl_if),
      .issue_instr_ack_i  (issue_instr_issue_id),
      .fetch_entry_valid_i(fetch_valid_if_id),
      .instruction_i      (rvfi_fetch_instr),
      .is_compressed_i    (rvfi_is_compressed),

      .issue_pointer_i (rvfi_issue_pointer),
      .commit_pointer_i(rvfi_commit_pointer),

      .flush_unissued_instr_i(flush_unissued_instr_ctrl_id),
      .decoded_instr_valid_i (issue_entry_valid_id_issue),
      .decoded_instr_ack_i   (issue_instr_issue_id),

      .rs1_i(rvfi_rs1),
      .rs2_i(rvfi_rs2),

      .commit_instr_i(commit_instr_id_commit),
      .commit_drop_i (commit_drop_id_commit),
      .ex_commit_i   (ex_commit),
      .priv_lvl_i    (priv_lvl),

      .lsu_ctrl_i  (rvfi_lsu_ctrl),
      .wbdata_i    (wbdata_ex_id),
      .commit_ack_i(commit_ack),
      .mem_paddr_i (rvfi_mem_paddr),
      .debug_mode_i(debug_mode),
      .wdata_i     (wdata_commit_id),

      .csr_i(rvfi_csr),
      .irq_i(irq_i),
      .resolved_branch_i(resolved_branch),
      .flu_trans_id_ex_id_i(flu_trans_id_ex_id),
      .rvfi_probes_o(rvfi_probes_o)

  );

endmodule  // ariane
