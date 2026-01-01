
TARGET_MCU = lpc824m201
#TARGET_MCU = $(patsubst mecrisp-stellaris-%.bin,%,$(TARGET_BIN))
TARGET_BIN = mecrisp-stellaris-$(TARGET_MCU).bin
PROG_TOOL = lpc21isp/lpc21isp
ADD_ON_FS = ../common/disassembler-m0.txt 
#ADD_ON_FS += ../common/assembler-m0.txt 
ADD_ON_FS += ../common/ansification.txt
ADD_ON_FS += dump.txt delay.txt
#ADD_ON_FS += lcd-sh1106-demo.txt

all: release

$(TARGET_BIN):
	make -C ../mecrisp-stellaris-source/$(TARGET_MCU)
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).bin .
	cp ../mecrisp-stellaris-source/$(TARGET_MCU)/$(basename $@).hex .

release: $(TARGET_BIN) mecrisp-stellaris-$(TARGET_MCU)-with-disassembler.bin
	python3 add_checksum.py $(basename $<)-with-disassembler.bin

mecrisp-stellaris-$(TARGET_MCU)-with-disassembler.bin: $(TARGET_BIN) ../thumbulator/thumbulator-lpc845m301
	cat $(ADD_ON_FS)  > include.txt
	./buildcore ../thumbulator/thumbulator-lpc845m301 $< include.txt $(basename $<)-with-disassembler.bin

$(PROG_TOOL): 
	make -C lpc21isp
	
# using make prog uart=/dev/ttyUSB0 , to prgoram fw.bin through /dev/ttyUSB0
## note, lpc21isp will fixed the checksum for you. no need to use xxx-with-disassembler-checksum.bin
prog: mecrisp-stellaris-$(TARGET_MCU)-with-disassembler.bin $(PROG_TOOL)
	$(if $(uart),,$(error error: uart device not defined! please use 'make prog uart=/dev/ttyUSBx'))
	$(PROG_TOOL) -wipe -bin $< $(uart) 115200 12000

clean:
	-make -C ../mecrisp-stellaris-source/$(TARGET_MCU) clean
	-make -C lpc21isp clean
	-rm *.bin
	-rm *.hex
	-rm include.txt
