//-
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
//                          Junior University
// Copyright (C) 2019 Stephen Ibanez
// All rights reserved.
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@

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
/*******************************************************************************
 *  File:
 *        axis_pkt_generator.v
 *
 *  Library:
 *
 *  Module:
 *        axis_pkt_generator
 *
 *  Author:
 *        Stephen Ibanez
 * 		
 *  Description:
 *        Simple AXI4 Stream packet generator
 *
 */

module axis_pkt_generator
#(
    // Pkt AXI Stream Data Width
    parameter C_AXIS_DATA_WIDTH  = 256,
    parameter C_AXIS_TUSER_WIDTH = 128
)
(
    // Global Ports
    input                                         axis_aclk,
    input                                         axis_resetn,

    // Request one packet to be generated
    input                                         gen_packet,

    // Generated Packets
    output reg  [C_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata,
    output reg  [((C_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output reg  [C_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser,
    output reg                                    m_axis_tvalid,
    input                                         m_axis_tready,
    output reg                                    m_axis_tlast

);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   //--------------------- Internal Parameters-------------------------
   /* For packet generation FSM */
   localparam WORD_ONE       = 0;
   localparam WORD_TWO       = 1;
   localparam L2_NUM_STATES  = 1;

   localparam ETH_HDR = 14; // bytes

   // maximum number of packets that can be generated in a burst
   localparam MAX_PKTS = 2048;
   localparam L2_MAX_PKTS = log2(MAX_PKTS);

   //---------------------- Wires and Regs ---------------------------- 
   reg [L2_MAX_PKTS-1:0] num_pkts_r, num_pkts_r_next;
   wire last_cycle;

   reg [L2_NUM_STATES-1:0] state, state_next;
   reg [15:0] etherType;

   //-------------------- Modules and Logic ---------------------------

    assign last_cycle = m_axis_tvalid & m_axis_tready & m_axis_tlast;

    /*----------------------------------------------*/
    /* Logic to track number of packets to generate */
    /*----------------------------------------------*/
    always @(*) begin
        // defaults
        num_pkts_r_next = num_pkts_r;

        if ( (gen_packet & ~last_cycle) && (num_pkts_r < MAX_PKTS-1) ) begin
            num_pkts_r_next = num_pkts_r + 1;
        end
        else if ( (~gen_packet & last_cycle) && (num_pkts_r > 0) ) begin
            num_pkts_r_next = num_pkts_r - 1;
        end
    end

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            num_pkts_r <= 0;
        end
        else begin
            num_pkts_r <= num_pkts_r_next;
        end
    end

    /*---------------------------------*/
    /* Packet Generation State Machine */
    /*---------------------------------*/
    always @(*) begin
        // defaults
        state_next = state;

        etherType = 16'h2121; // an arbitrary choice

        m_axis_tvalid = 0;
        m_axis_tdata = 0;
        m_axis_tkeep = 0;
        m_axis_tuser = 0;
        m_axis_tlast = 0;

        case(state)
            WORD_ONE: begin
                if (num_pkts_r > 0) begin
                    m_axis_tvalid = 1;
                    m_axis_tdata = {{(C_AXIS_DATA_WIDTH-(ETH_HDR*8)){1'b0}}, etherType, 96'b0};
                    m_axis_tkeep = {(C_AXIS_DATA_WIDTH/8){1'b1}};
                    m_axis_tuser = {{(C_AXIS_TUSER_WIDTH-32){1'b0}}, 8'b0, 8'b0, 16'd64};
                    m_axis_tlast = 0;                   
                    if (m_axis_tready) begin
                        state_next = WORD_TWO;
                    end
                end
            end

            WORD_TWO: begin
                m_axis_tvalid = 1;
                m_axis_tdata = 0;
                m_axis_tkeep = {(C_AXIS_DATA_WIDTH/8){1'b1}};
                m_axis_tuser = 0;
                m_axis_tlast = 1;
                if (m_axis_tready) begin
                    state_next = WORD_ONE;
                end
            end
        endcase
    end

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            state <= WORD_ONE;
        end
        else begin
            state <= state_next;
        end
    end

//`ifdef COCOTB_SIM
//initial begin
//  $dumpfile ("axis_pkt_generator_waveform.vcd");
//  $dumpvars (0, axis_pkt_generator);
//  #1 $display("Sim running...");
//end
//`endif
   
endmodule

