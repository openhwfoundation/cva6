# OBI

The repository contains a collection of SystemVerilog IPs for the [OBI v1.6 standard](https://github.com/openhwgroup/obi/blob/072d9173c1f2d79471d6f2a10eae59ee387d4c6f/OBI-v1.6.0.pdf).

They are designed by PULP-platform and are available under the Solderpad v0.51 license (See [`LICENSE`](LICENSE)).

## Using the IPs
As the OBI protocol is very configurable, the IPs are designed to incorporate specific parameters for the design:

- `ObiCfg`: This specifies the configuration used for the OBI protocol being input or output from the link. A default config can be found in the `obi_pkg.sv`. This config should be aligned with the `req` and `rsp` structs.
- `obi_req_t`: The OBI request struct is designed to be generated with a macro available in the `include/obi/typedef.svh` include file and has fields for the handshake and a field for the *A* channel.
- `obi_rsp_t`: The OBI response struct is designed to be generated with a macro available in the `include/obi/typedef.svh` include file and has fields for the handshake and a filed for the *R* channel.

Most IPs will also support a SystemVerilog `interface` variant, also based on `ObiCfg`.

## Available IPs
- `obi_mux.sv`: A multiplexer IP for the OBI protocol.
- `obi_demux.sv`: A demultiplexer IP for the OBI protocol.
- `obi_xbar.sv`: A crossbar interconnect IP for the OBI protocol.
- `obi_err_sbr.sv`: A error subordinate, responding with the error bit set.
- `obi_sram_shim.sv`: An adapter for a standard sram.
- `obi_atop_resolver.sv`: An atomics filter, resolving atomic operations on an exclusive bus.

## License
Solderpad Hardware License, Version 0.51
