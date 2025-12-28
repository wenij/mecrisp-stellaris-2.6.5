
TARGET_MCU = lpc824m201
#TARGET_MCU = $(patsubst mecrisp-stellaris-%.bin,%,$(TARGET_BIN))
TARGET_BIN = mecrisp-stellaris-$(TARGET_MCU).bin
ADD_ON_FS = ../common/disassembler-m0.txt dump.txt delay.txt

all: release

$(TARGET_BIN):
	make -C ../mecrisp-stellaris-source/$(TARGET_MCU)
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).bin .
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).hex .

release: $(TARGET_BIN)
	cat $(ADD_ON_FS)  > include.txt
	./buildcore ../thumbulator/thumbulator-lpc845m301 $< include.txt $(basename $<)-with-disassembler.bin
	python3 add_checksum.py $(basename $<)-with-disassembler.bin

clean:
	-make -C ../mecrisp-stellaris-source/$(TARGET_MCU) clean
	-rm *.bin
	-rm *.hex
	-rm include.txt
