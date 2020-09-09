//
// Copyright (c) 2017 Stephen Ibanez
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
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


#include <core.p4>
#include <sume_switch.p4>

/* This program processes Ethernet packets,
 * performing forwarding based on the destination Ethernet Address
 *
 * This version uses the digest_metadata bus rather than sending the 
 * whole packet
 */
typedef bit<48> EthernetAddress; 

// standard Ethernet header
header Ethernet_h { 
    EthernetAddress dstAddr; 
    EthernetAddress srcAddr; 
    bit<16> etherType;
}


// List of all recognized headers
struct Parsed_packet { 
    Ethernet_h ethernet; 
}

// digest data to send to cpu if desired
struct digest_data_t {
    bit<184> unused;
    bit<64> eth_src_addr;  // 64 bits so we can use the LELongField type for scapy
    port_t src_port;
}

// user defined metadata: can be used to share information between
// TopParser, TopPipe, and TopDeparser 
struct user_metadata_t {
    bit<8>  unused;
}

// Parser Implementation
@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in b, 
                 out Parsed_packet p, 
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        b.extract(p.ethernet);
        user_metadata.unused = 0;
        digest_data.src_port = 0;
        digest_data.eth_src_addr = 0;
        digest_data.unused = 0;
        transition accept;
    }
}

// match-action pipeline
control TopPipe(inout Parsed_packet headers,
                inout user_metadata_t user_metadata, 
                inout digest_data_t digest_data, 
                inout sume_metadata_t sume_metadata) {

    action set_output_port(port_t port) {
        sume_metadata.dst_port = port;
    }

    table forward {
        key = { headers.ethernet.dstAddr: exact; }

        actions = {
            set_output_port;
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

    action set_broadcast(port_t port) {
        sume_metadata.dst_port = port;
    }

    table broadcast {
        key = { sume_metadata.src_port: exact; }

        actions = {
            set_broadcast;
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

    table smac {
        key = { headers.ethernet.srcAddr: exact; }

        actions = {
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

    action send_to_control() {
        digest_data.src_port = sume_metadata.src_port;
        digest_data.eth_src_addr = 16w0 ++ headers.ethernet.srcAddr;
        sume_metadata.send_dig_to_cpu = 1;
    }

    apply {
        // try to forward based on destination Ethernet address
        if (!forward.apply().hit) {
            // miss in forwarding table
            broadcast.apply();
        }

        // check if src Ethernet address is in the forwarding database
        if (!smac.apply().hit) {
            // unknown source MAC address
            send_to_control();
        }
    }
}

// Deparser Implementation
@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) { 
    apply {
        b.emit(p.ethernet); 
    }
}


// Instantiate the switch
SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;

