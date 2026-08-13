PROJECT = reset-test
CPU     ?= cortex-m0plus

build:
	arm-none-eabi-as -mthumb -mcpu=$(CPU) --gdwarf-2 $(PROJECT).S -o $(PROJECT).o
	arm-none-eabi-ld -T link.ld $(PROJECT).o -o $(PROJECT).elf
	arm-none-eabi-objdump -D -S $(PROJECT).elf > $(PROJECT).elf.lst
	arm-none-eabi-readelf -a $(PROJECT).elf > $(PROJECT).elf.debug

flash: build
	openocd -f openocd.cfg -c "program $(PROJECT).elf verify reset exit"

clean:
	rm -rf *.out *.elf *.lst *.debug *.o