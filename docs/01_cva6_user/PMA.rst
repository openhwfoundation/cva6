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

.. _cva6_pma:

*This chapter is applicable to all configurations.*

PMA
===

An underlying system can have multiple physical memory attributes (PMA). CVA6
supports three main access properties:

- Non-idempotent regions (I/O regions): By the vary nature of a pipelined CPU
  architecture, the CPU will speculatively fetch (because of branch-prediction)
  and speculatively load (because of speculative execution). This can be
  problematic if reads to such a region are non-idempotent (i.e., they destroy
  state). As such, regions marked as non-idempotent will not be queried
  speculatively. Typical registers of that kind would be the UART or an
  interrupt claim register.
- Executable regions (Main memory): Regions marked as executable will be
  considered as code regions. This will allow the core to fetch instructions
  from that region.
- Cacheable regions (Main memory): Regions marked as cacheable will be
  considered as data and instruction regions. This will allow the core to fetch,
  load, and store data from that region.
- Bufferable regions: the bufferable attribute of the memory interface (OBI
  ``memtype[0]``, AXI ``AxCACHE[0]``). With the cacheable attribute, it gives
  the memory type of an access:

  ========= ========== ===================================================
  cacheable bufferable memory type
  ========= ========== ===================================================
  no        no         non-cacheable, writes acknowledged by their destination
  no        yes        non-cacheable, writes may be acknowledged before
                       they reach their destination
  yes       no         write-through
  yes       yes        write-back
  ========= ========== ===================================================

  A data cache with both write policies (``CacheWritePolicy`` =
  ``CACHE_WT_WB``) writes back in the cacheable bufferable regions and writes
  through in the other cacheable regions. A data cache that only writes back
  (``CACHE_WB``) requires every cacheable region to be bufferable; a data cache
  that only writes through (``CACHE_WT``) writes through in every cacheable
  region and reports the attribute of the region on the memory interface.

The regions are instantiation-time parameters, they can not be changed during
runtime. CVA6 uses the following fields in the ``cva6_cfg_t`` configuration
structure to describe the PMA regions statically:

- ``CVA6Cfg.NrNonIdempotentRules``: Number of active non-idempotent regions.
   - ``CVA6Cfg.NonIdempotentAddrBase``: Base address of the non-idempotent region.
   - ``CVA6Cfg.NonIdempotentLength``: Length of the non-idempotent region.
- ``CVA6Cfg.NrExecuteRegionRules``: Number of active executable regions.
   - ``CVA6Cfg.ExecuteRegionAddrBase``: Base address of the executable region.
   - ``CVA6Cfg.ExecuteRegionLength``: Length of the executable region.
- ``CVA6Cfg.NrCachedRegionRules``: Number of active cacheable regions.
   - ``CVA6Cfg.CachedRegionAddrBase``: Base address of the cacheable region.
   - ``CVA6Cfg.CachedRegionLength``: Length of the cacheable region.
- ``CVA6Cfg.NrBufferableRegionRules``: Number of active bufferable regions.
   - ``CVA6Cfg.BufferableRegionAddrBase``: Base address of the bufferable region.
   - ``CVA6Cfg.BufferableRegionLength``: Length of the bufferable region.

Unsupported PMAs
----------------

Currently the following RISC-V defined PMAs are not supported:

- Coherence: Stand-alone CVA6 does not support any coherence protocol. All memory accesses
  are considered as non-coherent. For coherent systems, such as OpenPiton, it is
  up to the system to define coherence attributes exactly. Most likely this will
  mean any cacheable region is also coherent.
- Atomicity: Atomicity is delegated to the underlying system. It is up the
  target to decide whether atomicity is supported or not.
- Reservability: Reservability is delegated to the underlying system. It is up the
  target to decide whether atomicity is supported or not.
- Vacant Regions: It is up to the underlying system to decide whether a region
  is vacant or not. CVA6 will not check for vacant regions. An AXI Decode Error
  or Slave Error is expected on vacant regions.
