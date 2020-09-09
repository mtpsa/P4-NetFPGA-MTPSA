#include <mtpsa_user.p4>

typedef bit<48> EthernetAddress;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16> type;
}

struct Parsed_packet {
    Ethernet_h ethernet;
}

struct user_metadata_t {
    bit<8>  unused;
}

struct digest_data_t {
    bit<256>  unused;
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
        transition accept;
    }
}

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout mtpsa_metadata_t mtpsa_metadata) {

    action set_output_port(bit<8> port) {
        mtpsa_metadata.dst_port = port;
    }

    table forward {
        actions = {
            set_output_port;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 64;
    }

    apply {
        if (hdr.ethernet.isValid()) {
            forward.apply();
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
    }
}

SimpleSumeSwitch( TopParser(), TopPipe(), TopDeparser() ) main;
