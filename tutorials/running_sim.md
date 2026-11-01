# Running standalone simulations

Simulating the CVA6 is done by using `verif/sim/cva6.py`.

The environment variable `DV_SIMULATORS` allows you to specify which simulator to use.

Four simulation types are supported:
- **veri-testharness**: verilator with corev_apu/testharness testbench
- **vcs-testharness**: vcs with corev_apu/testharness testbench
- **vcs-uvm**: vcs with UVM testbench
- **Spike** ISS 

You can set several simulators, such as :

```sh
export DV_SIMULATORS=veri-testharness,vcs-testharness,vcs_uvm
```

If exactly 2 simulators are given, their trace is compared ([see the Regression tests section](#running-regression-tests-simulations)).

Here is how you can run the hello world C program with the Verilator model: 

```sh
# Make sure to source this script from the root directory 
# to correctly set the environment variables related to the tools
source verif/sim/setup-env.sh

# Set the NUM_JOBS variable to increase the number of parallel make jobs
# export NUM_JOBS=

export DV_SIMULATORS=veri-testharness

cd ./verif/sim

python3 cva6.py --target cv32a60x --iss=$DV_SIMULATORS --iss_yaml=cva6.yaml \
--c_tests ../tests/custom/hello_world/hello_world.c \
--linker=../../config/gen_from_riscv_config/linker/link.ld \
--gcc_opts="-static -mcmodel=medany -fvisibility=hidden -nostdlib \
-nostartfiles -g ../tests/custom/common/syscalls.c \
../tests/custom/common/crt.S -lgcc \
-I../tests/custom/env -I../tests/custom/common"
```

You can run either assembly programs (check `verif/test/custom/hello_world/custom_test_template.S`) or C programs. Run `python3 cva6.py --help` to have more information on the available parameters.

## Simulating with the RISC-V proxy kernel
When running C programs, a common requirement is to use standard library functions like printf. On a bare-metal core, these functions do not work because they rely on underlying system calls that have no operating system to handle them. The [RISC-V proxy kernel](https://github.com/riscv-software-src/riscv-pk) (pk) solves this: it loads the program and serves its system calls through the host, here the TestHarness (e.g. to properly display printf output).

The flow runs with cook.py, on the Verilator or VCS TestHarness, for a target with U-mode and the debug module. For instance on a 32-bit target:
```sh
./cook.py git-dependencies --repo riscv-pk
./cook.py pk-build -t fpga_linux_cv32a6 -c gcc-15
./cook.py pk-hello-world -t fpga_linux_cv32a6 -c gcc-15
./cook.py verilator-testharness-comp -t fpga_linux_cv32a6
./cook.py verilator-testharness-run -t fpga_linux_cv32a6 -n pk-hello-world
```
The program prints its text in `build/fpga_linux_cv32a6/simulation/sim_rtl_verilator_testharness/pk-hello-world/testharness.log`, confirming that the printf statement was executed properly. See the `pk-build` and `pk-hello-world` recipes in [flows/README.md](../flows/README.md) for the details.

## Simulating with VCS and Verdi

You can set the environment variable `VERDI` as such if you want to launch Verdi while simulating with VCS:

```sh
export VERDI=1
```


# Running regression tests simulations

The smoke-tests script installs a random instruction generator and several tests suites:
- [riscv-dv](https://github.com/chipsalliance/riscv-dv)
- [riscv-compliance](https://github.com/lowRISC/riscv-compliance)
- [riscv-tests](https://github.com/riscv-software-src/riscv-tests)
- [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)


The regression tests are done by comparing a model simulation trace with the Spike trace.

Several tests scripts can be found in `./verif/regress`

For example, here is how would run the riscv-arch-test regression test suite with the Verilator model:

```sh
export DV_SIMULATORS=veri-testharness,spike
bash verif/regress/dv-riscv-arch-test.sh
```


# Logs

The logs from cva6.py are located in `./verif/sim/out_YEAR-MONTH-DAY`.

Assuming you ran the smoke-tests scripts in the previous step, here is the log directory hierarchy:

- **directed_asm_tests/**: The compiled (to .o then .bin) assembly tests
- **directed_c_tests/**: The compiled (to .o then .bin) c tests
- **spike_sim/**: Spike simulation log and trace files
- **veri_testharness_sim**: Verilator simulation log and trace files, when simulated using veri-testharness
- **iss_regr.log**: The regression test log 

The regression test log summarizes the comparison between the simulator trace and the Spike trace. Beware that a if a test fails before the comparison step, it will not appear in this log, check the output of cva6.py and the logs of the simulation instead.


# Waveform generation

Waveform generation is currently supported for Verilator (`veri-testharness`)
and VCS with full UVM testbench (`vcs-uvm`) simulation types.  It is disabled
by default to save simulation time and storage space.

To enable waveform generation for a supported simulation mode, set either
of the two shell variables that control tracing before running any of the
test scripts under `verif/regress`:
- `export TRACE_FAST=1` enables "fast" waveform generation (keep simulation
   time low at the expense of space).  This will produce VCD files when using
   Verilator, and VPD files when using Synopsys VCS with UVM testbench (`vcs-uvm`).
- `export TRACE_COMPACT=1` enables "compact" waveform generation (keep waveform
   files smaller at the expense of increased simulation time).  This will
   produce FST files when using Verilator, and FSDB files when using Synopsys
   VCS with UVM testbench (`vcs-uvm`).

To generate VCD waveforms of the `smoke-tests` regression suite using Verilator, use:
```sh
export DV_SIMULATORS=veri-testharness,spike
export TRACE_FAST=1
bash verif/regress/smoke-tests-<cpu_version>.sh
```

Where `<cpu_version>` is one of the following, depending on the CPU variant you want to use.
- `cv32a65x`.
- `fpga_linux_cv32a6`.
- `cv64a6_imafdc_sv39`.

After each simulation run involving Verilator or VCS, the generated waveforms
will be copied  to the directory containing the log files (see above,) with
the name of the current HW configuration added to the file name right before
the file type suffix (e.g., `I-ADD-01.cv32a60x.vcd`).
