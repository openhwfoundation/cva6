# CSR WFI single-step regression

This test instantiates the real `core/csr_regfile.sv` to reproduce CVA6 issue
#3497. It uses the `fpga_linux_cv32a6` configuration and a second instance of
that configuration with `DebugEn=0`. It does not force internal DUT state.

The driver supplies decoded CSR operations, commit acknowledgements, and
exceptions at the CSR boundary. Debug entry is requested through the normal
CSR inputs; `dcsr` is programmed through CSR accesses, preserving its other
fields and selecting machine privilege, and execution resumes through `DRET`.

Checks cover:

- Stepped WFI with no interrupts or debug request, for both `stepie` values.
- Debug-entry redirect, single-step cause, saved privilege, and exact `DPC=PC+4`.
- No WFI halt immediately after debug re-entry or on following clocks.
- Continued debug CSR accesses and ordinary WFI after single-step is disabled.
- WFI in Debug Mode, with single-step clear and set.
- Ordinary WFI stall and wake through an enabled pending software interrupt,
  `irq_i[1]`, and a debug request, including the debug-disabled case.
- Exception suppression of the WFI wait state and reset state.

This is a CSR unit regression. It does not execute instructions through the
decoder/pipeline, execute the Debug ROM, validate trigger priority, run the
VCS/UVM debug suite, or claim coverage of other configurations. The minimal
scoreboard type includes the fields consumed by this module with triggers
disabled; the driver checks that the selected configuration disables triggers.

## Requirements

Use a Verilator 5 installation supporting `--binary --timing`, GNU Make, and
a C++20 compiler. The `core/cvfpu` submodule must be initialized for its package.
No RISC-V compiler, Spike libraries, or VCS license is needed.

## Run

From the repository root:

```bash
bash verif/tests/unit/csr_wfi/run.sh /tmp/cva6-csr-wfi
```

The runner accepts an optional second argument selecting a different CSR RTL
file. `VERILATOR` may select an alternative Verilator executable. All generated
files go into the selected build directory, and compilation uses one job.

To prove failure before the patch and success after it, supply an unpatched
baseline commit compatible with the remaining source tree:

```bash
bash verif/tests/unit/csr_wfi/compare.sh \
  /tmp/cva6-3497-regression 40ac92ccc09534fb0c6b139a613f65868af9f499
```

The comparator obtains only the baseline CSR file with `git show`; it never
replaces the working-tree RTL. It requires the baseline to fail at the specific
issue-3497 assertion, then requires the working-tree test to exit successfully
with the final pass marker. A compile failure cannot count as a reproduction.
Logs are `before.log` and `after.log` in the specified build directory. Keep
this directory outside the repository and retain it for review.

On a machine with limited memory, run the comparator inside a systemd scope
with suitable memory limits, as with the main Verilator build.
