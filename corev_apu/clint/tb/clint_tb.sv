// Copyright 2026 OpenHW Group contributors.
// SPDX-License-Identifier: SHL-0.51

module clint_tb;
  localparam ariane_axi::addr_t MtimeCmp = 'h02004000;
  localparam ariane_axi::addr_t Mtime = 'h0200bff8;

  bit clk, rst_n, rtc;
  always #5 clk = ~clk;
  ariane_axi::req_t req;
  ariane_axi::resp_t resp;
  logic [1:0] timer_irq;

  clint #(
      .CVA6Cfg(build_config_pkg::build_config(cva6_config_pkg::cva6_cfg)),
      .AXI_ID_WIDTH(ariane_axi::IdWidth),
      .NR_CORES(2)
  ) dut (
      .clk_i(clk), .rst_ni(rst_n), .testmode_i(1'b0),
      .axi_req_i(req), .axi_resp_o(resp), .rtc_i(rtc), .timer_irq_o(timer_irq), .ipi_o()
  );

  task automatic write_reg(ariane_axi::addr_t addr, axi_pkg::size_t size,
                           ariane_axi::data_t data, ariane_axi::strb_t strb);
    req.aw.addr = addr;
    req.aw.size = size;
    req.aw_valid = 1;
    do @(posedge clk); while (!resp.aw_ready);
    @(negedge clk);
    req.aw_valid = 0;
    req.w.data = data;
    req.w.strb = strb;
    req.w.last = 1;
    req.w_valid = 1;
    do @(posedge clk); while (!resp.w_ready);
    @(negedge clk);
    req.w_valid = 0;
    do @(posedge clk); while (!resp.b_valid);
    @(negedge clk);
  endtask

  task automatic check_reg(ariane_axi::addr_t addr, ariane_axi::data_t expected);
    // A 32-bit read returns the addressed half in its corresponding AXI data lanes.
    for (int half = 0; half < 2; half++) begin
      req.ar.addr = addr + 4 * half;
      req.ar.size = 2;
      req.ar_valid = 1;
      do @(posedge clk); while (!resp.ar_ready);
      @(negedge clk);
      req.ar_valid = 0;
      do @(posedge clk); while (!resp.r_valid);
      if (resp.r.data[32*half+:32] !== expected[32*half+:32])
        $fatal(1, "addr %h: expected %h, got %h", req.ar.addr,
               expected[32*half+:32], resp.r.data[32*half+:32]);
      @(negedge clk);
    end
  endtask

  initial begin
    req = '0;
    req.r_ready = 1;
    req.b_ready = 1;
    repeat (2) @(negedge clk);
    rst_n = 1;

    write_reg(MtimeCmp, 2, 64'hdeadbeef_ffffffff, 8'h0f);
    write_reg(MtimeCmp + 4, 2, 64'h00000001_deadbeef, 8'hf0);
    check_reg(MtimeCmp, 64'h00000001_ffffffff);
    write_reg(MtimeCmp + 4, 2, 0, 8'hf0);
    check_reg(MtimeCmp, 64'h00000000_ffffffff);
    if (timer_irq[0] !== 1'b0) $fatal(1, "Future compare raised the timer IRQ");

    for (int reg_idx = 0; reg_idx < 2; reg_idx++) begin
      ariane_axi::addr_t addr;
      addr = reg_idx == 0 ? MtimeCmp + 8 : Mtime;
      write_reg(addr, 3, 64'h01234567_89abcdef, 8'hff);
      write_reg(addr, 3, '1, 8'h42);
      write_reg(addr, 3, 0, 8'h00);
      write_reg(addr + 7, 0, 64'h98000000_00000000, 8'h80);
      check_reg(addr, 64'h98ff4567_89abffef);
    end
    write_reg(MtimeCmp + 16, 3, 0, 8'hff);
    check_reg(MtimeCmp, 64'h00000000_ffffffff);

    write_reg(Mtime, 3, 64'h00000000_ffffffff, 8'hff);
    // The synchronizer delivers the RTC edge on the following write's data beat.
    rtc = 1;
    @(negedge clk);
    write_reg(Mtime + 4, 2, 64'h00000007_deadbeef, 8'hf0);
    check_reg(Mtime, 64'h00000007_00000000);
    $display("CLINT RV%0d timer write checks passed", cva6_config_pkg::CVA6ConfigXlen);
    $finish;
  end

  initial #10000 $fatal(1, "CLINT bus timeout");
endmodule
