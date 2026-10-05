/*
 *  Copyright 2023 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Cesar Fuguet
 *  Creation Date : March, 2020
 *  Description   : Behavioral model of a 1RW SRAM with write byte enable
 *  History       :
 */

// 512 |  128 

// ADDR_SIZE = 9,
// DATA_SIZE = 128,
// DEPTH = 2**ADDR_SIZE,
// NDATA = 1

module hpdcache_sram_wbyteenable_1rw_impl
(
    input  logic                              clk,
    input  logic                              rst_n,
    input  logic                              cs,
    input  logic                              we,
    input  logic [9-1:0]              addr,
    input  logic [1-1:0][128-1:0]   wdata,
    input  logic [1-1:0][128/8-1:0] wbyteenable,
    output logic [1-1:0][128-1:0]   rdata
);

    /*
     *  Internal memory array declaration
     */
    typedef logic [1-1:0][128-1:0] mem_t [2**9];
    mem_t mem;

    /*
     *  Process to update or read the memory array
     */
    always_ff @(posedge clk)
    begin : mem_update_ff
        if (cs == 1'b1) begin
            if (we == 1'b1) begin
                for (int j = 0; j < 1; j++) begin
                    for (int i = 0; i < 128/8; i++) begin
                        if (wbyteenable[j][i]) mem[addr][j][i*8 +: 8] <= wdata[j][i*8 +: 8];
                    end
                end
            end else begin
                rdata <= mem[addr];
            end
        end
    end : mem_update_ff
endmodule : hpdcache_sram_wbyteenable_1rw_impl