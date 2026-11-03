// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at

//   http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include "verilator.h"
#include "verilated.h"
#include "Variane_testharness.h"
#if (VERILATOR_VERSION_INTEGER >= 5000000)
  // Verilator v5 adds $root wrapper that provides rootp pointer.
  #include "Variane_testharness___024root.h"
#endif
#if VM_TRACE_FST
#include "verilated_fst_c.h"
#else
#include "verilated_vcd_c.h"
#endif
#include "Variane_testharness__Dpi.h"

#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <getopt.h>
#include <chrono>
#include <ctime>
#include <signal.h>
#include <unistd.h>

#include <fesvr/dtm.h>
#include <fesvr/htif_hexwriter.h>
#include <fesvr/elfloader.h>
#include "remote_bitbang.h"

// This software is heavily based on Rocket Chip
// Checkout this awesome project:
// https://github.com/freechipsproject/rocket-chip/


// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.
static vluint64_t main_time = 0;

static const char *verilog_plusargs[] = {"jtag_rbb_enable", "time_out", "debug_disable"};

extern dtm_t* dtm;
extern remote_bitbang_t * jtag;

void handle_sigterm(int sig) {
  dtm->stop();
}


extern "C" void read_elf(const char* filename);
extern "C" char get_section (long long* address, long long* len);
extern "C" void read_section_void(long long address, void * buffer, uint64_t size = 0);

// Called by $time in Verilog converts to double, to match what SystemC does
double sc_time_stamp () {
    return main_time;
}

static void usage(const char * program_name) {
  printf("Usage: %s [EMULATOR OPTION]... [VERILOG PLUSARG]... [HOST OPTION]... BINARY [TARGET OPTION]...\n",
         program_name);
  fputs("\
Run a BINARY on the Ariane emulator.\n\
\n\
Mandatory arguments to long options are mandatory for short options too.\n\
\n\
EMULATOR OPTIONS\n\
  -r, --rbb-port=PORT      Use PORT for remote bit bang (with OpenOCD and GDB) \n\
                           If not specified, a random port will be chosen\n\
                           automatically.\n\
", stdout);
#if VM_TRACE == 0
  fputs("\
\n\
EMULATOR DEBUG OPTIONS (only supported in debug build -- try `make debug`)\n",
        stdout);
#endif
  fputs("\
  -v, --vcd=FILE,          Write vcd trace to FILE (or '-' for stdout)\n\
  -f, --fst=FILE,          Write fst trace to FILE\n\
  -p,                      Print performance statistic at end of test\n\
", stdout);
  // fputs("\n" PLUSARG_USAGE_OPTIONS, stdout);
  fputs("\n" HTIF_USAGE_OPTIONS, stdout);
  printf("\n"
"EXAMPLES\n"
"  - run a bare metal test:\n"
"    %s $RISCV/riscv64-unknown-elf/share/riscv-tests/isa/rv64ui-p-add\n"
"  - run a bare metal test showing cycle-by-cycle information:\n"
"    %s spike-dasm < trace_core_00_0.dasm > trace.out\n"
#if VM_TRACE
"  - run a bare metal test to generate a VCD waveform:\n"
"    %s -v rv64ui-p-add.vcd $RISCV/riscv64-unknown-elf/share/riscv-tests/isa/rv64ui-p-add\n"
"  - run a bare metal test to generate an FST waveform:\n"
"    %s -f rv64ui-p-add.fst $RISCV/riscv64-unknown-elf/share/riscv-tests/isa/rv64ui-p-add\n"
#endif
  , program_name, program_name);
}

// In case we use the DTM we do not want to use the JTAG
// to preload the data but only use the DTM to host fesvr functionality.
class preload_aware_dtm_t : public dtm_t {
  public:
    preload_aware_dtm_t(int argc, char **argv) : dtm_t(argc, argv) {}
    bool is_address_preloaded(addr_t taddr, size_t len) override { return true; }
    // We do not want to reset the hart here as the reset function in `dtm_t` seems to disregard
    // the privilege level and in general does not perform proper reset (despite the name).
    // As all our binaries in preloading will always start at the base of DRAM this should not
    // be such a big problem.
    void reset() {}
};

int main(int argc, char **argv) {
  std::clock_t c_start = std::clock();
  auto t_start = std::chrono::high_resolution_clock::now();
  bool verbose;
  bool perf;
  unsigned random_seed = (unsigned)time(NULL) ^ (unsigned)getpid();
  uint64_t max_cycles = -1;
  int ret = 0;
  bool print_cycles = false;
  // Port numbers are 16 bit unsigned integers.
  uint16_t rbb_port = 0;
#if VM_TRACE
  FILE * vcdfile = NULL;
  char * fst_fname = NULL;
  uint64_t start = 0;
#endif
  char ** htif_argv = NULL;
  int verilog_plusargs_legal = 1;

  while (1) {
    static struct option long_options[] = {
      {"cycle-count", no_argument,       0, 'c' },
      {"help",        no_argument,       0, 'h' },
      {"max-cycles",  required_argument, 0, 'm' },
      {"seed",        required_argument, 0, 's' },
      {"rbb-port",    required_argument, 0, 'r' },
      {"verbose",     no_argument,       0, 'V' },
#if VM_TRACE
      {"vcd",         required_argument, 0, 'v' },
      {"dump-start",  required_argument, 0, 'x' },
      {"fst",         required_argument, 0, 'f' },
#endif
      HTIF_LONG_OPTIONS
    };
    int option_index = 0;
#if VM_TRACE
    int c = getopt_long(argc, argv, "-chpm:s:r:v:f:Vx:", long_options, &option_index);
#else
    int c = getopt_long(argc, argv, "-chpm:s:r:V", long_options, &option_index);
#endif
    if (c == -1) break;
 retry:
    switch (c) {
      // Process long and short EMULATOR options
      case '?': usage(argv[0]);             return 1;
      case 'c': print_cycles = true;        break;
      case 'h': usage(argv[0]);             return 0;
      case 'm': max_cycles = atoll(optarg); break;
      case 's': random_seed = atoi(optarg); break;
      case 'r': rbb_port = atoi(optarg);    break;
      case 'V': verbose = true;             break;
      case 'p': perf = true;                break;
#if VM_TRACE
      case 'v': {
        vcdfile = strcmp(optarg, "-") == 0 ? stdout : fopen(optarg, "w");
        if (!vcdfile) {
          std::cerr << "Unable to open " << optarg << " for VCD write\n";
          return 1;
        }
        break;
      }
      case 'f': {
        fst_fname = optarg;
        break;
      }
      case 'x': start = atoll(optarg);      break;
#endif
      // Process legacy '+' EMULATOR arguments by replacing them with
      // their getopt equivalents
      case 1: {
        std::string arg = optarg;
        if (arg.substr(0, 1) != "+") {
          optind--;
          goto done_processing;
        }
        if (arg == "+verbose")
          c = 'V';
        else if (arg.substr(0, 12) == "+max-cycles=") {
          c = 'm';
          optarg = optarg+12;
        }
#if VM_TRACE
        else if (arg.substr(0, 12) == "+dump-start=") {
          c = 'x';
          optarg = optarg+12;
        }
#endif
        else if (arg.substr(0, 12) == "+cycle-count")
          c = 'c';
        // If we don't find a legacy '+' EMULATOR argument, it still could be
        // a VERILOG_PLUSARG and not an error.
        else if (verilog_plusargs_legal) {
          const char ** plusarg = &verilog_plusargs[0];
          int legal_verilog_plusarg = 0;
          while (*plusarg && (legal_verilog_plusarg == 0)){
            if (arg.substr(1, strlen(*plusarg)) == *plusarg) {
              legal_verilog_plusarg = 1;
            }
            plusarg ++;
          }
          if (!legal_verilog_plusarg) {
            verilog_plusargs_legal = 0;
          } else {
            c = 'P';
          }
          goto retry;
        }
        // If we STILL don't find a legacy '+' argument, it still could be
        // an HTIF (HOST) argument and not an error. If this is the case, then
        // we're done processing EMULATOR and VERILOG arguments.
        else {
          static struct option htif_long_options [] = { HTIF_LONG_OPTIONS };
          struct option * htif_option = &htif_long_options[0];
          while (htif_option->name) {
            if (arg.substr(1, strlen(htif_option->name)) == htif_option->name) {
              optind--;
              goto done_processing;
            }
            htif_option++;
          }
          std::cerr << argv[0] << ": invalid plus-arg (Verilog or HTIF) \""
                    << arg << "\"\n";
          c = '?';
        }
        goto retry;
      }
      case 'P': break; // Nothing to do here, Verilog PlusArg
      // Realize that we've hit HTIF (HOST) arguments or error out
      default:
        if (c >= HTIF_LONG_OPTIONS_OPTIND) {
          optind--;
          goto done_processing;
        }
        c = '?';
        goto retry;
    }
  }

done_processing:
  if (optind == argc) {
    std::cerr << "No binary specified for emulator\n";
    usage(argv[0]);
    return 1;
  }
  int htif_argc = 1 + argc - optind;
  htif_argv = (char **) malloc((htif_argc) * sizeof (char *));
  htif_argv[0] = argv[0];
  for (int i = 1; optind < argc;) htif_argv[i++] = argv[optind++];

  const char *vcd_file = NULL;
  Verilated::commandArgs(argc, argv);

  jtag = new remote_bitbang_t(rbb_port);
  dtm = new preload_aware_dtm_t(htif_argc, htif_argv);
  signal(SIGTERM, handle_sigterm);

  std::unique_ptr<Variane_testharness> top(new Variane_testharness);

  read_elf(htif_argv[1]);

#if VM_TRACE
  Verilated::traceEverOn(true); // Verilator must compute traced signals
#if VM_TRACE_FST
  std::unique_ptr<VerilatedFstC> tfp(new VerilatedFstC());
  if (fst_fname) {
    std::cerr << "Starting FST waveform dump into file '" << fst_fname << "'...\n";
    top->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open(fst_fname);
  }
  else
    std::cerr << "No explicit FST file name supplied, using RTL defaults.\n";
#else
  std::unique_ptr<VerilatedVcdFILE> vcdfd(new VerilatedVcdFILE(vcdfile));
  std::unique_ptr<VerilatedVcdC> tfp(new VerilatedVcdC(vcdfd.get()));
  if (vcdfile) {
    std::cerr << "Starting VCD waveform dump ...\n";
    top->trace(tfp.get(), 99);  // Trace 99 levels of hierarchy
    tfp->open("");
  }
  else
    std::cerr << "No explicit VCD file name supplied, using RTL defaults.\n";
#endif
#endif

  for (int i = 0; i < 10; i++) {
    top->rst_ni = 0;
    top->clk_i = 0;
    top->rtc_i = 0;
    top->eval();
#if VM_TRACE
    if (vcdfile || fst_fname)
      tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif
    top->clk_i = 1;
    top->eval();
#if VM_TRACE
    if (vcdfile || fst_fname)
      tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    main_time++;
  }
  top->rst_ni = 1;

  // Preload memory.
#if (VERILATOR_VERSION_INTEGER >= 5000000)
  // Verilator v5: Use rootp pointer and .data() accessor.
#define MEM top->rootp->ariane_testharness__DOT__i_sram__DOT__gen_cut__BRA__0__KET____DOT__i_tc_sram_wrapper__DOT__i_tc_sram__DOT__sram.m_storage
#define MEM_USER top->rootp->ariane_testharness__DOT__i_sram__DOT__gen_cut__BRA__0__KET____DOT__gen_mem_user__DOT__i_tc_sram_wrapper_user__DOT__i_tc_sram__DOT__sram.m_storage
#else
  // Verilator v4
#define MEM top->ariane_testharness__DOT__i_sram__DOT__gen_cut__BRA__0__KET____DOT__i_tc_sram_wrapper__DOT__i_tc_sram__DOT__sram
#define MEM_USER top->ariane_testharness__DOT__i_sram__DOT__gen_cut__BRA__0__KET____DOT__gen_mem_user__DOT__i_tc_sram_wrapper_user__DOT__i_tc_sram__DOT__sram
#endif
  long long addr;
  long long len;

  size_t mem_size = 0xFFFFFF;
  constexpr uint64_t dram_base = 0x80000000ULL;
  const uint64_t dram_size = static_cast<uint64_t>(mem_size);
  while(get_section(&addr, &len))
  {
    if (addr >= 0 && len >= 0) {
      const uint64_t section_addr = static_cast<uint64_t>(addr);
      const uint64_t section_size = static_cast<uint64_t>(len);

      if (section_addr >= dram_base) {
        const uint64_t offset = section_addr - dram_base;

        // Check the range without computing offset + section_size, which
        // could overflow before it is compared with dram_size.
        if (offset <= dram_size && section_size <= dram_size - offset) {
          auto *destination = reinterpret_cast<uint8_t *>(MEM) + offset;
          read_section_void(addr, destination, section_size);
        }
      }
    }
    if (addr == 0x84000000)
        try {
          read_section_void(addr, (void *) MEM_USER , mem_size);
        } catch (...){
          std::cerr << "No user memory instantiated ...\n";
        }
  }

  while (!dtm->done() && !jtag->done() && !(top->exit_o & 0x1)) {
    top->clk_i = 0;
    top->eval();
#if VM_TRACE
    if (vcdfile || fst_fname)
      tfp->dump(static_cast<vluint64_t>(main_time * 2));
#endif

    top->clk_i = 1;
    top->eval();
#if VM_TRACE
    if (vcdfile || fst_fname)
      tfp->dump(static_cast<vluint64_t>(main_time * 2 + 1));
#endif
    // toggle RTC
    if (main_time % 2 == 0) {
      top->rtc_i ^= 1;
    }
    main_time++;
  }

#if VM_TRACE
  if (tfp)
    tfp->close();
  if (vcdfile)
    fclose(vcdfile);
#endif

  if (dtm->exit_code()) {
    fprintf(stderr, "%s *** FAILED *** (tohost = %d) after %ld cycles\n", htif_argv[1], dtm->exit_code(), main_time);
    ret = dtm->exit_code();
  } else if (jtag->exit_code()) {
    fprintf(stderr, "%s *** FAILED *** (tohost = %d, seed %d) after %ld cycles\n", htif_argv[1], jtag->exit_code(), random_seed, main_time);
    ret = jtag->exit_code();
  } else if (top->exit_o & 0xFFFFFFFE) {
    int exitcode = ((unsigned int) top->exit_o) >> 1;
    fprintf(stderr, "%s *** FAILED *** (tohost = %d) after %ld cycles\n", htif_argv[1], exitcode, main_time);
    ret = exitcode;
  } else {
    fprintf(stderr, "%s *** SUCCESS *** (tohost = 0) after %ld cycles\n", htif_argv[1], main_time);
  }

  if (dtm) delete dtm;
  if (jtag) delete jtag;

  std::clock_t c_end = std::clock();
  auto t_end = std::chrono::high_resolution_clock::now();

  if (perf) {
    std::cout << std::fixed << std::setprecision(2) << "CPU time used: "
              << 1000.0 * (c_end-c_start) / CLOCKS_PER_SEC << " ms\n"
              << "Wall clock time passed: "
              << std::chrono::duration<double, std::milli>(t_end-t_start).count()
              << " ms\n";
  }

  return ret;
}
