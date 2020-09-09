# Vivado Launch Script
#### Change design settings here #######
set design shared_output_buffer
set top shared_output_buffer
set device xc7vx690t-3-ffg1761
set proj_dir ./ip_proj
set ip_version 1.00
set lib_name NetFPGA
#####################################
# set IP paths
#####################################
set axi_lite_ipif_ip_path ../../../xilinx/cores/axi_lite_ipif/source/
#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(SUME_FOLDER)/lib/hw/  [current_fileset]
puts "Creating Output Buffer IP"
# Project Constraints
#####################################
# Project Structure & IP Build
#####################################
read_verilog -sv "./hdl/sss_shared_output_buffer_cpu_regs_defines.sv"
read_verilog -sv "./hdl/sss_shared_output_buffer_cpu_regs.sv"
read_verilog -sv "./hdl/sss_shared_output_buffer.sv"

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

ipx::add_user_parameter {C_M_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type user          [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_M_AXIS_DATA_WIDTH [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value 256                        [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_format long                [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter {C_S_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type user          [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_S_AXIS_DATA_WIDTH [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value 256                        [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_format long                [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter {C_M_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type user           [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_M_AXIS_TUSER_WIDTH [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value 128                         [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_format long                 [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter {C_S_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type user           [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_S_AXIS_TUSER_WIDTH [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value 296                         [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_format long                 [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter {NUM_QUEUES} [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters NUM_QUEUES -of_objects [ipx::current_core]]
set_property display_name NUM_QUEUES [ipx::get_user_parameters NUM_QUEUES -of_objects [ipx::current_core]]
set_property value 5                 [ipx::get_user_parameters NUM_QUEUES -of_objects [ipx::current_core]]
set_property value_format long       [ipx::get_user_parameters NUM_QUEUES -of_objects [ipx::current_core]]

ipx::add_user_parameter {C_S_AXI_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type user         [ipx::get_user_parameters C_S_AXI_DATA_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_S_AXI_DATA_WIDTH [ipx::get_user_parameters C_S_AXI_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value 32                        [ipx::get_user_parameters C_S_AXI_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_format long               [ipx::get_user_parameters C_S_AXI_DATA_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter C_S_AXI_ADDR_WIDTH   [ipx::current_core]
set_property value_resolve_type user         [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property display_name C_S_AXI_ADDR_WIDTH [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value 32                        [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH -of_objects [ipx::current_core]]
set_property value_format long               [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter {C_BASEADDR} [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters C_BASEADDR -of_objects [ipx::current_core]]
set_property display_name C_BASEADDR [ipx::get_user_parameters C_BASEADDR -of_objects [ipx::current_core]]
set_property value 0x00000000        [ipx::get_user_parameters C_BASEADDR -of_objects [ipx::current_core]]
set_property value_format bitstring  [ipx::get_user_parameters C_BASEADDR -of_objects [ipx::current_core]]

ipx::add_user_parameter {BITMASK_SIZE} [ipx::current_core]
set_property value_resolve_type user   [ipx::get_user_parameters BITMASK_SIZE -of_objects [ipx::current_core]]
set_property display_name BITMASK_SIZE [ipx::get_user_parameters BITMASK_SIZE -of_objects [ipx::current_core]]
set_property value 88                  [ipx::get_user_parameters BITMASK_SIZE -of_objects [ipx::current_core]]
set_property value_format bitstring    [ipx::get_user_parameters BITMASK_SIZE -of_objects [ipx::current_core]]

ipx::add_subcore NetFPGA:NetFPGA:sss_fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:sss_fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]

ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_0 -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_1 -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_2 -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_3 -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis_4 -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project

file delete -force ${proj_dir}
