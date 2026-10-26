//-----------------------------------------------------------------------------
// Copyright (C) 2022 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// SPDX-License-Identifier: SHL-0.51
//-----------------------------------------------------------------------------
//
// Author: Manuel Eggimann <meggimann@iis.ee.ethz.ch>
//
// Contains common defintions for the CDC Clear Synchronization Circuitry

package cdc_reset_ctrlr_pkg;

typedef enum logic[1:0] {
  CLEAR_PHASE_IDLE,
  CLEAR_PHASE_ISOLATE,
  CLEAR_PHASE_CLEAR,
  CLEAR_PHASE_POST_CLEAR
} clear_seq_phase_e;

endpackage : cdc_reset_ctrlr_pkg
