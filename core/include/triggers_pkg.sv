package triggers_pkg;
  // Triggers
  typedef struct packed {
    logic [31:28] t_type;   // type 3 for icount
    logic         dmode;
    logic         vs;
    logic         vu;
    logic         hit;
    logic [23:10] count;
    logic         m;
    logic         pending;
    logic         s;
    logic         u;
    logic [5:0]   action;
  } icount32_tdata1_t;

  typedef struct packed {
    logic [31:26] mhvalue;
    logic [25:23] mhselect;
    logic [22:20] zeroes;
    logic [19:18] sbytemask;
    logic [17:2]  svalue;
    logic [1:0]   sselect;
  } textra32_tdata3_t;

  typedef struct packed {
    logic [63:51] mhvalue;
    logic [50:48] mhselect;
    logic [47:40] zeroes;
    logic [39:36] sbytemask;
    logic [35:34] zero_field;
    logic [33:2]  svalue;
    logic [1:0]   sselect;
  } textra64_tdata3_t;

  typedef struct packed {
    logic [31:28] t_type;  // type 6 for mcontrol6
    logic dmode;
    logic uncertain;
    logic hit1;
    logic vs;
    logic vu;
    logic hit0;
    logic select;
    logic [20:19] zeroes;
    logic [18:16] size;
    logic [15:12] action;
    logic chain;
    logic [10:7] match;
    logic m;
    logic uncertainen;
    logic s;
    logic u;
    logic execute;
    logic store;
    logic load;
  } mcontrol6_32_tdata1_t;

  typedef struct packed {
    logic [31:28] t_type;  // type 4 for itrigger
    logic dmode;
    logic hit;
    logic [25:13] zeroed;
    logic vs;
    logic vu;
    logic nmi;
    logic m;
    logic zero;
    logic s;
    logic u;
    logic [5:0] action;
  } itrigger32_tdata1_t;

  typedef struct packed {
    logic [31:28] t_type;  // type 5 for etrigger
    logic dmode;
    logic hit;
    logic [25:13] zeroes;
    logic vs;
    logic vu;
    logic zeroed;
    logic m;
    logic zero;
    logic s;
    logic u;
    logic [5:0] action;
  } etrigger32_tdata1_t;

  typedef union packed {
    logic [31:0] tdata1_type;
    mcontrol6_32_tdata1_t mc6_type;
    etrigger32_tdata1_t etrigger_type;
    itrigger32_tdata1_t itrigger_type;
    icount32_tdata1_t icount_type;
  } trigger_32_tdata1_type;

  // NAPOT range match: the base address ends with a run of ones that sets the
  // range size. ~(base ^ (base + 1)) keeps only the bits above that run, which
  // are the ones compared.
  function automatic logic napot_match32(logic [31:0] base, logic [31:0] value);
    logic [31:0] mask;
    mask = ~(base ^ (base + 1));
    return (value & mask) == (base & mask);
  endfunction

  function automatic logic napot_match64(logic [63:0] base, logic [63:0] value);
    logic [63:0] mask;
    mask = ~(base ^ (base + 1));
    return (value & mask) == (base & mask);
  endfunction

  function automatic logic match_scontext32(input logic [31:0] scontext, input logic [1:0] sselect,
                                            input logic [1:0] sbytemask, input logic [15:0] svalue,
                                            input logic flag);
    logic match;
    int   max_bytes = 0;
    match = 1'b1;
    if (sselect == 2'd1) begin
      max_bytes = (flag) ? 4 : 2;
      for (int b = 0; b < 4; b++) begin
        if (b < max_bytes && !sbytemask[b]) begin
          if (scontext[8*b+:8] != svalue[8*b+:8]) match = 1'b0;
        end
      end
    end else match = 1'b0;
    return match;
  endfunction

  function automatic logic match_scontext64(input logic [31:0] scontext, input logic [1:0] sselect,
                                            input logic [3:0] sbytemask, input logic [31:0] svalue,
                                            input logic flag);
    logic match;
    int   max_bytes = 0;
    match = 1'b1;
    if (sselect == 2'd1) begin
      max_bytes = (flag) ? 4 : 2;
      for (int b = 0; b < 4; b++) begin
        if (b < max_bytes && !sbytemask[b]) begin
          if (scontext[8*b+:8] != svalue[8*b+:8]) match = 1'b0;
        end
      end
    end else match = 1'b0;
    return match;
  endfunction


endpackage
