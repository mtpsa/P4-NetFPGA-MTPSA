## -- The following two properties should be set for every design
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

## -- PCIe Transceiver clock (100 MHz)

set_property LOC IBUFDS_GTE2_X1Y11 [get_cells IBUFDS_GTE2_inst]
create_clock -period 10.000 -name sys_clk -add [get_pins -hier -filter name=~*IBUFDS_GTE2_inst/O]
create_clock -period 10.000 -name sys_clkp -waveform {0.000 5.000} [get_ports sys_clkp]

## -- PCIe sys reset
set_property PACKAGE_PIN AY35 [get_ports sys_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_reset_n]
set_property PULLUP true [get_ports sys_reset_n]

set_false_path -from [get_ports sys_reset_n]

# 200MHz System Clock -- SUME
set_property PACKAGE_PIN H19 [get_ports fpga_sysclk_p]
set_property VCCAUX_IO DONTCARE [get_ports fpga_sysclk_p]
set_property IOSTANDARD LVDS [get_ports fpga_sysclk_p]
set_property IOSTANDARD LVDS [get_ports fpga_sysclk_n]

#create_clock -period 5.00 [get_ports {axi_clocking_i/s_axi_aclk}]
create_clock -period 5.000 -name fpga_sysclk_p -waveform {0.000 2.500} [get_ports fpga_sysclk_p]

## -- 200MHz & 100MHz clks
create_clock -period 5.000 -name clk_200 -add [get_pins -hier -filter name=~*axi_clocking_i*clk_wiz_i/clk_out1]
create_clock -period 10.000 -name axi_clk -add [get_pins -hier -filter name=~*axi_lite_bufg0/O]

# Main I2C Bus - 100KHz - SUME
set_property IOSTANDARD LVCMOS18 [get_ports i2c_clk]
set_property SLEW SLOW [get_ports i2c_clk]
set_property DRIVE 16 [get_ports i2c_clk]
set_property PULLUP true [get_ports i2c_clk]
set_property PACKAGE_PIN AK24 [get_ports i2c_clk]

set_property IOSTANDARD LVCMOS18 [get_ports i2c_data]
set_property SLEW SLOW [get_ports i2c_data]
set_property DRIVE 16 [get_ports i2c_data]
set_property PULLUP true [get_ports i2c_data]
set_property PACKAGE_PIN AK25 [get_ports i2c_data]

# i2c_reset[0] - i2c_mux reset - high active
# i2c_reset[1] - si5324 reset - high active
set_property SLEW SLOW [get_ports {i2c_reset[*]}]
set_property DRIVE 16 [get_ports {i2c_reset[*]}]
set_property PACKAGE_PIN AM39 [get_ports {i2c_reset[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {i2c_reset[0]}]
set_property PACKAGE_PIN BA29 [get_ports {i2c_reset[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {i2c_reset[1]}]

## -- USER LEDS
set_property PACKAGE_PIN AR22 [get_ports {leds[0]}]
set_property PACKAGE_PIN AR23 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {leds[1]}]

set_false_path -to [get_ports -filter NAME=~led*]

# UART - 115200 8-1 no parity
set_property PACKAGE_PIN AY19 [get_ports uart_rxd]
set_property PACKAGE_PIN BA19 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS15 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS15 [get_ports uart_txd]

#False paths
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {control_sub_i/dma_sub/pcie3_7x_1/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/pipe_txoutclk_out}]

# Bitfile Generation
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_false_path -from [get_clocks sys_clk] -to [get_clocks clk_200]

set_false_path -from [get_clocks axi_clk] -to [get_clocks clk_200]
set_false_path -from [get_clocks clk_200] -to [get_clocks axi_clk]
