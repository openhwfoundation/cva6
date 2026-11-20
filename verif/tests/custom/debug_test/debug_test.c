/*
**
** Copyright 2020 OpenHW Group
**
** Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     https://solderpad.org/licenses/
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
**
*******************************************************************************
** Basic debugger test. Needs more work and bugs fixed
** It will launch a debug request and have debugger code execute (debugger.S)
*******************************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "corev_uvmt.h"

volatile int glb_hart_status  = 0; // Written by main code only, read by debug code
volatile int glb_debug_status = 0; // Written by debug code only, read by main code
volatile int glb_ebreak_status = 0; // Written by ebreak code only, read by main code
volatile int glb_illegal_insn_status = 0; // Written by illegal instruction code only, read by main code
volatile int glb_debug_exception_status = 0; // Written by debug code during exception only
volatile int glb_exception_ebreak_status = 0; // Written by main code, read by exception handler

volatile int glb_previous_dpc = 0; // holds last dpc, used for checking correctness of stepping
volatile int glb_step_info = 0; // info to dbg code about actions to take on stepping
volatile int glb_step_count = 0; //  Written by debug code for each time single step is entered
// Expectation flags. Raise an error if handler or routine is enterred when not expected,
volatile int glb_expect_illegal_insn    = 0;
volatile int glb_expect_ebreak_handler  = 0;
volatile int glb_expect_debug_entry     = 0;
volatile int glb_expect_debug_exception = 0;
volatile int glb_expect_irq_entry = 0;
volatile int glb_irq_timeout = 0;
// Counter values
// Checked at start and end of debug code
// Only lower 32 bits checked, as simulation cannot overflow on 32 bits
volatile int glb_mcycle_start = 0;
volatile int glb_mcycle_end = 0;
volatile int glb_minstret_start = 0;
volatile int glb_minstret_end = 0;
#define TEST_FAILED  *(volatile int *)CV_VP_STATUS_FLAGS_BASE = 1
#define TEST_PASSED  *(volatile int *)CV_VP_STATUS_FLAGS_BASE = 123456789

extern int __stack_start;
typedef union {
  struct {
    unsigned int start_delay      : 15; // 14: 0
    unsigned int rand_start_delay : 1;  //    15
    unsigned int pulse_width      : 13; // 28:16
    unsigned int rand_pulse_width : 1;  //    29
    unsigned int pulse_mode       : 1;  //    30    0 = level, 1 = pulse
    unsigned int value            : 1;  //    31
  } fields;
  unsigned int bits;
}  debug_req_control_t;

#define DEBUG_REQ_CONTROL_REG *((volatile uint32_t *) (CV_VP_DEBUG_CONTROL_BASE))
#define TIMER_REG_ADDR         ((volatile uint32_t *) (CV_VP_INTR_TIMER_BASE+0))
#define TIMER_VAL_ADDR         ((volatile uint32_t *) (CV_VP_INTR_TIMER_BASE+4))

typedef union {
  struct {
    unsigned int uie   : 1;  //     0 // Implemented if USER mode enabled
    unsigned int sie   : 1;  //     1
    unsigned int wpri  : 1;  //     2
    unsigned int mie   : 1;  //     3 // Implemented
    unsigned int upie  : 1;  //     4 // Implemented if USER mode enabled
    unsigned int spie  : 1;  //     5
    unsigned int wpri0 : 1;  //     6
    unsigned int mpie  : 1;  //     7 // Implemented
    unsigned int spp   : 1;  //     8
    unsigned int wpri1 : 2;  // 10: 9
    unsigned int mpp   : 2;  // 12:11 // Implemented
    unsigned int fs    : 2;  // 14:13
    unsigned int xs    : 2;  // 16:15
    unsigned int mprv  : 1;  //    17
    unsigned int sum   : 1;  //    18
    unsigned int mxr   : 1;  //    19
    unsigned int tvm   : 1;  //    20
    unsigned int tw    : 1;  //    21
    unsigned int tsr   : 1;  //    22
    unsigned int wpri3 : 8;  // 30:23
    unsigned int sd    : 1;  //    31
  } fields;
  unsigned int bits;
}  mstatus_t;

extern void _single_step(int d);
// Tag is simply to help debug and determine where the failure came from
void check_debug_status(int tag, int value)
{
  if(glb_debug_status != value){
    printf("ERROR: check_debug_status(%d, %d): Tag=%d status=%d, exp=%d \n\n",
           tag, value, tag, glb_debug_status, value);
    TEST_FAILED;
  }
}
void check_debug_exception_status(int tag, int value)
{
  if(glb_debug_exception_status != value){
    printf("ERROR: check_debug_exception_status(%d, %d): Tag=%d status=%d, exp=%d \n\n",
           tag, value, tag, glb_debug_exception_status, value);
    TEST_FAILED;
  }
}
void check_hart_status(int tag, int value)
{
  if(glb_hart_status != value){
    printf("ERROR: check_hart_status(%d, %d): Tag=%d status=%d, exp=%d \n\n",
           tag, value, tag, glb_hart_status, value);
    TEST_FAILED;
  }
}
void check_ebreak_status(int tag, int value)
{
  if(glb_ebreak_status != value){
    printf("ERROR: check_ebreak_status(%d, %d): Tag=%d status=%d, exp=%d \n\n",
           tag, value, tag, glb_ebreak_status, value);
    TEST_FAILED;
  }
}
void check_illegal_insn_status(int tag, int value)
{
  if(glb_illegal_insn_status != value){
    printf("ERROR: check_illegal_insn_status(%d, %d): Tag=%d status=%d, exp=%d \n\n",
           tag, value, tag, glb_illegal_insn_status, value);
    TEST_FAILED;
  }
}
void delay(int count) {
    for (volatile int d = 0; d < count; d++);
}

void mstatus_mie_enable() {
    int mie_bit = 0x1 << 3;
    asm volatile("csrrs x0, mstatus, %0" : : "r" (mie_bit));
}

void mstatus_mie_disable() {
    int mie_bit = 0x1 << 3;
    asm volatile("csrrc x0, mstatus, %0" : : "r" (mie_bit));
}

void mie_enable_all() {
    uint32_t mie_mask = (uint32_t) -1;
    asm volatile("csrrs x0, mie, %0" : : "r" (mie_mask));
}

void mie_disable_all() {
    uint32_t mie_mask = (uint32_t) -1;
    asm volatile("csrrc x0, mie, %0" : : "r" (mie_mask));
}

void mie_enable(uint32_t irq) {
    // Enable the interrupt irq in MIE
    uint32_t mie_bit = 0x1 << irq;
    asm volatile("csrrs x0, mie, %0" : : "r" (mie_bit));
}

void mie_disable(uint32_t irq) {
    // Disable the interrupt irq in MIE
    uint32_t mie_bit = 0x1 << irq;
    asm volatile("csrrc x0, mie, %0" : : "r" (mie_bit));
}

void mm_ram_assert_irq(uint32_t mask, uint32_t cycle_delay) {
    *TIMER_REG_ADDR = mask;
    *TIMER_VAL_ADDR = 1 + cycle_delay;
}

void counters_enable() {
    // Enable counters mcycle (bit0) and minstret (bit2)
    uint32_t mask = 1<<2 | 1<<0;
    asm volatile("csrrc x0, 0x320, %0" : : "r" (mask));
}
#define MACHINE 3
int main(int argc, char *argv[])
{
    unsigned int temp,temp1,temp2;
    debug_req_control_t debug_req_control;
    mstatus_t mstatus, mstatus_cmp;
    counters_enable();
    printf("\nBasic test checking debug functionality.\n");

    printf("------------------------\n");
    printf(" Test1: check initialization values\n");
    //check_debug_status(0,0);

    temp1 = 0xFFFFFFFF;
    /* get relevant CSRs and compare init values*/
    __asm__ volatile("csrr %0, mstatus" : "=r"(temp1));
    __asm__ volatile("csrw mstatus, %0 " : "=r"(temp1));
    __asm__ volatile("csrr %0, mstatus" : "=r"(mstatus.bits));
    __asm__ volatile("csrr %0, mie" : "=r"(temp));
    __asm__ volatile("csrw mie, %0 " : "=r"(temp1));
    __asm__ volatile("csrr %0, mie" : "=r"(temp2));
    printf("\tmstats_rval = 0x%0x 0x%0x 0x%0x 0x%0x\n",temp2,mstatus.bits,temp,temp1);

    check_debug_status(0,0);
    printf("------------------------\n");
    printf(" Test2.1: check access to Debug and Trigger registers\n");
    // debug specification 13.2: 4.8 Core Debug Registers are not accessable unless in debug mode

    // ----------------------
    // Check Debug Write Access
    temp = 0xFFFFFFFF;
    temp1 = glb_illegal_insn_status+1;
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrw  dcsr, %0"     : "=r"(temp)); // Debug DCSR
    check_illegal_insn_status(11,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrw  dpc, %0"      : "=r"(temp)); // Debug DPC
    check_illegal_insn_status(12,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrw  dscratch, %0" : "=r"(temp)); // Debug DSCRATCH0
    check_illegal_insn_status(13,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrw  0x7b3, %0" : "=r"(temp));    // Debug DSCRATCH1
    check_illegal_insn_status(14,temp1++);

    // Check Read Access
    temp1 = glb_illegal_insn_status+1;
    // Allow illegal instruction handler to run
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrr %0, dcsr"    : "=r"(temp)); // Debug DCSR
    check_illegal_insn_status(1,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrr %0, dpc"     : "=r"(temp)); // Debug DPC
    check_illegal_insn_status(2,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrr %0, dscratch": "=r"(temp)); // Debug DSCRATCH0
    check_illegal_insn_status(3,temp1++);
    glb_expect_illegal_insn = 1;
    __asm__ volatile("csrr %0, 0x7b3"   : "=r"(temp)); // Debug DSCRATCH1
    check_illegal_insn_status(4,temp1++);

    printf("------------------------\n");
    printf(" Test2.2: check access to Trigger registers\n");

    // NOTE: As of July 2024, CVA6 does not implement the trigger module.
    // TODO: Consider adding trigger module support in future revisions.

    // Writes are ignored
    temp = 0xFFFFFFFF;    //TODO:MT should these be writes?
    __asm__ volatile("csrw  0x7a0, %0"     : "=r"(temp)); // Trigger TSELECT
    __asm__ volatile("csrw  0x7a1, %0"     : "=r"(temp)); // Trigger TDATA1
    __asm__ volatile("csrw  0x7a2, %0"     : "=r"(temp)); // Trigger TDATA2
    __asm__ volatile("csrw  0x7a3, %0"     : "=r"(temp)); // Trigger TDATA3
    __asm__ volatile("csrw  0x7a4, %0"     : "=r"(temp)); // Trigger TINFO

    // Read default value
    __asm__ volatile("csrr %0, 0x7a0"   : "=r"(temp)); // Trigger TSELECT
    // CVA6 if(temp != 0x0){printf("ERROR: TSELET Read\n");TEST_FAILED;}

    __asm__ volatile("csrr %0, 0x7a1"   : "=r"(temp)); // Trigger TDATA1
    // CVA6 //   31:28 type      = 2
    // CVA6 //      27 dmode     = 1
    // CVA6 //   15:12 action    = 1
    // CVA6 //      6  m(achine) = 1
    // CVA6 if(temp !=  (2<<28 | 1<<27 | 1<<12 | 1<<6)){printf("ERROR: TDATA1 Read\n");TEST_FAILED;}

    __asm__ volatile("csrr %0, 0x7a2"   : "=r"(temp)); // Trigger TDATA2
    // CVA6 if(temp != 0x0){printf("ERROR: TDATA2 Read\n");TEST_FAILED;}

    __asm__ volatile("csrr %0, 0x7a3"   : "=r"(temp)); // Trigger TDATA3
    // CVA6 if(temp != 0x0){printf("ERROR: TDATA3 Read\n");TEST_FAILED;}

    __asm__ volatile("csrr %0, 0x7a4"   : "=r"(temp)); // Trigger TINFO
    // CVA6 // tmatch = 1<<2
    // CVA6 if(temp != 1<<2){printf("ERROR: TINFO Read %d \n",temp);TEST_FAILED;}


   // Do not expect or allow any more illegal instructions


    mstatus_cmp = (mstatus_t) {
    .fields.mpp   = MACHINE  //
    };
    if(mstatus_cmp.bits != mstatus.bits) {printf("ERROR: init mstatus mismatch exp=%x val=%x\n",
                                           mstatus_cmp.bits, mstatus.bits); TEST_FAILED;}
    //TODO:MT are these switched up?
    printf("------------------------\n");
    printf(" Test3.1: check hart ebreak executes ebreak handler but does not execute debugger code\n");
    glb_expect_ebreak_handler = 1;
    asm volatile("c.ebreak");
    check_ebreak_status(32,1);

    printf("------------------------\n");
    printf(" Test3.2: check hart c.ebreak executes ebreak handler but does not execute debugger code\n");
    glb_expect_ebreak_handler = 1;
    asm volatile(".4byte 0x00100073");
    check_ebreak_status(32,2);

    printf("------------------------\n");
    printf(" Test4: request hardware debugger\n");

    debug_req_control = (debug_req_control_t) {
      .fields.value            = 1,
      .fields.pulse_mode       = 1, //PULSE Mode
      .fields.rand_pulse_width = 0,
      .fields.pulse_width      = 5,// TODO:MT determine pulse width with non-sticky debug_req
      .fields.rand_start_delay = 0,
      .fields.start_delay      = 200
    };
    glb_expect_debug_entry = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;

    glb_hart_status = 4; // Basic test
    while(glb_debug_status != glb_hart_status){
      printf("Wait for Debugger\n");
    }
    check_debug_status(41,glb_hart_status);

    printf("------------------------\n");
    printf(" Test5: have debugger execute ebreak 3 more times\n");

    glb_hart_status = 5;
    glb_expect_debug_entry = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    while(glb_debug_status != (5+3)){
      printf("Wait for Debugger\n");
    }
    check_debug_status(51,(5+3));

    printf("------------------------\n");
    printf(" Test6: Test CSR access and default values in debug mode\n");
    glb_hart_status = 6;
    glb_expect_debug_entry = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    while(glb_debug_status != glb_hart_status){
      printf("Wait for Debugger\n");
    }
    check_debug_status(61,glb_hart_status);


    printf("------------------------\n");
    printf(" Test10: check hart ebreak executes debugger code\n");
    glb_hart_status = 10;
    glb_expect_debug_entry = 1;
    asm volatile(".4byte 0x00100073");
    check_debug_status(33,glb_hart_status);

    printf("------------------------\n");
    printf(" Test11: check illegal csr exception during debug launches debugger exception and no csr modified\n");
    glb_hart_status = 11;
    glb_expect_debug_entry = 1;
    glb_expect_debug_exception = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    while(glb_debug_status != glb_hart_status){
      printf("Wait for Debugger\n");
    }
    check_debug_status(111,glb_hart_status);
    check_debug_exception_status(111,glb_hart_status);
    //FIXME TBD BUG : need to update test to check actual csrs not modified.

    printf("------------------------\n");
    printf(" Test12: check ecall exception during debug launches debugger exception and no csr modified\n");
    glb_hart_status = 12;
    glb_expect_debug_entry = 1;
    glb_expect_debug_exception = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    while(glb_debug_status != glb_hart_status){
      printf("Wait for Debugger\n");
    }
    check_debug_status(112,glb_hart_status);
    check_debug_exception_status(112,glb_hart_status);
    //FIXME TBD BUG : need to update test to check actual csrs not modified.

    printf("------------------------\n");
    printf(" Test13: check mret during debug launches debugger exception and no csr modified\n");
    glb_hart_status = 13;
    glb_expect_debug_entry = 1;
    glb_expect_debug_exception = 1;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    while(glb_debug_status != glb_hart_status){
      printf("Wait for Debugger\n");
    }
    check_debug_status(113,glb_hart_status);
    check_debug_exception_status(113,glb_hart_status);

    printf("------------------------\n");
    printf(" Test14: Check exception ebreak enters debug mode\n");
    glb_hart_status = 14;
    glb_expect_illegal_insn = 1;
    glb_exception_ebreak_status = 1;
    glb_expect_debug_entry = 1;

    // DCSR read will cause illegal instruction.
    // Exception routine reads glb_exception_ebreak_status=1 and executes c.ebreak
    __asm__ volatile("csrr %0, dcsr"    : "=r"(temp)); // Debug DCSR

    while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }

    check_illegal_insn_status(114,temp1++);
    check_debug_status(114, glb_hart_status);
    printf("----------------------\n");
    printf("Test 16: dret in m-mode causes exception\n");

    glb_expect_illegal_insn = 1;
    __asm__ volatile("dret");
    check_illegal_insn_status(16, temp1++);

    printf("------------------------\n");
    printf("Test 17: WFI before debug_req_i and WFI in debug mode\n");
    printf("If test hangs, WFI is NOT converted to NOP\n");

    glb_expect_debug_entry = 1;
    glb_hart_status = 17;
    // start_delay is set to 200, should get the wfi executing before dbg request is asserted
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;

    // Execute WFI, when debug is asserted, it will act as NOP and enter debug mode
    // If not, test will hang
    __asm__ volatile("wfi");
    check_debug_status(117, glb_hart_status);

    printf("----------------------\n");
    printf("Checking interrupt, as this is needed by later tests\n");

    // Assert and check irq, as this is needed by some tests.
    mstatus_mie_enable();
    mie_enable(30);
    glb_expect_irq_entry = 1;
    mm_ram_assert_irq(0x40000000, 1);
    while(glb_expect_irq_entry == 1);
    mm_ram_assert_irq(0,0);
    printf("Irq check done\n");

    // Check that stoupcount bit (10) in dcsr has no affect
    printf("-------------------------\n");
    printf("Test 21: Setting stopcount bit=1\n");
    glb_expect_debug_entry = 1;
    glb_hart_status = 21;

    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
     while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }
    check_debug_status(121, glb_hart_status);


    printf("------------------------\n");
    printf("Test 18: Single stepping\n");
    glb_hart_status = 18;

    // Run single step code (in single_step.S)
    _single_step(0);

    // Single step code should generate 2 illegal insn
    temp1++;
    check_illegal_insn_status(118, temp1++);
    check_debug_status(118, glb_hart_status);

    printf("Stepped %d times\n", glb_step_count);


    printf("------------------------\n");
    printf("Test 19: irq in debug\n");
    glb_hart_status = 19;
    glb_expect_debug_entry = 1;

    // Does not expect irq to be taken while in debug mode
    // but it will be taken when we exit from debug.
    // Timeout added in debug code to check for taken irq or not
    glb_expect_irq_entry = 1;
    DEBUG_REQ_CONTROL_REG=debug_req_control.bits;

    while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }

    check_debug_status(119, glb_hart_status);
    if(glb_irq_timeout != 0) {
        printf("glb_irq_timeout != 0, interrupt taken in debug.\n");
        TEST_FAILED;
    }

    // Test debug req vs irq timing
    printf("-----------------------\n");
    printf("Test 20: Asserting debug_req and irq at the same cycle\n");
    glb_expect_debug_entry = 1;
    glb_expect_irq_entry = 1;
    glb_hart_status = 20;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;
    // 170 halts on first instruction in interrupt handler
    // 175 gives same timing for interrupt and debug_req_i
    mm_ram_assert_irq(0x40000000, 175+20);

    while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }
    check_debug_status(120, glb_hart_status);


    // Execute fence instruction in debug
    printf("-----------------------------\n");
    printf("Test 22: Execute fence in debug mode\n");
    glb_expect_debug_entry = 1;
    glb_hart_status = 22;
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;

    while(glb_debug_status != glb_hart_status) {
        printf("Wait for debugger\n");
    }

    check_debug_status(121, glb_hart_status);

    printf("------------------------\n");
    printf("Test 23: trigger match in debug mode with match disabled\n");
    glb_hart_status = 23;
    glb_expect_debug_entry = 1;

    // Request debug
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;

    while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }

    check_debug_status(123, glb_hart_status);
    printf("------------------------\n");
    printf("Test 24: trigger register access in D-mode\n");
    glb_hart_status = 24;
    glb_expect_debug_entry = 1;

    // Request debug
    DEBUG_REQ_CONTROL_REG = debug_req_control.bits;

    while(glb_debug_status != glb_hart_status){
        printf("Wait for Debugger\n");
    }

    check_debug_status(124, glb_hart_status);

    //--------------------------------
    //return EXIT_FAILURE;
    printf("------------------------\n");
    printf("Finished \n");
    return EXIT_SUCCESS;
}
