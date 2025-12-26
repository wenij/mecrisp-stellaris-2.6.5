
ARMGNU?=arm-none-eabi

COPS = -Wall  -Os -nostdlib -nostartfiles -ffreestanding -save-temps
AOPS = --warn --fatal-warnings

all : mecrisp-stellaris-lpc824m201.bin

mecrisp-stellaris-lpc824m201.o : mecrisp-stellaris-lpc824m201.s
	$(ARMGNU)-as mecrisp-stellaris-lpc824m201.s -o mecrisp-stellaris-lpc824m201.o

mecrisp-stellaris-lpc824m201.bin : memmap mecrisp-stellaris-lpc824m201.o
	$(ARMGNU)-ld -o mecrisp-stellaris-lpc824m201.elf -T memmap mecrisp-stellaris-lpc824m201.o
	$(ARMGNU)-objdump -D mecrisp-stellaris-lpc824m201.elf > mecrisp-stellaris-lpc824m201.list
	$(ARMGNU)-objcopy mecrisp-stellaris-lpc824m201.elf mecrisp-stellaris-lpc824m201.bin -O binary
	$(ARMGNU)-objcopy mecrisp-stellaris-lpc824m201.elf mecrisp-stellaris-lpc824m201.hex -O ihex
	python3 add_checksum.py $@
	
clean:
	rm -f *.bin
	rm -f *.o
	rm -f *.elf
	rm -f *.list
	rm -f *.hex
