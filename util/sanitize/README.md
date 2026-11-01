<!--
 Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory

 SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1

 Authors       : Vincent Verdillon
 Creation Date : June, 2026
 Description   : Sanitize Makefile
 History       :
-->

# Conform

This directory provides multiple scripts to apply format and sanitize rules on this project.
You can execute all sanitize rules by executing `make`.
Or execute separately with `make verilog`, `make xlen`.

- `make verilog` apply RTL format rule from the contributing doc.
- `make xlen` search for use of CVA6Cfg's XLEN attribute in arithmetical operations and IS_XLEN
  attribute in logical operations.
