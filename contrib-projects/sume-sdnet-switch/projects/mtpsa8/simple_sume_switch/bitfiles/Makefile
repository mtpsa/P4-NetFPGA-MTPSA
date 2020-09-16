.PHONY: all load
all: mtpsa8.bit config_writes.sh load

load:
	${SUME_SDNET}/tools/program_switch.sh mtpsa8.bit config_writes.sh

config_writes.sh:
	cp ${P4_PROJECT_DIR}/testdata/suIngress/config_writes.sh ./config_writes_suIngress.sh
	cp ${P4_PROJECT_DIR}/testdata/suEgress/config_writes.sh ./config_writes_suEgress.sh
	cp ${P4_PROJECT_DIR}/testdata/user0/config_writes.sh ./config_writes_user0.sh
	cp ${P4_PROJECT_DIR}/testdata/user1/config_writes.sh ./config_writes_user1.sh
	cp ${P4_PROJECT_DIR}/testdata/user2/config_writes.sh ./config_writes_user2.sh
	cp ${P4_PROJECT_DIR}/testdata/user3/config_writes.sh ./config_writes_user3.sh
	cp ${P4_PROJECT_DIR}/testdata/user4/config_writes.sh ./config_writes_user4.sh
	cp ${P4_PROJECT_DIR}/testdata/user5/config_writes.sh ./config_writes_user5.sh
	cp ${P4_PROJECT_DIR}/testdata/user6/config_writes.sh ./config_writes_user6.sh
	cp ${P4_PROJECT_DIR}/testdata/user7/config_writes.sh ./config_writes_user7.sh
	cat config_writes_suIngress.sh > config_writes.sh
	tail -n +2 config_writes_user0.sh >> config_writes.sh
	tail -n +2 config_writes_user1.sh >> config_writes.sh
	tail -n +2 config_writes_user2.sh >> config_writes.sh
	tail -n +2 config_writes_user3.sh >> config_writes.sh
	tail -n +2 config_writes_user4.sh >> config_writes.sh
	tail -n +2 config_writes_user5.sh >> config_writes.sh
	tail -n +2 config_writes_user6.sh >> config_writes.sh
	tail -n +2 config_writes_user7.sh >> config_writes.sh
	tail -n +2 config_writes_suEgress.sh >> config_writes.sh

mtpsa8.bit:
	test -s simple_sume_switch.bit || { echo "Error: simple_sume_switch.bit does not exist"; exit 1;  }
	mv simple_sume_switch.bit mtpsa8.bit
