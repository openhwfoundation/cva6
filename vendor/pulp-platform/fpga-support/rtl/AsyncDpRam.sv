// Copyright 2022 Thales Research and Technology
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses
//
// Inferable, Asynchronous Dual-Port RAM, there are a write port and a read port
//
//
// This module is designed to work with both Xilinx and Microchip FPGA tools by following the respective
// guidelines:
// - Xilinx UG901 Vivado Design Suite User Guide: Synthesis
// - Inferring Microchip PolarFire RAM Blocks
//
// Intel FPGA (Altera) doesn't seem to support asynchronous RAM
//
// Current Maintainers:: Sébastien Jacq - sjthales on github.com

 
module AsyncDpRam
#(
  parameter ADDR_WIDTH = 10,
  parameter DATA_DEPTH = 1024, // usually 2**ADDR_WIDTH, but can be lower
  parameter DATA_WIDTH = 32
)(
  input  logic                    Clk_CI,

  // Write port
  input  logic                    WrEn_SI,
  input  logic [ADDR_WIDTH-1:0]   WrAddr_DI,
  input  logic [DATA_WIDTH-1:0]   WrData_DI,
  
  // Read port
  input  logic [ADDR_WIDTH-1:0]   RdAddr_DI,
  output logic [DATA_WIDTH-1:0]   RdData_DO
);

  logic [DATA_WIDTH-1:0] mem [DATA_DEPTH-1:0]= '{default:0};

  // WRITE
  // always, not always_ff: mem also has an initial value, and always_ff
  // forbids any other process from writing the variable it drives.
  always @(posedge Clk_CI)
  begin
    if (WrEn_SI) begin
      mem[WrAddr_DI] <= WrData_DI;
    end
  end

 // READ
  assign RdData_DO = mem[RdAddr_DI];
  
  ////////////////////////////
  // assertions
  ////////////////////////////

  // pragma translate_off
  assert property
    (@(posedge Clk_CI) (longint'(2)**longint'(ADDR_WIDTH) >= longint'(DATA_DEPTH)))
    else $error("depth out of bounds");
  // pragma translate_on

endmodule 
