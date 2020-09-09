#!/usr/bin/env python

#
# Copyright (c) 2020 -
# All rights reserved.
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


import argparse
import collections
import random
import sys

from nf_sim_tools import *
import mtpsa_user_metadata

tuple_in_file = "Tuple_in.txt"
tuple_expect_file = "Tuple_expect.txt"

dig_field_len = collections.OrderedDict()
dig_field_len['unused'] = 256

dig_tuple_expect = collections.OrderedDict()
dig_tuple_expect['unused'] = 0

def clear_tuple_files():
    """
    Clear the tuple files
    """
    with open(tuple_in_file, "w") as f:
        f.write("")

    with open(tuple_expect_file, "w") as f:
        f.write("")


def get_bin_val(field_name, value, field_len_dic):
    """
    Return a binary string with length = field_len_dic[field_name]
    """
    format_string = "{0:0%db}" % field_len_dic[field_name]
    bin_string = format_string.format(value)
    return bin_string

def bin_to_hex(bin_string):
    """
    Given a binary string, return the hex version
    """
    hex_string = ''
    assert(len(bin_string) % 4 == 0)
    for i in range(0,len(bin_string),4):
        hex_string += "{0:1x}".format(int(bin_string[i:i+4], 2))
    return hex_string

def write_tuples():
    """
    Write the next line of the Tuple_in.txt and Tuple_expect.txt
    """
    with open("Tuple_in.txt", "a") as f:
        tup_bin_string = ''
        for field_name, value in mtpsa_user_metadata.mtpsa_tuple_in.iteritems():
            bin_val = get_bin_val(field_name, value, mtpsa_user_metadata.mtpsa_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + '\n')

    with open("Tuple_expect.txt", "a") as f:
        tup_bin_string = ''
        for field_name, value in dig_tuple_expect.iteritems():
            bin_val = get_bin_val(field_name, value, dig_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + ' ')

        tup_bin_string = ''
        for field_name, value in mtpsa_user_metadata.mtpsa_tuple_expect.iteritems():
            bin_val = get_bin_val(field_name, value, mtpsa_user_metadata.mtpsa_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + '\n')

DEF_PKT_SIZE = 256  # default packet size (in bytes)
HEADER_SIZE = 46    # headers size: Ether/IP/UDP
DEF_PKT_NUM = 24    # default packets number to simulation
DEF_HOST_NUM = 4    # default hosts number in network topology
src_host = 0        # packets sender host
vlan_id = 0         # vlan identifier to matching with IPI architecture and nf_datapath.v
vlan_prio = 0       # vlan priority

dst_host_map = {0:1, 1:0, 2:3, 3:2}                   # map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}  # map the keys of dictionary nf_id_map
vlan_id_map = {"l2_switch1":1, "l2_switch2":2}        # map the vlans of parrallel switches

port_slicing = {}                                     # map the slicing of ports of SUME nf[0, 1, 2, 3] based in network topology
port_slicing[0] = "l2_switch1"
port_slicing[1] = "l2_switch1"
port_slicing[2] = "l2_switch2"
port_slicing[3] = "l2_switch2"

########################
# pkt generation tools #
########################

pktsApplied = []
pktsExpected = []

# Pkt lists for SUME simulations
nf_applied = collections.OrderedDict()
nf_applied[0] = []
nf_applied[1] = []
nf_applied[2] = []
nf_applied[3] = []
nf_expected = collections.OrderedDict()
nf_expected[0] = []
nf_expected[1] = []
nf_expected[2] = []
nf_expected[3] = []

nf_port_map = {"nf0":0b00000001, "nf1":0b00000100, "nf2":0b00010000, "nf3":0b01000000, "none":0b00000000}
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}

clear_tuple_files()

def applyPkt(pkt, ingress, time):
    pktsApplied.append(pkt)
    mtpsa_user_metadata.mtpsa_tuple_in['pkt_len'] = len(pkt)
    mtpsa_user_metadata.mtpsa_tuple_in['src_port'] = nf_port_map[ingress]
    mtpsa_user_metadata.mtpsa_tuple_expect['pkt_len'] = len(pkt)
    mtpsa_user_metadata.mtpsa_tuple_expect['src_port'] = nf_port_map[ingress]
    pkt.time = time
    nf_applied[nf_id_map[ingress]].append(pkt)

def expPkt(pkt, egress, drop):
    pktsExpected.append(pkt)
    mtpsa_user_metadata.mtpsa_tuple_expect['dst_port'] = nf_port_map[egress]
    mtpsa_user_metadata.mtpsa_tuple_expect['drop'] = drop
    write_tuples()
    if egress in ["nf0","nf1","nf2","nf3"] and drop == False:
        nf_expected[nf_id_map[egress]].append(pkt)
    elif egress == 'bcast' and drop == False:
        nf_expected[0].append(pkt)
        nf_expected[1].append(pkt)
        nf_expected[2].append(pkt)
        nf_expected[3].append(pkt)

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

#####################
# generate testdata #
#####################

MAC_addr_H = {}
MAC_addr_H[nf_id_map["nf0"]] = "08:11:11:11:11:08"
MAC_addr_H[nf_id_map["nf1"]] = "08:22:22:22:22:08"
MAC_addr_H[nf_id_map["nf2"]] = "08:33:33:33:33:08"
MAC_addr_H[nf_id_map["nf3"]] = "08:44:44:44:44:08"

IP_addr_H = {}
IP_addr_H[nf_id_map["nf0"]] = "10.1.1.1"
IP_addr_H[nf_id_map["nf1"]] = "10.2.2.2"
IP_addr_H[nf_id_map["nf2"]] = "10.3.3.3"
IP_addr_H[nf_id_map["nf3"]] = "10.4.4.4"

MAC_addr_S = {}
MAC_addr_S[nf_id_map["nf0"]] = "05:11:11:11:11:05"
MAC_addr_S[nf_id_map["nf1"]] = "05:22:22:22:22:05"
MAC_addr_S[nf_id_map["nf2"]] = "05:33:33:33:33:05"
MAC_addr_S[nf_id_map["nf3"]] = "05:44:44:44:44:05"


def get_rand_port():
    return random.randint(1, 0xffff)

sport = get_rand_port()
dport = get_rand_port()

# create some packets
for time in range(DEF_PKT_NUM):
    vlan_id = vlan_id_map[port_slicing[src_host]]
    src_IP = IP_addr_H[src_host]
    dst_IP = IP_addr_H[dst_host_map[src_host]]

    if ( vlan_id == vlan_id_map["l2_switch1"] ):
        src_MAC = MAC_addr_H[src_host]
        dst_MAC = MAC_addr_H[dst_host_map[src_host]]
        pkt_exp = pkt_app = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / UDP(sport=sport, dport=dport) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
    elif( vlan_id == vlan_id_map["l2_switch2"] ):
        src_MAC = MAC_addr_H[src_host]
        dst_MAC = MAC_addr_H[dst_host_map[src_host]]
        pkt_exp = pkt_app = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / UDP(sport=sport, dport=dport) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
    else:
        print("\nERROR: vlan_id not mapped!\n")
        exit(1)

    pkt_app = pad_pkt(pkt_app, DEF_PKT_SIZE)
    ingress = inv_nf_id_map[src_host]
    applyPkt(pkt_app, ingress, time)
    pkt_exp = pad_pkt(pkt_exp, DEF_PKT_SIZE)
    egress = inv_nf_id_map[dst_host_map[src_host]]
    drop = False
    expPkt(pkt_exp, egress, drop)

    src_host += 1
    vlan_prio += 1
    if ( src_host > (DEF_HOST_NUM-1) ):
        src_host = 0
        vlan_prio = 0

write_pcap_files()
