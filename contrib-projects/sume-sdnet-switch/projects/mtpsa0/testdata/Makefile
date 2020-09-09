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

SRC := $(wildcard ./*/gen_testdata.py)
SRC := $(SRC:%/gen_testdata.py=%/Tuple_in.txt)

all: $(SRC)

$(SRC):
	./gen_testdata.py && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_in.axi --bus_width 256 src.pcap && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_expect.axi --bus_width 256 dst.pcap
	cd $(dir $@) && \
	./gen_testdata.py && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_in.axi --bus_width 256 src.pcap && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_expect.axi --bus_width 256 dst.pcap

clean:
	rm -f ./*/*.pcap ./*/*.txt ./*/*.pyc ./*/*.axi ./*/config_writes.* ./*/*_reg_defines.py ./*/*_extern_defines.json
	rm -f ./*.pcap ./*.txt ./*.pyc ./*.axi ./config_writes.* ./*_reg_defines.py ./*_extern_defines.json
