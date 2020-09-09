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

`timescale 1ns / 1ps

module nf_datapath #(
    //Slave AXI parameters
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 32,
    parameter C_BASEADDR            = 32'h00000000,

    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=5,
    parameter DIGEST_WIDTH=80
)
(
    //Datapath clock
    input                                     axis_aclk,
    input                                     axis_resetn,

    //Registers clock
    input                                     axi_aclk,
    input                                     axi_resetn,

    // Slave AXI Ports
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_AWADDR,
    input                                     S0_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S0_AXI_WSTRB,
    input                                     S0_AXI_WVALID,
    input                                     S0_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_ARADDR,
    input                                     S0_AXI_ARVALID,
    input                                     S0_AXI_RREADY,
    output                                    S0_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_RDATA,
    output     [1 : 0]                        S0_AXI_RRESP,
    output                                    S0_AXI_RVALID,
    output                                    S0_AXI_WREADY,
    output     [1 :0]                         S0_AXI_BRESP,
    output                                    S0_AXI_BVALID,
    output                                    S0_AXI_AWREADY,

    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_AWADDR,
    input                                     S1_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S1_AXI_WSTRB,
    input                                     S1_AXI_WVALID,
    input                                     S1_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_ARADDR,
    input                                     S1_AXI_ARVALID,
    input                                     S1_AXI_RREADY,
    output                                    S1_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_RDATA,
    output     [1 : 0]                        S1_AXI_RRESP,
    output                                    S1_AXI_RVALID,
    output                                    S1_AXI_WREADY,
    output     [1 :0]                         S1_AXI_BRESP,
    output                                    S1_AXI_BVALID,
    output                                    S1_AXI_AWREADY,

    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_AWADDR,
    input                                     S2_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S2_AXI_WSTRB,
    input                                     S2_AXI_WVALID,
    input                                     S2_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_ARADDR,
    input                                     S2_AXI_ARVALID,
    input                                     S2_AXI_RREADY,
    output                                    S2_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_RDATA,
    output     [1 : 0]                        S2_AXI_RRESP,
    output                                    S2_AXI_RVALID,
    output                                    S2_AXI_WREADY,
    output     [1 :0]                         S2_AXI_BRESP,
    output                                    S2_AXI_BVALID,
    output                                    S2_AXI_AWREADY,

    // Slave Stream Ports (interface from Rx queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_0_tuser,
    input                                     s_axis_0_tvalid,
    output                                    s_axis_0_tready,
    input                                     s_axis_0_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_1_tuser,
    input                                     s_axis_1_tvalid,
    output                                    s_axis_1_tready,
    input                                     s_axis_1_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_2_tuser,
    input                                     s_axis_2_tvalid,
    output                                    s_axis_2_tready,
    input                                     s_axis_2_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_3_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_3_tuser,
    input                                     s_axis_3_tvalid,
    output                                    s_axis_3_tready,
    input                                     s_axis_3_tlast,

    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_4_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_4_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_4_tuser,
    input                                     s_axis_4_tvalid,
    output                                    s_axis_4_tready,
    input                                     s_axis_4_tlast,

    // Master Stream Ports (interface to TX queues)
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_tuser,
    output                                     m_axis_0_tvalid,
    input                                      m_axis_0_tready,
    output                                     m_axis_0_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_tuser,
    output                                     m_axis_1_tvalid,
    input                                      m_axis_1_tready,
    output                                     m_axis_1_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_2_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_2_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_2_tuser,
    output                                     m_axis_2_tvalid,
    input                                      m_axis_2_tready,
    output                                     m_axis_2_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_3_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_3_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_3_tuser,
    output                                     m_axis_3_tvalid,
    input                                      m_axis_3_tready,
    output                                     m_axis_3_tlast,

    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_4_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_4_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_4_tuser,
    output                                     m_axis_4_tvalid,
    input                                      m_axis_4_tready,
    output                                     m_axis_4_tlast
);
    localparam C_AXIS_TUSER_DIGEST_WIDTH = 304;

    /* Internal connectivity */

    // Input Arbiter -> Superuser Ingress Pipeline
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_opl_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_opl_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_opl_tuser;
    wire                                     s_axis_opl_tvalid;
    wire                                     s_axis_opl_tready;
    wire                                     s_axis_opl_tlast;

    // Superuser Ingress Pipeline -> Demultiplexer
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_suIngress_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_suIngress_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_suIngress_tuser;
    wire                                     m_axis_suIngress_tvalid;
    wire                                     m_axis_suIngress_tready;
    wire                                     m_axis_suIngress_tlast;

    // Demultiplexer -> User 0
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_demux_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_demux_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_demux_tuser;
    wire                                     m_axis_0_demux_tvalid;
    wire                                     m_axis_0_demux_tready;
    wire                                     m_axis_0_demux_tlast;

    // Demultiplexer -> User 1
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_demux_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_demux_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_demux_tuser;
    wire                                     m_axis_1_demux_tvalid;
    wire                                     m_axis_1_demux_tready;
    wire                                     m_axis_1_demux_tlast;

    // User 0 -> Multiplexer
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_0_mux_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_mux_tkeep;
    wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_0_mux_tuser;
    wire                                     s_axis_0_mux_tvalid;
    wire                                     s_axis_0_mux_tready;
    wire                                     s_axis_0_mux_tlast;

    // User 1 -> Multiplexer
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_1_mux_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_mux_tkeep;
    wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_1_mux_tuser;
    wire                                     s_axis_1_mux_tvalid;
    wire                                     s_axis_1_mux_tready;
    wire                                     s_axis_1_mux_tlast;

    // Multiplexer -> Superuser Egress Pipeline
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_mux_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_mux_tkeep;
    wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_mux_tuser;
    wire                                     m_axis_mux_tvalid;
    wire                                     m_axis_mux_tready;
    wire                                     m_axis_mux_tlast;

    // Superuser Egress Pipeline -> Output Queues
    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_suEgress_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_suEgress_tkeep;
    wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_suEgress_tuser;
    wire                                     m_axis_suEgress_tvalid;
    wire                                     m_axis_suEgress_tready;
    wire                                     m_axis_suEgress_tlast;

    localparam Q_SIZE_WIDTH = 16;
    wire [Q_SIZE_WIDTH-1:0] nf0_q_size;
    wire [Q_SIZE_WIDTH-1:0] nf1_q_size;
    wire [Q_SIZE_WIDTH-1:0] nf2_q_size;
    wire [Q_SIZE_WIDTH-1:0] nf3_q_size;
    wire [Q_SIZE_WIDTH-1:0] dma_q_size;

    // Input Arbiter
    input_arbiter_ip
    input_arbiter_v1_0 (
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),

        .m_axis_tdata (s_axis_opl_tdata),
        .m_axis_tkeep (s_axis_opl_tkeep),
        .m_axis_tuser (s_axis_opl_tuser),
        .m_axis_tvalid(s_axis_opl_tvalid),
        .m_axis_tready(s_axis_opl_tready),
        .m_axis_tlast (s_axis_opl_tlast),

        .s_axis_0_tdata (s_axis_0_tdata),
        .s_axis_0_tkeep (s_axis_0_tkeep),
        .s_axis_0_tuser (s_axis_0_tuser),
        .s_axis_0_tvalid(s_axis_0_tvalid),
        .s_axis_0_tready(s_axis_0_tready),
        .s_axis_0_tlast (s_axis_0_tlast),

        .s_axis_1_tdata (s_axis_1_tdata),
        .s_axis_1_tkeep (s_axis_1_tkeep),
        .s_axis_1_tuser (s_axis_1_tuser),
        .s_axis_1_tvalid(s_axis_1_tvalid),
        .s_axis_1_tready(s_axis_1_tready),
        .s_axis_1_tlast (s_axis_1_tlast),

        .s_axis_2_tdata (s_axis_2_tdata),
        .s_axis_2_tkeep (s_axis_2_tkeep),
        .s_axis_2_tuser (s_axis_2_tuser),
        .s_axis_2_tvalid(s_axis_2_tvalid),
        .s_axis_2_tready(s_axis_2_tready),
        .s_axis_2_tlast (s_axis_2_tlast),

        .s_axis_3_tdata (s_axis_3_tdata),
        .s_axis_3_tkeep (s_axis_3_tkeep),
        .s_axis_3_tuser (s_axis_3_tuser),
        .s_axis_3_tvalid(s_axis_3_tvalid),
        .s_axis_3_tready(s_axis_3_tready),
        .s_axis_3_tlast (s_axis_3_tlast),

        .s_axis_4_tdata (s_axis_4_tdata),
        .s_axis_4_tkeep (s_axis_4_tkeep),
        .s_axis_4_tuser (s_axis_4_tuser),
        .s_axis_4_tvalid(s_axis_4_tvalid),
        .s_axis_4_tready(s_axis_4_tready),
        .s_axis_4_tlast (s_axis_4_tlast),

        .S_AXI_AWADDR   (S0_AXI_AWADDR),
        .S_AXI_AWVALID  (S0_AXI_AWVALID),
        .S_AXI_WDATA    (S0_AXI_WDATA),
        .S_AXI_WSTRB    (S0_AXI_WSTRB),
        .S_AXI_WVALID   (S0_AXI_WVALID),
        .S_AXI_BREADY   (S0_AXI_BREADY),
        .S_AXI_ARADDR   (S0_AXI_ARADDR),
        .S_AXI_ARVALID  (S0_AXI_ARVALID),
        .S_AXI_RREADY   (S0_AXI_RREADY),
        .S_AXI_ARREADY  (S0_AXI_ARREADY),
        .S_AXI_RDATA    (S0_AXI_RDATA),
        .S_AXI_RRESP    (S0_AXI_RRESP),
        .S_AXI_RVALID   (S0_AXI_RVALID),
        .S_AXI_WREADY   (S0_AXI_WREADY),
        .S_AXI_BRESP    (S0_AXI_BRESP),
        .S_AXI_BVALID   (S0_AXI_BVALID),
        .S_AXI_AWREADY  (S0_AXI_AWREADY),

        .S_AXI_ACLK     (axi_aclk),
        .S_AXI_ARESETN  (axi_resetn),
        .pkt_fwd()
    );

    // Superuser Ingress Pipeline
    nf_sdnet_suIngress_ip
    nf_sdnet_suIngress_inst (
        .axis_aclk(axis_aclk),
        .axis_resetn(axis_resetn),

        .m_axis_tdata   (m_axis_suIngress_tdata),
        .m_axis_tkeep   (m_axis_suIngress_tkeep),
        .m_axis_tuser   (m_axis_suIngress_tuser),
        .m_axis_tvalid  (m_axis_suIngress_tvalid),
        .m_axis_tready  (m_axis_suIngress_tready),
        .m_axis_tlast   (m_axis_suIngress_tlast),

        .s_axis_tdata   (s_axis_opl_tdata),
        .s_axis_tkeep   (s_axis_opl_tkeep),
        .s_axis_tuser   ({dma_q_size, nf3_q_size, nf2_q_size, nf1_q_size, nf0_q_size, s_axis_opl_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
        .s_axis_tvalid  (s_axis_opl_tvalid),
        .s_axis_tready  (s_axis_opl_tready),
        .s_axis_tlast   (s_axis_opl_tlast),

        .S_AXI_AWADDR   (S1_AXI_AWADDR),
        .S_AXI_AWVALID  (S1_AXI_AWVALID),
        .S_AXI_WDATA    (S1_AXI_WDATA),
        .S_AXI_WSTRB    (S1_AXI_WSTRB),
        .S_AXI_WVALID   (S1_AXI_WVALID),
        .S_AXI_BREADY   (S1_AXI_BREADY),
        .S_AXI_ARADDR   (S1_AXI_ARADDR),
        .S_AXI_ARVALID  (S1_AXI_ARVALID),
        .S_AXI_RREADY   (S1_AXI_RREADY),
        .S_AXI_ARREADY  (S1_AXI_ARREADY),
        .S_AXI_RDATA    (S1_AXI_RDATA),
        .S_AXI_RRESP    (S1_AXI_RRESP),
        .S_AXI_RVALID   (S1_AXI_RVALID),
        .S_AXI_WREADY   (S1_AXI_WREADY),
        .S_AXI_BRESP    (S1_AXI_BRESP),
        .S_AXI_BVALID   (S1_AXI_BVALID),
        .S_AXI_AWREADY  (S1_AXI_AWREADY),

        .S_AXI_ACLK     (axi_aclk),
        .S_AXI_ARESETN  (axi_resetn)
    );

    // Demultiplexer
    demux
    demux_0 (
      .axis_aclk        (axis_aclk),
      .axis_resetn      (axis_resetn),

      // Master Ports: Users
      .m_axis_0_tdata   (m_axis_0_demux_tdata),
      .m_axis_0_tkeep   (m_axis_0_demux_tkeep),
      .m_axis_0_tuser   (m_axis_0_demux_tuser),
      .m_axis_0_tvalid  (m_axis_0_demux_tvalid),
      .m_axis_0_tlast   (m_axis_0_demux_tlast),
      .m_axis_0_tready  (m_axis_0_demux_tready),

      .m_axis_1_tdata   (m_axis_1_demux_tdata),
      .m_axis_1_tkeep   (m_axis_1_demux_tkeep),
      .m_axis_1_tuser   (m_axis_1_demux_tuser),
      .m_axis_1_tvalid  (m_axis_1_demux_tvalid),
      .m_axis_1_tlast   (m_axis_1_demux_tlast),
      .m_axis_1_tready  (m_axis_1_demux_tready),

      // Slave Ports: Superuser Ingress
      .s_axis_tdata     (m_axis_suIngress_tdata),
      .s_axis_tkeep     (m_axis_suIngress_tkeep),
      .s_axis_tuser     (m_axis_suIngress_tuser),
      .s_axis_tvalid    (m_axis_suIngress_tvalid),
      .s_axis_tready    (m_axis_suIngress_tready),
      .s_axis_tlast     (m_axis_suIngress_tlast)
    );

    // User 0
    nf_sdnet_user0_ip
    user0Switch (
      .axis_aclk    (axis_aclk),
      .axis_resetn  (axis_resetn),

      // User 0 -> Multiplexer
      .m_axis_tdata (s_axis_0_mux_tdata),
      .m_axis_tkeep (s_axis_0_mux_tkeep),
      .m_axis_tuser (s_axis_0_mux_tuser),
      .m_axis_tvalid(s_axis_0_mux_tvalid),
      .m_axis_tready(s_axis_0_mux_tready),
      .m_axis_tlast (s_axis_0_mux_tlast),

      // Demultiplexer -> User 0
      .s_axis_tdata (m_axis_0_demux_tdata),
      .s_axis_tkeep (m_axis_0_demux_tkeep),
      .s_axis_tuser (m_axis_0_demux_tuser),
      .s_axis_tvalid(m_axis_0_demux_tvalid),
      .s_axis_tready(m_axis_0_demux_tready),
      .s_axis_tlast (m_axis_0_demux_tlast),

      .S_AXI_ACLK   (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );

    // User 1
    nf_sdnet_user1_ip
    user1Switch (
      .axis_aclk   (axis_aclk),
      .axis_resetn (axis_resetn),

      // User 1 -> Multiplexer
      .m_axis_tdata (s_axis_1_mux_tdata),
      .m_axis_tkeep (s_axis_1_mux_tkeep),
      .m_axis_tuser (s_axis_1_mux_tuser),
      .m_axis_tvalid(s_axis_1_mux_tvalid),
      .m_axis_tready(s_axis_1_mux_tready),
      .m_axis_tlast (s_axis_1_mux_tlast),

      // Demultiplexer -> User 0
      .s_axis_tdata (m_axis_1_demux_tdata),
      .s_axis_tkeep (m_axis_1_demux_tkeep),
      .s_axis_tuser (m_axis_1_demux_tuser),
      .s_axis_tvalid(m_axis_1_demux_tvalid),
      .s_axis_tready(m_axis_1_demux_tready),
      .s_axis_tlast (m_axis_1_demux_tlast),

      .S_AXI_ACLK   (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );

    // Multiplexer
    mux
    mux_0 (
      .axis_aclk      (axis_aclk),
      .axis_resetn    (axis_resetn),

      // Master Ports: Superuser Egress Pipeline
      .m_axis_tdata   (m_axis_mux_tdata),
      .m_axis_tkeep   (m_axis_mux_tkeep),
      .m_axis_tuser   (m_axis_mux_tuser),
      .m_axis_tvalid  (m_axis_mux_tvalid),
      .m_axis_tlast   (m_axis_mux_tlast),
      .m_axis_tready  (m_axis_mux_tready),

      // Slave Ports: Users
      .s_axis_0_tdata (s_axis_0_mux_tdata),
      .s_axis_0_tkeep (s_axis_0_mux_tkeep),
      .s_axis_0_tuser (s_axis_0_mux_tuser),
      .s_axis_0_tvalid(s_axis_0_mux_tvalid),
      .s_axis_0_tlast (s_axis_0_mux_tlast),
      .s_axis_0_tready(s_axis_0_mux_tready),

      .s_axis_1_tdata (s_axis_1_mux_tdata),
      .s_axis_1_tkeep (s_axis_1_mux_tkeep),
      .s_axis_1_tuser (s_axis_1_mux_tuser),
      .s_axis_1_tvalid(s_axis_1_mux_tvalid),
      .s_axis_1_tlast (s_axis_1_mux_tlast),
      .s_axis_1_tready(s_axis_1_mux_tready)
    );

    // Superuser Egress Pipeline
    nf_sdnet_suEgress_ip
    nf_sdnet_suEgress_inst  (
        .axis_aclk      (axis_aclk),
        .axis_resetn    (axis_resetn),

        .m_axis_tdata   (m_axis_suEgress_tdata),
        .m_axis_tkeep   (m_axis_suEgress_tkeep),
        .m_axis_tuser   (m_axis_suEgress_tuser),
        .m_axis_tvalid  (m_axis_suEgress_tvalid),
        .m_axis_tready  (m_axis_suEgress_tready),
        .m_axis_tlast   (m_axis_suEgress_tlast),

        .s_axis_tdata   (m_axis_mux_tdata),
        .s_axis_tkeep   (m_axis_mux_tkeep),
        .s_axis_tuser   (m_axis_mux_tuser),
        .s_axis_tvalid  (m_axis_mux_tvalid),
        .s_axis_tready  (m_axis_mux_tready),
        .s_axis_tlast   (m_axis_mux_tlast),

        .S_AXI_AWADDR   (S2_AXI_AWADDR),
        .S_AXI_AWVALID  (S2_AXI_AWVALID),
        .S_AXI_WDATA    (S2_AXI_WDATA),
        .S_AXI_WSTRB    (S2_AXI_WSTRB),
        .S_AXI_WVALID   (S2_AXI_WVALID),
        .S_AXI_BREADY   (S2_AXI_BREADY),
        .S_AXI_ARADDR   (S2_AXI_ARADDR),
        .S_AXI_ARVALID  (S2_AXI_ARVALID),
        .S_AXI_RREADY   (S2_AXI_RREADY),
        .S_AXI_ARREADY  (S2_AXI_ARREADY),
        .S_AXI_RDATA    (S2_AXI_RDATA),
        .S_AXI_RRESP    (S2_AXI_RRESP),
        .S_AXI_RVALID   (S2_AXI_RVALID),
        .S_AXI_WREADY   (S2_AXI_WREADY),
        .S_AXI_BRESP    (S2_AXI_BRESP),
        .S_AXI_BVALID   (S2_AXI_BVALID),
        .S_AXI_AWREADY  (S2_AXI_AWREADY),

        .S_AXI_ACLK     (axi_aclk),
        .S_AXI_ARESETN  (axi_resetn)
    );


    wire [C_S_AXI_DATA_WIDTH-1:0] bytes_dropped;
    wire [5-1:0] pkt_dropped;

    // Output queues
    sss_output_queues_ip
    bram_output_queues_1 (
        .axis_aclk      (axis_aclk),
        .axis_resetn    (axis_resetn),

        .s_axis_tdata   (m_axis_suEgress_tdata),
        .s_axis_tkeep   (m_axis_suEgress_tkeep),
        .s_axis_tuser   (m_axis_suEgress_tuser),
        .s_axis_tvalid  (m_axis_suEgress_tvalid),
        .s_axis_tready  (m_axis_suEgress_tready),
        .s_axis_tlast   (m_axis_suEgress_tlast),

        .m_axis_0_tdata (m_axis_0_tdata),
        .m_axis_0_tkeep (m_axis_0_tkeep),
        .m_axis_0_tuser (m_axis_0_tuser),
        .m_axis_0_tvalid(m_axis_0_tvalid),
        .m_axis_0_tready(m_axis_0_tready),
        .m_axis_0_tlast (m_axis_0_tlast),

        .m_axis_1_tdata (m_axis_1_tdata),
        .m_axis_1_tkeep (m_axis_1_tkeep),
        .m_axis_1_tuser (m_axis_1_tuser),
        .m_axis_1_tvalid(m_axis_1_tvalid),
        .m_axis_1_tready(m_axis_1_tready),
        .m_axis_1_tlast (m_axis_1_tlast),

        .m_axis_2_tdata (m_axis_2_tdata),
        .m_axis_2_tkeep (m_axis_2_tkeep),
        .m_axis_2_tuser (m_axis_2_tuser),
        .m_axis_2_tvalid(m_axis_2_tvalid),
        .m_axis_2_tready(m_axis_2_tready),
        .m_axis_2_tlast (m_axis_2_tlast),

        .m_axis_3_tdata (m_axis_3_tdata),
        .m_axis_3_tkeep (m_axis_3_tkeep),
        .m_axis_3_tuser (m_axis_3_tuser),
        .m_axis_3_tvalid(m_axis_3_tvalid),
        .m_axis_3_tready(m_axis_3_tready),
        .m_axis_3_tlast (m_axis_3_tlast),

        .m_axis_4_tdata (m_axis_4_tdata),
        .m_axis_4_tkeep (m_axis_4_tkeep),
        .m_axis_4_tuser (m_axis_4_tuser),
        .m_axis_4_tvalid(m_axis_4_tvalid),
        .m_axis_4_tready(m_axis_4_tready),
        .m_axis_4_tlast (m_axis_4_tlast),

        .nf0_q_size(nf0_q_size),
        .nf1_q_size(nf1_q_size),
        .nf2_q_size(nf2_q_size),
        .nf3_q_size(nf3_q_size),
        .dma_q_size(dma_q_size),

        .bytes_stored(),
        .pkt_stored(),

        .bytes_removed_0(),
        .bytes_removed_1(),
        .bytes_removed_2(),
        .bytes_removed_3(),
        .bytes_removed_4(),

        .pkt_removed_0(),
        .pkt_removed_1(),
        .pkt_removed_2(),
        .pkt_removed_3(),
        .pkt_removed_4(),

        .bytes_dropped(bytes_dropped),
        .pkt_dropped(pkt_dropped),

        .S_AXI_AWADDR  (),
        .S_AXI_AWVALID (),
        .S_AXI_WDATA   (),
        .S_AXI_WSTRB   (),
        .S_AXI_WVALID  (),
        .S_AXI_BREADY  (),
        .S_AXI_ARADDR  (),
        .S_AXI_ARVALID (),
        .S_AXI_RREADY  (),
        .S_AXI_ARREADY (),
        .S_AXI_RDATA   (),
        .S_AXI_RRESP   (),
        .S_AXI_RVALID  (),
        .S_AXI_WREADY  (),
        .S_AXI_BRESP   (),
        .S_AXI_BVALID  (),
        .S_AXI_AWREADY (),
        .S_AXI_ACLK    (axi_aclk),
        .S_AXI_ARESETN (axi_resetn)
    );

endmodule