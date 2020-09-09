.PHONY: all
all: mtpsa0.bit config_writes.sh load

load:
	${SUME_SDNET}/tools/program_switch.sh mtpsa0.bit config_writes.sh

config_writes.sh:
	cp ${P4_PROJECT_DIR}/testdata/suIngress/config_writes.sh ./config_writes_suIngress.sh
	cp ${P4_PROJECT_DIR}/testdata/suEgress/config_writes.sh ./config_writes_suEgress.sh
	cat config_writes_suIngress.sh > config_writes.sh
	tail -n +2 config_writes_suEgress.sh >> config_writes.sh

mtpsa0.bit:
	test -s simple_sume_switch.bit || { echo "Error: simple_sume_switch.bit does not exist"; exit 1;  }
	mv simple_sume_switch.bit mtpsa0.bit
