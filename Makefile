# This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# Simple Makefile to create Pine64 u-boot in Armbian build script compatible way
# Made by makefile noob, so no facepalms please

VERSION= 1
PATCHLEVEL= 0
SUBLEVEL= 0
EXTRAVERSION= -armbian

SHELL := bash

.PHONY : all
all: make_image

.PHONY: u_boot
u_boot:
	$(MAKE) -C u-boot pine64_plus_defconfig
	$(MAKE) -C u-boot

.PHONY: arm_trusted_firmware
arm_trusted_firmware:
	$(MAKE) -C arm-trusted-firmware PLAT=sun50iw1p1 DEBUG=1 bl31

boot0img: boot0img.o

.PHONY: make_image
make_image: u_boot arm_trusted_firmware boot0img
	./boot0img -B blobs/boot0.bin -s arm-trusted-firmware/build/sun50iw1p1/debug/bl31.bin -a 0x44008 -d trampoline64:0x44000 -u u-boot/u-boot.bin -e -o u-boot-with-spl.bin

.PHONY: clean
clean:
	[ -f u-boot/Makefile ] && $(MAKE) -C u-boot clean
	[ -f arm-trusted-firmware/Makefile ] && $(MAKE) -C arm-trusted-firmware PLAT=sun50iw1p1 distclean
	@rm -f boot0img *.o u-boot-with-spl.bin arm-trusted-firmware/build/sun50iw1p1/debug/bl31.bin

.PHONY: pine64_plus_defconfig
pine64_plus_defconfig: ;

.PHONY: pine64_defconfig
pine64_defconfig: ;
