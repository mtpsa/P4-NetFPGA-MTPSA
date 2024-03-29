PROJ = ${NF_PROJECT_NAME}

all:
	@echo ""
	@echo "NetFPGA-SUME Referece Project HW Makefile"
	@echo ""
	@echo "make TARGETS"
	@echo "------------------------------------------------------"
	@echo "project:         Create hardware project"
	@echo "sim:             Run project simulation"
	@echo "export_to_sdk:   Export implemented project to sw/embedded"
	@echo "load_elf:        Load ELF file for specified project"
	@echo ""
	@echo "clean:           Remove specified project"
	@echo "distclean:       Remove all generated projects"
	@echo ""

.PHONY: clean project export_to_sdk load_elf

project: identifier
	echo "Create reference project under folder /project";\
	if test -d project/; then\
		echo "Project already exists"; \
	else \
		vivado -mode batch -source tcl/${PROJ}.tcl;\
		if [ -f patch/${PROJ}.patch ]; then\
			patch -p1 < patch/${PROJ}.patch;\
		fi;\
	fi;\

projectgui:
	echo "Create reference project under folder /project";\
	if test -d project/; then\
		echo "Project already exists"; \
	else \
		vivado -mode gui -source tcl/${PROJ}.tcl;\
		if [ -f patch/${PROJ}.patch ]; then\
			patch -p1 < patch/${PROJ}.patch;\
		fi;\
	fi;\

export_to_sdk: identifier
	if test -d project; then\
		echo "export ${PROJ} project to SDK"; \
		vivado -mode tcl -source tcl/export_hardware.tcl -tclargs ${PROJ};\
	else \
		echo "Project ${PROJ} does not exist.";\
		echo "Please run \"make project\" to create and build the project first";\
	fi;\

load_elf:
	@if [ ! -d ../bitfiles ]; then mkdir ../bitfiles; fi;
	if test -d project; then\
		echo "export ${PROJ} project to SDK"; \
		vivado -mode tcl -source tcl/load_elf.tcl -tclargs ${PROJ};\
	else \
		echo "Project ${PROJ} does not exist.";\
		echo "Please run \"make project\" to create and build the project first";\
	fi;\

identifier:
	rm -f ../hw/create_ip/id_rom16x32.coe
	cp ${SUME_FOLDER}/tools/scripts/epoch.sh . && sh epoch.sh && rm -f epoch.sh
	echo 16028002 >> rom_data.txt
	echo `${SUME_FOLDER}/run_tag.sh` >> rom_data.txt
	echo 00000204 >> rom_data.txt
	echo 0000FFFF >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	echo FFFF0000 >> rom_data.txt
	cp ${SUME_FOLDER}/tools/scripts/format_coe.py . && python format_coe.py && rm -f format_coe.py
	mv -f id_rom16x32.coe ../hw/create_ip/
	mv -f rom_data.txt ../hw/create_ip/

sim:	simclean identifier
	cp -f $(NF_DESIGN_DIR)/test/reg_defines_${NF_PROJECT_NAME}.py $(NF_DESIGN_DIR)/test/${TESTNAME}/reg_defines_${NF_PROJECT_NAME}.py
	vivado -mode batch -source ${NF_DESIGN_DIR}/hw/tcl/${NF_PROJECT_NAME}_sim.tcl -tclargs ${TESTNAME}
	$(SUME_FOLDER)/tools/scripts/nf_sim_reconcile_axi_logs.py
	$(SUME_FOLDER)/tools/scripts/nf_sim_registers_axi_logs.py

reg:
	vivado -mode batch -source $(NF_DESIGN_DIR)/hw/tcl/${NF_PROJECT_NAME}_defines.tcl
	vivado -mode batch -source $(NF_DESIGN_DIR)/hw/tcl/export_registers.tcl
	cd ../sw/embedded/src  && cp ${SUME_FOLDER}/tools/scripts/xparam2regdefines.py . && python xparam2regdefines.py
	cd ../sw/embedded/src  && rm -f xparam2regdefines.py && mv reg_defines.h ../
	cd ../sw/embedded && cp ${SUME_FOLDER}/tools/scripts/python_parser.py . && python python_parser.py
	cd ../sw/embedded && rm -f python_parser.py && mv reg_defines.py ../../test/reg_defines_${NF_PROJECT_NAME}.py

simgui: simclean identifier
	cp -f $(NF_DESIGN_DIR)/test/reg_defines_simple_sume_switch.py $(NF_DESIGN_DIR)/test/${TESTNAME}/reg_defines_simple_sume_switch.py
	vivado -mode gui -source ${NF_DESIGN_DIR}/hw/tcl/${NF_PROJECT_NAME}_sim.tcl -tclargs ${TESTNAME}
	$(SUME_FOLDER)/tools/scripts/nf_sim_reconcile_axi_logs.py
	$(SUME_FOLDER)/tools/scripts/nf_sim_registers_axi_logs.py

simclean:
	rm -rf proj_* vivado*.* *.*~ .Xil* $(NF_DESIGN_DIR)/hw/ip_repo/ $(NF_DESIGN_DIR)/hw/project/
	rm -rf *[0-9]_{stim,expected,log}.axi
	rm -f *.axi
	rm -f portconfig.sim
	rm -f seed
	rm -f *.log
	rm -f ../test/Makefile
	rm -rf ../test/*.log
	rm -rf ../test/*.axi
	rm -rf ../test/seed
	rm -rf ../test/*.sim
	rm -rf ../test/proj_*
	rm -rf ../test/ip_repo
	rm -f ../test/vivado*.*
	rm -f ../test/*_*_*/reg_defines_${NF_PROJECT_NAME}.py
	rm -f ../test/*_*_*/reg_defines_${NF_PROJECT_NAME}.pyc

distclean: clean

clean:	simclean
		rm -rfv project;\
		rm -rfv ../sw/embedded/project;\
		rm -rfv vivado*;\
		rm -rfv *.log;\
		rm -rfv .Xil;\
		rm -rfv ..rej;\
		rm -rfv .srcs;\
		rm -rfv webtalk*;\
		rm -rfv *.*~;\
		rm -rfv ip_repo;\
		rm -rfv ip_proj;\
		rm -rfv std;\
