###############################################################################
#    $@ is the file being generated.
#    $< is first prerequisite.
#    $^ is all prerequisites.
#    $* is file_name (w/o extension) of target

DTB ?= cva6.dtb
LCS ?= linker.ld

# Tools yer gonna need
RISCV_EXE_PREFIX ?= riscv64-unknown-elf
RISCV_GCC        ?= $(RISCV_EXE_PREFIX)-gcc
RISCV_OBJCOPY    ?= $(RISCV_EXE_PREFIX)-objcopy
RISCV_READELF    ?= $(RISCV_EXE_PREFIX)-readelf
RISCV_OBJDUMP    ?= $(RISCV_EXE_PREFIX)-objdump
PYTHON           ?= python3
DTC              ?= dtc
DD               ?= dd

.PRECIOUS : %.elf

%.dtb: %.dts
	$(DTC) -I dts $< -O dtb -o $@

%.elf: %.S $(LCS) $(DTB)
	$(RISCV_GCC) -T$(LCS) -march=rv32i -mabi=ilp32 $< -nostdlib -static -Wl,--no-gc-sections -o $@

%.hex: %.elf
	$(RISCV_OBJCOPY) -O verilog $< $@

%.readelf: %.elf
	$(RISCV_READELF) -a $< > $@

%.objdump: %.elf
	$(RISCV_OBJDUMP) -D -S $< > $@

clean:
	rm -f $(bootrom_img) $(DTB) *.elf *.hex *.readelf *.objdump

###############################################################################
# Deprecated variables and targets

#bootrom_img    = bootrom.img bootrom.sv

#%.sv: %.img
#	$(PYTHON) ./gen_rom.py $<

#%.img: %.bin
#	$(DD) if=$< of=$@ bs=128

#%.bin: %.elf
#	$(RISCV_OBJCOPY) -O binary $< $@

