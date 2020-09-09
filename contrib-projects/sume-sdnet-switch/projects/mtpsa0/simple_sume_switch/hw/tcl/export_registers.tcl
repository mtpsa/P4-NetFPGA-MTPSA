# The following list include all the items that are mapped to memory segments
# The structure of each item is as follows {<Prefix name> <ID> <has registers> <library name>}
set DEF_LIST {
	{MICROBLAZE_AXI_IIC 0 0 ""} \
	{MICROBLAZE_UARTLITE 0 0 ""} \
	{MICROBLAZE_DLMB_BRAM 0 0 ""} \
	{MICROBLAZE_ILMB_BRAM 0 0 ""} \
	{MICROBLAZE_AXI_INTC 0 0 ""} \
	{INPUT_ARBITER 0 1 input_arbiter_v1_0_0/data/input_arbiter_regs_defines.txt} \
	{OUTPUT_QUEUES 0 1 output_queues_v1_0_0/data/output_queues_regs_defines.txt} \
	{OUTPUT_PORT_LOOKUP 0 1 switch_output_port_lookup_v1_0_1/data/output_port_lookup_regs_defines.txt} \
	{NF_10G_INTERFACE0 0 1 nf_10ge_interface_shared_v1_0_0/data/nf_10g_interface_shared_regs_defines.txt} \
	{NF_10G_INTERFACE1 1 1 nf_10ge_interface_v1_0_0/data/nf_10g_interface_regs_defines.txt} \
	{NF_10G_INTERFACE2 2 1 nf_10ge_interface_v1_0_0/data/nf_10g_interface_regs_defines.txt} \
	{NF_10G_INTERFACE3 3 1 nf_10ge_interface_v1_0_0/data/nf_10g_interface_regs_defines.txt} \
	{NF_RIFFA_DMA 0 1 nf_riffa_dma_v1_0_0/data/nf_riffa_dma_regs_defines.txt} \
}

set target_path $::env(NF_DESIGN_DIR)/sw/embedded/src/
set target_file $target_path/sume_register_defines.h

######################################################
# the following function writes the license header
# into the file
######################################################
proc write_header { target_file } {
    # creat a blank header file
    # do a fresh rewrite in case the file already exits
    file delete -force $target_file
    open $target_file "w"
    set h_file [open $target_file "w"]

   puts $h_file "/////////////////////////////////////////////////////////////////////////////////"
   puts $h_file "// This is an automatically generated header definitions file"
   puts $h_file "/////////////////////////////////////////////////////////////////////////////////"
   puts $h_file ""

   close $h_file

}; # end of proc write_header


######################################################
# the following function writes all the information
# of a specific core into a file
######################################################

proc write_core {target_file prefix id has_registers lib_name} {
        set h_file [open $target_file "a"]

        #First, read the memory map information from the reference_project defines file
        source $::env(NF_DESIGN_DIR)/hw/tcl/$::env(NF_PROJECT_NAME)_defines.tcl
        set public_repo_dir $::env(SUME_FOLDER)/lib/hw/

        set baseaddr [set $prefix\_BASEADDR]
        set highaddr [set $prefix\_HIGHADDR]
        set sizeaddr [set $prefix\_SIZEADDR]

        puts $h_file "//######################################################"
        puts $h_file "//# Definitions for $prefix"
        puts $h_file "//######################################################"

        puts $h_file "#define SUME_$prefix\_BASEADDR $baseaddr"
        puts $h_file "#define SUME_$prefix\_HIGHADDR $highaddr"
        puts $h_file "#define SUME_$prefix\_SIZEADDR $sizeaddr"
        puts $h_file ""

        #Second, read the registers information from the library defines file
        if $has_registers {
            set lib_path "$public_repo_dir/std/cores/$lib_name"
            set regs_h_define_file $lib_path
            set regs_h_define_file_read [open $regs_h_define_file r]
            set regs_h_define_file_data [read $regs_h_define_file_read]
            close $regs_h_define_file_read
            set regs_h_define_file_data_line [split $regs_h_define_file_data "\n"]

            foreach read_line $regs_h_define_file_data_line {
                if {[regexp "#define" $read_line]} {
                    puts $h_file "#define SUME_[lindex $read_line 2]\_$id\_[lindex $read_line 3]\_[lindex $read_line 4] [lindex $read_line 5]"
            }
        }
    }
    puts $h_file ""
    close $h_file
}; # end of proc write_core

######################################################
# the main function
######################################################
write_header  $target_file

foreach lib_item $DEF_LIST {
    write_core  $target_file [lindex $lib_item 0] [lindex $lib_item 1] [lindex $lib_item 2] [lindex $lib_item 3]
}
