#!/usr/bin/env python

#
# Copyright (c) 2017 Stephen Ibanez
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#


"""
This version uses the digest data bus and expects all digest pkts
to be received on the dma0 interface
"""

from nf_sim_tools import *
from collections import OrderedDict
import random
import sss_sdnet_tuples
from sss_digest_header import *

ETH_KNOWN = ["08:11:11:11:11:08",
            "08:22:22:22:22:08",
            "08:33:33:33:33:08",
            "08:44:44:44:44:08"]

ETH_UNKNOWN = ["08:de:ad:be:ef:08",
              "08:ca:fe:ba:be:08",
              "08:ba:5e:ba:11:08",
              "08:b0:1d:fa:ce:08"]

IPv4_ADDR = ["192.168.10.1",
            "192.168.10.2",
            "192.168.10.3",
            "192.168.10.4"]

portMap = {0 : 0b00000001, 1 : 0b00000100, 2 : 0b00010000, 3 : 0b01000000}
bcast_portMap = {0 : 0b01010100, 1 : 0b01010001, 2 : 0b01000101, 3 : 0b00010101}

sss_sdnet_tuples.clear_tuple_files()

pkt_num = 0
pktsApplied = []
pktsExpected = []

# Pkt lists for SUME simulations
nf_applied = OrderedDict()
nf_applied[0] = []
nf_applied[1] = []
nf_applied[2] = []
nf_applied[3] = []
nf_expected = OrderedDict()
nf_expected[0] = []
nf_expected[1] = []
nf_expected[2] = []
nf_expected[3] = []

dma0_expected = []

def applyPkt(pkt, src_ind):
    global pkt_num
    pktsApplied.append(pkt)
    sss_sdnet_tuples.sume_tuple_in['src_port'] = portMap[src_ind]
    sss_sdnet_tuples.sume_tuple_expect['src_port'] = portMap[src_ind]
    pkt.time = pkt_num
    nf_applied[src_ind].append(pkt)
    pkt_num += 1

def expPkt(pkt, src_ind, dst_ind, src_known, dst_known):
    pktsExpected.append(pkt)
    # If dst MAC address is unknown, broadcast with src port pruning
    if dst_known:
        sss_sdnet_tuples.sume_tuple_expect['dst_port'] = portMap[dst_ind]
        nf_expected[dst_ind].append(pkt) 
    else:
        sss_sdnet_tuples.sume_tuple_expect['dst_port'] = bcast_portMap[src_ind] 
        for ind in [0,1,2,3]:
            if ind != src_ind:
                nf_expected[ind].append(pkt)

    # If src MAC address is unknown, send over DMA
    if not src_known:
        sss_sdnet_tuples.sume_tuple_expect['dst_port'] = sss_sdnet_tuples.sume_tuple_expect['dst_port']
        src_port = portMap[src_ind]
        eth_src_addr = int(pkt[Ether].src.replace(':',''),16)
        digest_pkt = pad_pkt(Digest_data(src_port=src_port, eth_src_addr=eth_src_addr), 10) # pad to 10 bytes (80 bits)
        dma0_expected.append(digest_pkt)
        sss_sdnet_tuples.sume_tuple_expect['send_dig_to_cpu'] = 1
        sss_sdnet_tuples.dig_tuple_expect['src_port'] = src_port
        sss_sdnet_tuples.dig_tuple_expect['eth_src_addr'] = eth_src_addr 
    else:
        sss_sdnet_tuples.sume_tuple_expect['send_dig_to_cpu'] = 0
        sss_sdnet_tuples.dig_tuple_expect['src_port'] = 0
        sss_sdnet_tuples.dig_tuple_expect['eth_src_addr'] = 0

    sss_sdnet_tuples.write_tuples()

def write_pcap_files():
    wrpcap("src.pcap", pktsApplied)
    wrpcap("dst.pcap", pktsExpected)

    for i in nf_applied.keys():
        if (len(nf_applied[i]) > 0):
            wrpcap('nf{0}_applied.pcap'.format(i), nf_applied[i])

    for i in nf_expected.keys():
        if (len(nf_expected[i]) > 0):
            wrpcap('nf{0}_expected.pcap'.format(i), nf_expected[i])

    for i in nf_applied.keys():
        print "nf{0}_applied times: ".format(i), [p.time for p in nf_applied[i]]

    if (len(dma0_expected) > 0):
        wrpcap('dma0_expected.pcap', dma0_expected)


src_pkts = []
dst_pkts = []
# create some packets that are known and some that are unknown
for i in range(20):
    src_known = bool(random.getrandbits(1))
    dst_known = bool(random.getrandbits(1))
    src_ind = random.randint(0,3)
    dst_ind = random.randint(0,3)

    # pick src MAC
    if src_known:
        src_MAC = ETH_KNOWN[src_ind]
    else:
        src_MAC = ETH_UNKNOWN[src_ind]

    # pick dst MAC
    if dst_known:
        dst_MAC = ETH_KNOWN[dst_ind]
    else:
        dst_MAC = ETH_UNKNOWN[dst_ind]

    pkt = Ether(src=src_MAC, dst=dst_MAC) / IP(src=IPv4_ADDR[src_ind], dst=IPv4_ADDR[dst_ind]) / TCP()
    pkt = pad_pkt(pkt, 64)
    applyPkt(pkt, src_ind)
    expPkt(pkt, src_ind, dst_ind, src_known, dst_known)    

write_pcap_files()


