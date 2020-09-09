#!/usr/bin/env python

"""
Define the mtpsa_metadata bus for SDNet simulations
"""

import collections

""" SDNet Tuple format:
   dma_queue_size;    (16 bits)
   nf3_queue_size;    (16 bits)
   nf2_queue_size;    (16 bits)
   nf1_queue_size;    (16 bits)
   nf0_queue_size;    (16 bits)
   send_dig_to_cpu;   (8 bits)
   drop;              (8 bits)
   dst_port;          (8 bits)
   src_port;          (8 bits)
   pkt_len;           (16 bits)
"""

mtpsa_field_len = collections.OrderedDict()
mtpsa_field_len['dma_q_size'] = 16
mtpsa_field_len['nf3_q_size'] = 16
mtpsa_field_len['nf2_q_size'] = 16
mtpsa_field_len['nf1_q_size'] = 16
mtpsa_field_len['nf0_q_size'] = 16
mtpsa_field_len['send_dig_to_cpu'] = 8
mtpsa_field_len['drop'] = 8
mtpsa_field_len['dst_port'] = 8
mtpsa_field_len['src_port'] = 8
mtpsa_field_len['pkt_len'] = 16

# initialize tuple_in
mtpsa_tuple_in = collections.OrderedDict()
mtpsa_tuple_in['dma_q_size'] = 0
mtpsa_tuple_in['nf3_q_size'] = 0
mtpsa_tuple_in['nf2_q_size'] = 0
mtpsa_tuple_in['nf1_q_size'] = 0
mtpsa_tuple_in['nf0_q_size'] = 0
mtpsa_tuple_in['send_dig_to_cpu'] = 0
mtpsa_tuple_in['drop'] = 0
mtpsa_tuple_in['dst_port'] = 0
mtpsa_tuple_in['src_port'] = 0
mtpsa_tuple_in['pkt_len'] = 0

#initialize tuple_expect
mtpsa_tuple_expect = collections.OrderedDict()
mtpsa_tuple_expect['dma_q_size'] = 0
mtpsa_tuple_expect['nf3_q_size'] = 0
mtpsa_tuple_expect['nf2_q_size'] = 0
mtpsa_tuple_expect['nf1_q_size'] = 0
mtpsa_tuple_expect['nf0_q_size'] = 0
mtpsa_tuple_expect['send_dig_to_cpu'] = 0
mtpsa_tuple_expect['drop'] = 0
mtpsa_tuple_expect['dst_port'] = 0
mtpsa_tuple_expect['src_port'] = 0
mtpsa_tuple_expect['pkt_len'] = 0

