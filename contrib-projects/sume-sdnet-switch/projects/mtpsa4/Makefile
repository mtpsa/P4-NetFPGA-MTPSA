#
# Copyright (c) 2020 -
# All rights reserved.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

P4USER:=suIngress
P4_SWITCH_BASE_ADDR:=0x44020000
SDNET_OUT_DIR=nf_sdnet_$(P4USER)_ip
P4_WRAPPER=nf_sdnet_${P4USER}.v
P4_SWITCH=${P4USER}Switch

PX=sdnet
PX_FLAGS=-prefix ${P4_SWITCH} -busType axi -busWidth 256 -singlecontrolport -workDir ${SDNET_OUT_DIR} -altVivadoScripts
TARGET=${SUME_FOLDER}/lib/hw/contrib/cores
SWITCH_INFO=src/$(P4USER)/.sdnet_switch_info.dat

all:
	$(MAKE) P4USER=suIngress P4_SWITCH_BASE_ADDR=0x44020000 build
	$(MAKE) P4USER=suEgress  P4_SWITCH_BASE_ADDR=0x44030000 build
	$(MAKE) P4USER=user0     P4_SWITCH_BASE_ADDR=0x44040000 build
	$(MAKE) P4USER=user1     P4_SWITCH_BASE_ADDR=0x44050000 build
	$(MAKE) P4USER=user2     P4_SWITCH_BASE_ADDR=0x44060000 build
	$(MAKE) P4USER=user3     P4_SWITCH_BASE_ADDR=0x44070000 build

# Compile to HDL with P4-SDNet
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to user provided expected output
build: frontend compile_no_cpp_test run_scripts
	cp src/$(P4USER)/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/$(P4USER)/*.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/$(P4USER)/*.axi ${SDNET_OUT_DIR}/${P4_SWITCH}/

# Compile to HDL with P4-SDNet
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to the C++ simulation output
cpp_test: frontend compile_cpp_test run_scripts
	cp src/$(P4USER)/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/$(P4USER)/src.pcap ${SDNET_OUT_DIR}/${P4_SWITCH}/Packet.user
	cp testdata/$(P4USER)/Tuple_in.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/Tuple.user
	cp src/$(P4USER)/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/
	cp testdata/$(P4USER)/src.pcap ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Packet.user
	cp testdata/$(P4USER)/Tuple_in.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Tuple.user

frontend:
	make -C src/
	make -C testdata/

compile_cpp_test:
	$(PX) ./src/$(P4USER)/${P4USER}.sdnet $(PX_FLAGS)

compile_no_cpp_test:
	$(PX) ./src/$(P4USER)/${P4USER}.sdnet -skipEval $(PX_FLAGS)

run_scripts:
	${SUME_SDNET}/bin/gen_P4_SWITCH_externs.py \
	    ${SWITCH_INFO} \
	    ${SDNET_OUT_DIR}/${P4_SWITCH}/ \
	    ${SUME_SDNET}/templates/ \
	    ./testdata/$(P4USER)/\
	    ./sw/ \
	    --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_API.py \
	    ${SWITCH_INFO} \
	    ${SDNET_OUT_DIR}/${P4_SWITCH}/ \
	    sw/ \
	    ${SUME_SDNET}/templates/ \
	    --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_CLI.py \
	    ${SWITCH_INFO} \
	    ${SDNET_OUT_DIR}/${P4_SWITCH}/ \
	    sw/ \
	    ${SUME_SDNET}/templates/ \
	    --base_address ${P4_SWITCH_BASE_ADDR}
	# The following command only applies if running P4_SWITCH Questa Simulation with Ubuntu
	sed -i 's/vsim/vsim \-ldflags \"\-B\/usr\/lib\/x86\_64\-linux-gnu\"/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/questa.bash
	# modify the P4_SWITCH_tb so that it writes the table configuration writes to a file
	${SUME_SDNET}/bin/modify_P4_SWITCH_tb.py ${SDNET_OUT_DIR}/${P4_SWITCH}/Testbench/${P4_SWITCH}_tb.sv
	# Fix introduced for SDNet 2017.4
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim.bash
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash
	# Fix introduced for SDNet 2018.2
	sed -i 's/glbl_sim/glbl/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash
	sed -i 's/${P4USER}Switch_tb_sim#work.glbl/${P4USER}Switch_tb/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash

config_writes:
	$(MAKE) P4USER=suIngress P4_SWITCH_BASE_ADDR=0x44020000 _config_writes
	$(MAKE) P4USER=suEgress  P4_SWITCH_BASE_ADDR=0x44030000 _config_writes
	$(MAKE) P4USER=user0     P4_SWITCH_BASE_ADDR=0x44040000 _config_writes
	$(MAKE) P4USER=user1     P4_SWITCH_BASE_ADDR=0x44050000 _config_writes
	$(MAKE) P4USER=user2     P4_SWITCH_BASE_ADDR=0x44060000 _config_writes
	$(MAKE) P4USER=user3     P4_SWITCH_BASE_ADDR=0x44070000 _config_writes

_config_writes:
	${SUME_SDNET}/bin/gen_config_writes.py ${SDNET_OUT_DIR}/${P4_SWITCH}/config_writes.txt ${P4_SWITCH_BASE_ADDR} testdata/$(P4USER)

# install the SDNet core as a NetFPGA-SUME-SDNet library core
install_sdnet:
	$(MAKE) P4USER=suIngress _install_sdnet
	$(MAKE) P4USER=suEgress _install_sdnet
	$(MAKE) P4USER=user0 _install_sdnet
	$(MAKE) P4USER=user1 _install_sdnet
	$(MAKE) P4USER=user2 _install_sdnet
	$(MAKE) P4USER=user3 _install_sdnet

_install_sdnet: uninstall_sdnet
	cp -r ${SDNET_OUT_DIR} ${TARGET}/
	mkdir ${TARGET}/${SDNET_OUT_DIR}/wrapper
	cp ${P4_PROJECT_DIR}/sss_wrapper/hdl/${P4_WRAPPER} ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${P4_PROJECT_DIR}/sss_wrapper/hdl/mtpsa_to_sdnet.v ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${P4_PROJECT_DIR}/sss_wrapper/hdl/changeEndian.v ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${P4_PROJECT_DIR}/sss_wrapper/tcl/nf_sume_sdnet.tcl ${TARGET}/${SDNET_OUT_DIR}/
	cp ${P4_PROJECT_DIR}/sss_wrapper/Makefile ${TARGET}/${SDNET_OUT_DIR}/
	make -C ${TARGET}/${SDNET_OUT_DIR}/

uninstall_sdnet:
	rm -rf ${TARGET}/${SDNET_OUT_DIR}

clean:
	make -C src/ clean
	make -C testdata/ clean
	rm -rf nf_sdnet_*_ip/ $(shell find -name *.log -o -name *.jou) sw/config_tables.c

