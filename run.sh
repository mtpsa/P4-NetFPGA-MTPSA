#!/bin/bash

if [[ -z "${P4_PROJECT_NAME}"  ]]; then
	source tools/settings.sh
fi

# Build Vivado core IP modules
cd $SUME_FOLDER/lib/hw/xilinx/cores/tcam_v1_1_0/ && make update && make
cd $SUME_FOLDER/lib/hw/xilinx/cores/cam_v1_1_0/ && make update && make
cd $SUME_SDNET/sw/sume && make
cd $SUME_FOLDER && make

# Build sume_riffa driver
make -C $DRIVER_FOLDER all
make -C $DRIVER_FOLDER install
modprobe sume_riffa

# Generate verilog code and API/CLI tools
make -C $P4_PROJECT_DIR

# Run SDNet simulation
for dir in $P4_PROJECT_DIR/nf_*/*/vivado_sim.bash
do
    cd ${dir%/vivado_sim.bash}
    ./vivado_sim.bash
done

# Generate the scripts for NetFPGA SUME simulation
make -C $P4_PROJECT_DIR config_writes
make -C $P4_PROJECT_DIR install_sdnet
make -C $NF_DESIGN_DIR/test/sim_switch_default

# Run NetFPGA simulation
cd $SUME_FOLDER
./tools/scripts/nf_test.py sim --major switch --minor default

# Build bitstream
make -C $NF_DESIGN_DIR
