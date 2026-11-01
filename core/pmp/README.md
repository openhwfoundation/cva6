# PMP

This repository houses a purely combinatorial and parameterizable physical memory protection (PMP) unit.

__Warning__: The PMP unit does only check the exact byte that is addressed. If the processor wants to load a 8 byte value, then every single byte should get checked. Due to the default granularity of PMPs of 4 bytes, this only comes into play for 8byte RISC-V memory accesses. An easy fix is to increase the granularity to 8 bytes. You can do this by setting the lowest bit of conf_addr_i to 1 if the pmp is in NAPOT mode, or to 0 if the PMP is in TOR mode.