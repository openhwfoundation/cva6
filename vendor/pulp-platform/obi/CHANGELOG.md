# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

## 0.1.3 - 2024-07-18
### Added
- Add `obi_rready_converter` to convert between manager requiring rready to subordinate not supporting it.

## 0.1.2 - 2024-03-11
### Added
- Add assertion module to check protocol constraints.
- Add additional typedefs.

## 0.1.1 - 2023-08-08
### Fixed
- `obi_mux`: Move `if` outside `always_comb` to enforce `generate` and remove compile warning.

## 0.1.0 - 2023-07-24

Initial release
### Added
- `obi_mux.sv`: A multiplexer IP for the OBI protocol.
- `obi_demux.sv`: A demultiplexer IP for the OBI protocol.
- `obi_xbar.sv`: A crossbar interconnect IP for the OBI protocol.
- `obi_err_sbr.sv`: A error subordinate, responding with the error bit set.
- `obi_sram_shim.sv`: An adapter for a standard sram.
- `obi_atop_resolver.sv`: An atomics filter, resolving atomic operations on an exclusive bus.
- Various support infrastructure for types and configurations in `obi_pkg.sv`, `obi_typedef.svh`, and `obi_assign.svh`.
- Initial testing infrastructure, testing `obi_xbar` and `obi_atop_resolver`.
