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

#ifndef _MTPSA_USER_SWITCH_P4_
#define _MTPSA_USER_SWITCH_P4_

#include <core.p4>

// one-hot encoded: {DMA, NF3, DMA, NF2, DMA, NF1, DMA, NF0}
typedef bit<8> port_t;

/* Standard metadata */
struct mtpsa_metadata_t {
    bit<16> dma_q_size; // measured in 32-byte words
    bit<16> nf3_q_size; // measured in 32-byte words
    bit<16> nf2_q_size; // measured in 32-byte words
    bit<16> nf1_q_size; // measured in 32-byte words
    bit<16> nf0_q_size; // measured in 32-byte words
    bit<8> send_dig_to_cpu; // send digest_data to CPU
    bit<8> drop;
    port_t dst_port; // one-hot encoded: {DMA, NF3, DMA, NF2, DMA, NF1, DMA, NF0}
    port_t src_port; // one-hot encoded: {DMA, NF3, DMA, NF2, DMA, NF1, DMA, NF0}
    bit<16> pkt_len; // unsigned int
}

/**
 * Parser
 *
 * @param b: Input packet
 * @param <H>: Type of headers
 * @param parsedHeaders: Extracted packet header data
 * @param <M>: Type of metadata
 * @param user_metadata: User metadata constructed by parser
 * @param <D>: Type of checksum
 * @param digest_data: Packet checksum
 * @param mtpsa_metadata: Standard metadata
 */
parser Parser<H, M, D>(packet_in b,
                       out H parsedHeaders,
                       out M user_metadata,
                       out D digest_data,
                       inout mtpsa_metadata_t mtpsa_metadata);

/**
 * Match-action pipeline
 *
 * @param <H>: type of input and output headers
 * @param parsedHeaders: Packet headers (received from parser/sent to deparser)
 * @param <M>: Type of input and output user metadata
 * @param user_metadata: User metadata
 * @param <D>: Type of checksum
 * @param digest_data: Packet checksum
 * @param mtpsa_metadata: Standard metadata
 */
control Pipe<H, M, D>(inout H parsedHeaders,
                      inout M user_metadata,
                      inout D digest_data,
                      inout mtpsa_metadata_t mtpsa_metadata);

/**
 * Deparser
 *
 * @param b: Output packet
 * @param <H> type of headers
 * @param parsedHeaders: Packet headers data
 * @param <M> type of metadata
 * @param user_metadata: User metadata
 * @param mtpsa_metadata: Standard metadata
 */
control Deparser<H, M, D>(packet_out b,
                          in H parsedHeaders,
                          in M user_metadata,
                          inout D digest_data,
                          inout mtpsa_metadata_t mtpsa_metadata);

/**
 * Top-level package declaration - must be instantiated by user.
 * The arguments to the package indicate blocks that
 * must be instantiated by the user.
 * @param <H> user-defined type of the headers processed.
 */
package SimpleSumeSwitch<H, M, D>(Parser<H, M, D> p,
                                  Pipe<H, M, D> map,
                                  Deparser<H, M, D> d);

#endif  /* _MTPSA_USER_SWITCH_P4_ */
