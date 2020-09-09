`timescale 1ns / 1ps

//
// Copyright (c) 2019 Stephen Ibanez
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

//////////////////////////////////////////////////////////////////////////////////
// Affiliation: Stanford University
// Author: Stephen Ibanez 
// 
// Create Date: 04/08/2019
// Module Name: sume_event_switch
//
// Description: Wrapper file for SUME event-driven architecture. 
//////////////////////////////////////////////////////////////////////////////////

module sume_event_switch #(
    //Slave AXI parameters
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
     parameter C_BASEADDR            = 32'h00000000,

    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH  = 256,
    parameter C_S_AXIS_DATA_WIDTH  = 256,
    parameter C_M_AXIS_TUSER_WIDTH = 128,
    parameter C_S_AXIS_TUSER_WIDTH = 128,

    parameter NUM_LINKS = 4
)
(
    /*----------------*/
    /* Datapath clock */
    /*----------------*/
    input                                     axis_aclk,
    input                                     axis_resetn,
    /*-----------------*/
    /* Registers clock */
    /*-----------------*/
    input                                     axi_aclk,
    input                                     axi_resetn,

    /*----------------------*/
    /* Slave AXI Lite Ports */
    /*----------------------*/
    // Input Arbiter (UNUSED)
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
    // SDNet Module
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
    // Output Queues (UNUSED)
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

    /*------------------------------------------------------*/
    /* Slave Stream Packet Ports (interface from Rx queues) */
    /*------------------------------------------------------*/
    // nf0
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_0_tuser,
    input                                     s_axis_0_tvalid,
    output                                    s_axis_0_tready,
    input                                     s_axis_0_tlast,
    // nf1
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_1_tuser,
    input                                     s_axis_1_tvalid,
    output                                    s_axis_1_tready,
    input                                     s_axis_1_tlast,
    // nf2
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_2_tuser,
    input                                     s_axis_2_tvalid,
    output                                    s_axis_2_tready,
    input                                     s_axis_2_tlast,
    // nf3
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_3_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_3_tuser,
    input                                     s_axis_3_tvalid,
    output                                    s_axis_3_tready,
    input                                     s_axis_3_tlast,
    // dma
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_4_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_4_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_4_tuser,
    input                                     s_axis_4_tvalid,
    output                                    s_axis_4_tready,
    input                                     s_axis_4_tlast,

    /*-----------------------------------------------------*/
    /* Master Stream Packet Ports (interface to TX queues) */
    /*-----------------------------------------------------*/
    // nf0
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_tuser,
    output                                     m_axis_0_tvalid,
    input                                      m_axis_0_tready,
    output                                     m_axis_0_tlast,
    // nf1
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_tuser,
    output                                     m_axis_1_tvalid,
    input                                      m_axis_1_tready,
    output                                     m_axis_1_tlast,
    // nf2
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_2_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_2_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_2_tuser,
    output                                     m_axis_2_tvalid,
    input                                      m_axis_2_tready,
    output                                     m_axis_2_tlast,
    // nf3
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_3_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_3_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_3_tuser,
    output                                     m_axis_3_tvalid,
    input                                      m_axis_3_tready,
    output                                     m_axis_3_tlast,
    // dma
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_4_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_4_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_4_tuser,
    output                                     m_axis_4_tvalid,
    input                                      m_axis_4_tready,
    output                                     m_axis_4_tlast,

    input [NUM_LINKS-1:0]                      link_status
);

    //--------------------- Internal Parameters-------------------------
    localparam PKT_LEN_WIDTH = 16;
    localparam PORT_WIDTH = 8;
    localparam STD_SUME_META_WIDTH = PKT_LEN_WIDTH + 2*PORT_WIDTH;

    localparam USER_ENQ_DATA_WIDTH  = 32;
    localparam USER_DEQ_DATA_WIDTH  = 32;
    localparam USER_DROP_DATA_WIDTH = 32;

    localparam TIMER_PERIOD_WIDTH = 32;
    localparam TIMER_WIDTH        = 48;

    localparam NUM_EVENTS = 6;

    localparam C_AXIS_SDNET_TUSER_WIDTH = STD_SUME_META_WIDTH
                                          + USER_ENQ_DATA_WIDTH
                                          + USER_DEQ_DATA_WIDTH
                                          + USER_DROP_DATA_WIDTH
                                          + 3*PORT_WIDTH
                                          + TIMER_PERIOD_WIDTH + TIMER_WIDTH
                                          + NUM_LINKS
                                          + NUM_EVENTS
                                          + 6;

    localparam TIMER_PERIOD_LO = STD_SUME_META_WIDTH
                                 + USER_ENQ_DATA_WIDTH
                                 + USER_DEQ_DATA_WIDTH
                                 + USER_DROP_DATA_WIDTH
                                 + 3*PORT_WIDTH;

    localparam TIMER_PERIOD_HI = TIMER_PERIOD_LO + TIMER_PERIOD_WIDTH - 1;

    localparam GEN_PACKET_POS = C_AXIS_SDNET_TUSER_WIDTH - 6;

    //---------------------- Wires and Regs ----------------------------

    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_pkt_gen_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_pkt_gen_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_pkt_gen_tuser;
    wire                                     m_axis_pkt_gen_tvalid;
    wire                                     m_axis_pkt_gen_tready;
    wire                                     m_axis_pkt_gen_tlast;

    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_merger_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_merger_tkeep;
    wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_merger_tuser;
    wire                                     s_axis_merger_tvalid;
    wire                                     s_axis_merger_tready;
    wire                                     s_axis_merger_tlast;

    wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_sdnet_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_sdnet_tkeep;
    wire                                     s_axis_sdnet_tvalid;
    wire                                     s_axis_sdnet_tready;
    wire                                     s_axis_sdnet_tlast;
    wire [C_AXIS_SDNET_TUSER_WIDTH-1:0]      s_axis_sdnet_tuser;
    wire                                     s_axis_sdnet_tuser_valid;

    wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_sdnet_tdata;
    wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_sdnet_tkeep;
    wire                                     m_axis_sdnet_tvalid;
    wire                                     m_axis_sdnet_tready;
    wire                                     m_axis_sdnet_tlast;
    wire [C_AXIS_SDNET_TUSER_WIDTH-1:0]      m_axis_sdnet_tuser;
    wire                                     m_axis_sdnet_tuser_valid;

    wire                            gen_packet;
    wire [TIMER_PERIOD_WIDTH-1:0]   timer_period;
    wire                            timer_period_valid;

    wire                                       enq_trigger;
    wire                                       enq_event_rd;
    wire [USER_ENQ_DATA_WIDTH+PORT_WIDTH-1:0]  enq_event_data;

    wire                                       deq_trigger;
    wire                                       deq_event_rd;
    wire [USER_DEQ_DATA_WIDTH+PORT_WIDTH-1:0]  deq_event_data;

    wire                                       drop_trigger;
    wire                                       drop_event_rd;
    wire [USER_DROP_DATA_WIDTH+PORT_WIDTH-1:0] drop_event_data;

    wire sdnet_rst_done;

    //-------------------- Modules ---------------------------

    // Packet Generator
    axis_pkt_generator #(
      .C_AXIS_DATA_WIDTH  (C_S_AXIS_DATA_WIDTH),
      .C_AXIS_TUSER_WIDTH (C_S_AXIS_TUSER_WIDTH)
    )
    pkt_gen_inst (
      .axis_aclk      (axis_aclk),
      .axis_resetn    (axis_resetn),
      // request packet generation
      .gen_packet     (gen_packet),
      // generated packet stream
      .m_axis_tdata   (m_axis_pkt_gen_tdata),
      .m_axis_tkeep   (m_axis_pkt_gen_tkeep),
      .m_axis_tuser   (m_axis_pkt_gen_tuser),
      .m_axis_tvalid  (m_axis_pkt_gen_tvalid),
      .m_axis_tready  (m_axis_pkt_gen_tready),
      .m_axis_tlast   (m_axis_pkt_gen_tlast)
    );

    // Input Arbiter
    input_arbiter #(
      .C_M_AXIS_DATA_WIDTH  (C_S_AXIS_DATA_WIDTH),
      .C_S_AXIS_DATA_WIDTH  (C_S_AXIS_DATA_WIDTH),
      .C_M_AXIS_TUSER_WIDTH (C_S_AXIS_TUSER_WIDTH),
      .C_S_AXIS_TUSER_WIDTH (C_S_AXIS_TUSER_WIDTH)
    )
    input_arbiter_inst (
      .axis_aclk      (axis_aclk),
      .axis_resetn    (axis_resetn),
      // input to event merger
      .m_axis_tdata   (s_axis_merger_tdata),
      .m_axis_tkeep   (s_axis_merger_tkeep),
      .m_axis_tuser   (s_axis_merger_tuser),
      .m_axis_tvalid  (s_axis_merger_tvalid),
      .m_axis_tready  (s_axis_merger_tready),
      .m_axis_tlast   (s_axis_merger_tlast),
      // nf0
      .s_axis_0_tdata (s_axis_0_tdata),
      .s_axis_0_tkeep (s_axis_0_tkeep),
      .s_axis_0_tuser (s_axis_0_tuser),
      .s_axis_0_tvalid(s_axis_0_tvalid),
      .s_axis_0_tready(s_axis_0_tready),
      .s_axis_0_tlast (s_axis_0_tlast),
      // nf1
      .s_axis_1_tdata (s_axis_1_tdata),
      .s_axis_1_tkeep (s_axis_1_tkeep),
      .s_axis_1_tuser (s_axis_1_tuser),
      .s_axis_1_tvalid(s_axis_1_tvalid),
      .s_axis_1_tready(s_axis_1_tready),
      .s_axis_1_tlast (s_axis_1_tlast),
      // nf2
      .s_axis_2_tdata (s_axis_2_tdata),
      .s_axis_2_tkeep (s_axis_2_tkeep),
      .s_axis_2_tuser (s_axis_2_tuser),
      .s_axis_2_tvalid(s_axis_2_tvalid),
      .s_axis_2_tready(s_axis_2_tready),
      .s_axis_2_tlast (s_axis_2_tlast),
      // nf3
      .s_axis_3_tdata (s_axis_3_tdata),
      .s_axis_3_tkeep (s_axis_3_tkeep),
      .s_axis_3_tuser (s_axis_3_tuser),
      .s_axis_3_tvalid(s_axis_3_tvalid),
      .s_axis_3_tready(s_axis_3_tready),
      .s_axis_3_tlast (s_axis_3_tlast),
      // dma
      .s_axis_4_tdata (s_axis_4_tdata),
      .s_axis_4_tkeep (s_axis_4_tkeep),
      .s_axis_4_tuser (s_axis_4_tuser),
      .s_axis_4_tvalid(s_axis_4_tvalid),
      .s_axis_4_tready(s_axis_4_tready),
      .s_axis_4_tlast (s_axis_4_tlast),
      // generated packets
      .s_axis_5_tdata (m_axis_pkt_gen_tdata),
      .s_axis_5_tkeep (m_axis_pkt_gen_tkeep),
      .s_axis_5_tuser (m_axis_pkt_gen_tuser),
      .s_axis_5_tvalid(m_axis_pkt_gen_tvalid),
      .s_axis_5_tready(m_axis_pkt_gen_tready),
      .s_axis_5_tlast (m_axis_pkt_gen_tlast)
    ); // Input Arbiter

    // Event Merger
    event_merger #(
      .PKT_LEN_WIDTH           (PKT_LEN_WIDTH),
      .PORT_WIDTH              (PORT_WIDTH),
      .STD_SUME_META_WIDTH     (STD_SUME_META_WIDTH),
      .USER_ENQ_DATA_WIDTH     (USER_ENQ_DATA_WIDTH),
      .USER_DEQ_DATA_WIDTH     (USER_DEQ_DATA_WIDTH),
      .USER_DROP_DATA_WIDTH    (USER_DROP_DATA_WIDTH),
      .TIMER_PERIOD_WIDTH      (TIMER_PERIOD_WIDTH),
      .TIMER_WIDTH             (TIMER_WIDTH),
      .NUM_LINKS               (NUM_LINKS),
      .C_S_AXIS_DATA_WIDTH     (C_S_AXIS_DATA_WIDTH),
      .C_S_AXIS_TUSER_WIDTH    (C_S_AXIS_TUSER_WIDTH),
      .C_M_AXIS_DATA_WIDTH     (C_M_AXIS_DATA_WIDTH),
      .C_M_AXIS_TUSER_WIDTH    (C_AXIS_SDNET_TUSER_WIDTH)
    )
    event_merger_inst (
      .axis_aclk            (axis_aclk),
      .axis_resetn          (axis_resetn),
      // input to SDNet module
      .m_axis_tdata         (s_axis_sdnet_tdata),
      .m_axis_tkeep         (s_axis_sdnet_tkeep),
      .m_axis_tvalid        (s_axis_sdnet_tvalid),
      .m_axis_tready        (s_axis_sdnet_tready),
      .m_axis_tlast         (s_axis_sdnet_tlast),
      .m_axis_tuser         (s_axis_sdnet_tuser),
      .m_axis_tuser_valid   (s_axis_sdnet_tuser_valid),
      // packets with merged events
      .s_axis_tdata         (s_axis_merger_tdata),
      .s_axis_tkeep         (s_axis_merger_tkeep),
      .s_axis_tuser         (s_axis_merger_tuser),
      .s_axis_tvalid        (s_axis_merger_tvalid),
      .s_axis_tready        (s_axis_merger_tready),
      .s_axis_tlast         (s_axis_merger_tlast),
      // enqueue event (slave interface)
      .enq_trigger          (enq_trigger),
      .enq_event_rd         (enq_event_rd),
      .enq_event_data       (enq_event_data),
      // dequeue events (slave interface)
      .deq_trigger          (deq_trigger),
      .deq_event_rd         (deq_event_rd),
      .deq_event_data       (deq_event_data),
      // drop events (slave interface)
      .drop_trigger         (drop_trigger),
      .drop_event_rd        (drop_event_rd),
      .drop_event_data      (drop_event_data),
      // timer module configuration
      .s_timer_period_valid (timer_period_valid),
      .s_timer_period       (timer_period),
      // current link stats (one-hot encoded, 4-bits)
      .link_status          (link_status)
    );

    // SDNet Module
    SimpleSumeSwitch
    SimpleSumeSwitch_inst (
      // AXIS PACKET INPUT INTERFACE
      .packet_in_packet_in_TVALID                                        (s_axis_sdnet_tvalid),
      .packet_in_packet_in_TREADY                                        (s_axis_sdnet_tready),
      .packet_in_packet_in_TDATA                                         (s_axis_sdnet_tdata),
      .packet_in_packet_in_TKEEP                                         (s_axis_sdnet_tkeep),
      .packet_in_packet_in_TLAST                                         (s_axis_sdnet_tlast),

      // TUPLE INPUT INTERFACE
      .tuple_in_sume_metadata_VALID                                      (s_axis_sdnet_tuser_valid),
      .tuple_in_sume_metadata_DATA                                       (s_axis_sdnet_tuser),
   
      // AXI-LITE CONTROL INTERFACE
      .control_S_AXI_AWADDR                                              (S1_AXI_AWADDR),
      .control_S_AXI_AWVALID                                             (S1_AXI_AWVALID),
      .control_S_AXI_AWREADY                                             (S1_AXI_AWREADY),
      .control_S_AXI_WDATA                                               (S1_AXI_WDATA),
      .control_S_AXI_WSTRB                                               (S1_AXI_WSTRB),
      .control_S_AXI_WVALID                                              (S1_AXI_WVALID),
      .control_S_AXI_WREADY                                              (S1_AXI_WREADY),
      .control_S_AXI_BRESP                                               (S1_AXI_BRESP),
      .control_S_AXI_BVALID                                              (S1_AXI_BVALID),
      .control_S_AXI_BREADY                                              (S1_AXI_BREADY),
      .control_S_AXI_ARADDR                                              (S1_AXI_ARADDR),
      .control_S_AXI_ARVALID                                             (S1_AXI_ARVALID),
      .control_S_AXI_ARREADY                                             (S1_AXI_ARREADY),
      .control_S_AXI_RDATA                                               (S1_AXI_RDATA),
      .control_S_AXI_RRESP                                               (S1_AXI_RRESP),
      .control_S_AXI_RVALID                                              (S1_AXI_RVALID),
      .control_S_AXI_RREADY                                              (S1_AXI_RREADY),
      
      // ENABLE SIGNAL
      .enable_processing                                                 (1'b1),
      
      // AXIS PACKET OUTPUT INTERFACE
      .packet_out_packet_out_TVALID                                      (m_axis_sdnet_tvalid),
      .packet_out_packet_out_TREADY                                      (m_axis_sdnet_tready),
      .packet_out_packet_out_TDATA                                       (m_axis_sdnet_tdata),
      .packet_out_packet_out_TKEEP                                       (m_axis_sdnet_tkeep),
      .packet_out_packet_out_TLAST                                       (m_axis_sdnet_tlast),
      
      // TUPLE OUTPUT INTERFACE
      .tuple_out_sume_metadata_VALID                                     (m_axis_sdnet_tuser_valid),
      .tuple_out_sume_metadata_DATA                                      (m_axis_sdnet_tuser),
      .tuple_out_digest_data_VALID                                       (), // UNUSED
      .tuple_out_digest_data_DATA                                        (), // UNUSED
      
      // LINE CLK & RST SIGNALS
      .clk_line_rst                                                      (~axis_resetn), // INV
      .clk_line                                                          (axis_aclk),
      
      // PACKET CLK & RST SIGNALS
      .clk_lookup_rst                                                    (~axis_resetn), // INV
      .clk_lookup                                                        (axis_aclk),
      
      // CONTROL CLK & RST SIGNALS
      .clk_control_rst                                                   (~axi_resetn), // INV
      .clk_control                                                       (axi_aclk),
      
      // RST DONE SIGNAL
      .internal_rst_done                                                 (sdnet_rst_done)
    ); // SDNet Module

    // Output Queues
    event_output_queues #(
      .C_M_AXIS_DATA_WIDTH  (C_M_AXIS_DATA_WIDTH),
      .C_S_AXIS_DATA_WIDTH  (C_S_AXIS_DATA_WIDTH),
      .C_M_AXIS_TUSER_WIDTH (C_M_AXIS_TUSER_WIDTH),
      .C_S_AXIS_TUSER_WIDTH (C_S_AXIS_TUSER_WIDTH),

      .PORT_WIDTH           (PORT_WIDTH),

      .USER_ENQ_DATA_WIDTH  (USER_ENQ_DATA_WIDTH),
      .USER_DEQ_DATA_WIDTH  (USER_DEQ_DATA_WIDTH),
      .USER_DROP_DATA_WIDTH (USER_DROP_DATA_WIDTH)
    )
    output_queues_inst (
      .axis_aclk      (axis_aclk),
      .axis_resetn    (axis_resetn),
      // SDNet module output packets
      .s_axis_tdata   (m_axis_sdnet_tdata),
      .s_axis_tkeep   (m_axis_sdnet_tkeep),
      .s_axis_tuser   (m_axis_sdnet_tuser[C_M_AXIS_TUSER_WIDTH-1:0]),
      .s_axis_tvalid  (m_axis_sdnet_tvalid),
      .s_axis_tready  (m_axis_sdnet_tready),
      .s_axis_tlast   (m_axis_sdnet_tlast),
      // nf0
      .m_axis_0_tdata (m_axis_0_tdata),
      .m_axis_0_tkeep (m_axis_0_tkeep),
      .m_axis_0_tuser (m_axis_0_tuser),
      .m_axis_0_tvalid(m_axis_0_tvalid),
      .m_axis_0_tready(m_axis_0_tready),
      .m_axis_0_tlast (m_axis_0_tlast),
      // nf1
      .m_axis_1_tdata (m_axis_1_tdata),
      .m_axis_1_tkeep (m_axis_1_tkeep),
      .m_axis_1_tuser (m_axis_1_tuser),
      .m_axis_1_tvalid(m_axis_1_tvalid),
      .m_axis_1_tready(m_axis_1_tready),
      .m_axis_1_tlast (m_axis_1_tlast),
      // nf2
      .m_axis_2_tdata (m_axis_2_tdata),
      .m_axis_2_tkeep (m_axis_2_tkeep),
      .m_axis_2_tuser (m_axis_2_tuser),
      .m_axis_2_tvalid(m_axis_2_tvalid),
      .m_axis_2_tready(m_axis_2_tready),
      .m_axis_2_tlast (m_axis_2_tlast),
      // nf3
      .m_axis_3_tdata (m_axis_3_tdata),
      .m_axis_3_tkeep (m_axis_3_tkeep),
      .m_axis_3_tuser (m_axis_3_tuser),
      .m_axis_3_tvalid(m_axis_3_tvalid),
      .m_axis_3_tready(m_axis_3_tready),
      .m_axis_3_tlast (m_axis_3_tlast),
      // dma
      .m_axis_4_tdata (m_axis_4_tdata),
      .m_axis_4_tkeep (m_axis_4_tkeep),
      .m_axis_4_tuser (m_axis_4_tuser),
      .m_axis_4_tvalid(m_axis_4_tvalid),
      .m_axis_4_tready(m_axis_4_tready),
      .m_axis_4_tlast (m_axis_4_tlast),
      // enqueue events
      .m_enq_event_valid  (enq_trigger),
      .m_enq_event_rd     (enq_event_rd),
      .m_enq_event_data   (enq_event_data),
      // dequeue events
      .m_deq_event_valid  (deq_trigger),
      .m_deq_event_rd     (deq_event_rd),
      .m_deq_event_data   (deq_event_data),
      // drop events
      .m_drop_event_valid (drop_trigger),
      .m_drop_event_rd    (drop_event_rd),
      .m_drop_event_data  (drop_event_data)
    );

    //-------------------- Logic ---------------------------

    assign gen_packet = m_axis_sdnet_tuser[GEN_PACKET_POS] & m_axis_sdnet_tuser_valid;

    assign timer_period       = m_axis_sdnet_tuser[TIMER_PERIOD_HI:TIMER_PERIOD_LO];
    assign timer_period_valid = m_axis_sdnet_tuser_valid;

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("sume_event_switch_waveform.vcd");
  $dumpvars (0, sume_event_switch);
  #1 $display("Sim running...");
end
`endif

endmodule


