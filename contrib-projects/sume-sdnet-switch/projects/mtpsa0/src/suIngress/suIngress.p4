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

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16> type;
}

struct Parsed_packet {
    Ethernet_h ethernet;
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
        packet.extract(hdr.ethernet);
        user_metadata.unused = 0;
        digest_data.unused = 0;
	transition  accept;
    }
}

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout mtpsa_metadata_t mtpsa_metadata)
{
    action set_output_port(port_t port) {
        mtpsa_metadata.dst_port = port;
    }

    table forward {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = {
            set_output_port;
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

   apply {
        forward.apply();
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
    }
}

SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;
