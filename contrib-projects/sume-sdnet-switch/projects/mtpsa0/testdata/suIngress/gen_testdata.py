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


import sys
import random
from collections import OrderedDict

from nf_sim_tools import *
from scapy.all import *

import mtpsa_metadata

tuple_in_file = "Tuple_in.txt"
tuple_expect_file = "Tuple_expect.txt"

dig_field_len = OrderedDict()
dig_field_len['unused'] = 256

dig_tuple_expect = OrderedDict()
dig_tuple_expect['unused'] = 0


class Digest_data(Packet):
    name = "Digest_data"
    fields_desc = [
        ByteField("src_port", 0),
        LELongField("eth_src_addr", 0),
        LELongField("unused1", 0),
        LELongField("unused2", 0),
        LEIntField("unused3", 0),
        X3BytesField("unused4", 0)
    ]
    def mysummary(self):
        return self.sprintf("src_port=%op1% eth_src_addr=%eth_src_addr% unused=%unused%")

def clear_tuple_files():
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
        for field_name, value in mtpsa_metadata.mtpsa_tuple_in.iteritems():
            bin_val = get_bin_val(field_name, value, mtpsa_metadata.mtpsa_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + '\n')

    with open("Tuple_expect.txt", "a") as f:
        tup_bin_string = ''
        for field_name, value in dig_tuple_expect.iteritems():
            bin_val = get_bin_val(field_name, value, dig_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + ' ')

        tup_bin_string = ''
        for field_name, value in mtpsa_metadata.mtpsa_tuple_expect.iteritems():
            bin_val = get_bin_val(field_name, value, mtpsa_metadata.mtpsa_field_len)
            tup_bin_string += bin_val
        f.write(bin_to_hex(tup_bin_string) + '\n')

def find_tup_len(field_len_dic):
    num_bits = 0
    for length in field_len_dic.values():
        num_bits += length
    return num_bits

def hex_to_bin(hex_string, length):
    """
    Given a hex string, convert it to a binary string
    """
    fmat_string = '{0:0%db}' % length
    bin_string = fmat_string.format(int(hex_string, 16))
    return bin_string

def check_length(bin_string, field_len_dic):
    num_bits = find_tup_len(field_len_dic)
    try:
        assert(len(bin_string) == num_bits)
    except:
        print('ERROR: unexpected input')
        print('len(bin_string) = ', len(bin_string))
        print('num_bits = ', num_bits)
        sys.exit(1)

def parse_tup_string(tup_string, field_len_dic):
    """
    Given hex string representation of a tuple, return the parsed version of it
    """
    tup_len = find_tup_len(field_len_dic)
    bin_string = hex_to_bin(tup_string, tup_len)
    check_length(bin_string, field_len_dic)
    tup = OrderedDict()
    i = 0
    for (field,length) in field_len_dic.iteritems():
        tup[field] = int(bin_string[i:i+length], 2)
        i += length
    return tup

def parse_line(line, tuple_type):
    if tuple_type == 'mtpsa':
        field_len = mtpsa_metadata.mtpsa_field_len
    elif tuple_type == 'digest':
        field_len = dig_field_len
    else:
        print("ERROR: unsupported tuple_type, must one of: [mtpsa, digest]")
        sys.exit(1)

    tup_string = line.strip()
    tup = parse_tup_string(tup_string, field_len)
    print("Parsed Tuple:\n", '-----------------------')
    for (key, val) in tup.items():
        if (key in ['src_port', 'dst_port']):
            print ("{} = {0:08b}".format(key, val))
        else:
            print ("{} = {}".format(key, val))

ETH_KNOWN = [
    "08:11:11:11:11:08",
    "08:22:22:22:22:08",
    "08:33:33:33:33:08",
    "08:44:44:44:44:08",
]

IPv4_ADDR = [
    "192.168.10.1",
    "192.168.10.2",
    "192.168.10.3",
    "192.168.10.4",
]

portMap = {0 : 0b00000001, 1 : 0b00000100, 2 : 0b00010000, 3 : 0b01000000}
bcast_portMap = {0 : 0b01010100, 1 : 0b01010001, 2 : 0b01000101, 3 : 0b00010101}

clear_tuple_files()

pkt_num = 0
pktsApplied = []
pktsExpected = []


class DefaultListOrderedDict(OrderedDict):
    def __missing__(self,k):
        self[k] = []
        return self[k]

nf_applied = DefaultListOrderedDict()
nf_expected = DefaultListOrderedDict()

dma0_expected = []

def applyPkt(pkt, src_ind):
    global pkt_num
    pktsApplied.append(pkt)
    mtpsa_metadata.mtpsa_tuple_in['src_port'] = portMap[src_ind]
    mtpsa_metadata.mtpsa_tuple_expect['src_port'] = portMap[src_ind]
    pkt.time = pkt_num
    nf_applied[src_ind].append(pkt)
    pkt_num += 1

def expPkt(pkt, src_ind, dst_ind):
    pktsExpected.append(pkt)
    mtpsa_metadata.mtpsa_tuple_expect['dst_port'] = portMap[dst_ind]
    nf_expected[dst_ind].append(pkt)
    write_tuples()


def write_pcap_files():
    wrpcap("src.pcap", pktsApplied)
    wrpcap("dst.pcap", pktsExpected)

    for i in nf_applied.keys():
        if len(nf_applied[i]) > 0:
            wrpcap('nf{0}_applied.pcap'.format(i), nf_applied[i])

    for i in nf_expected.keys():
        if len(nf_expected[i]) > 0:
            wrpcap('nf{0}_expected.pcap'.format(i), nf_expected[i])

    for i in nf_applied.keys():
        print "nf{0}_applied times: ".format(i), [p.time for p in nf_applied[i]]

    if len(dma0_expected) > 0:
        wrpcap('dma0_expected.pcap', dma0_expected)

if __name__ == "__main__":
    src_pkts = []
    dst_pkts = []

    bind_layers(Digest_data, Raw)

    for i in range(20):
        src_ind = random.randint(0,3)
        dst_ind = random.randint(0,3)

        src_MAC = ETH_KNOWN[src_ind]
        dst_MAC = ETH_KNOWN[dst_ind]

        pkt = Ether(src=src_MAC, dst=dst_MAC) / IP(src=IPv4_ADDR[src_ind], dst=IPv4_ADDR[dst_ind]) / TCP()
        pkt = pad_pkt(pkt, 64)
        applyPkt(pkt, src_ind)
        expPkt(pkt, src_ind, dst_ind)

    write_pcap_files()
