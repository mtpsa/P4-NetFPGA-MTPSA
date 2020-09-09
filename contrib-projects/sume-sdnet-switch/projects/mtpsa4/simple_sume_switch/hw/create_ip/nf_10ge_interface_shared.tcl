## CORE CONFIGURATION parameters
# should correspond to hdl params
set sharedLogic         "TRUE"
set tdataWidth          256

set convWidth [expr $tdataWidth/8]

if { $sharedLogic eq "True" || $sharedLogic eq "TRUE" || $sharedLogic eq "true" } {
   set supportLevel 1
} else {
   set supportLevel 0
}

create_ip -name axi_10g_ethernet -vendor xilinx.com -library ip -version 3.1 -module_name axi_10g_ethernet_shared
set_property -dict [list CONFIG.Management_Interface {false}] [get_ips axi_10g_ethernet_shared]
set_property -dict [list CONFIG.base_kr {BASE-R}] [get_ips axi_10g_ethernet_shared]
set_property -dict [list CONFIG.SupportLevel $supportLevel] [get_ips axi_10g_ethernet_shared]
set_property -dict [list CONFIG.autonegotiation {0}] [get_ips axi_10g_ethernet_shared]
set_property -dict [list CONFIG.fec {0}] [get_ips axi_10g_ethernet_shared]
set_property -dict [list CONFIG.Statistics_Gathering {0}] [get_ips axi_10g_ethernet_shared]

set_property generate_synth_checkpoint false [get_files axi_10g_ethernet_shared.xci]
reset_target all [get_ips axi_10g_ethernet_shared]
generate_target all [get_ips axi_10g_ethernet_shared]
