/* Places wb_word and wt_word of write_policy.S at fixed addresses, after the
   image given by the linker script of the target. */
SECTIONS
{
  .write_policy_wb 0x80100000 : { *(.write_policy_wb) }
  .write_policy_wt 0x80200000 : { *(.write_policy_wt) }
}
INSERT AFTER .bss;
