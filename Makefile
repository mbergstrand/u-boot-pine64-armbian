# This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# Simple Makefile to create Pine64 u-boot in Armbian biuld script compatible way
# Made by makefile noob, so no facepalms please

SHELL := bash

# pass ccache to submodules make
ccache := $(findstring ccache,$(CROSS_COMPILE))

.PHONY: all
all: submodules u_boot_pine64 arm_trusted_firmware sunxi_pack_tools make_image

.PHONY: submodules
.NOTPARALLEL: submodules
submodules:
	@git submodule update --init -f

.PHONY: u_boot_pine64
u_boot_pine64:
	$(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE="$(ccache) arm-linux-gnueabihf-" sun50iw1p1_config
	$(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE="$(ccache) arm-linux-gnueabihf-"

#.PHONY: u_boot_mainline
#u_boot_mainline:
#	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE="$(ccache) aarch64-linux-gnu-" pine64_plus_defconfig
#	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE="$(ccache) aarch64-linux-gnu-"

.PHONY: arm_trusted_firmware
arm_trusted_firmware:
	$(MAKE) -C arm-trusted-firmware ARCH=arm CROSS_COMPILE="$(ccache) aarch64-linux-gnu-" PLAT=sun50iw1p1 bl31

.PHONY: sunxi_pack_tools
sunxi_pack_tools:
	$(MAKE) -C sunxi-pack-tools

#.PHONY: pine64_image
#pine64_image:
#	gcc pine64_image.c -o pine64_image

.NOTPARALLEL: make_image
.PHONY: make_image
make_image:
	@cp -avf u-boot-pine64/u-boot-sun50iw1p1.bin u-boot.bin
	@cp -avf arm-trusted-firmware/build/sun50iw1p1/release/bl31.bin .
	@cp blobs/scp.bin .
	@cp blobs/sys_config.fex .
	@cp blobs/boot0.bin .
	@dtc -O dtb -o pine64.dtb dt.dts
	@dtc -O dtb -o pine64-plus.dtb blobs/pine64.dts
	@dtc -O dtb -o pine64.dtb blobs/pine64noplus.dts
	@unix2dos sys_config.fex
	sunxi-pack-tools/bin/script sys_config.fex
	sunxi-pack-tools/bin/merge_uboot u-boot.bin bl31.bin u-boot-merged.bin secmonitor
	sunxi-pack-tools/bin/merge_uboot u-boot-merged.bin scp.bin u-boot-merged2.bin scp
	sunxi-pack-tools/bin/update_uboot_fdt u-boot-merged2.bin pine64.dtb u-boot-with-dtb.bin
	sunxi-pack-tools/bin/update_uboot u-boot-with-dtb.bin sys_config.bin

.PHONY: clean
clean:
	[[ -d u-boot-pine64 ]] && $(MAKE) -C u-boot-pine64 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
	[[ -d arm-trusted-firmware ]] && $(MAKE) -C arm-trusted-firmware ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- clean
	[[ -d sunxi-pack-tools ]] && $(MAKE) -C sunxi-pack-tools clean
	@rm -f u-boot.bin bl31.bin scp.bin sys_config.fex u-boot-merged.bin u-boot-merged2.bin u-boot-with-dtb.bin

.PHONY: pine64_plus_defconfig
pine64_plus_defconfig:
	@cp blobs/pine64.dts dt.dts

.PHONY: pine64_defconfig
pine64_defconfig:
	@cp blobs/pine64noplus.dts dt.dts