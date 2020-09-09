
TOPLEVEL_LANG = verilog

#COMPILE_ARGS=-pfileline=1

NETFPGA_HW_LIB=$(SUME_FOLDER)/lib/hw/std/cores

VERILOG_SOURCES =  $(NETFPGA_HW_LIB)/fallthrough_small_fifo_v1_0_0/hdl/small_fifo.v
VERILOG_SOURCES += $(NETFPGA_HW_LIB)/fallthrough_small_fifo_v1_0_0/hdl/fallthrough_small_fifo.v

VERILOG_SOURCES += ../../hdl/axis_pkt_generator.v
VERILOG_SOURCES += ../../hdl/input_arbiter.v
VERILOG_SOURCES += ../../hdl/timer_module.v
VERILOG_SOURCES += ../../hdl/event_merger.v
VERILOG_SOURCES += ../../hdl/SimpleSumeSwitch_dummy.v
VERILOG_SOURCES += ../../hdl/event_output_queues.v
VERILOG_SOURCES += ../../hdl/sume_event_switch.v

TOPLEVEL = sume_event_switch
MODULE = test_sume_event_switch

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

