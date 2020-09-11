#
# Copyright (c) 2015 Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by
# Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
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

# Set variables.
set design        axi_sim_transactor
set device        xc7vx690t-3-ffg1761
set proj_dir      ./ip_proj
set ip_version    1.00
set lib_name      NetFPGA

set axis_sim_pkg_path ../axis_sim_pkg_v1_0_0/hdl/
set lib_srl_fifo_path $::env(XILINX_VIVADO)/data/ip/xilinx/lib_srl_fifo_v1_0/hdl/
set lib_pkg_path $::env(XILINX_VIVADO)/data/ip/xilinx/lib_pkg_v1_0/hdl/

# Project setting.
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property top ${design} [current_fileset]
set_property ip_repo_paths $::env(SUME_FOLDER)/lib/hw/  [current_fileset]

# IP build.
file copy -force ${lib_srl_fifo_path}/ "./hdl/lib_srl_fifo_v1_0/"
read_vhdl "./hdl/lib_srl_fifo_v1_0/lib_srl_fifo_v1_0_rfs.vhd"

set_property is_global_include true [get_files  ./hdl/lib_srl_fifo_v1_0/lib_srl_fifo_v1_0_rfs.vhd]

update_ip_catalog

file copy -force ${lib_pkg_path}/ "./hdl/lib_pkg_v1_0/"
read_vhdl "./hdl/lib_pkg_v1_0/lib_pkg_v1_0_rfs.vhd"

set_property is_global_include true [get_files  ./hdl/lib_pkg_v1_0/lib_pkg_v1_0_rfs.vhd]

update_ip_catalog
file copy -force ${axis_sim_pkg_path}/ "./hdl/axis_sim_pkg/"
read_vhdl "./hdl/axis_sim_pkg/axis_sim_pkg.vhd"
update_ip_catalog
read_vhdl "./hdl/transactor_fifos.vhd"
read_vhdl "./hdl/axi_sim_transactor.vhd"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {NetFPGA} [ipx::current_core]
set_property company_url {http://www.netfpga.org} [ipx::current_core]
set_property vendor {NetFPGA} [ipx::current_core]
set_property supported_families {{virtex7} {Production}} [ipx::current_core]
set_property taxonomy {{/NetFPGA/Generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

update_ip_catalog -rebuild 

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project





