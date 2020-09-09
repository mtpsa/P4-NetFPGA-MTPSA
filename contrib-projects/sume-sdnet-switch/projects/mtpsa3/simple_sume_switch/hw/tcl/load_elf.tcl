set design [lindex $argv 0]
set ws "SDK_Workspace"

# open project
puts "\nOpening $design XPR project\n"
open_project project/$design.xpr

set bd_file [get_files -regexp -nocase {.*sub*.bd}]
set elf_file ../sw/embedded/$ws/$design/app/Debug/app.elf

puts "\nOpening $design BD project\n"
open_bd_design $bd_file

# insert elf if it is not inserted yet
if {[llength [get_files app.elf]]} {
    puts "ELF File [get_files app.elf] is already associated"
    exit
} else {
    add_files -norecurse -force ${elf_file}
    set_property SCOPED_TO_REF [current_bd_design] [get_files -all -of_objects [get_fileset sources_1] ${elf_file}]
    set_property SCOPED_TO_CELLS nf_mbsys/mbsys/microblaze_0 [get_files -all -of_objects [get_fileset sources_1] ${elf_file}]
}

# Create bitstream with up-to-date elf files
reset_run impl_1 -prev_step
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1
write_bitstream -force ../bitfiles/$design.bit

exit
