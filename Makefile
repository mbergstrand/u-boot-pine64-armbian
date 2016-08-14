# This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# Simple Makefile to create Pine64 u-boot in Armbian build script compatible way
# Made by makefile noob, so no facepalms please

VERSION= 1
PATCHLEVEL= 0
SUBLEVEL= 0
EXTRAVERSION= -armbian

SHELL := bash

# pass ccache to submodules make
ccache := $(findstring ccache,$(CROSS_COMPILE))

DTS := $(wildcard blobs/*.dts)
DTB := $(patsubst blobs/%.dts, %.dtb, $(DTS))

.PHONY: all
all: make_image

.PHONY: u_boot_pine64
u_boot_pine64:
	$(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE="$(ccache) arm-linux-gnueabihf-" sun50iw1p1_config
	$(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE="$(ccache) arm-linux-gnueabihf-"

.PHONY: arm_trusted_firmware
arm_trusted_firmware:
	$(MAKE) -C arm-trusted-firmware PLAT=sun50iw1p1 DEBUG=1 bl31

boot0img: boot0img.o

%.dtb: blobs/%.dts
	dtc -I dts -O dtb -o $@ $<

.PHONY: make_image
make_image: u_boot_pine64 arm_trusted_firmware boot0img $(DTB)
	@dtc -I dts -O dtb -o dt.dtb dt.dts
	./boot0img -B blobs/boot0.bin -s blobs/scp.bin -d arm-trusted-firmware/build/sun50iw1p1/debug/bl31.bin -u u-boot-pine64/u-boot.bin -e -F dt.dtb -o u-boot-with-dtb.bin

.PHONY: clean
clean:
	[ -f u-boot-pine64/Makefile ] && $(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
	[ -f arm-trusted-firmware/Makefile ] && $(MAKE) -C arm-trusted-firmware PLAT=sun50iw1p1 distclean
	@rm -f u-boot-with-dtb.bin dt.dts dt.dtb $(DTB)

.PHONY: pine64_plus_defconfig
pine64_plus_defconfig:
	@cp blobs/pine64-plus.dts dt.dts

.PHONY: pine64_defconfig
pine64_defconfig:
	@cp blobs/pine64.dts dt.dts
