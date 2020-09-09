
TOPLEVEL_LANG = verilog

#COMPILE_ARGS=-pfileline=1

NETFPGA_HW_LIB=$(SUME_FOLDER)/lib/hw/std/cores

# pkt_storage source files
VERILOG_SOURCES = ../../hdl/axis_pkt_generator.v

TOPLEVEL = axis_pkt_generator 
MODULE = test_axis_pkt_generator

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

