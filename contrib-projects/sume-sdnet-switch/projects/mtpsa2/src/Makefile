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

SRC_FILES := $(shell find . ! -name "mtpsa*.p4" -name "*.p4")
OBJ_FILES := $(patsubst %.p4,%.sdnet,$(SRC_FILES))

all: $(OBJ_FILES)

$(OBJ_FILES):
	$(eval P4USER=$(basename $(notdir $@)))
	cd $(P4USER) && \
	p4c-sdnet \
	    -I ../include \
	    -o $(P4USER).sdnet \
	    --toplevel_name $(P4USER)Switch \
	    --sdnet_info .sdnet_switch_info.dat \
	    $(P4USER).p4 && \
	${SUME_SDNET}/bin/p4_px_tables.py commands.txt .sdnet_switch_info.dat

clean:
	rm -f ./*/*.sdnet ./*/*.tbl ./*/.sdnet_switch_info.dat
