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
/*******************************************************************************
 *  File:
 *        input_arbiter.v
 *
 *  Library:
 *
 *  Module:
 *        input_arbiter
 *
 *  Author:
 *        Stephen Ibanez
 * 		
 *  Description:
 *        Work-conserving arbiter (N inputs to 1 output)
 *
 */

module input_arbiter
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    parameter NUM_QUEUES=6
)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    /*----------------------------------------------*/
    /* Master Stream Ports (interface to data path) */
    /*----------------------------------------------*/
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser,
    output                                     m_axis_tvalid,
    input                                      m_axis_tready,
    output                                     m_axis_tlast,

    /*---------------------------------------------*/
    /* Slave Stream Ports (interface to RX queues) */
    /*---------------------------------------------*/
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

    // packet generator
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_5_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_5_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_5_tuser,
    input                                     s_axis_5_tvalid,
    output                                    s_axis_5_tready,
    input                                     s_axis_5_tlast

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

   // ------------ Internal Params --------

   localparam L2_NUM_QUEUES = log2(NUM_QUEUES) + 1;

   localparam L2_NUM_STATES = 1;
   localparam IDLE = 0;
   localparam WR_PKT = 1;

   localparam MAX_PKT_SIZE = 2048; // bytes
   localparam FIFO_DEPTH_BITS = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

   // ------------- Regs/ wires -----------

   wire [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata [NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tkeep [NUM_QUEUES-1:0];
   wire [C_M_AXIS_TUSER_WIDTH-1:0]       in_tuser [NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0]                 in_tvalid;
   wire [NUM_QUEUES-1:0]                 in_tlast;

   wire [C_M_AXIS_TUSER_WIDTH-1:0]       in_fifo_tuser [NUM_QUEUES-1:0];
   wire [C_M_AXIS_DATA_WIDTH-1:0]        in_fifo_tdata [NUM_QUEUES-1:0];
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_fifo_tkeep [NUM_QUEUES-1:0];
   wire [NUM_QUEUES-1:0]                 in_fifo_tlast;

   wire [NUM_QUEUES-1:0]                 in_fifo_nearly_full;
   wire [NUM_QUEUES-1:0]                 in_fifo_empty;
   reg  [NUM_QUEUES-1:0]                 in_fifo_rd_en;

   reg [L2_NUM_STATES-1:0]               state;
   reg [L2_NUM_STATES-1:0]               state_next;

   reg [L2_NUM_QUEUES-1:0]               cur_queue;
   reg [L2_NUM_QUEUES-1:0]               cur_queue_r, cur_queue_r_next;

   reg                                   out_fifo_wr_en;
   wire                                  out_fifo_nearly_full;

   wire [C_M_AXIS_TUSER_WIDTH-1:0]       out_fifo_tuser;
   wire [C_M_AXIS_DATA_WIDTH-1:0]        out_fifo_tdata;
   wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  out_fifo_tkeep;
   wire                                  out_fifo_tlast;

   // ------------ Modules -------------

   generate
   genvar i;
   for(i=0; i<NUM_QUEUES; i=i+1) begin: in_arb_queues
     fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
           .MAX_DEPTH_BITS(FIFO_DEPTH_BITS))
      in_arb_fifo
        (// Outputs
         .dout                           ({in_fifo_tlast[i], in_fifo_tuser[i], in_fifo_tkeep[i], in_fifo_tdata[i]}),
         .full                           (),
         .nearly_full                    (in_fifo_nearly_full[i]),
	 .prog_full                      (),
         .empty                          (in_fifo_empty[i]),
         // Inputs
         .din                            ({in_tlast[i], in_tuser[i], in_tkeep[i], in_tdata[i]}),
         .wr_en                          (in_tvalid[i] & ~in_fifo_nearly_full[i]),
         .rd_en                          (in_fifo_rd_en[i]),
         .reset                          (~axis_resetn),
         .clk                            (axis_aclk));
   end
   endgenerate

   fallthrough_small_fifo
      #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
         .MAX_DEPTH_BITS(FIFO_DEPTH_BITS))
    output_fifo
      (// Outputs
       .dout                           ({m_axis_tlast, m_axis_tuser, m_axis_tkeep, m_axis_tdata}),
       .full                           (),
       .nearly_full                    (out_fifo_nearly_full),
       .prog_full                      (),
       .empty                          (out_fifo_empty),
       // Inputs
       .din                            ({out_fifo_tlast, out_fifo_tuser, out_fifo_tkeep, out_fifo_tdata}),
       .wr_en                          (out_fifo_wr_en),
       .rd_en                          (m_axis_tready & ~out_fifo_empty),
       .reset                          (~axis_resetn),
       .clk                            (axis_aclk));

   // ------------- Logic ------------

   // nf0
   assign in_tdata[0]        = s_axis_0_tdata;
   assign in_tkeep[0]        = s_axis_0_tkeep;
   assign in_tuser[0]        = s_axis_0_tuser;
   assign in_tvalid[0]       = s_axis_0_tvalid;
   assign in_tlast[0]        = s_axis_0_tlast;
   assign s_axis_0_tready    = !in_fifo_nearly_full[0];

   // nf1
   assign in_tdata[1]        = s_axis_1_tdata;
   assign in_tkeep[1]        = s_axis_1_tkeep;
   assign in_tuser[1]        = s_axis_1_tuser;
   assign in_tvalid[1]       = s_axis_1_tvalid;
   assign in_tlast[1]        = s_axis_1_tlast;
   assign s_axis_1_tready    = !in_fifo_nearly_full[1];

   // nf2
   assign in_tdata[2]        = s_axis_2_tdata;
   assign in_tkeep[2]        = s_axis_2_tkeep;
   assign in_tuser[2]        = s_axis_2_tuser;
   assign in_tvalid[2]       = s_axis_2_tvalid;
   assign in_tlast[2]        = s_axis_2_tlast;
   assign s_axis_2_tready    = !in_fifo_nearly_full[2];

   // nf3
   assign in_tdata[3]        = s_axis_3_tdata;
   assign in_tkeep[3]        = s_axis_3_tkeep;
   assign in_tuser[3]        = s_axis_3_tuser;
   assign in_tvalid[3]       = s_axis_3_tvalid;
   assign in_tlast[3]        = s_axis_3_tlast;
   assign s_axis_3_tready    = !in_fifo_nearly_full[3];

   // dma
   assign in_tdata[4]        = s_axis_4_tdata;
   assign in_tkeep[4]        = s_axis_4_tkeep;
   assign in_tuser[4]        = s_axis_4_tuser;
   assign in_tvalid[4]       = s_axis_4_tvalid;
   assign in_tlast[4]        = s_axis_4_tlast;
   assign s_axis_4_tready    = !in_fifo_nearly_full[4];

   // packet generator
   assign in_tdata[5]        = s_axis_5_tdata;
   assign in_tkeep[5]        = s_axis_5_tkeep;
   assign in_tuser[5]        = s_axis_5_tuser;
   assign in_tvalid[5]       = s_axis_5_tvalid;
   assign in_tlast[5]        = s_axis_5_tlast;
   assign s_axis_5_tready    = !in_fifo_nearly_full[5];

   // wires to output fifo
   assign out_fifo_tlast = in_fifo_tlast[cur_queue];
   assign out_fifo_tuser = in_fifo_tuser[cur_queue];
   assign out_fifo_tkeep = in_fifo_tkeep[cur_queue];
   assign out_fifo_tdata = in_fifo_tdata[cur_queue];

   // wire up outputs
   assign m_axis_tvalid = ~out_fifo_empty;

   integer j;

   /*---------------------------------------*/
   /* State machine to write to output fifo */
   /*---------------------------------------*/
   always @(*) begin
      state_next = state;

      in_fifo_rd_en = 0;
      out_fifo_wr_en = 0;

      cur_queue = cur_queue_r;
      cur_queue_r_next = cur_queue_r;

      case(state)
        /* pick the first non-empty queue (if any) */
        IDLE: begin
            for (j=0; j<NUM_QUEUES; j=j+1) begin
                if (~in_fifo_empty[j] & ~out_fifo_nearly_full & ~out_fifo_wr_en) begin
                    out_fifo_wr_en = 1;
                    in_fifo_rd_en[j] = 1;
                    cur_queue = j;
                    cur_queue_r_next = j;
                    if (~in_fifo_tlast[j]) begin
                        // only transistion if this is not a single cycle packet
                        state_next = WR_PKT;
                    end
                end
            end
        end

        /* wait until eop */
        WR_PKT: begin
            // FIFO read/write logic
            if (~out_fifo_nearly_full & ~in_fifo_empty[cur_queue]) begin
                out_fifo_wr_en = 1;
                in_fifo_rd_en[cur_queue] = 1;
            end

            // state transition logic
            if (out_fifo_wr_en & out_fifo_tlast) begin
                state_next = IDLE;
            end
        end // case: WR_PKT

      endcase // case(state)
   end // always @ (*)

   always @(posedge axis_aclk) begin
      if(~axis_resetn) begin
         state <= IDLE;
         cur_queue_r <= 0;
      end
      else begin
         state <= state_next;
         cur_queue_r <= cur_queue_r_next;
      end
   end

//`ifdef COCOTB_SIM
//initial begin
//  $dumpfile ("input_arbiter_waveform.vcd");
//  $dumpvars (0, input_arbiter);
//  #1 $display("Sim running...");
//end
//`endif

endmodule
