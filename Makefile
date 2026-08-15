PROJECT = reset-test
CPU     ?= cortex-m0plus

OPENOCD = C:/msys64/mingw64/bin/openocd.exe
OPENOCD_FLAGS = -f interface/stlink.cfg -f target/stm32g0x.cfg

build:
	arm-none-eabi-as -mthumb -mcpu=$(CPU) --gdwarf-2 $(PROJECT).S -o $(PROJECT).o
	arm-none-eabi-ld -T link.ld $(PROJECT).o -o $(PROJECT).elf
	arm-none-eabi-objdump -D -S $(PROJECT).elf > $(PROJECT).elf.lst
	arm-none-eabi-readelf -a $(PROJECT).elf > $(PROJECT).elf.debug

flash: build
	$(OPENOCD) $(OPENOCD_FLAGS) -c "program $(PROJECT).elf verify reset exit"

clean:
	rm -rf *.out *.elf *.lst *.debug *.o