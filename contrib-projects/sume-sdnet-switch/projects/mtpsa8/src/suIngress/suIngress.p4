//
// Copyright (c) 2020 -
// All rights reserved.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//

#include <mtpsa.p4>

typedef bit<48> EthernetAddress;

const bit<16> ETHERTYPE_IP4 = 0x0800;
const bit<8> PROTO_TCP = 6;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16> type;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header tcp_t {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

struct Parsed_packet {
    Ethernet_h ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
}

struct digest_data_t {
    bit<256> unused;
}

struct user_metadata_t {
    bit<8>  unused;
}

@Xilinx_MaxPacketRegion(16384)
    parser TopParser(packet_in packet,
                     out Parsed_packet hdr,
                     out user_metadata_t user_metadata,
                     out digest_data_t digest_data,
                     inout mtpsa_metadata_t mtpsa_metadata) {
        state start {
            user_metadata.unused = 0;
            digest_data.unused = 0;
            transition parse_ethernet;
        }

        state parse_ethernet {
            packet.extract(hdr.ethernet);
            transition select(hdr.ethernet.type) {
                 ETHERTYPE_IP4: parse_ipv4;
                 default: accept;
            }
        }

        state parse_ipv4 {
            packet.extract(hdr.ipv4);
            transition select(hdr.ipv4.protocol) {
                PROTO_TCP:  parse_tcp;
                default: accept;
            }
        }

        state parse_tcp {
            packet.extract(hdr.tcp);
            transition accept;
        }
    }

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout mtpsa_metadata_t mtpsa_metadata)
{
    action set_user_id(bit<8> id) {
        mtpsa_metadata.user_id = id;
    }

    table users_table {
        key = { hdr.tcp.sport: exact; }
        actions = {
            set_user_id;
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

    apply {
        mtpsa_metadata.user_id = 0;
        if (hdr.tcp.isValid()) {
            users_table.apply();
        }
    }
}

@Xilinx_MaxPacketRegion(16384)
    control TopDeparser(packet_out packet,
                        in Parsed_packet hdr,
                        in user_metadata_t user_metadata,
                        inout digest_data_t digest_data,
                        inout mtpsa_metadata_t mtpsa_metadata) {
        apply {
            packet.emit(hdr.ethernet);
            packet.emit(hdr.ipv4);
            packet.emit(hdr.tcp);
        }
    }

SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;
