..
   Copyright (c) 2023 OpenHW Group
   Copyright (c) 2023 Thales DIS design services SAS

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.. Level 1
   =======

   Level 2
   -------

   Level 3
   ~~~~~~~

   Level 4
   ^^^^^^^

.. _cva6_parameters_configuration:

Parameters and Configuration
============================

Main contributor: Jean-Roch Coulon - Thales


Parameters
----------

.. include:: user_cfg_doc.rst

\*: Some parameters are incompatible with others:

- ``SuperscalarEn``:

   - Recommended to set ``NrScoreboardEntries`` to at least 8 for performance.

- Floating point (``RVF``, ``RVD``):

   - ``RVD`` needs ``RVF``.
   - The FPU takes its operands from and returns its result on the
     ``XLEN``-wide execution datapath: FLEN, the width of the widest enabled
     format, must equal ``XLEN``. Supported: ``RVF`` on RV32, ``RVF`` and
     ``RVD`` on RV64.
   - Not supported: ``RVD`` on RV32 (FLEN 64), which would need an FP datapath
     wider than ``XLEN`` and 64-bit FP loads and stores on a 32-bit core;
     ``RVF`` without ``RVD`` on RV64 (FLEN 32).

- ``RVH``:

   - Only supported on RV64 (Sv39x4).

An unsupported combination stops the elaboration with a ``$fatal`` message.


Configurations
--------------
A configuration is a fixed set of parameters.

.. csv-table::
   :widths: auto
   :align: left
   :header: "Parameter", "CV32A6_v5.0.0 config"

   "``Cva6MArchID``",               "3"
   "``Xlen``",                      "32"
   "``CExtEn``",                    "1"
   "``AExtEn``",                    "1"
   "``BMExtEn``",                   "0"
   "``FpuEn``",                     "0"
   "``F16En``",                     "0"
   "``F16AltEn``",                  "0"
   "``F8En``",                      "0"
   "``FVecEn``",                    "0"
   "``MMUEn``",                     "1"
   "``InstrTlbEntries``",           "16"
   "``DataTlbEntries``",            "16"
   "``RASDepth``",                  "0"
   "``BTBEntries``",                "0"
   "``BHTEntries``",                "0"
   "``NrNonIdempotentRules``",      "2"
   "``NonIdempotentAddrBase``",     "{64’b0, 64’b0}"
   "``NonIdempotentLength``",       "{64’b0, 64’b0}"
   "``NrExecuteRegionRules``",      "3"
   "``ExecuteRegionAddrBase``",     "{64’h8000_0000,64’h1_0000,64’h0}"
   "``ExecuteRegionLength``",       "{64’h4000_0000,64’h10000,64’h1000}"
   "``NrCachedRegionRules``",       "1"
   "``CachedRegionAddrBase``",      "{64’h8000_0000}"
   "``CachedRegionLength``",        "{64’h4000_0000}"
   "``NrBufferableRegionRules``",   "0"
   "``BufferableRegionAddrBase``",  "{64’b0}"
   "``BufferableRegionLength``",    "{64’b0}"
   "``NrPMPEntries``",              "4"
   "``DmBaseAddress``",             "0"
   "``CvxifEn``",                   "1"
   "``RVFI_TRACE (define)``",       "1"
   "``FIRESIM_TRACE (define)``",    "0"
   "``PITON_ARIANE (define)``",     "0"
   "``WT_CACHE (define)``",         "1"
   "``DepthStoreBuffer``",          "4"
   "``IcacheSetAssoc``",            "4"
   "``DcacheSetAssoc``",            "4"
   "``NrLoadPipeRegs``",            "1"
   "``NrStorePipeRegs``",           "0"
   "``AxiCompliant``",              "1"
   "``SwapEndianess``",             "0"
   "``FetchUserEn``",               "0"
   "``FetchUserWidth``",            "32"
   "``DataUserEn``",                "0"
   "``DataUserWidth``",             "32"
   "``RenameEn``",                  "0"
   "``NrCommitPorts``",             "1"
   "``NrScoreboardEntries``",       "4"
   "``FpgaEn``",                    "0"
