// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 17.06.2017
// Description: Instruction tracer single exception item

`ifndef VERILATOR
class ex_trace_item #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
);

    // Interrupt cause encodings, built here rather than taken as parameters:
    // see the note in core/decoder.sv.
    typedef struct packed {
      logic [CVA6Cfg.XLEN-1:0] S_SW;
      logic [CVA6Cfg.XLEN-1:0] VS_SW;
      logic [CVA6Cfg.XLEN-1:0] M_SW;
      logic [CVA6Cfg.XLEN-1:0] S_TIMER;
      logic [CVA6Cfg.XLEN-1:0] VS_TIMER;
      logic [CVA6Cfg.XLEN-1:0] M_TIMER;
      logic [CVA6Cfg.XLEN-1:0] S_EXT;
      logic [CVA6Cfg.XLEN-1:0] VS_EXT;
      logic [CVA6Cfg.XLEN-1:0] M_EXT;
      logic [CVA6Cfg.XLEN-1:0] HS_EXT;
    } interrupts_t;

    localparam interrupts_t INTERRUPTS = '{
        S_SW: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_S_SOFT),
        VS_SW: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_VS_SOFT),
        M_SW: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_M_SOFT),
        S_TIMER: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_S_TIMER),
        VS_TIMER: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_VS_TIMER),
        M_TIMER: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_M_TIMER),
        S_EXT: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_S_EXT),
        VS_EXT: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_VS_EXT),
        M_EXT: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_M_EXT),
        HS_EXT: (CVA6Cfg.XLEN'(1) << (CVA6Cfg.XLEN - 1)) | CVA6Cfg.XLEN'(riscv::IRQ_HS_EXT)
    };

    // contains a human readable form of the cause value
    string                  cause_s;
    logic [63:0]            cause;
    logic [63:0]            tval;
    logic [CVA6Cfg.VLEN-1:0] pc;

    function new (logic [CVA6Cfg.VLEN-1:0] pc, logic [63:0] cause, logic [63:0] tval);

        this.cause = cause;

        case (cause)
            riscv::INSTR_ADDR_MISALIGNED: this.cause_s = "Instruction Address Misaligned";
            riscv::INSTR_ACCESS_FAULT:    this.cause_s = "Instruction Access Fault";
            riscv::ILLEGAL_INSTR:         this.cause_s = "Illegal Instruction";
            riscv::BREAKPOINT:            this.cause_s = "Breakpoint";
            riscv::LD_ADDR_MISALIGNED:    this.cause_s = "Load Address Misaligned";
            riscv::LD_ACCESS_FAULT:       this.cause_s = "Load Access Fault";
            riscv::ST_ADDR_MISALIGNED:    this.cause_s = "Store Address Misaligned";
            riscv::ST_ACCESS_FAULT:       this.cause_s = "Store Access Fault";
            riscv::ENV_CALL_UMODE:        this.cause_s = "Environment Call User Mode";
            riscv::ENV_CALL_SMODE:        this.cause_s = "Environment Call Supervisor Mode";
            riscv::ENV_CALL_MMODE:        this.cause_s = "Environment Call Machine Mode";
            riscv::INSTR_PAGE_FAULT:      this.cause_s = "Instruction Page Fault";
            riscv::LOAD_PAGE_FAULT:       this.cause_s = "Load Page Fault";
            riscv::STORE_PAGE_FAULT:      this.cause_s = "Store Page Fault";
            riscv::HARDWARE_ERROR:        this.cause_s = "Hardware Error";
            INTERRUPTS.S_SW:              this.cause_s = "Supervisor Software Interrupt";
            INTERRUPTS.M_SW:              this.cause_s = "Machine Software Interrupt";
            INTERRUPTS.S_TIMER:           this.cause_s = "Supervisor Timer Interrupt";
            INTERRUPTS.M_TIMER:           this.cause_s = "Machine Timer Interrupt";
            INTERRUPTS.S_EXT:             this.cause_s = "Supervisor External Interrupt";
            INTERRUPTS.M_EXT:             this.cause_s = "Machine External Interrupt";
            riscv::DEBUG_REQUEST:         this.cause_s = "Request Debug Mode";
            default: this.cause_s = "Interrupt";
        endcase

        this.tval = tval;
        this.pc = pc;
    endfunction : new

    function string printException();
        string s;
        s = $sformatf("Exception @%10t, PC: %h, Cause: %s", $time, this.pc, this.cause_s);
        // write out tval if it wasn't an environment call or interrupt, in that case the tval field has no meaning
        if (!(this.cause inside {
                riscv::ENV_CALL_MMODE,
                riscv::ENV_CALL_SMODE,
                riscv::ENV_CALL_UMODE,
                INTERRUPTS.S_SW,
                INTERRUPTS.M_SW,
                INTERRUPTS.S_TIMER,
                INTERRUPTS.M_TIMER,
                INTERRUPTS.S_EXT,
                INTERRUPTS.M_EXT
            }))
            s = $sformatf("%s, \n\t\t\t\ttval: %h", s, this.tval);
        return s;
    endfunction

endclass : ex_trace_item
`endif
