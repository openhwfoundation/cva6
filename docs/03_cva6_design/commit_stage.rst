Commit Stage
=============

The commit stage is the last stage in the processor's pipeline. Its
purpose is to take incoming instruction and update the architectural
state. This includes writing CSR registers, committing stores and
writing back data to the register file. The golden rule is that no other
pipeline stage is allowed to update the architectural state under any
circumstances. If it keeps an internal state it must be re-settable
(e.g.: by a flush signal, see ).

We can distinguish two categories of retiring instructions. The first
category just write the architectural register file. The second might as
well write the register file but needs some further business logic to
happen. At the time of this writing the only two places where this is
necessary it the store unit where the commit stage needs to tell the
store unit to actually commit the store to memory and the CSR buffer
which needs to be freed as soon as the corresponding CSR instruction
retires.

In addition to retiring instructions the commit stage also manages the
various exception sources. In particular at time of commit exceptions
can arise from three different sources. First an exception has occurred
in any of the previous four pipeline stages (only four as PC Gen can't
throw an exception). Second an exception happened during commit. The only
source where during commit an exception can happen is from the CS
register file and from an interrupt.

To allow precise interrupts to happen they are considered during the
commit only and associated with this particular instruction. Because we
need a particular PC to associate the interrupt with it, it can be the
case that an interrupt needs to be deferred until another valid
instruction is in the commit stage.

Furthermore commit stage controls the overall stalling of the processor.
If the halt signal is asserted it will not commit any new instruction
which will generate back-pressure and eventually stall the pipeline.
Commit stage also communicates heavily with the controller to execute
fence instructions (cache flushes) and other pipeline re-sets.
