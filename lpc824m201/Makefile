
TARGET_MCU = lpc824m201
#TARGET_MCU = $(patsubst mecrisp-stellaris-%.bin,%,$(TARGET_BIN))
TARGET_BIN = mecrisp-stellaris-$(TARGET_MCU).bin


all: release

$(TARGET_BIN):
	make -C ../mecrisp-stellaris-source/$(TARGET_MCU)
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).bin .
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).hex .

release: $(TARGET_BIN)
	./buildcore ../thumbulator/thumbulator-lpc845m301 $< ../common/disassembler-m0.txt $(basename $<)-with-disassembler.bin
	python3 add_checksum.py $(basename $<)-with-disassembler.bin

clean:
	-make -C ../mecrisp-stellaris-source/$(TARGET_MCU) clean
	-rm *.bin
	-rm *.hex
