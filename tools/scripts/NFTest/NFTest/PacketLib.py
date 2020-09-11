#!/usr/bin/env python

#
# Copyright (c) 2015 University of Cambridge
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

import sys
import os
from random import randint
from random import seed

try:
    import scapy.all as scapy
except:
    try:
        import scapy as scapy
    except:
        sys.exit("Error: Need to install scapy for packet handling")

############################
# Function: make_MAC_hdr
# Keyword Arguments: src_MAC, dst_MAC, EtherType
# Description: creates and returns a scapy Ether layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_MAC_hdr(src_MAC = None, dst_MAC = None, EtherType = None, **kwargs):
    hdr = scapy.Ether()
    if src_MAC:
        hdr.src = src_MAC
    if dst_MAC:
        hdr.dst = dst_MAC
    if EtherType:
        hdr.type = EtherType
    return hdr

############################
# Function: make_IP_hdr
# Keyword Arguments: src_IP, dst_IP, TTL
# Description: creates and returns a scapy Ether layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_IP_hdr(src_IP = None, dst_IP = None, TTL = None, **kwargs):
    hdr = scapy.IP()
    if src_IP:
        hdr[scapy.IP].src = src_IP
    if dst_IP:
        hdr[scapy.IP].dst = dst_IP
    if TTL:
        hdr[scapy.IP].ttl = TTL
    return hdr

############################
# Function: make_ARP_hdr
# Keyword Arguments: src_IP, dst_IP, TTL
# Description: creates and returns a scapy ARP layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_ARP_hdr(op = None, src_MAC = None, dst_MAC = None, src_IP = None, dst_IP = None, **kwargs):
    hdr = scapy.ARP()
    if op:
        hdr.op = op
    if src_MAC:
        hdr.hwsrc = src_MAC
    if dst_MAC:
        hdr.hwdst = dst_MAC
    if src_IP:
        hdr.psrc = src_IP
    if dst_IP:
        hdr.pdst = dst_IP
    return hdr

############################
# Function: make_IP_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
#                    pkt_len
# Description: creates and returns a complete IP packet of length pkt_len
############################
def make_IP_pkt(pkt_len = 60, **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/generate_load(pkt_len - 34)
    return pkt

############################
# Function: make_ICMP_reply_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_reply_pkt(data = None, **kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type="echo-reply")
    if data:
        pkt = pkt/data
    else:
        pkt = pkt/("\x00"*56)
    return pkt

############################
# Function: make_ICMP_request_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP request packet
############################
def make_ICMP_request_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type="echo-request")/("\x00"*56)
    return pkt

############################
# Function: make_ICMP_ttl_exceed_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_ttl_exceed_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type=11, code=0)
    return pkt

############################
# Function: make_ICMP_host_unreach_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_host_unreach_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type=3, code=0)
    return pkt

############################
# Function: make_ARP_request_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP
# Description: creates and returns a complete ICMP reply packet
############################
def make_ARP_request_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_ARP_hdr(op="who-has", **kwargs)/("\x00"*18)
    return pkt

############################
# Function: make_ARP_reply_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#
# Description: creates and returns a complete ARP reply packet
############################
def make_ARP_reply_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_ARP_hdr(op="is-at", **kwargs)/("\x00"*18)
    return pkt

############################
# Function: generate_load
# Keyword Arguments: length
# Description: creates and returns a payload of the specified length
############################
def generate_load(length):
    load = ''
    for i in range(length):
        load += chr(randint(0,255))
    return load

############################
# Function: set_seed
# Description: sets the seed for the random number generator if specified
#              enables reproducibility in tests
############################
def set_seed():
    global SEED
    if '--seed' in sys.argv:
            SEED = int(sys.argv[sys.argv.index('--seed')+1])
    else:
        SEED = hash(os.urandom(32))
    seed(SEED)

############################
# Function: print_seed
# Description: returns the seed used by the random number generator
############################
def print_seed():
    f = open('./seed', 'w')
    f.write(str(SEED))
    f.close()

set_seed()
print_seed()
