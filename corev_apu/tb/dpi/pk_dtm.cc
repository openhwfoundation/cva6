// Copyright 2026 Thales France
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51
// (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing, software, hardware and materials
// distributed under this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//
// Contributors:
//   Yannick Casamatta, Thales - Original Author
//
// Description: debug_tick of the SimDTM for a program the testbench preloads.
//
// Loaded by the run recipes ahead of libfesvr only for a test under the proxy
// kernel, so its debug_tick is the one the simulator binds. The testbench
// preloads the ELF through +elf_file: telling HTIF the memory is preloaded
// keeps fesvr from writing the image again through the debug module, eight
// bytes per debug session. Same DTM as the one ariane_tb.cpp builds for the
// Verilator TestHarness.

#include <fesvr/dtm.h>

#include <cstring>
#include <string>
#include <vector>

// The simulator provides vpi_get_vlog_info (IEEE 1364): declared here so
// that the library builds without the headers of a given simulator.
extern "C" {
typedef struct t_vpi_vlog_info {
  int argc;
  char **argv;
  char *product;
  char *version;
} s_vpi_vlog_info;
int vpi_get_vlog_info(s_vpi_vlog_info *vlog_info_p);
}

namespace {

class preload_aware_dtm_t : public dtm_t {
 public:
  preload_aware_dtm_t(int argc, char **argv) : dtm_t(argc, argv) {}
  bool is_address_preloaded(addr_t, size_t) override { return true; }
  // The preloaded program starts at the reset vector: the reset of dtm_t,
  // which forces the debug PC to the entry point, is not needed.
  void reset() override {}
};

preload_aware_dtm_t *dtm = nullptr;

// Arguments of HTIF out of the simulator command line: the ones between
// +permissive and +permissive-off are skipped, and a leading `++` marks the
// program and its arguments.
std::vector<std::string> htif_args() {
  s_vpi_vlog_info info;
  if (!vpi_get_vlog_info(&info)) abort();
  std::vector<std::string> args;
  bool permissive = false;
  for (int i = 1; i < info.argc; i++) {
    std::string arg = info.argv[i];
    if (arg == "+permissive") permissive = true;
    if (arg.size() > 2 && arg[0] == '+' && arg[1] == '+') arg = arg.substr(2);
    if (!permissive) args.push_back(arg);
    if (arg == "+permissive-off") permissive = false;
  }
  return args;
}

}  // namespace

extern "C" int debug_tick(unsigned char *debug_req_valid, unsigned char debug_req_ready,
                          int *debug_req_bits_addr, int *debug_req_bits_op,
                          int *debug_req_bits_data, unsigned char debug_resp_valid,
                          unsigned char *debug_resp_ready, int debug_resp_bits_resp,
                          int debug_resp_bits_data) {
  if (!dtm) {
    static std::vector<std::string> args = htif_args();
    static std::vector<char *> argv;
    argv.push_back(const_cast<char *>("htif"));
    for (auto &arg : args) argv.push_back(const_cast<char *>(arg.c_str()));
    dtm = new preload_aware_dtm_t(argv.size(), argv.data());
  }

  dtm_t::resp resp_bits;
  resp_bits.resp = debug_resp_bits_resp;
  resp_bits.data = debug_resp_bits_data;

  dtm->tick(debug_req_ready, debug_resp_valid, resp_bits);

  *debug_resp_ready = dtm->resp_ready();
  *debug_req_valid = dtm->req_valid();
  *debug_req_bits_addr = dtm->req_bits().addr;
  *debug_req_bits_op = dtm->req_bits().op;
  *debug_req_bits_data = dtm->req_bits().data;

  return dtm->done() ? (dtm->exit_code() << 1 | 1) : 0;
}
