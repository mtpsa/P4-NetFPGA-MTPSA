#!/usr/bin/env python
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from NFTest import *
import sys
import os
#from scapy.layers.all import Ether, IP, TCP
from scapy.all import *

import config_writes_suIngress
import config_writes_suEgress
import config_writes_user0
import config_writes_user1
import config_writes_user2
import config_writes_user3

phy2loop0 = ('../connections/conn', [])
nftest_init(sim_loop = [], hw_config = [phy2loop0])

print "About to start the test"

nftest_start()

def try_read_pkts(pcap_file):
    pkts = []
    try:
        pkts = rdpcap(pcap_file)
    except:
        print pcap_file, ' not found'
    return pkts

def schedule_pkts(pkt_list, iface):
    for pkt in pkt_list:
        pkt.time = baseTime + delta*pkt.time
        pkt.tuser_sport = nf_port_map[iface]

# configure the tables in the P4_SWITCH
nftest_regwrite(0x440200f0, 0x00000001)
nftest_regwrite(0x440200f0, 0x00000001)
nftest_regwrite(0x440200f0, 0x00000001)
nftest_regwrite(0x440200f0, 0x00000001)
nftest_regwrite(0x440200f0, 0x00000001)

config_writes_suIngress.config_tables()
config_writes_suEgress.config_tables()
config_writes_user0.config_tables()
config_writes_user1.config_tables()
config_writes_user2.config_tables()
config_writes_user3.config_tables()

nf0_applied   = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf0_applied.pcap'))
nf1_applied   = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf1_applied.pcap'))
nf2_applied   = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf2_applied.pcap'))
nf3_applied   = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf3_applied.pcap'))
nf0_expected  = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf0_expected.pcap'))
nf1_expected  = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf1_expected.pcap'))
nf2_expected  = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf2_expected.pcap'))
nf3_expected  = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/nf3_expected.pcap'))
dma0_expected = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/dma0_expected.pcap'))
dma1_expected = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/dma1_expected.pcap'))
dma2_expected = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/dma2_expected.pcap'))
dma3_expected = try_read_pkts(os.path.expandvars('$P4_PROJECT_DIR/testdata/dma3_expected.pcap'))

nf_port_map = {
    'nf0':0b00000001,
    'nf1':0b00000100,
    'nf2':0b00010000,
    'nf3':0b01000000
}

# send packets after the configuration writes have finished
baseTime = 25e-6
delta = 1e-6 #1e-8

schedule_pkts(nf0_applied, 'nf0')
schedule_pkts(nf1_applied, 'nf1')
schedule_pkts(nf2_applied, 'nf2')
schedule_pkts(nf3_applied, 'nf3')

# Apply and check the packets
nftest_send_phy('nf0', nf0_applied)
nftest_send_phy('nf1', nf1_applied)
nftest_send_phy('nf2', nf2_applied)
nftest_send_phy('nf3', nf3_applied)

nftest_expect_phy('nf0', nf0_expected)
nftest_expect_phy('nf1', nf1_expected)
nftest_expect_phy('nf2', nf2_expected)
nftest_expect_phy('nf3', nf3_expected)

nftest_expect_dma('nf0', dma0_expected)
nftest_expect_dma('nf1', dma1_expected)
nftest_expect_dma('nf2', dma2_expected)
nftest_expect_dma('nf3', dma3_expected)

nftest_barrier()

mres=[]
nftest_finish(mres)
