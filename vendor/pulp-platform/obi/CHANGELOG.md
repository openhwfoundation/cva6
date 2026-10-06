# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

## 0.1.7 - 2025-05-21
### Fixed
- `obi_cut`: Fix connection error
- `obi_atop_resolver`: Add support for any-width OBI atomic transactions.
- Replace `$clog2` with `idx_width` for widths to ensure non-zero widths.
- Use `always_comb` blocks with default `='0` for structs to ensure non-assigned field are tied.
### Added
- Add `apb_to_obi` module.

## 0.1.6 - 2025-03-26
### Fixed
- `obi_atop_resolver`: Fix assertion error output.
- `obi_cut`: Fix synthesis error.

## 0.1.5 - 2024-08-15
### Fixed
- `obi_cut`: Fix syntax error.

## 0.1.4 - 2024-08-15
### Added
- Add `obi_cut` to add a pipeline stage and cut combinatorial paths.
### Fixed
- `obi_demux`: Ensure `gnt` signal is properly passed and handshake is consistent for Manager and Subordinate ports.

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
