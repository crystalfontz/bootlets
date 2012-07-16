export CROSS_COMPILE
MEM_TYPE ?= MEM_DDR1
export MEM_TYPE

DFT_IMAGE?=$(DEV_IMAGE)/boot/zImage
BAREBOX_IMAGE?=$(DEV_IMAGE)/barebox

BOARD ?= stmp378x_dev
ELFTOSB ?= elftosb

ifeq ($(BOARD), stmp37xx_dev)
ARCH = 37xx
endif
ifeq ($(BOARD), stmp378x_dev)
ARCH = mx23
endif
ifeq ($(BOARD), iMX28_EVK)
ARCH = mx28
endif
ifeq ($(BOARD), cfa10036)
ARCH = mx28
endif

all: linuxsb bareboxsb

linuxsb: linux_prep boot_prep power_prep
	@echo "Generating Linux bootstream image"
ifeq "$(DFT_IMAGE)" "$(wildcard $(DFT_IMAGE))"
	@echo "By using $(DFT_IMAGE)"
	sed 's,[^ *]zImage.*;,\tzImage="$(DFT_IMAGE)";,' linux.bd > linux.bd.tmp
	sed 's,[^ *]zImage.*;,\tzImage="$(DFT_IMAGE)";,' linux_ivt.bd > linux_ivt.bd.tmp
	$(ELFTOSB) -z -c ./linux.bd.tmp -o $(BOARD)_linux.sb
	$(ELFTOSB) -z -f imx28 -c ./linux_ivt.bd.tmp -o $(BOARD)_ivt_linux.sb
else
	@echo "by using the pre-built kernel"
	$(ELFTOSB) -z -c ./linux.bd -o $(BOARD)_linux.sb
	$(ELFTOSB) -z -f imx28 -c  ./linux_ivt.bd -o $(BOARD)_ivt_linux.sb
endif

bareboxsb: power_prep boot_prep
	@echo "Generating Barebox bootstream image"
ifeq "$(BAREBOX_IMAGE)" "$(wildcard $(BAREBOX_IMAGE))"
	@echo "By using $(BAREBOX_IMAGE)"
	sed 's,[^ *]barebox.*;,\tbarebox="$(BAREBOX_IMAGE)";,' barebox_ivt.bd > barebox_ivt.bd.tmp
	$(ELFTOSB) -z -f imx28 -c ./barebox_ivt.bd.tmp -o $(BOARD)_ivt_barebox.sb
	rm -f barebox_ivt.bd.tmp
else
	@echo "By using a prebuilt image"
	$(ELFTOSB) -z -f imx28 -c  ./barebox_ivt.bd -o $(BOARD)_ivt_barebox.sb
endif

power_prep:
	@echo "build power_prep"
	$(MAKE) -C power_prep ARCH=$(ARCH) BOARD=$(BOARD)

boot_prep:
	@echo "build boot_prep"
	$(MAKE) -C boot_prep  ARCH=$(ARCH) BOARD=$(BOARD)

updater: linux_prep boot_prep power_prep
	@echo "Build updater firmware"
	$(ELFTOSB) -z -c ./updater.bd -o updater.sb
	$(ELFTOSB) -z -f imx28 -c ./updater_ivt.bd -o updater_ivt.sb

linux_prep:
	@echo "Building linux_prep"
	$(MAKE) -C linux_prep ARCH=$(ARCH) BOARD=$(BOARD)

install:
	cp -f boot_prep/boot_prep  ${DESTDIR}
	cp -f power_prep/power_prep  ${DESTDIR}
	cp -f linux_prep/output-target/linux_prep ${DESTDIR}
	cp -f *.sb ${DESTDIR}
#	to create finial mfg updater.sb
#	cp -f elftosb ${DESTDIR}
	cp -f ./updater*.bd ${DESTDIR}
	cp -f ./create_updater.sh  ${DESTDIR}

distclean: clean
clean:
	-rm -rf *.sb
	rm -f sd_mmc_bootstream.raw
	$(MAKE) -C linux_prep clean ARCH=$(ARCH)
	$(MAKE) -C boot_prep clean ARCH=$(ARCH)
	$(MAKE) -C power_prep clean ARCH=$(ARCH)

.PHONY: all linuxsb bareboxsb build_prep linux_prep boot_prep power_prep distclean clean
