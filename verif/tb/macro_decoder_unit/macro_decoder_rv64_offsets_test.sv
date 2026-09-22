module macro_decoder_rv64_offsets_test;

  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
      cva6_config_pkg::cva6_cfg
  );

  localparam logic [2:0] ST_IDLE = 3'd0;

  logic        clk_i;
  logic        rst_ni;
  logic [31:0] instr_i;
  logic        is_macro_instr_i;
  logic        illegal_instr_i;
  logic        is_compressed_i;
  logic        issue_ack_i;

  logic [31:0] instr_o;
  logic        illegal_instr_o;
  logic        is_compressed_o;
  logic        fetch_stall_o;
  logic        is_last_macro_instr_o;
  logic        is_double_rd_macro_instr_o;

  integer errors;

  always #5 clk_i = ~clk_i;

  macro_decoder #(
      .CVA6Cfg(CVA6Cfg)
  ) dut (
      .instr_i,
      .clk_i,
      .rst_ni,
      .is_macro_instr_i,
      .illegal_instr_i,
      .is_compressed_i,
      .issue_ack_i,
      .instr_o,
      .illegal_instr_o,
      .is_compressed_o,
      .fetch_stall_o,
      .is_last_macro_instr_o,
      .is_double_rd_macro_instr_o
  );

  function automatic integer store_imm(input logic [31:0] instr);
    logic signed [11:0] imm;
    begin
      imm = {instr[31:25], instr[11:7]};
      store_imm = imm;
    end
  endfunction

  function automatic integer itype_imm(input logic [31:0] instr);
    logic signed [11:0] imm;
    begin
      imm = instr[31:20];
      itype_imm = imm;
    end
  endfunction

  task automatic reset_dut;
    begin
      is_macro_instr_i = 1'b0;
      illegal_instr_i  = 1'b0;
      is_compressed_i  = 1'b1;
      issue_ack_i      = 1'b0;
      instr_i          = '0;

      rst_ni = 1'b0;
      repeat (2) @(posedge clk_i);

      @(negedge clk_i);
      rst_ni = 1'b1;
      #1;

      assert (dut.state_q == ST_IDLE)
      else $fatal(1, "decoder did not reset to IDLE");
    end
  endtask

  task automatic start_macro(input logic [15:0] encoding);
    begin
      instr_i          = {16'h0000, encoding};
      is_macro_instr_i = 1'b1;
      issue_ack_i      = 1'b1;
      #1;

      if (illegal_instr_o) begin
        $display("encoding 0x%04h unexpectedly decoded as illegal", encoding);
        errors++;
      end
    end
  endtask

  task automatic advance_uop;
    begin
      @(posedge clk_i);
      @(negedge clk_i);
      #1;
    end
  endtask

  task automatic check_store(
      input logic [4:0] expected_rs2,
      input integer expected_imm,
      input string name
  );
    integer actual_imm;
    begin
      actual_imm = store_imm(instr_o);

      if (instr_o[6:0] !== riscv::OpcodeStore) begin
        $display("%s: expected STORE, got instruction %08h", name, instr_o);
        errors++;
      end

      if (instr_o[14:12] !== 3'h3) begin
        $display("%s: expected SD funct3=3, got %0h", name, instr_o[14:12]);
        errors++;
      end

      if (instr_o[19:15] !== 5'h2) begin
        $display("%s: expected rs1=sp(x2), got x%0d", name, instr_o[19:15]);
        errors++;
      end

      if (instr_o[24:20] !== expected_rs2) begin
        $display(
            "%s: expected rs2=x%0d, got x%0d",
            name,
            expected_rs2,
            instr_o[24:20]
        );
        errors++;
      end

      if (actual_imm != expected_imm) begin
        $display(
            "%s: expected offset %0d, got %0d",
            name,
            expected_imm,
            actual_imm
        );
        errors++;
      end else begin
        $display("PASS: %s offset=%0d", name, actual_imm);
      end
    end
  endtask

  task automatic check_load(
      input logic [4:0] expected_rd,
      input integer expected_imm,
      input string name
  );
    integer actual_imm;
    begin
      actual_imm = itype_imm(instr_o);

      if (instr_o[6:0] !== riscv::OpcodeLoad) begin
        $display("%s: expected LOAD, got instruction %08h", name, instr_o);
        errors++;
      end

      if (instr_o[14:12] !== 3'h3) begin
        $display("%s: expected LD funct3=3, got %0h", name, instr_o[14:12]);
        errors++;
      end

      if (instr_o[19:15] !== 5'h2) begin
        $display("%s: expected rs1=sp(x2), got x%0d", name, instr_o[19:15]);
        errors++;
      end

      if (instr_o[11:7] !== expected_rd) begin
        $display(
            "%s: expected rd=x%0d, got x%0d",
            name,
            expected_rd,
            instr_o[11:7]
        );
        errors++;
      end

      if (actual_imm != expected_imm) begin
        $display(
            "%s: expected offset %0d, got %0d",
            name,
            expected_imm,
            actual_imm
        );
        errors++;
      end else begin
        $display("PASS: %s offset=%0d", name, actual_imm);
      end
    end
  endtask

  task automatic check_store_offset(
      input integer expected_imm,
      input string name
  );
    integer actual_imm;
    begin
      actual_imm = store_imm(instr_o);

      if (instr_o[6:0] !== riscv::OpcodeStore) begin
        $display("%s: expected STORE, got instruction %08h", name, instr_o);
        errors++;
      end

      if (actual_imm != expected_imm) begin
        $display(
            "%s: expected offset %0d, got %0d",
            name,
            expected_imm,
            actual_imm
        );
        errors++;
      end else begin
        $display("PASS: %s offset=%0d", name, actual_imm);
      end
    end
  endtask

  task automatic check_load_offset(
      input integer expected_imm,
      input string name
  );
    integer actual_imm;
    begin
      actual_imm = itype_imm(instr_o);

      if (instr_o[6:0] !== riscv::OpcodeLoad) begin
        $display("%s: expected LOAD, got instruction %08h", name, instr_o);
        errors++;
      end

      if (actual_imm != expected_imm) begin
        $display(
            "%s: expected offset %0d, got %0d",
            name,
            expected_imm,
            actual_imm
        );
        errors++;
      end else begin
        $display("PASS: %s offset=%0d", name, actual_imm);
      end
    end
  endtask

  task automatic check_sp_addi(
      input integer expected_imm,
      input string name
  );
    integer actual_imm;
    begin
      actual_imm = itype_imm(instr_o);

      if (instr_o[6:0] !== riscv::OpcodeOpImm) begin
        $display("%s: expected OP-IMM, got instruction %08h", name, instr_o);
        errors++;
      end

      if (instr_o[14:12] !== 3'h0) begin
        $display("%s: expected ADDI funct3=0", name);
        errors++;
      end

      if (instr_o[19:15] !== 5'h2) begin
        $display("%s: expected rs1=sp(x2), got x%0d", name, instr_o[19:15]);
        errors++;
      end

      if (instr_o[11:7] !== 5'h2) begin
        $display("%s: expected rd=sp(x2), got x%0d", name, instr_o[11:7]);
        errors++;
      end

      if (actual_imm != expected_imm) begin
        $display(
            "%s: expected stack adjustment %0d, got %0d",
            name,
            expected_imm,
            actual_imm
        );
        errors++;
      end else begin
        $display("PASS: %s stack adjustment=%0d", name, actual_imm);
      end
    end
  endtask

  task automatic test_push_three_registers;
    begin
      reset_dut();

      // RV64:
      // cm.push {ra, s0-s1}, -32
      //
      // Expected expansion:
      //   sd   s1,  -8(sp)
      //   sd   s0, -16(sp)
      //   sd   ra, -24(sp)
      //   addi sp, sp, -32
      start_macro(16'hb862);

      check_store(5'h9, -8, "push s1");

      advance_uop();
      check_store(5'h8, -16, "push s0");

      advance_uop();
      check_store(5'h1, -24, "push ra");

      advance_uop();
      check_sp_addi(-32, "push sp");

      if (!is_last_macro_instr_o) begin
        $display("push final ADDI was not marked as last macro instruction");
        errors++;
      end
    end
  endtask

  task automatic test_pop_three_registers;
    begin
      reset_dut();

      // RV64:
      // cm.pop {ra, s0-s1}, 32
      //
      // Expected expansion:
      //   ld   s1, 24(sp)
      //   ld   s0, 16(sp)
      //   ld   ra,  8(sp)
      //   addi sp, sp, 32
      start_macro(16'hba62);

      check_load(5'h9, 24, "pop s1");

      advance_uop();
      check_load(5'h8, 16, "pop s0");

      advance_uop();
      check_load(5'h1, 8, "pop ra");

      advance_uop();
      check_sp_addi(32, "pop sp");

      if (!is_last_macro_instr_o) begin
        $display("pop final ADDI was not marked as last macro instruction");
        errors++;
      end
    end
  endtask

  task automatic check_ret(input string name);
    begin
      if (instr_o[6:0] !== riscv::OpcodeJalr) begin
        $display("%s: expected JALR, got instruction %08h", name, instr_o);
        errors++;
      end

      if (instr_o[14:12] !== 3'h0) begin
        $display("%s: expected JALR funct3=0", name);
        errors++;
      end

      if (instr_o[19:15] !== 5'h1) begin
        $display("%s: expected rs1=ra(x1), got x%0d", name, instr_o[19:15]);
        errors++;
      end

      if (instr_o[11:7] !== 5'h0) begin
        $display("%s: expected rd=x0, got x%0d", name, instr_o[11:7]);
        errors++;
      end

      if (itype_imm(instr_o) != 0) begin
        $display("%s: expected JALR immediate 0, got %0d", name, itype_imm(instr_o));
        errors++;
      end

      if (!is_last_macro_instr_o) begin
        $display("%s: return was not marked as last macro instruction", name);
        errors++;
      end

      $display("PASS: %s", name);
    end
  endtask

  task automatic test_popret_three_registers;
    begin
      reset_dut();

      // RV64:
      // cm.popret {ra, s0-s1}, 32
      //
      // Expected relevant expansion:
      //   ld   s1, 24(sp)
      //   ld   s0, 16(sp)
      //   ld   ra,  8(sp)
      //   addi sp, sp, 32
      //   ret
      //
      // Existing GNU-binutils-derived cm.popret {ra},16 encoding is
      // 16'hbe42. rlist occupies bits [7:4], therefore rlist=6 gives be62.
      start_macro(16'hbe62);

      check_load(5'h9, 24, "popret s1");

      advance_uop();
      check_load(5'h8, 16, "popret s0");

      advance_uop();
      check_load(5'h1, 8, "popret ra");

      advance_uop();
      check_sp_addi(32, "popret sp");

      advance_uop();
      check_ret("popret ret");
    end
  endtask

  task automatic test_popretz_three_registers;
    begin
      reset_dut();

      // RV64:
      // cm.popretz {ra, s0-s1}, 32
      //
      // Relevant memory/SP behavior must match cm.popret. cm.popretz
      // additionally emits the a0-zeroing micro-ops before SP adjustment.
      //
      // Existing GNU-binutils-derived cm.popretz {ra},16 encoding is
      // 16'hbc42. rlist=6 therefore gives bc62.
      start_macro(16'hbc62);

      check_load(5'h9, 24, "popretz s1");

      advance_uop();
      check_load(5'h8, 16, "popretz s0");

      advance_uop();
      check_load(5'h1, 8, "popretz ra");

      // POPRETZ_1 first emits LUI a0,0.
      advance_uop();

      if (instr_o[6:0] !== riscv::OpcodeLui ||
          instr_o[11:7] !== 5'hA) begin
        $display(
            "popretz zero-a0 LUI: unexpected instruction %08h",
            instr_o
        );
        errors++;
      end else begin
        $display("PASS: popretz zero-a0 LUI");
      end

      // Then ADDI a0,a0,0.
      advance_uop();

      if (instr_o[6:0] !== riscv::OpcodeOpImm ||
          instr_o[19:15] !== 5'hA ||
          instr_o[11:7] !== 5'hA ||
          itype_imm(instr_o) != 0) begin
        $display(
            "popretz zero-a0 ADDI: unexpected instruction %08h",
            instr_o
        );
        errors++;
      end else begin
        $display("PASS: popretz zero-a0 ADDI");
      end

      // The decoder then performs the corrected RV64 SP adjustment.
      advance_uop();
      check_sp_addi(32, "popretz sp");

      advance_uop();
      check_ret("popretz ret");
    end
  endtask

  task automatic test_max_rlist_push_prefix;
    begin
      reset_dut();

      // RV64 rlist=15:
      // cm.push {ra, s0-s11}, -112
      //
      // This specifically exercises the PUSH_POP_INSTR_2 state.
      start_macro(16'hb8f2);

      check_store_offset(-8, "max-rlist push first slot");

      advance_uop();
      check_store_offset(-16, "max-rlist push second slot");
    end
  endtask

  task automatic test_max_rlist_pop_prefix;
    begin
      reset_dut();

      // RV64 rlist=15:
      // cm.pop {ra, s0-s11}, 112
      //
      // This specifically exercises the PUSH_POP_INSTR_2 state.
      start_macro(16'hbaf2);

      check_load_offset(104, "max-rlist pop first slot");

      advance_uop();
      check_load_offset(96, "max-rlist pop second slot");
    end
  endtask

  initial begin
    clk_i            = 1'b0;
    rst_ni           = 1'b0;
    instr_i          = '0;
    is_macro_instr_i = 1'b0;
    illegal_instr_i  = 1'b0;
    is_compressed_i  = 1'b1;
    issue_ack_i      = 1'b0;
    errors           = 0;

    test_push_three_registers();
    test_pop_three_registers();
    test_popret_three_registers();
    test_popretz_three_registers();

    // Also cover the special rlist=15 state transition, because it has
    // separate PUSH/POP offset-update logic.
    test_max_rlist_push_prefix();
    test_max_rlist_pop_prefix();

    if (errors != 0) begin
      $fatal(1, "RV64 Zcmp offset regression failed with %0d error(s)", errors);
    end

    $display("PASS: RV64 Zcmp PUSH/POP offsets and SP adjustments are correct");
    $finish;
  end

endmodule
