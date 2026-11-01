module zicbom_permissions_test;
  import ariane_pkg::*;

  function automatic config_pkg::cva6_cfg_t make_test_cfg();
    config_pkg::cva6_user_cfg_t cfg;
    cfg = cva6_config_pkg::cva6_cfg;

    // The stock H configuration has RVH enabled but Zicbom disabled.
    // Enable Zicbom locally for this decoder regression.
    cfg.RVZiCbom = 1'b1;

    // Disable CV-X-IF so decoder-generated illegal instructions directly
    // become architectural exceptions in this standalone test.
    cfg.CvxifEn = 1'b0;

    return build_config_pkg::build_config(cfg);
  endfunction

  localparam config_pkg::cva6_cfg_t CVA6Cfg = make_test_cfg();

  typedef struct packed {
    cf_t                     cf;
    logic [CVA6Cfg.VLEN-1:0] predict_address;
  } branchpredict_sbe_t;

  typedef struct packed {
    logic [CVA6Cfg.XLEN-1:0]  cause;
    logic [CVA6Cfg.XLEN-1:0]  tval;
    logic [CVA6Cfg.GPLEN-1:0] tval2;
    logic [31:0]              tinst;
    logic                     gva;
    logic                     valid;
    logic                     timing;
  } exception_t;

  typedef struct packed {
    logic [CVA6Cfg.VLEN-1:0]          pc;
    logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;
    fu_t                              fu;
    fu_op                             op;
    logic [REG_ADDR_SIZE-1:0]         rs1;
    logic [REG_ADDR_SIZE-1:0]         rs2;
    logic [REG_ADDR_SIZE-1:0]         rd;
    logic [CVA6Cfg.XLEN-1:0]          result;
    logic                             valid;
    logic                             use_imm;
    logic                             use_zimm;
    logic                             use_pc;
    exception_t                       ex;
    branchpredict_sbe_t               bp;
    logic                             is_compressed;
    logic                             is_macro_instr;
    logic                             is_last_macro_instr;
    logic                             is_double_rd_macro_instr;
    logic                             is_zcmt;
  } scoreboard_entry_t;

  typedef struct packed {
    logic [CVA6Cfg.XLEN-1:0] mie;
    logic [CVA6Cfg.XLEN-1:0] mip;
    logic [CVA6Cfg.XLEN-1:0] mideleg;
    logic [CVA6Cfg.XLEN-1:0] hideleg;
    logic                    sie;
    logic                    global_enable;
  } irq_ctrl_t;

  typedef struct packed {
    logic [CVA6Cfg.XLEN-1:0] S_SW;
    logic [CVA6Cfg.XLEN-1:0] VS_SW;
    logic [CVA6Cfg.XLEN-1:0] M_SW;
    logic [CVA6Cfg.XLEN-1:0] S_TIMER;
    logic [CVA6Cfg.XLEN-1:0] VS_TIMER;
    logic [CVA6Cfg.XLEN-1:0] M_TIMER;
    logic [CVA6Cfg.XLEN-1:0] S_EXT;
    logic [CVA6Cfg.XLEN-1:0] VS_EXT;
    logic [CVA6Cfg.XLEN-1:0] M_EXT;
    logic [CVA6Cfg.XLEN-1:0] HS_EXT;
  } interrupts_t;

  localparam interrupts_t INTERRUPTS = '0;

  localparam logic [31:0] CBO_INVAL_INSN = 32'h0000_200f;
  localparam logic [31:0] CBO_CLEAN_INSN = 32'h0010_200f;
  localparam logic [31:0] CBO_FLUSH_INSN = 32'h0020_200f;

  logic debug_req_i;
  logic [CVA6Cfg.VLEN-1:0] pc_i;
  logic is_compressed_i;
  logic [15:0] compressed_instr_i;
  logic is_illegal_i;
  logic [31:0] instruction_i;
  logic is_macro_instr_i;
  logic is_last_macro_instr_i;
  logic is_double_rd_macro_instr_i;
  logic is_zcmt_i;
  logic [CVA6Cfg.XLEN-1:0] jump_address_i;
  branchpredict_sbe_t branch_predict_i;
  exception_t ex_i;
  logic [1:0] irq_i;
  irq_ctrl_t irq_ctrl_i;
  riscv::priv_lvl_t priv_lvl_i;
  logic v_i;
  logic debug_mode_i;
  riscv::xs_t fs_i;
  riscv::xs_t vfs_i;
  logic [2:0] frm_i;
  logic tvm_i;
  logic tw_i;
  logic vtw_i;
  logic tsr_i;
  logic hu_i;

  riscv::cbie_t mcbie_i;
  riscv::cbie_t scbie_i;
  riscv::cbie_t hcbie_i;

  logic mcbcfe_i;
  logic scbcfe_i;
  logic hcbcfe_i;

  scoreboard_entry_t instruction_o;
  logic [31:0] orig_instr_o;
  logic is_control_flow_instr_o;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_decoder_action_i;

  integer errors;

  decoder #(
      .CVA6Cfg(CVA6Cfg),
      .branchpredict_sbe_t(branchpredict_sbe_t),
      .exception_t(exception_t),
      .irq_ctrl_t(irq_ctrl_t),
      .scoreboard_entry_t(scoreboard_entry_t),
      .interrupts_t(interrupts_t),
      .INTERRUPTS(INTERRUPTS)
  ) dut (
      .debug_req_i,
      .pc_i,
      .is_compressed_i,
      .compressed_instr_i,
      .is_illegal_i,
      .instruction_i,
      .is_macro_instr_i,
      .is_last_macro_instr_i,
      .is_double_rd_macro_instr_i,
      .is_zcmt_i,
      .jump_address_i,
      .branch_predict_i,
      .ex_i,
      .irq_i,
      .irq_ctrl_i,
      .priv_lvl_i,
      .v_i,
      .debug_mode_i,
      .fs_i,
      .vfs_i,
      .frm_i,
      .tvm_i,
      .tw_i,
      .vtw_i,
      .tsr_i,
      .hu_i,
      .mcbie_i,
      .scbie_i,
      .hcbie_i,
      .mcbcfe_i,
      .scbcfe_i,
      .hcbcfe_i,
      .instruction_o,
      .orig_instr_o,
      .is_control_flow_instr_o,
      .sdtrig_decoder_action_i
  );

  task automatic run_case(input string name, input logic [31:0] instr_word,
                          input riscv::priv_lvl_t priv, input logic v, input logic hu,
                          input riscv::cbie_t mcbie, input riscv::cbie_t scbie,
                          input riscv::cbie_t hcbie, input logic mcbcfe, input logic scbcfe,
                          input logic hcbcfe, input logic expected_trap,
                          input logic [CVA6Cfg.XLEN-1:0] expected_cause, input fu_op expected_op);
    begin
      instruction_i = instr_word;
      priv_lvl_i = priv;
      v_i = v;
      hu_i = hu;

      mcbie_i = mcbie;
      scbie_i = scbie;
      hcbie_i = hcbie;

      mcbcfe_i = mcbcfe;
      scbcfe_i = scbcfe;
      hcbcfe_i = hcbcfe;

      #1;

      if (instruction_o.ex.valid !== expected_trap) begin
        $display("FAIL: %s: trap valid=%0b expected=%0b", name, instruction_o.ex.valid,
                 expected_trap);
        errors = errors + 1;
      end else if (expected_trap && instruction_o.ex.cause !== expected_cause) begin
        $display("FAIL: %s: cause=%0d expected=%0d", name, instruction_o.ex.cause, expected_cause);
        errors = errors + 1;
      end else if (!expected_trap && instruction_o.op !== expected_op) begin
        $display("FAIL: %s: op=%0d expected=%0d", name, instruction_o.op, expected_op);
        errors = errors + 1;
      end else begin
        $display("PASS: %s", name);
      end
    end
  endtask

  initial begin
    errors = 0;

    debug_req_i = 1'b0;
    pc_i = '0;
    is_compressed_i = 1'b0;
    compressed_instr_i = '0;
    is_illegal_i = 1'b0;
    instruction_i = '0;
    is_macro_instr_i = 1'b0;
    is_last_macro_instr_i = 1'b0;
    is_double_rd_macro_instr_i = 1'b0;
    is_zcmt_i = 1'b0;
    jump_address_i = '0;
    branch_predict_i = '0;
    ex_i = '0;
    irq_i = '0;
    irq_ctrl_i = '0;
    priv_lvl_i = riscv::PRIV_LVL_M;
    v_i = 1'b0;
    debug_mode_i = 1'b0;
    fs_i = riscv::Off;
    vfs_i = riscv::Off;
    frm_i = '0;
    tvm_i = 1'b0;
    tw_i = 1'b0;
    vtw_i = 1'b0;
    tsr_i = 1'b0;
    hu_i = 1'b0;
    mcbie_i = riscv::CBIE_INVAL;
    scbie_i = riscv::CBIE_INVAL;
    hcbie_i = riscv::CBIE_INVAL;
    mcbcfe_i = 1'b1;
    scbcfe_i = 1'b1;
    hcbcfe_i = 1'b1;
    sdtrig_decoder_action_i = '0;

    #1;

    // HU must not turn ordinary host U-mode into VU.
    run_case("host U ignores HU for INVAL", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b0, 1'b1,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_INVAL);

    // VU + senvcfg.CBIE=00 -> virtual-instruction.
    run_case("VU sCBIE illegal is virtual", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_ILLEGAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b1, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_INVAL);

    // VS + henvcfg.CBIE=00 -> virtual-instruction.
    run_case("VS hCBIE illegal is virtual", CBO_INVAL_INSN, riscv::PRIV_LVL_S, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_ILLEGAL, 1'b1, 1'b1, 1'b1, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_INVAL);

    // VU + henvcfg.CBIE=00 -> virtual-instruction.
    run_case("VU hCBIE illegal is virtual", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_ILLEGAL, 1'b1, 1'b1, 1'b1, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_INVAL);

    // henvcfg does not govern HS execution.
    run_case("HS ignores hCBIE", CBO_INVAL_INSN, riscv::PRIV_LVL_S, 1'b0, 1'b0, riscv::CBIE_INVAL,
             riscv::CBIE_INVAL, riscv::CBIE_ILLEGAL, 1'b1, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_INVAL);

    // VS henvcfg.CBIE=01 performs a flush.
    run_case("VS hCBIE flush", CBO_INVAL_INSN, riscv::PRIV_LVL_S, 1'b1, 1'b0, riscv::CBIE_INVAL,
             riscv::CBIE_INVAL, riscv::CBIE_FLUSH, 1'b1, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_FLUSH);

    // VU senvcfg.CBIE=01 performs a flush.
    run_case("VU sCBIE flush", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0, riscv::CBIE_INVAL,
             riscv::CBIE_FLUSH, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_FLUSH);

    // VU henvcfg.CBIE=01 performs a flush.
    run_case("VU hCBIE flush", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0, riscv::CBIE_INVAL,
             riscv::CBIE_INVAL, riscv::CBIE_FLUSH, 1'b1, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_FLUSH);

    // VS CBO.CLEAN with henvcfg.CBCFE=0 -> virtual-instruction.
    run_case("VS CLEAN hCBCFE disabled", CBO_CLEAN_INSN, riscv::PRIV_LVL_S, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b0, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_CLEAN);

    // VU requires both henvcfg.CBCFE and senvcfg.CBCFE.
    run_case("VU FLUSH hCBCFE disabled", CBO_FLUSH_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b0, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_FLUSH);

    run_case("VU FLUSH sCBCFE disabled", CBO_FLUSH_INSN, riscv::PRIV_LVL_U, 1'b1, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b0, 1'b1, 1'b1,
             riscv::VIRTUAL_INSTRUCTION, ariane_pkg::CBO_FLUSH);

    // Ordinary host U still gets cause 2 from senvcfg.CBCFE.
    run_case("host U CLEAN sCBCFE disabled", CBO_CLEAN_INSN, riscv::PRIV_LVL_U, 1'b0, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b0, 1'b1, 1'b1,
             riscv::ILLEGAL_INSTR, ariane_pkg::CBO_CLEAN);

    // An INVAL converted to FLUSH by CBIE must not be rejected by CBCFE.
    run_case("S INVAL-as-FLUSH ignores mCBCFE", CBO_INVAL_INSN, riscv::PRIV_LVL_S, 1'b0, 1'b0,
             riscv::CBIE_FLUSH, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b0, 1'b1, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_FLUSH);

    run_case("U INVAL-as-FLUSH ignores sCBCFE", CBO_INVAL_INSN, riscv::PRIV_LVL_U, 1'b0, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_FLUSH, riscv::CBIE_INVAL, 1'b1, 1'b0, 1'b1, 1'b0, '0,
             ariane_pkg::CBO_FLUSH);

    // Genuine FLUSH remains governed by CBCFE.
    run_case("S genuine FLUSH obeys mCBCFE", CBO_FLUSH_INSN, riscv::PRIV_LVL_S, 1'b0, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b0, 1'b1, 1'b1, 1'b1,
             riscv::ILLEGAL_INSTR, ariane_pkg::CBO_FLUSH);

    run_case("U genuine FLUSH obeys sCBCFE", CBO_FLUSH_INSN, riscv::PRIV_LVL_U, 1'b0, 1'b0,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b0, 1'b1, 1'b1,
             riscv::ILLEGAL_INSTR, ariane_pkg::CBO_FLUSH);

    // menvcfg checks have higher priority and still produce cause 2
    // even while V=1.
    run_case("guest mCBIE illegal remains illegal", CBO_INVAL_INSN, riscv::PRIV_LVL_S, 1'b1, 1'b0,
             riscv::CBIE_ILLEGAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b1, 1'b1,
             riscv::ILLEGAL_INSTR, ariane_pkg::CBO_INVAL);

    // HU must likewise not make host U subject to henvcfg.CBCFE.
    run_case("host U ignores HU for CBCFE", CBO_CLEAN_INSN, riscv::PRIV_LVL_U, 1'b0, 1'b1,
             riscv::CBIE_INVAL, riscv::CBIE_INVAL, riscv::CBIE_INVAL, 1'b1, 1'b1, 1'b0, 1'b0, '0,
             ariane_pkg::CBO_CLEAN);

    if (errors != 0) begin
      $fatal(1, "FAIL: %0d Zicbom permission checks failed", errors);
    end

    $display("PASS: all Zicbom permission checks passed");
    $finish;
  end

endmodule
