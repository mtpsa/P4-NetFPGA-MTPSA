all: clean
	for P4USER in suIngress suEgress user0 user1 user2 user3 ; do \
		cp ${P4_PROJECT_DIR}/testdata/$$P4USER/config_writes.py ./config_writes_$$P4USER.py; \
	done

clean:
	rm -f config_writes*.py *.pyc
