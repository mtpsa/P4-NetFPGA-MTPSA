set design [lindex $argv 0]

puts "\nOpening $design XPR project\n"
open_project project/$design.xpr

puts "\nOpening $design Implementation design\n"
open_run impl_1

puts "\nCopying top.sysdef\n"
file copy -force ./project/$design.runs/impl_1/top.sysdef ../sw/embedded/$design.hdf

exit

