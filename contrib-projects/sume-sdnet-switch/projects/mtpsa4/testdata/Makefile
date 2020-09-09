SRC := $(wildcard ./*/gen_testdata.py)
SRC := $(SRC:%/gen_testdata.py=%/Tuple_in.txt)

all: $(SRC)

$(SRC):
	./gen_testdata.py && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_in.axi --bus_width 256 src.pcap && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_expect.axi --bus_width 256 dst.pcap
	cd $(dir $@) && \
	./gen_testdata.py && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_in.axi --bus_width 256 src.pcap && \
	${SUME_SDNET}/bin/pcap2axi --output Packet_expect.axi --bus_width 256 dst.pcap

clean:
	rm -f ./*/*.pcap ./*/*.txt ./*/*.pyc ./*/*.axi ./*/config_writes.* ./*/*_reg_defines.py ./*/*_extern_defines.json
	rm -f ./*.pcap ./*.txt ./*.pyc ./*.axi ./config_writes.* ./*_reg_defines.py ./*_extern_defines.json
