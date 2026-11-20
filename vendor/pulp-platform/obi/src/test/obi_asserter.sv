// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
// - Tobias Senti <tsenti@ethz.ch>

`include "common_cells/assertions.svh"

/// Checks for compliance with the OBI spec !!!Not complete!!!
module obi_asserter #(
    parameter type obi_req_t = logic,
    parameter type obi_rsp_t = logic
) (
    input logic clk_i,
    input logic rst_ni,

    input obi_req_t obi_req_i,
    input obi_rsp_t obi_rsp_i
);
    //R-2.1
    `ASSERT(OBIAReqLowDuringReset, !rst_ni |-> !obi_req_i.a_req, clk_i, 1'b0)
    //R-2.2
    `ASSERT(OBIRValidLowDuringReset, !rst_ni |-> !obi_rsp_i.r_valid, clk_i, 1'b0)

    //R-3.1 - Stable during address phase
    `ASSERT(OBIReadStableDuringAddressPhase,
        ((obi_req_i.a_req && !obi_req_i.a.we && !obi_rsp_i.a_gnt) |=>
        $stable({obi_req_i.a_req, obi_req_i.a.we, obi_req_i.a.addr, obi_req_i.a.be})),
        clk_i, !rst_ni)

    `ASSERT(OBIWriteStableDuringAddressPhase,
        ((obi_req_i.a_req && obi_req_i.a.we && !obi_rsp_i.a_gnt) |=>
        $stable({obi_req_i.a_req, obi_req_i.a})), clk_i, !rst_ni)

    //R-4.1 - Stable during response phase
    `ASSERT(OBIStableDuringResponsePhase, ((obi_rsp_i.r_valid && !obi_req_i.r_ready) |=>
        $stable({obi_rsp_i.r_valid, obi_rsp_i.r})), clk_i, !rst_ni)

    //R-5 - Response phase should only be sent after the corresponding address phase has ended

endmodule
