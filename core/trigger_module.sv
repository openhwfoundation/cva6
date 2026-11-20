// Copyright 2026 10x Engineers
// Copyright 2026 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Munail Waqar - 10x Engineers
// Contributors : Mounsaf YOUSFI - Thales DIS

module trigger_module
  import ariane_pkg::*;
  import triggers_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg     = config_pkg::cva6_cfg_empty,
    parameter type                   exception_t = logic
) (
    input logic clk_i,
    input logic rst_ni,
    input logic [CVA6Cfg.NrCommitPorts-1:0] commit_ack_i,
    input exception_t ex_i,
    input riscv::priv_lvl_t priv_lvl_i,
    input logic v_i,
    input logic debug_mode_i,
    input logic mret_i,
    input logic sret_i,
    input logic [13:0] instr_count_d,
    input logic [13:0] instr_count_q,
    input logic [CVA6Cfg.VLEN-1:0] sdtrig_lsu_inputs_vaddr_i,
    input logic [CVA6Cfg.XLEN-1:0] sdtrig_lsu_inputs_data_i,
    input logic sdtrig_lsu_inputs_fu_i,
    input logic sdtrig_lsu_inputs_valid_i,
    input logic [CVA6Cfg.XLEN-1:0] sdtrig_load_data_i,
    input logic sdtrig_load_valid_i,

    input logic [CVA6Cfg.XLEN-1:0] scontext_i,

    input logic [CVA6Cfg.XLEN-1:0] tdata1_i,
    input logic [CVA6Cfg.XLEN-1:0] tdata2_i,
    input logic [CVA6Cfg.XLEN-1:0] tdata3_i,
    input logic [CVA6Cfg.XLEN-1:0] tselect_i,
    input logic tselect_we,
    input logic tdata1_we,
    input logic tdata2_we,
    input logic tdata3_we,

    output logic [CVA6Cfg.XLEN-1:0] tselect_o,
    output logic [CVA6Cfg.XLEN-1:0] tdata1_o,
    output logic [CVA6Cfg.XLEN-1:0] tdata2_o,
    output logic [CVA6Cfg.XLEN-1:0] tdata3_o,
    output logic flush_o,

    input logic [CVA6Cfg.XLEN-1:0] mepc_i,
    input logic [CVA6Cfg.XLEN-1:0] mcause_i,
    input logic [CVA6Cfg.XLEN-1:0] mtval_i,
    output logic etrigger_context_saved_valid_o,
    output logic [CVA6Cfg.XLEN-1:0] etrigger_context_mepc_o,
    output logic [CVA6Cfg.XLEN-1:0] etrigger_context_mcause_o,
    output logic [CVA6Cfg.XLEN-1:0] etrigger_context_mtval_o,

    input logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.VLEN-1:0] fetch_sdtrig_pc_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][31:0] fetch_sdtrig_instr_i,
    output logic [CVA6Cfg.XLEN-1:0] sdtrig_decoder_action_o[CVA6Cfg.NrIssuePorts],

    // Break asked by a load data trigger on the load retiring in this cycle
    output logic [CVA6Cfg.XLEN-1:0] sdtrig_load_data_action_o,
    output logic sdtrig_load_cancel_o,
    output logic [CVA6Cfg.XLEN-1:0] sdtrig_load_action_o,
    output logic sdtrig_store_stall_o,
    output logic [CVA6Cfg.XLEN-1:0] sdtrig_store_action_o,

    output logic sdtrig_commit_std_exception_valid_o,
    output logic sdtrig_commit_icount_valid_o,
    output logic [CVA6Cfg.XLEN-1:0] sdtrig_commit_action_o,
    output logic [(CVA6Cfg.NrCommitPorts > 1 ? $clog2(
CVA6Cfg.NrCommitPorts
) : 1)-1:0] sdtrig_commit_icount_nr_instr_o
);

  // tdata2 holds one bit per exception or interrupt cause
  function automatic logic cause_selected(input logic [CVA6Cfg.XLEN-1:0] tdata2,
                                          input logic [CVA6Cfg.XLEN-1:0] cause);
    return tdata2[cause[$clog2(CVA6Cfg.XLEN)-1:0]];
  endfunction

  function automatic logic std_match(input logic [CVA6Cfg.XLEN-1:0] tdata2_ref,
                                     input logic [CVA6Cfg.XLEN-1:0] comp_val,
                                     input logic [3:0] match_type);
    logic match = 0;

    unique case (match_type)
      4'd0:
      if (CVA6Cfg.SdtrigSupportedMatch[0])  // equal
        match = (tdata2_ref == comp_val);

      4'd1:
      if (CVA6Cfg.SdtrigSupportedMatch[1]) begin  //napot
        if (CVA6Cfg.IS_XLEN32) match = (napot_match32(32'(tdata2_ref), 32'(comp_val)));
        else if (CVA6Cfg.IS_XLEN64) match = (napot_match64(64'(tdata2_ref), 64'(comp_val)));
      end

      4'd2:
      if (CVA6Cfg.SdtrigSupportedMatch[2])  //greater or equal than
        match = (tdata2_ref[CVA6Cfg.XLEN-1:0] >= comp_val);

      4'd3:
      if (CVA6Cfg.SdtrigSupportedMatch[3])  //lower than 
        match = (tdata2_ref[CVA6Cfg.XLEN-1:0] < comp_val);

      4'd4:
      if (CVA6Cfg.SdtrigSupportedMatch[4])  //mask low
        match = ((tdata2_ref[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2] & comp_val[(CVA6Cfg.XLEN)/2-1:0]) == tdata2_ref[(CVA6Cfg.XLEN)/2-1:0]);

      4'd5:
      if (CVA6Cfg.SdtrigSupportedMatch[5])  //mask high
        match = ((tdata2_ref[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2] & comp_val[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2]) == tdata2_ref[(CVA6Cfg.XLEN)/2-1:0]);

      4'd8:
      if (CVA6Cfg.SdtrigSupportedMatch[6])  //not equal
        match = (tdata2_ref[CVA6Cfg.XLEN-1:0] != comp_val);

      4'd9:
      if (CVA6Cfg.SdtrigSupportedMatch[7]) begin  //not napot
        if (CVA6Cfg.IS_XLEN32) match = !(napot_match32(32'(tdata2_ref), 32'(comp_val)));
        else if (CVA6Cfg.IS_XLEN64) match = !(napot_match64(64'(tdata2_ref), 64'(comp_val)));
      end

      4'd12:
      if (CVA6Cfg.SdtrigSupportedMatch[8])  //not mask low
        match = !((tdata2_ref[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2] & comp_val[(CVA6Cfg.XLEN)/2-1:0]) == tdata2_ref[(CVA6Cfg.XLEN)/2-1:0]);

      4'd13:
      if (CVA6Cfg.SdtrigSupportedMatch[9])  //not mask high
        match = !((tdata2_ref[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2] & comp_val[CVA6Cfg.XLEN-1:(CVA6Cfg.XLEN)/2]) == tdata2_ref[(CVA6Cfg.XLEN)/2-1:0]);

      default: match = '0;
    endcase

    return match;
  endfunction

  typedef struct packed {
    logic valid;
    logic [CVA6Cfg.XLEN-1:0] action;
  } fire_req_t;

  // Trigger Module Helpers
  logic
      trigger_chain_vector_d[CVA6Cfg.SdtrigNrTriggers],
      trigger_chain_vector_q[CVA6Cfg.SdtrigNrTriggers];
  logic [14:0] instr_count_offset;
  logic [14:0] icount_diff;
  logic matchEA, matchED, matchSX, matchLA, matchLD;
  //EA = Match Control 6 Exec Address; ED = MC6 Exec Data; SX = MC6 Store (both addr. and data);...
  fire_req_t
      fire_req_EA[CVA6Cfg.NrIssuePorts],
      fire_req_ED[CVA6Cfg.NrIssuePorts],
      fire_req_SX,
      fire_req_LA,
      fire_req_LD,
      fire_req_Icount,
      fire_req_Etrigger,
      fire_req_Itrigger;
  logic [$clog2(CVA6Cfg.SdtrigNrTriggers)-1:0] previous_trigg_i;
  logic sdtrig_commit_icount_valid_d;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_commit_action_d;
  logic [(CVA6Cfg.NrCommitPorts > 1 ? $clog2(
CVA6Cfg.NrCommitPorts
) : 1)-1:0] sdtrig_commit_icount_nr_instr_d;
  logic e_matched_q, e_matched_d;
  logic
      sdtrig_commit_std_exception_valid_q,
      sdtrig_commit_std_exception_valid_d,
      sdtrig_load_cancel_d,
      sdtrig_load_cancel_q;
  logic [CVA6Cfg.XLEN-1:0] sdtrig_load_action_d, sdtrig_load_action_q;
  logic etrigger_context_saved_valid_q, etrigger_context_saved_valid_d;
  logic [CVA6Cfg.XLEN-1:0] etrigger_context_mepc_q, etrigger_context_mepc_d;
  logic [CVA6Cfg.XLEN-1:0] etrigger_context_mcause_q, etrigger_context_mcause_d;
  logic [CVA6Cfg.XLEN-1:0] etrigger_context_mtval_q, etrigger_context_mtval_d;
  logic in_trap_handler_d, in_trap_handler_q;
  logic mret_reg_q, mret_reg_d;

  logic [$clog2(CVA6Cfg.SdtrigNrTriggers)-1:0] tselect_q, tselect_d;
  logic [3:0] trigger_type_q[CVA6Cfg.SdtrigNrTriggers], trigger_type_d[CVA6Cfg.SdtrigNrTriggers];
  logic [CVA6Cfg.SdtrigNrTriggers-1:0] priv_match, scontext_match;
  logic [CVA6Cfg.XLEN-1:0] tdata2_q[CVA6Cfg.SdtrigNrTriggers], tdata2_d[CVA6Cfg.SdtrigNrTriggers];
  trigger_32_tdata1_type
      trigger_32_tdata1_q[CVA6Cfg.SdtrigNrTriggers], trigger_32_tdata1_d[CVA6Cfg.SdtrigNrTriggers];
  textra32_tdata3_t
      textra32_tdata3_q[CVA6Cfg.SdtrigNrTriggers], textra32_tdata3_d[CVA6Cfg.SdtrigNrTriggers];
  textra64_tdata3_t
      textra64_tdata3_q[CVA6Cfg.SdtrigNrTriggers], textra64_tdata3_d[CVA6Cfg.SdtrigNrTriggers];


  logic [CVA6Cfg.NrIssuePorts-1:0] fire_req_EA_valid, fire_req_ED_valid;
  logic [CVA6Cfg.XLEN-1:0]
      fire_req_EA_action[CVA6Cfg.NrIssuePorts], fire_req_ED_action[CVA6Cfg.NrIssuePorts];

  for (genvar i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
    assign fire_req_EA_valid[i]  = fire_req_EA[i].valid;
    assign fire_req_ED_valid[i]  = fire_req_ED[i].valid;
    assign fire_req_EA_action[i] = fire_req_EA[i].action;
    assign fire_req_ED_action[i] = fire_req_ED[i].action;
  end

  assign instr_count_offset = (CVA6Cfg.SdtrigIcount) ? instr_count_d - instr_count_q : '0;

  // A trigger fires in the privilege mode the current one maps to: M, S/HS or
  // U outside virtualization, VS or VU (vs, vu) when the hart is virtualized.
  function automatic logic mode_match(logic m, logic s, logic u, logic vs, logic vu);
    unique case (priv_lvl_i)
      riscv::PRIV_LVL_M: return m;
      riscv::PRIV_LVL_S: return (CVA6Cfg.RVH && v_i) ? vs : s;
      riscv::PRIV_LVL_U: return (CVA6Cfg.RVH && v_i) ? vu : u;
      default: return 1'b0;
    endcase
  endfunction

  always_comb begin : in_trap
    if (CVA6Cfg.SdtrigIcount) begin
      in_trap_handler_d = in_trap_handler_q;
      if (ex_i.valid || etrigger_context_saved_valid_q) in_trap_handler_d = 1'b1;
      else if (mret_i) in_trap_handler_d = 1'b0;
    end
  end

  // Trigger CSRs write/update logic
  // 64-bit views of the CSR write data: the RV64 write branch reads bits above
  // 31, which only exist with XLEN=64.
  logic [63:0] tdata1_w, tdata3_w;
  assign tdata1_w = 64'(tdata1_i);
  assign tdata3_w = 64'(tdata3_i);

  always_comb begin : write_path
    // defaults: tdata3 is tied to zero without textra support
    for (int i = 0; i < CVA6Cfg.SdtrigNrTriggers; i++) begin
      textra32_tdata3_d[i] = (CVA6Cfg.SdtrigSupportTextra && CVA6Cfg.IS_XLEN32) ? textra32_tdata3_q[i] : '0;
      textra64_tdata3_d[i] = (CVA6Cfg.SdtrigSupportTextra && CVA6Cfg.IS_XLEN64) ? textra64_tdata3_q[i] : '0;
    end

    trigger_type_d = trigger_type_q;
    trigger_32_tdata1_d = trigger_32_tdata1_q;
    tdata2_d = tdata2_q;
    tselect_d = tselect_q;
    matchEA = 1'b0;
    matchED = 1'b0;
    matchSX = 1'b0;
    matchLA = 1'b0;
    matchLD = 1'b0;
    sdtrig_load_cancel_d = 1'b0;
    sdtrig_load_data_action_o = '0;
    sdtrig_store_stall_o = 1'b0;
    sdtrig_commit_icount_valid_d = 1'b0;
    sdtrig_commit_icount_nr_instr_d = '0;
    sdtrig_commit_action_d = '0;
    sdtrig_commit_std_exception_valid_d = 1'b0;
    sdtrig_load_action_d = sdtrig_load_action_q;
    sdtrig_load_action_o = sdtrig_load_cancel_q ? sdtrig_load_action_q : '0;
    sdtrig_store_action_o = '0;
    flush_o = 1'b0;

    //Break from mcontrol6 from execution is a comb. only signal that
    //informs decode stage that the currently decoded PC/instr must generate
    //a breakpoint exception or a debug request
    for (int i = 0; i < CVA6Cfg.NrIssuePorts; i++) begin
      sdtrig_decoder_action_o[i] = '0;
      fire_req_EA[i].valid = 1'b0;
      fire_req_EA[i].action = '0;
      fire_req_ED[i].valid = 1'b0;
      fire_req_ED[i].action = '0;
    end

    if (ex_i.valid || !CVA6Cfg.SdtrigTriggerChaining) begin
      for (int i = 0; i < CVA6Cfg.SdtrigNrTriggers; i++) trigger_chain_vector_d[i] = 1'b0;
    end else if (CVA6Cfg.SdtrigTriggerChaining) trigger_chain_vector_d = trigger_chain_vector_q;

    previous_trigg_i               = '0;

    //Trigger fire requests reset
    fire_req_SX.valid              = 1'b0;
    fire_req_SX.action             = '0;
    fire_req_LA.valid              = 1'b0;
    fire_req_LA.action             = '0;
    fire_req_LD.valid              = 1'b0;
    fire_req_LD.action             = '0;
    fire_req_Icount.valid          = 1'b0;
    fire_req_Icount.action         = '0;
    fire_req_Etrigger.valid        = 1'b0;
    fire_req_Etrigger.action       = '0;
    fire_req_Itrigger.valid        = 1'b0;
    fire_req_Itrigger.action       = '0;

    etrigger_context_saved_valid_d = (mret_i) ? 1'b0 : etrigger_context_saved_valid_q;
    etrigger_context_mepc_d        = etrigger_context_mepc_q;
    etrigger_context_mcause_d      = etrigger_context_mcause_q;
    etrigger_context_mtval_d       = etrigger_context_mtval_q;

    e_matched_d                    = e_matched_q;
    mret_reg_d                     = mret_reg_q;

    if (CVA6Cfg.Sdtrig) begin
      // Triggers Match Logic
      for (int i = 0; i < CVA6Cfg.SdtrigNrTriggers; i++) begin
        matchEA = 1'b0;
        matchED = 1'b0;
        matchSX = 1'b0;
        matchLD = 1'b0;
        matchLA = 1'b0;
        icount_diff = '0;

        if (CVA6Cfg.SdtrigTriggerChaining)
          previous_trigg_i = $bits(
              previous_trigg_i
          )'((i - 1 + CVA6Cfg.SdtrigNrTriggers) % CVA6Cfg.SdtrigNrTriggers);
        priv_match[i] = 1'b0;
        // icount match logic
        if (trigger_type_d[i] == 4'd3 && CVA6Cfg.SdtrigIcount) begin
          priv_match[i] = mode_match(
            trigger_32_tdata1_d[i].icount_type.m,
            trigger_32_tdata1_d[i].icount_type.s,
            trigger_32_tdata1_d[i].icount_type.u,
            trigger_32_tdata1_d[i].icount_type.vs,
            trigger_32_tdata1_d[i].icount_type.vu
          );
          // S_MODE context match check
          if (priv_lvl_i == riscv::PRIV_LVL_S && trigger_32_tdata1_d[i].icount_type.s && CVA6Cfg.SdtrigSupportTextra) begin
            if (CVA6Cfg.IS_XLEN32) begin
              scontext_match[i] = match_scontext32(
                scontext_i[31:0],
                textra32_tdata3_d[i].sselect,
                textra32_tdata3_d[i].sbytemask,
                textra32_tdata3_d[i].svalue,
                1'b0
              );
            end else begin
              scontext_match[i] = match_scontext64(
                scontext_i[31:0],
                textra64_tdata3_d[i].sselect,
                textra64_tdata3_d[i].sbytemask,
                textra64_tdata3_d[i].svalue,
                1'b1
              );
            end
            priv_match[i] &= scontext_match[i];
          end
          if (!in_trap_handler_q) begin
            if (!trigger_32_tdata1_d[i].icount_type.pending) begin
              icount_diff = trigger_32_tdata1_q[i].icount_type.count - instr_count_offset[13:0];
            end
            if ((trigger_32_tdata1_q[i].icount_type.count > 0) && instr_count_offset != 0) begin
              if (icount_diff[14] == 1'b0) begin
                trigger_32_tdata1_d[i].icount_type.count = icount_diff[13:0];
              end else begin
                trigger_32_tdata1_d[i].icount_type.count = 'd0;
              end
            end
          end
          if (priv_match[i] && !trigger_32_tdata1_q[i].icount_type.pending && !trigger_32_tdata1_q[i].icount_type.hit) begin
            if (32'(trigger_32_tdata1_d[i].icount_type.count) < CVA6Cfg.NrCommitPorts) begin
              if (trigger_32_tdata1_d[i].icount_type.count == 0) begin
                trigger_32_tdata1_d[i].icount_type.pending = 1'b1;
              end
              fire_req_Icount.valid = 1'b1;
              sdtrig_commit_icount_nr_instr_d =
                  $bits(sdtrig_commit_icount_nr_instr_d)'(trigger_32_tdata1_d[i].icount_type.count);
              unique case (trigger_32_tdata1_d[i].icount_type.action)
                6'd0:
                if (CVA6Cfg.SdtrigSupportedActions[0]) fire_req_Icount.action = riscv::BREAKPOINT;
                6'd1:
                if (CVA6Cfg.SdtrigSupportedActions[1])
                  fire_req_Icount.action = riscv::DEBUG_REQUEST;
                default: ;
              endcase
            end
          end
          if (trigger_32_tdata1_q[i].icount_type.pending && ex_i.valid) begin
            trigger_32_tdata1_d[i].icount_type.hit = 1'b1;
            trigger_32_tdata1_d[i].icount_type.pending = 1'b0;
            fire_req_Icount.valid = 1'b0;
            fire_req_Icount.action = '0;
          end
          if (debug_mode_i && trigger_32_tdata1_q[i].icount_type.pending) begin
            trigger_32_tdata1_d[i].icount_type.pending = 1'b0;
            trigger_32_tdata1_d[i].icount_type.hit = 1'b1;
            fire_req_Icount.valid = 1'b0;
            fire_req_Icount.action = '0;
          end
        end
        // mcontrol6 match logic
        if (trigger_type_d[i] == 4'd6 && CVA6Cfg.SdtrigMcontrol6) begin
          priv_match[i] = mode_match(
            trigger_32_tdata1_d[i].mc6_type.m,
            trigger_32_tdata1_d[i].mc6_type.s,
            trigger_32_tdata1_d[i].mc6_type.u,
            trigger_32_tdata1_d[i].mc6_type.vs,
            trigger_32_tdata1_d[i].mc6_type.vu
          );
          // S_MODE context match check
          if (CVA6Cfg.SdtrigSupportTextra && priv_lvl_i == riscv::PRIV_LVL_S && trigger_32_tdata1_d[i].mc6_type.s) begin
            if (CVA6Cfg.IS_XLEN32) begin
              scontext_match[i] = match_scontext32(
                scontext_i[31:0],
                textra32_tdata3_d[i].sselect,
                textra32_tdata3_d[i].sbytemask,
                textra32_tdata3_d[i].svalue,
                1'b0
              );
            end else if (CVA6Cfg.IS_XLEN64) begin
              scontext_match[i] = match_scontext64(
                scontext_i[31:0],
                textra64_tdata3_d[i].sselect,
                textra64_tdata3_d[i].sbytemask,
                textra64_tdata3_d[i].svalue,
                1'b1
              );
            end
            priv_match[i] &= scontext_match[i];
          end

          //Execute triggers
          if ((CVA6Cfg.SdtrigMcontrol6ExecAddr || CVA6Cfg.SdtrigMcontrol6ExecData) && trigger_32_tdata1_d[i].mc6_type.execute) begin
            for (int n = 0; n < CVA6Cfg.NrIssuePorts; n++) begin
              //Execute trigger on address
              if (CVA6Cfg.SdtrigMcontrol6ExecAddr) begin
                if (!trigger_32_tdata1_d[i].mc6_type.select) begin
                  matchEA = std_match(
                    {
                      {{CVA6Cfg.XLEN - CVA6Cfg.VLEN} {1'b0}}, tdata2_d[i][CVA6Cfg.VLEN-1:0]
                    },
                    {
                      {{CVA6Cfg.XLEN - CVA6Cfg.VLEN} {1'b0}}, fetch_sdtrig_pc_i[n]
                    },
                    trigger_32_tdata1_d[i].mc6_type.match
                  );
                end
              end
              //Execute trigger on data
              if (CVA6Cfg.SdtrigMcontrol6ExecData) begin
                if (trigger_32_tdata1_d[i].mc6_type.select) begin
                  matchED = std_match(
                    tdata2_d[i],
                    CVA6Cfg.XLEN'(fetch_sdtrig_instr_i[n]),
                    trigger_32_tdata1_d[i].mc6_type.match
                  );
                end
              end
              //Request fire
              if (priv_match[i] && (CVA6Cfg.SdtrigMcontrol6ExecAddr && matchEA || CVA6Cfg.SdtrigMcontrol6ExecData && matchED)) begin
                trigger_32_tdata1_d[i].mc6_type.hit0 = 1'b1;  //before
                trigger_32_tdata1_d[i].mc6_type.hit1 = 1'b0;
                if (CVA6Cfg.SdtrigTriggerChaining) begin
                  if(!trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && trigger_32_tdata1_d[i].mc6_type.chain || trigger_chain_vector_d[previous_trigg_i] && trigger_32_tdata1_d[i].mc6_type.chain)
                    trigger_chain_vector_d[i] = 1'b1;
                  if(trigger_chain_vector_d[previous_trigg_i] && !trigger_32_tdata1_d[i].mc6_type.chain || !trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && !trigger_32_tdata1_d[i].mc6_type.chain) begin
                    if (matchEA && CVA6Cfg.SdtrigMcontrol6ExecAddr) begin
                      fire_req_EA[n].valid = 1'b1;

                      if(CVA6Cfg.SdtrigSupportedActions[0] && trigger_32_tdata1_d[i].mc6_type.action == 4'd0) begin
                        fire_req_EA[n].action = riscv::BREAKPOINT;
                      end
                      else if (CVA6Cfg.SdtrigSupportedActions[1] && trigger_32_tdata1_d[i].mc6_type.action == 4'd1) begin
                        if (CVA6Cfg.DebugEn && !debug_mode_i) begin
                          fire_req_EA[n].action = riscv::DEBUG_REQUEST;
                        end
                      end
                    end
                  end
                  // A link that is not the last of its chain only records its
                  // match: the action is taken by the last link.
                end else begin
                  fire_req_EA[n].valid  = 1'b1;
                  fire_req_EA[n].action = riscv::BREAKPOINT;
                end
              end
              if (priv_match[i] && CVA6Cfg.SdtrigMcontrol6ExecData && matchED) begin
                trigger_32_tdata1_d[i].mc6_type.hit0 = 1'b1;  //before
                trigger_32_tdata1_d[i].mc6_type.hit1 = 1'b0;
                if (CVA6Cfg.SdtrigTriggerChaining) begin
                  if(!trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && trigger_32_tdata1_d[i].mc6_type.chain || trigger_chain_vector_d[previous_trigg_i] && trigger_32_tdata1_d[i].mc6_type.chain)
                    trigger_chain_vector_d[i] = 1'b1;
                  if(trigger_chain_vector_d[previous_trigg_i] && !trigger_32_tdata1_d[i].mc6_type.chain || !trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && !trigger_32_tdata1_d[i].mc6_type.chain) begin
                    fire_req_ED[n].valid = 1'b1;
                    if(CVA6Cfg.SdtrigSupportedActions[0] && trigger_32_tdata1_d[i].mc6_type.action == 4'd0) begin
                      fire_req_ED[n].action = riscv::BREAKPOINT;
                    end
                    else if (CVA6Cfg.SdtrigSupportedActions[1] && trigger_32_tdata1_d[i].mc6_type.action == 4'd1) begin
                      if (CVA6Cfg.DebugEn && !debug_mode_i) begin
                        fire_req_ED[n].action = riscv::DEBUG_REQUEST;
                      end
                    end
                  end
                end else begin
                  fire_req_ED[n].valid = 1'b1;
                  if(CVA6Cfg.SdtrigSupportedActions[0] && trigger_32_tdata1_d[i].mc6_type.action == 4'd0) begin
                    fire_req_ED[n].action = riscv::BREAKPOINT;
                  end
                  else if (CVA6Cfg.SdtrigSupportedActions[1] && trigger_32_tdata1_d[i].mc6_type.action == 4'd1) begin
                    if (CVA6Cfg.DebugEn && !debug_mode_i) begin
                      fire_req_ED[n].action = riscv::DEBUG_REQUEST;
                    end
                  end
                end
              end
            end
          end

          //Store triggers
          if (CVA6Cfg.SdtrigMcontrol6Store && trigger_32_tdata1_d[i].mc6_type.store) begin
            //Store trigger on data
            if (CVA6Cfg.SdtrigMcontrol6Store) begin
              if (trigger_32_tdata1_d[i].mc6_type.select) begin
                if (sdtrig_lsu_inputs_valid_i && sdtrig_lsu_inputs_fu_i) begin  //0: load, 1: store
                  matchSX = std_match(tdata2_d[i], sdtrig_lsu_inputs_data_i,
                                      trigger_32_tdata1_d[i].mc6_type.match);
                end
              end
              if (!trigger_32_tdata1_d[i].mc6_type.select) begin
                if (sdtrig_lsu_inputs_valid_i && sdtrig_lsu_inputs_fu_i) begin  //0: load, 1: store
                  matchSX = std_match(tdata2_d[i], sdtrig_lsu_inputs_vaddr_i,
                                      trigger_32_tdata1_d[i].mc6_type.match);
                end
              end
            end
            //Request fire
            if (priv_match[i] && matchSX) begin
              trigger_32_tdata1_d[i].mc6_type.hit0 = 1'b1;  //before
              trigger_32_tdata1_d[i].mc6_type.hit1 = 1'b0;
              if (CVA6Cfg.SdtrigTriggerChaining) begin
                if(!trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && trigger_32_tdata1_d[i].mc6_type.chain || trigger_chain_vector_d[previous_trigg_i] && trigger_32_tdata1_d[i].mc6_type.chain)
                  trigger_chain_vector_d[i] = 1'b1;
                if(trigger_chain_vector_d[previous_trigg_i] && !trigger_32_tdata1_d[i].mc6_type.chain || !trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && !trigger_32_tdata1_d[i].mc6_type.chain) begin
                  if (matchSX && CVA6Cfg.SdtrigMcontrol6Store) fire_req_SX.valid = 1'b1;
                  unique case (trigger_32_tdata1_d[i].mc6_type.action)
                    4'd0:
                    if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1) begin
                      if (matchSX && CVA6Cfg.SdtrigMcontrol6Store)
                        fire_req_SX.action = riscv::BREAKPOINT;
                    end
                    4'd1:
                    if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1)
                      if (CVA6Cfg.DebugEn && !debug_mode_i) begin
                        if (matchSX && CVA6Cfg.SdtrigMcontrol6Store)
                          fire_req_SX.action = riscv::DEBUG_REQUEST;
                      end
                    default: ;
                  endcase
                end
              end else begin
                if (matchSX && CVA6Cfg.SdtrigMcontrol6Store) fire_req_SX.valid = 1'b1;
                unique case (trigger_32_tdata1_d[i].mc6_type.action)
                  4'd0:
                  if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1) begin
                    if (matchSX && CVA6Cfg.SdtrigMcontrol6Store)
                      fire_req_SX.action = riscv::BREAKPOINT;
                  end
                  4'd1:
                  if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1)
                    if (CVA6Cfg.DebugEn && !debug_mode_i) begin
                      if (matchSX && CVA6Cfg.SdtrigMcontrol6Store)
                        fire_req_SX.action = riscv::DEBUG_REQUEST;
                    end
                  default: ;
                endcase
              end
            end
          end

          //Load triggers
          if ((CVA6Cfg.SdtrigMcontrol6LoadAddr || CVA6Cfg.SdtrigMcontrol6LoadData) && trigger_32_tdata1_d[i].mc6_type.load) begin
            //Load trigger on data
            if (CVA6Cfg.SdtrigMcontrol6LoadData) begin
              if (trigger_32_tdata1_d[i].mc6_type.select) begin
                matchLD = sdtrig_load_valid_i && std_match(tdata2_d[i], sdtrig_load_data_i,
                                                           trigger_32_tdata1_d[i].mc6_type.match);
                // Load data match: break after the load (hit0 and hit1 set), so that the
                // loaded value is written back first.
                if (priv_match[i] && matchLD) begin
                  trigger_32_tdata1_d[i].mc6_type.hit0 = 1'b1;
                  trigger_32_tdata1_d[i].mc6_type.hit1 = 1'b1;  //immediately after
                  if (CVA6Cfg.SdtrigTriggerChaining) begin
                    if(!trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && trigger_32_tdata1_d[i].mc6_type.chain || trigger_chain_vector_d[previous_trigg_i] && trigger_32_tdata1_d[i].mc6_type.chain)
                      trigger_chain_vector_d[i] = 1'b1;
                    if(trigger_chain_vector_d[previous_trigg_i] && !trigger_32_tdata1_d[i].mc6_type.chain || !trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && !trigger_32_tdata1_d[i].mc6_type.chain) begin
                      fire_req_LD.valid = 1'b1;
                      unique case (trigger_32_tdata1_d[i].mc6_type.action)
                        4'd0:
                        if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1)
                          fire_req_LD.action = riscv::BREAKPOINT;
                        4'd1:
                        if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1 && CVA6Cfg.DebugEn && !debug_mode_i)
                          fire_req_LD.action = riscv::DEBUG_REQUEST;
                        default: ;
                      endcase
                    end
                  end else begin
                    fire_req_LD.valid = 1'b1;
                    unique case (trigger_32_tdata1_d[i].mc6_type.action)
                      4'd0:
                      if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1)
                        fire_req_LD.action = riscv::BREAKPOINT;
                      4'd1:
                      if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1 && CVA6Cfg.DebugEn && !debug_mode_i)
                        fire_req_LD.action = riscv::DEBUG_REQUEST;
                      default: ;
                    endcase
                  end
                end
              end
            end
            //Load trigger on address
            if (CVA6Cfg.SdtrigMcontrol6LoadAddr) begin
              if (!trigger_32_tdata1_d[i].mc6_type.select) begin
                if (sdtrig_lsu_inputs_valid_i && ~sdtrig_lsu_inputs_fu_i) begin
                  matchLA = std_match(tdata2_d[i], sdtrig_lsu_inputs_vaddr_i,
                                      trigger_32_tdata1_d[i].mc6_type.match);
                end
                //Load trigger on address fire logic
                if (priv_match[i] && matchLA) begin
                  trigger_32_tdata1_d[i].mc6_type.hit0 = 1'b1;  //before
                  trigger_32_tdata1_d[i].mc6_type.hit1 = 1'b0;
                  if (CVA6Cfg.SdtrigTriggerChaining) begin
                    if(!trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && trigger_32_tdata1_d[i].mc6_type.chain || trigger_chain_vector_d[previous_trigg_i] && trigger_32_tdata1_d[i].mc6_type.chain)
                      trigger_chain_vector_d[i] = 1'b1;
                    if(trigger_chain_vector_d[previous_trigg_i] && !trigger_32_tdata1_d[i].mc6_type.chain || !trigger_32_tdata1_d[previous_trigg_i].mc6_type.chain && !trigger_32_tdata1_d[i].mc6_type.chain) begin
                      fire_req_LA.valid = 1'b1;
                      unique case (trigger_32_tdata1_d[i].mc6_type.action)
                        4'd0:
                        if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1)
                          fire_req_LA.action = riscv::BREAKPOINT;
                        4'd1:
                        if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1 && CVA6Cfg.DebugEn && !debug_mode_i)
                          fire_req_LA.action = riscv::DEBUG_REQUEST;
                        default: ;
                      endcase
                    end
                  end else begin
                    fire_req_LA.valid = 1'b1;
                    unique case (trigger_32_tdata1_d[i].mc6_type.action)
                      4'd0:
                      if (CVA6Cfg.SdtrigSupportedActions[0] == 1'b1)
                        fire_req_LA.action = riscv::BREAKPOINT;
                      4'd1:
                      if (CVA6Cfg.SdtrigSupportedActions[1] == 1'b1 && CVA6Cfg.DebugEn && !debug_mode_i)
                        fire_req_LA.action = riscv::DEBUG_REQUEST;
                      default: ;
                    endcase
                  end
                end
              end
            end
          end
        end
        // etrigger match logic
        if (trigger_type_d[i] == 4'd5 && CVA6Cfg.SdtrigEtrigger) begin
          priv_match[i] = mode_match(
            trigger_32_tdata1_d[i].etrigger_type.m,
            trigger_32_tdata1_d[i].etrigger_type.s,
            trigger_32_tdata1_d[i].etrigger_type.u,
            trigger_32_tdata1_d[i].etrigger_type.vs,
            trigger_32_tdata1_d[i].etrigger_type.vu
          );
          // S_MODE context match check
          if (priv_lvl_i == riscv::PRIV_LVL_S && trigger_32_tdata1_d[i].etrigger_type.s) begin
            if (CVA6Cfg.IS_XLEN32) begin
              scontext_match[i] = match_scontext32(
                scontext_i[31:0],
                textra32_tdata3_d[i].sselect,
                textra32_tdata3_d[i].sbytemask,
                textra32_tdata3_d[i].svalue,
                1'b0
              );
            end else begin
              scontext_match[i] = match_scontext64(
                scontext_i[31:0],
                textra64_tdata3_d[i].sselect,
                textra64_tdata3_d[i].sbytemask,
                textra64_tdata3_d[i].svalue,
                1'b1
              );
            end
            priv_match[i] &= scontext_match[i];
          end
          if (cause_selected(
                  tdata2_d[i], ex_i.cause
              ) && priv_match[i] && !etrigger_context_saved_valid_q) begin
            e_matched_d = 1'd1;
          end
          if (e_matched_q && !trigger_32_tdata1_q[i].etrigger_type.hit) begin
            fire_req_Etrigger.valid = 1'b1;
            unique case (trigger_32_tdata1_d[i].etrigger_type.action)
              6'd0:
              if (CVA6Cfg.SdtrigSupportedActions[0]) fire_req_Etrigger.action = riscv::BREAKPOINT;
              6'd1:
              if (CVA6Cfg.SdtrigSupportedActions[1])
                fire_req_Etrigger.action = riscv::DEBUG_REQUEST;
              default: ;
            endcase
          end
          if (sdtrig_commit_std_exception_valid_q && (ex_i.valid || debug_mode_i)) begin
            trigger_32_tdata1_d[i].etrigger_type.hit = 1'b1;
            e_matched_d = 1'b0;
            fire_req_Etrigger.valid = 1'b0;
          end
          if (e_matched_d && ex_i.valid) begin
            etrigger_context_saved_valid_d = 1'b1;
            etrigger_context_mepc_d = mepc_i;
            etrigger_context_mcause_d = mcause_i;
            etrigger_context_mtval_d = mtval_i;
          end
        end
        // itrigger match logic
        if (trigger_type_d[i] == 4'd4 && CVA6Cfg.SdtrigItrigger) begin
          priv_match[i] = mode_match(
            trigger_32_tdata1_d[i].itrigger_type.m,
            trigger_32_tdata1_d[i].itrigger_type.s,
            trigger_32_tdata1_d[i].itrigger_type.u,
            trigger_32_tdata1_d[i].itrigger_type.vs,
            trigger_32_tdata1_d[i].itrigger_type.vu
          );
          // S_MODE context match check
          if (priv_lvl_i == riscv::PRIV_LVL_S && trigger_32_tdata1_d[i].itrigger_type.s) begin
            if (CVA6Cfg.IS_XLEN32) begin
              scontext_match[i] = match_scontext32(
                scontext_i[31:0],
                textra32_tdata3_d[i].sselect,
                textra32_tdata3_d[i].sbytemask,
                textra32_tdata3_d[i].svalue,
                1'b0
              );
            end else begin
              scontext_match[i] = match_scontext64(
                scontext_i[31:0],
                textra64_tdata3_d[i].sselect,
                textra64_tdata3_d[i].sbytemask,
                textra64_tdata3_d[i].svalue,
                1'b1
              );
            end
            priv_match[i] &= scontext_match[i];
          end
          if (ex_i.cause[CVA6Cfg.XLEN-1]) begin
            if (cause_selected(
                    tdata2_d[i], CVA6Cfg.XLEN'(ex_i.cause[4:0])
                ) && !etrigger_context_saved_valid_q)
              e_matched_d = 1'b1; // checking etrigger context valid bit avoids conflicts and context loss because of concurrent triggering by different types
          end
          if (mret_i || sret_i) mret_reg_d = 1'b1;
          if (e_matched_q && priv_match[i] && mret_reg_q && (commit_ack_i != 2'b00) || sdtrig_commit_std_exception_valid_q) begin
            e_matched_d = 1'b0;
            trigger_32_tdata1_d[i].itrigger_type.hit = 1'b1;
            fire_req_Itrigger.valid = 1'b1;
            case (trigger_32_tdata1_d[i].itrigger_type.action)
              6'd0:
              if (CVA6Cfg.SdtrigSupportedActions[0]) fire_req_Itrigger.action = riscv::BREAKPOINT;
              6'd1:
              if (CVA6Cfg.SdtrigSupportedActions[1])
                fire_req_Itrigger.action = riscv::DEBUG_REQUEST;
              default: ;
            endcase
          end
          if (sdtrig_commit_std_exception_valid_q && ex_i.valid) begin
            trigger_32_tdata1_d[i].itrigger_type.hit = 1'b0;
            fire_req_Itrigger.valid = 1'b0;
          end
        end
      end


      //Trigger fire logic
      //Priorities : load data > execute address > execute data > load address/store address/store data
      if (CVA6Cfg.SdtrigMcontrol6LoadData && fire_req_LD.valid || CVA6Cfg.SdtrigIcount && fire_req_Icount.valid || CVA6Cfg.SdtrigEtrigger && fire_req_Etrigger.valid || CVA6Cfg.SdtrigItrigger && fire_req_Itrigger.valid) begin
        if (fire_req_LD.valid) begin
          sdtrig_load_data_action_o = fire_req_LD.action;
        end
        if (fire_req_Icount.valid) begin
          sdtrig_commit_icount_valid_d = 1'b1;
          sdtrig_commit_action_d = fire_req_Icount.action;
        end
        if (fire_req_Etrigger.valid) begin
          sdtrig_commit_std_exception_valid_d = 1'b1;
          sdtrig_commit_action_d = fire_req_Etrigger.action;
        end
        if (fire_req_Itrigger.valid) begin
          sdtrig_commit_std_exception_valid_d = 1'b1;
          sdtrig_commit_action_d = fire_req_Itrigger.action;
        end
      end else if (CVA6Cfg.SdtrigMcontrol6ExecAddr && |fire_req_EA_valid) begin
        sdtrig_decoder_action_o = fire_req_EA_action;
      end else if (CVA6Cfg.SdtrigMcontrol6ExecData && |fire_req_ED_valid) begin
        sdtrig_decoder_action_o = fire_req_ED_action;
      end else
      
      if (CVA6Cfg.SdtrigMcontrol6LoadAddr && fire_req_LA.valid || CVA6Cfg.SdtrigMcontrol6Store && fire_req_SX.valid) begin
        if (CVA6Cfg.SdtrigMcontrol6LoadAddr && fire_req_LA.valid) begin
          sdtrig_load_cancel_d = (sdtrig_load_cancel_q) ? 1'b0 : 1'b1;
          if (!sdtrig_load_cancel_q) sdtrig_load_action_d = fire_req_LA.action;
          sdtrig_load_action_o = sdtrig_load_cancel_q ? sdtrig_load_action_q : fire_req_LA.action;
        end
        if (CVA6Cfg.SdtrigMcontrol6Store && fire_req_SX.valid) begin
          sdtrig_store_action_o = fire_req_SX.action;
          sdtrig_store_stall_o  = 1'b1;
        end
      end
    end

    // Trigger module CSRs
    if (tselect_we) begin
      tselect_d = (tselect_i < CVA6Cfg.XLEN'(CVA6Cfg.SdtrigNrTriggers)) ?
          tselect_i[$clog2(CVA6Cfg.SdtrigNrTriggers)-1:0] : tselect_q;
    end
    //  A trigger whose dmode is set belongs to the debugger: machine mode
    //  must not be able to touch it, and cannot set dmode itself either.
    if (tdata1_we && (!trigger_32_tdata1_q[tselect_q].tdata1_type[27] || debug_mode_i)) begin
      if (CVA6Cfg.IS_XLEN32) begin
        if (CVA6Cfg.Sdtrig && CVA6Cfg.SdtrigNrTriggers > 0) begin
          if(   CVA6Cfg.SdtrigIcount && tdata1_i[31:28] == 4'd3
             || CVA6Cfg.SdtrigMcontrol6 && tdata1_i[31:28] == 4'd6
             || CVA6Cfg.SdtrigEtrigger && tdata1_i[31:28] == 4'd5
             || CVA6Cfg.SdtrigItrigger && tdata1_i[31:28] == 4'd4
             || tdata1_i[31:28] == 4'd15 || tdata1_i[31:28] == 4'd0) begin
            trigger_type_d[tselect_q] = tdata1_i[31:28];
          end
          if (CVA6Cfg.SdtrigIcount && trigger_type_d[tselect_q] == 4'd3) begin
            trigger_32_tdata1_d[tselect_q].icount_type.t_type = trigger_type_d[tselect_q];
            trigger_32_tdata1_d[tselect_q].icount_type.dmode = debug_mode_i && tdata1_i[27];
            trigger_32_tdata1_d[tselect_q].icount_type.vs = CVA6Cfg.RVH && tdata1_i[26];
            trigger_32_tdata1_d[tselect_q].icount_type.vu = CVA6Cfg.RVH && tdata1_i[25];
            trigger_32_tdata1_d[tselect_q].icount_type.hit = tdata1_i[24];
            trigger_32_tdata1_d[tselect_q].icount_type.count = tdata1_i[23:10];
            trigger_32_tdata1_d[tselect_q].icount_type.m = tdata1_i[9];
            trigger_32_tdata1_d[tselect_q].icount_type.pending = tdata1_i[8];
            trigger_32_tdata1_d[tselect_q].icount_type.s = tdata1_i[7];
            trigger_32_tdata1_d[tselect_q].icount_type.u = tdata1_i[6];
            trigger_32_tdata1_d[tselect_q].icount_type.action = tdata1_i[5:0];
            flush_o = 1'b1;
          end else if (CVA6Cfg.SdtrigMcontrol6 && trigger_type_d[tselect_q] == 4'd6) begin
            trigger_32_tdata1_d[tselect_q].mc6_type.t_type = trigger_type_d[tselect_q];
            trigger_32_tdata1_d[tselect_q].mc6_type.dmode = debug_mode_i && tdata1_i[27];
            trigger_32_tdata1_d[tselect_q].mc6_type.uncertain = 0;
            trigger_32_tdata1_d[tselect_q].mc6_type.hit1 = tdata1_i[25];
            trigger_32_tdata1_d[tselect_q].mc6_type.vs = CVA6Cfg.RVH && tdata1_i[24];
            trigger_32_tdata1_d[tselect_q].mc6_type.vu = CVA6Cfg.RVH && tdata1_i[23];
            trigger_32_tdata1_d[tselect_q].mc6_type.hit0 = tdata1_i[22];
            trigger_32_tdata1_d[tselect_q].mc6_type.select = tdata1_i[21];
            trigger_32_tdata1_d[tselect_q].mc6_type.zeroes = '0;
            trigger_32_tdata1_d[tselect_q].mc6_type.size = tdata1_i[18:16];
            trigger_32_tdata1_d[tselect_q].mc6_type.action = tdata1_i[15:12];
            trigger_32_tdata1_d[tselect_q].mc6_type.chain = tdata1_i[11];
            trigger_32_tdata1_d[tselect_q].mc6_type.match = tdata1_i[10:7];
            trigger_32_tdata1_d[tselect_q].mc6_type.m = tdata1_i[6];
            trigger_32_tdata1_d[tselect_q].mc6_type.uncertainen = 0;
            trigger_32_tdata1_d[tselect_q].mc6_type.s = tdata1_i[4];
            trigger_32_tdata1_d[tselect_q].mc6_type.u = tdata1_i[3];
            trigger_32_tdata1_d[tselect_q].mc6_type.execute = tdata1_i[2];
            trigger_32_tdata1_d[tselect_q].mc6_type.store = tdata1_i[1];
            trigger_32_tdata1_d[tselect_q].mc6_type.load = tdata1_i[0];
            flush_o = 1'b1;
          end else if (CVA6Cfg.SdtrigEtrigger && trigger_type_d[tselect_q] == 4'd5) begin
            trigger_32_tdata1_d[tselect_q].etrigger_type.t_type = trigger_type_d[tselect_q];
            trigger_32_tdata1_d[tselect_q].etrigger_type.dmode = debug_mode_i && tdata1_i[27];
            trigger_32_tdata1_d[tselect_q].etrigger_type.hit = tdata1_i[26];
            trigger_32_tdata1_d[tselect_q].etrigger_type.zeroes = '0;
            trigger_32_tdata1_d[tselect_q].etrigger_type.vs = CVA6Cfg.RVH && tdata1_i[12];
            trigger_32_tdata1_d[tselect_q].etrigger_type.vu = CVA6Cfg.RVH && tdata1_i[11];
            trigger_32_tdata1_d[tselect_q].etrigger_type.zeroed = 0;
            trigger_32_tdata1_d[tselect_q].etrigger_type.m = tdata1_i[9];
            trigger_32_tdata1_d[tselect_q].etrigger_type.zero = 0;
            trigger_32_tdata1_d[tselect_q].etrigger_type.s = tdata1_i[7];
            trigger_32_tdata1_d[tselect_q].etrigger_type.u = tdata1_i[6];
            trigger_32_tdata1_d[tselect_q].etrigger_type.action = tdata1_i[5:0];
          end else if (CVA6Cfg.SdtrigItrigger && trigger_type_d[tselect_q] == 4'd4) begin
            trigger_32_tdata1_d[tselect_q].itrigger_type.t_type = trigger_type_d[tselect_q];
            trigger_32_tdata1_d[tselect_q].itrigger_type.dmode = debug_mode_i && tdata1_i[27];
            trigger_32_tdata1_d[tselect_q].itrigger_type.hit = tdata1_i[26];
            trigger_32_tdata1_d[tselect_q].itrigger_type.zeroed = '0;
            trigger_32_tdata1_d[tselect_q].itrigger_type.vs = CVA6Cfg.RVH && tdata1_i[12];
            trigger_32_tdata1_d[tselect_q].itrigger_type.vu = CVA6Cfg.RVH && tdata1_i[11];
            trigger_32_tdata1_d[tselect_q].itrigger_type.nmi = 0;
            trigger_32_tdata1_d[tselect_q].itrigger_type.m = tdata1_i[9];
            trigger_32_tdata1_d[tselect_q].itrigger_type.zero = 0;
            trigger_32_tdata1_d[tselect_q].itrigger_type.s = tdata1_i[7];
            trigger_32_tdata1_d[tselect_q].itrigger_type.u = tdata1_i[6];
            trigger_32_tdata1_d[tselect_q].itrigger_type.action = tdata1_i[5:0];
          end
        end
      end else if (CVA6Cfg.IS_XLEN64) begin
        if (CVA6Cfg.SdtrigIcount && tdata1_w[63:60] == 4'd3) begin
          trigger_type_d[tselect_q] = tdata1_w[63:60];
          trigger_32_tdata1_d[tselect_q].icount_type.t_type  = (tdata1_w[63:60] == 4'd3 || tdata1_w[63:60] == 4'd15) ? tdata1_w[63:60] : trigger_type_q[tselect_q];
          trigger_32_tdata1_d[tselect_q].icount_type.dmode = debug_mode_i && tdata1_w[59];
          trigger_32_tdata1_d[tselect_q].icount_type.vs = CVA6Cfg.RVH && tdata1_w[26];
          trigger_32_tdata1_d[tselect_q].icount_type.vu = CVA6Cfg.RVH && tdata1_w[25];
          trigger_32_tdata1_d[tselect_q].icount_type.hit = tdata1_w[24];
          trigger_32_tdata1_d[tselect_q].icount_type.count = tdata1_w[23:10];
          trigger_32_tdata1_d[tselect_q].icount_type.m = tdata1_w[9];
          trigger_32_tdata1_d[tselect_q].icount_type.pending = tdata1_w[8];
          trigger_32_tdata1_d[tselect_q].icount_type.s = tdata1_w[7];
          trigger_32_tdata1_d[tselect_q].icount_type.u = tdata1_w[6];
          trigger_32_tdata1_d[tselect_q].icount_type.action = tdata1_w[5:0];
          flush_o = 1'b1;
        end else if (CVA6Cfg.SdtrigMcontrol6 && tdata1_w[63:60] == 4'd6) begin
          trigger_type_d[tselect_q] = tdata1_w[63:60];
          trigger_32_tdata1_d[tselect_q].mc6_type.t_type  = (tdata1_w[63:60] == 4'd6 || tdata1_w[63:60] == 4'd15) ? tdata1_w[63:60] : trigger_type_q[tselect_q];
          trigger_32_tdata1_d[tselect_q].mc6_type.dmode = debug_mode_i && tdata1_w[59];
          trigger_32_tdata1_d[tselect_q].mc6_type.uncertain = 0;
          trigger_32_tdata1_d[tselect_q].mc6_type.hit1 = tdata1_w[25];
          trigger_32_tdata1_d[tselect_q].mc6_type.vs = CVA6Cfg.RVH && tdata1_w[24];
          trigger_32_tdata1_d[tselect_q].mc6_type.vu = CVA6Cfg.RVH && tdata1_w[23];
          trigger_32_tdata1_d[tselect_q].mc6_type.hit0 = tdata1_w[22];
          trigger_32_tdata1_d[tselect_q].mc6_type.select = tdata1_w[21];
          trigger_32_tdata1_d[tselect_q].mc6_type.zeroes = '0;
          trigger_32_tdata1_d[tselect_q].mc6_type.size = tdata1_w[18:16];
          trigger_32_tdata1_d[tselect_q].mc6_type.action = tdata1_w[15:12];
          trigger_32_tdata1_d[tselect_q].mc6_type.chain = tdata1_w[11];
          trigger_32_tdata1_d[tselect_q].mc6_type.match = tdata1_w[10:7];
          trigger_32_tdata1_d[tselect_q].mc6_type.m = tdata1_w[6];
          trigger_32_tdata1_d[tselect_q].mc6_type.uncertainen = 0;
          trigger_32_tdata1_d[tselect_q].mc6_type.s = tdata1_w[4];
          trigger_32_tdata1_d[tselect_q].mc6_type.u = tdata1_w[3];
          trigger_32_tdata1_d[tselect_q].mc6_type.execute = tdata1_w[2];
          trigger_32_tdata1_d[tselect_q].mc6_type.store = tdata1_w[1];
          trigger_32_tdata1_d[tselect_q].mc6_type.load = tdata1_w[0];
          flush_o = 1'b1;
        end else if (CVA6Cfg.SdtrigEtrigger && tdata1_w[63:60] == 4'd5) begin
          trigger_type_d[tselect_q] = tdata1_w[63:60];
          trigger_32_tdata1_d[tselect_q].etrigger_type.t_type  = (tdata1_w[63:60] == 4'd5 || tdata1_w[63:60] == 4'd15) ? tdata1_w[63:60] : trigger_type_q[tselect_q];
          trigger_32_tdata1_d[tselect_q].etrigger_type.dmode = debug_mode_i && tdata1_w[59];
          trigger_32_tdata1_d[tselect_q].etrigger_type.hit = tdata1_w[58];
          trigger_32_tdata1_d[tselect_q].etrigger_type.zeroes = '0;
          trigger_32_tdata1_d[tselect_q].etrigger_type.vs = CVA6Cfg.RVH && tdata1_w[12];
          trigger_32_tdata1_d[tselect_q].etrigger_type.vu = CVA6Cfg.RVH && tdata1_w[11];
          trigger_32_tdata1_d[tselect_q].etrigger_type.zeroed = 0;
          trigger_32_tdata1_d[tselect_q].etrigger_type.m = tdata1_w[9];
          trigger_32_tdata1_d[tselect_q].etrigger_type.zero = 0;
          trigger_32_tdata1_d[tselect_q].etrigger_type.s = tdata1_w[7];
          trigger_32_tdata1_d[tselect_q].etrigger_type.u = tdata1_w[6];
          trigger_32_tdata1_d[tselect_q].etrigger_type.action = tdata1_w[5:0];
        end else if (CVA6Cfg.SdtrigItrigger && tdata1_w[63:60] == 4'd4) begin
          trigger_type_d[tselect_q] = tdata1_w[63:60];
          trigger_32_tdata1_d[tselect_q].itrigger_type.t_type  = (tdata1_w[63:60] == 4'd4 || tdata1_w[63:60] == 4'd15) ? tdata1_w[63:60] : trigger_type_q[tselect_q];
          trigger_32_tdata1_d[tselect_q].itrigger_type.dmode = debug_mode_i && tdata1_w[59];
          trigger_32_tdata1_d[tselect_q].itrigger_type.hit = tdata1_w[58];
          trigger_32_tdata1_d[tselect_q].itrigger_type.zeroed = '0;
          trigger_32_tdata1_d[tselect_q].itrigger_type.vs = CVA6Cfg.RVH && tdata1_w[12];
          trigger_32_tdata1_d[tselect_q].itrigger_type.vu = CVA6Cfg.RVH && tdata1_w[11];
          trigger_32_tdata1_d[tselect_q].itrigger_type.nmi = 0;
          trigger_32_tdata1_d[tselect_q].itrigger_type.m = tdata1_w[9];
          trigger_32_tdata1_d[tselect_q].itrigger_type.zero = 0;
          trigger_32_tdata1_d[tselect_q].itrigger_type.s = tdata1_w[7];
          trigger_32_tdata1_d[tselect_q].itrigger_type.u = tdata1_w[6];
          trigger_32_tdata1_d[tselect_q].itrigger_type.action = tdata1_w[5:0];
        end else if (tdata1_w[63:60] == 4'd15) begin
          trigger_type_d[tselect_q] = tdata1_w[63:60];
        end
      end
    end
    if (tdata2_we && (!trigger_32_tdata1_q[tselect_q].tdata1_type[27] || debug_mode_i)) begin
      tdata2_d[tselect_q] = tdata2_i;
      flush_o = 1'b1;
    end
    if (CVA6Cfg.SdtrigSupportTextra && tdata3_we && (!trigger_32_tdata1_q[tselect_q].tdata1_type[27] || debug_mode_i)) begin
      if (CVA6Cfg.IS_XLEN32) begin
        textra32_tdata3_d[tselect_q].mhvalue   = '0;
        textra32_tdata3_d[tselect_q].mhselect  = '0;
        textra32_tdata3_d[tselect_q].zeroes    = '0;
        textra32_tdata3_d[tselect_q].sbytemask = tdata3_i[19:18];
        textra32_tdata3_d[tselect_q].svalue    = tdata3_i[17:2];
        textra32_tdata3_d[tselect_q].sselect   = tdata3_i[1:0];
      end
      if (CVA6Cfg.IS_XLEN64) begin  // textra64
        textra64_tdata3_d[tselect_q].mhvalue    = '0;
        textra64_tdata3_d[tselect_q].mhselect   = '0;
        textra64_tdata3_d[tselect_q].zeroes     = '0;
        textra64_tdata3_d[tselect_q].sbytemask  = tdata3_w[39:36];
        textra64_tdata3_d[tselect_q].zero_field = '0;
        textra64_tdata3_d[tselect_q].svalue     = tdata3_w[33:2];
        textra64_tdata3_d[tselect_q].sselect    = tdata3_w[1:0];
      end
    end
  end

  always_comb begin : read_path
    // TSELECT read
    tselect_o = CVA6Cfg.XLEN'(tselect_q);

    // TDATA1 read (depends on trigger type)
    unique case (trigger_type_q[tselect_q])
      4'd3:
      tdata1_o = (CVA6Cfg.IS_XLEN32) ? CVA6Cfg.XLEN'(trigger_32_tdata1_q[tselect_q]) : CVA6Cfg.XLEN'({ trigger_32_tdata1_q[tselect_q].icount_type.t_type, trigger_32_tdata1_q[tselect_q].icount_type.dmode, 32'd0, trigger_32_tdata1_q[tselect_q][26:0] });
      4'd6:
      tdata1_o = (CVA6Cfg.IS_XLEN32) ? CVA6Cfg.XLEN'(trigger_32_tdata1_q[tselect_q]) : CVA6Cfg.XLEN'({ trigger_32_tdata1_q[tselect_q].mc6_type.t_type, trigger_32_tdata1_q[tselect_q].mc6_type.dmode, 32'd0, trigger_32_tdata1_q[tselect_q][26:0] });
      4'd5:
      tdata1_o = (CVA6Cfg.IS_XLEN32) ? CVA6Cfg.XLEN'(trigger_32_tdata1_q[tselect_q]) : CVA6Cfg.XLEN'({ trigger_32_tdata1_q[tselect_q].etrigger_type.t_type, trigger_32_tdata1_q[tselect_q].etrigger_type.dmode, trigger_32_tdata1_q[tselect_q].etrigger_type.hit, 45'd0, trigger_32_tdata1_q[tselect_q][12:0] });
      4'd4:
      tdata1_o = (CVA6Cfg.IS_XLEN32) ? CVA6Cfg.XLEN'(trigger_32_tdata1_q[tselect_q]) : CVA6Cfg.XLEN'({ trigger_32_tdata1_q[tselect_q].itrigger_type.t_type, trigger_32_tdata1_q[tselect_q].itrigger_type.dmode, trigger_32_tdata1_q[tselect_q].itrigger_type.hit, 45'd0, trigger_32_tdata1_q[tselect_q][12:0] });
      default: tdata1_o = '0;
    endcase

    // TDATA2 read
    tdata2_o = {{(CVA6Cfg.XLEN - CVA6Cfg.VLEN) {1'b0}}, tdata2_q[tselect_q]};

    // TDATA3 read
    if (CVA6Cfg.SdtrigSupportTextra)
      tdata3_o = (CVA6Cfg.IS_XLEN32) ? CVA6Cfg.XLEN'(textra32_tdata3_q[tselect_q]) : CVA6Cfg.XLEN'(textra64_tdata3_q[tselect_q]);
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin : state_update
    if (~rst_ni) begin
      if (CVA6Cfg.Sdtrig) begin
        tselect_q <= '0;
        e_matched_q <= 1'b0;
        mret_reg_q <= 1'b0;
        sdtrig_commit_std_exception_valid_q <= 0;
        sdtrig_commit_icount_valid_o <= 1'b0;
        sdtrig_commit_icount_nr_instr_o <= '0;
        sdtrig_commit_action_o <= '0;
        sdtrig_load_cancel_q <= '0;
        sdtrig_load_action_q <= '0;
        etrigger_context_saved_valid_q <= 1'b0;
        etrigger_context_mepc_q <= '0;
        etrigger_context_mcause_q <= '0;
        etrigger_context_mtval_q <= '0;
        if (CVA6Cfg.SdtrigIcount) in_trap_handler_q <= '0;
        for (int i = 0; i < CVA6Cfg.SdtrigNrTriggers; ++i) begin
          trigger_type_q[i] <= '0;
          trigger_32_tdata1_q[i] <= '0;
          if (CVA6Cfg.SdtrigTriggerChaining) trigger_chain_vector_q[i] <= '0;
          textra32_tdata3_q[i] <= '0;
          textra64_tdata3_q[i] <= '0;
          tdata2_q[i] <= '0;
        end
      end
    end else begin
      if (CVA6Cfg.Sdtrig) begin
        textra32_tdata3_q               <= textra32_tdata3_d;
        textra64_tdata3_q               <= textra64_tdata3_d;

        trigger_type_q                  <= trigger_type_d;
        trigger_32_tdata1_q             <= trigger_32_tdata1_d;
        tselect_q                       <= tselect_d;
        tdata2_q                        <= tdata2_d;
        sdtrig_commit_icount_valid_o    <= sdtrig_commit_icount_valid_d;
        sdtrig_commit_icount_nr_instr_o <= sdtrig_commit_icount_nr_instr_d;
        sdtrig_commit_action_o          <= sdtrig_commit_action_d;
        etrigger_context_saved_valid_q  <= etrigger_context_saved_valid_d;
        etrigger_context_mepc_q         <= etrigger_context_mepc_d;
        etrigger_context_mcause_q       <= etrigger_context_mcause_d;
        etrigger_context_mtval_q        <= etrigger_context_mtval_d;
        if (CVA6Cfg.SdtrigIcount) begin
          in_trap_handler_q <= in_trap_handler_d;
        end
        sdtrig_commit_std_exception_valid_q <= sdtrig_commit_std_exception_valid_d;
        e_matched_q                         <= e_matched_d;
        mret_reg_q                          <= mret_reg_d;
        sdtrig_load_cancel_q                <= sdtrig_load_cancel_d;
        sdtrig_load_action_q                <= sdtrig_load_action_d;
        if (CVA6Cfg.SdtrigTriggerChaining) trigger_chain_vector_q <= trigger_chain_vector_d;
      end
    end
  end

  // Outputs
  assign sdtrig_commit_std_exception_valid_o = sdtrig_commit_std_exception_valid_q;
  assign etrigger_context_saved_valid_o = etrigger_context_saved_valid_q;
  assign etrigger_context_mepc_o = etrigger_context_mepc_q;
  assign etrigger_context_mcause_o = etrigger_context_mcause_q;
  if (CVA6Cfg.TvalEn) begin
    assign etrigger_context_mtval_o = etrigger_context_mtval_q;
  end else begin
    assign etrigger_context_mtval_o = '0;
  end
  assign sdtrig_load_cancel_o = sdtrig_load_cancel_q;
  if (!CVA6Cfg.SdtrigIcount) begin
    assign in_trap_handler_q = '0;
    assign in_trap_handler_d = '0;
  end

endmodule
