HW = hw
SW = sw/embedded/
TEST = test

all:    clean
	make -C ${HW} project
	make -C ${HW} export_to_sdk
	make -C ${SW} project
	make -C ${SW} compile
	make -C ${HW} load_elf

clean:
	make -C ${HW} distclean
	make -C ${SW} distclean
	rm -rfv vivado*;\
