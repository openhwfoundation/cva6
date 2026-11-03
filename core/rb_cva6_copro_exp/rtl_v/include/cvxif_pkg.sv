// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume CHAUVON (guillaume.chauvon@thalesgroup.com)

// Package for the CoreV-X-Interface for the CVA6

package cvxif_pkg;
  import config_pkg::*;
  import cva6_config_pkg::*;
  import riscv::*;
  import ariane_pkg::*;

  localparam X_DATAWIDTH = riscv::XLEN;
  localparam X_NUM_RS = ariane_pkg::NR_RGPR_PORTS;  //2 or 3
  localparam X_ID_WIDTH = $clog2(cva6_config_pkg::CVA6ConfigNrScoreboardEntries);
  localparam X_MEM_WIDTH = 64;
  localparam X_RFR_WIDTH = riscv::XLEN;
  localparam X_RFW_WIDTH = riscv::XLEN;

  typedef struct packed {
    logic [15:0]           instr;
    logic [1:0]            mode;
    logic [X_ID_WIDTH-1:0] id;
  } x_compressed_req_t;

  typedef struct packed {
    logic [31:0] instr;
    logic        accept;
  } x_compressed_resp_t;

  typedef struct packed {
    logic [31:0]                          instr;
    logic [1:0]                           mode;
    logic [X_ID_WIDTH-1:0]                id;
    logic [X_NUM_RS-1:0][X_RFR_WIDTH-1:0] rs;
    logic [X_NUM_RS-1:0]                  rs_valid;
  } x_issue_req_t;

  typedef struct packed {
    logic accept;
    logic writeback;
    logic dualwrite;
    logic dualread;
    logic loadstore;
    logic exc;
  } x_issue_resp_t;

  typedef struct packed {
    logic [X_ID_WIDTH-1:0] id;
    logic                  x_commit_kill;
  } x_commit_t;

  typedef struct packed {
    logic [X_ID_WIDTH-1:0]  id;
    logic [31:0]            addr;
    logic [1:0]             mode;
    logic                   we;
    logic [1:0]             size;
    logic [X_MEM_WIDTH-1:0] wdata;
    logic                   last;
    logic                   spec;
  } x_mem_req_t;

  typedef struct packed {
    logic       exc;
    logic [5:0] exccode;
  } x_mem_resp_t;

  typedef struct packed {
    logic [X_ID_WIDTH-1:0]  id;
    logic [X_MEM_WIDTH-1:0] rdata;
    logic                   err;
  } x_mem_result_t;

  typedef struct packed {
    logic [X_ID_WIDTH-1:0]  id;
    logic [X_RFW_WIDTH-1:0] data;
    logic [4:0]             rd;
    logic                   we;
    logic                   exc;
    logic [5:0]             exccode;
  } x_result_t;

  typedef struct packed {
    logic              x_compressed_valid;
    x_compressed_req_t x_compressed_req;
    logic              x_issue_valid;
    x_issue_req_t      x_issue_req;
    logic              x_commit_valid;
    x_commit_t         x_commit;
    logic              x_mem_ready;
    x_mem_resp_t       x_mem_resp;
    logic              x_mem_result_valid;
    x_mem_result_t     x_mem_result;
    logic              x_result_ready;
  } cvxif_req_t;

  typedef struct packed {
    logic               x_compressed_ready;
    x_compressed_resp_t x_compressed_resp;
    logic               x_issue_ready;
    x_issue_resp_t      x_issue_resp;
    logic               x_mem_valid;
    x_mem_req_t         x_mem_req;
    logic               x_result_valid;
    x_result_t          x_result;
  } cvxif_resp_t;

endpackage
