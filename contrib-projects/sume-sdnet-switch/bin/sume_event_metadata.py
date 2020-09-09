#!/usr/bin/env python

#
# Copyright (c) 2019 Stephen Ibanez
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
Define the sume_metadata bus for SDNet simulations
"""

import collections

""" SUME Tuple format:
   unused             (5 bits)
   gen_packet         (1 bit)
   link_trigger       (1 bit)
   timer_trigger      (1 bit)
   drop_trigger       (1 bit)
   deq_trigger        (1 bit)
   enq_trigger        (1 bit)
   pkt_trigger        (1 bit)
   link_status        (4 bits)
   timer_now          (48 bits)
   timer_period       (32 bits)
   drop_port          (8 bits)
   deq_port           (8 bits)
   enq_port           (8 bits)
   drop_data          (32 bits)
   deq_data           (32 bits) 
   enq_data           (32 bits) 
   dst_port;          (8 bits) 
   src_port;          (8 bits) 
   pkt_len;           (16 bits)
"""

sume_field_len = collections.OrderedDict()
sume_field_len['unused']         = 5
sume_field_len['gen_packet']     = 1
sume_field_len['link_trigger']   = 1
sume_field_len['timer_trigger']  = 1
sume_field_len['drop_trigger']   = 1
sume_field_len['deq_trigger']    = 1
sume_field_len['enq_trigger']    = 1
sume_field_len['pkt_trigger']    = 1
sume_field_len['link_status']    = 4
sume_field_len['timer_now']      = 48
sume_field_len['timer_period']   = 32
sume_field_len['drop_port']      = 8
sume_field_len['deq_port']       = 8
sume_field_len['enq_port']       = 8
sume_field_len['drop_data']      = 32
sume_field_len['deq_data']       = 32
sume_field_len['enq_data']       = 32
sume_field_len['dst_port']       = 8
sume_field_len['src_port']       = 8
sume_field_len['pkt_len']        = 16

# initialize tuple_in
sume_tuple_in = collections.OrderedDict()
sume_tuple_in['unused']         = 0
sume_tuple_in['gen_packet']     = 0
sume_tuple_in['link_trigger']   = 0
sume_tuple_in['timer_trigger']  = 0
sume_tuple_in['drop_trigger']   = 0
sume_tuple_in['deq_trigger']    = 0
sume_tuple_in['enq_trigger']    = 0
sume_tuple_in['pkt_trigger']    = 0
sume_tuple_in['link_status']    = 0
sume_tuple_in['timer_now']      = 0
sume_tuple_in['timer_period']   = 0
sume_tuple_in['drop_port']      = 0
sume_tuple_in['deq_port']       = 0
sume_tuple_in['enq_port']       = 0
sume_tuple_in['drop_data']      = 0
sume_tuple_in['deq_data']       = 0
sume_tuple_in['enq_data']       = 0
sume_tuple_in['dst_port']       = 0
sume_tuple_in['src_port']       = 0
sume_tuple_in['pkt_len']        = 0

# initialize tuple_expect
sume_tuple_expect = collections.OrderedDict()
sume_tuple_expect['unused']         = 0
sume_tuple_expect['gen_packet']     = 0
sume_tuple_expect['link_trigger']   = 0
sume_tuple_expect['timer_trigger']  = 0
sume_tuple_expect['drop_trigger']   = 0
sume_tuple_expect['deq_trigger']    = 0
sume_tuple_expect['enq_trigger']    = 0
sume_tuple_expect['pkt_trigger']    = 0
sume_tuple_expect['link_status']    = 0
sume_tuple_expect['timer_now']      = 0
sume_tuple_expect['timer_period']   = 0
sume_tuple_expect['drop_port']      = 0
sume_tuple_expect['deq_port']       = 0
sume_tuple_expect['enq_port']       = 0
sume_tuple_expect['drop_data']      = 0
sume_tuple_expect['deq_data']       = 0
sume_tuple_expect['enq_data']       = 0
sume_tuple_expect['dst_port']       = 0
sume_tuple_expect['src_port']       = 0
sume_tuple_expect['pkt_len']        = 0

