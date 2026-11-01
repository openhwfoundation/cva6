..
   Copyright (c) 2022 OpenHW Group

   Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   https://solderpad.org/licenses/

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

   This is the CVA6 documentation master file.

CVA6: An application class RISC-V CPU core
==========================================

The goal of the CVA6 project is create a family of production quality, open source, application class RISC-V CPU cores.
The CVA6 targets both ASIC and FPGA implementations, although individual cores may target a specific implementation technology.
The CVA6 is written in SystemVerilog and is heavily parameterizable.
For example parameters can set the ILEN to be either 32- or 64-bits and support for floating point can be enabled/disabled.

CORE-V Nomenclature
-------------------

**CORE-V** is the name of the OpenHW Group family of RISC-V cores.
CVA6 is the name of a GitHub repository for the source code for a set of application class CORE-V cores.
The CV prefix identifies it as a member of the CORE-V family and the A6 indicates that it is an application class processor with a six stage execution pipeline.
However, the CVA6 "as is" is not intended to implement a specific production core.
Rather, the CVA6 is expected to be the basis for a number of application class cores.
The naming convention for these cores is:

``CV <ILEN> <class> <# of pipeline stages> <product identifier>``

Thus, the CV64A60 would be a 64-bit application core with a six stage pipeline.
Note that in this example, the product identifier is "0".


Organization of this Document
-----------------------------

This documentation is split into multiple parts.

The :doc:`CVA6 User Guide <01_cva6_user/index>` provides a detailed introduction to the CVA6.
This document is based on the original Ariane documentation and is aimed at hardware developers integrating CVA6 into a design.

The :doc:`CVA6 Requirements Specification <02_cva6_requirements/cva6_requirements_specification>` is the top-level specification of the CVA6.
One of the key attributes of this document is to specify the feature set of specific CORE-V products based on CVA6.
This document focuses on _what_ the CVA6 does, without detailed consideration of _how_ a specific requirement is implemented.
The target audience of this document is current and existing members of the OpenHW Group who wish to participate in the definition of future cores based on the CVA6.

The :doc:`CVA6 Design Document <03_cva6_design/index>` describes in detail the **CVA6**, the code base that can be used to compile/synthesize a specific core instance (e.g. cv32a65x).

The :doc:`CV32A65X Design Document <04_cv32a65x/design/design>` describes in detail the **CV32A65X**, a specific core based on the CVA6 and the first production quality 32-bit application processor derived from the CVA6.
The primary audience for this documentation are design and verification engineers working to bring the CV32A65X to TRL-5.

The :doc:`CVA6 APU <05_cva6_apu/index>` describes an Application Processor Unit built around the CVA6.

.. toctree::
   :maxdepth: 2
   :hidden:

   02_cva6_requirements/cva6_requirements_specification.rst
   01_cva6_user/index.rst
   03_cva6_design/index.rst
   04_cv32a65x/index.rst
   07_cv32a60x/index.rst
   06_cv64a6_mmu/index.rst
   05_cva6_apu/index.rst
