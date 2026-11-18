# Linux

Purpose: know where Linux runs on CVA6 and which page to follow.

**Prerequisites:** [getting_started.md](../getting_started.md), an FPGA
board and its tools ([fpga/README.md](../fpga/README.md)).

Linux runs on the FPGA boards only. No recipe boots Linux in simulation.

The Linux image is not built by `cook.py`. It comes from the
[CVA6 SDK](https://github.com/openhwgroup/cva6-sdk), which also provides
the RISC-V tools and Buildroot. Its README explains how to build the
image and how to prepare the SD card.

`cook.py` builds the bitstream, programs the board and checks the boot:

- Genesys 2 and the SD card: [fpga/README.md, Booting Linux](../fpga/README.md#booting-linux);
- Agilex 7: [fpga/README.md, Agilex 7](../fpga/README.md#agilex-7);
- the boot check, `fpga-linux-boot`:
  [flows/README.md](../../flows/README.md#fpga-linux-boot).

## See also

- [zephyr.md](zephyr.md): an RTOS that also runs in simulation
- [fpga/README.md](../fpga/README.md): the whole FPGA chain
