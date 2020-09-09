//-
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
 *        SimpleSumeSwitch_dummy.v
 *
 *  Library:
 *
 *  Module:
 *        SimpleSumeSwitch_dummy
 *
 *  Author:
 *        Stephen Ibanez
 * 		
 *  Description:
 *        A dummy SimpleSumeSwitch module to be used for testing only.
 *
 */

module SimpleSumeSwitch_dummy
#(
    // Slave AXI parameters
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 32,
    parameter C_BASEADDR            = 32'h00000000,

    // Pkt AXI Stream Data Width
    parameter C_AXIS_DATA_WIDTH  = 256,
    parameter C_AXIS_TUSER_WIDTH = 248
)
(

    // AXIS PACKET INPUT INTERFACE
    input [C_AXIS_DATA_WIDTH - 1:0]              packet_in_packet_in_TDATA,
    input [((C_AXIS_DATA_WIDTH / 8)) - 1:0]      packet_in_packet_in_TKEEP,
    input                                        packet_in_packet_in_TVALID,
    output                                       packet_in_packet_in_TREADY,
    input                                        packet_in_packet_in_TLAST,

    // TUPLE INPUT INTERFACE
    input                                        tuple_in_sume_metadata_VALID,
    input [C_AXIS_TUSER_WIDTH-1:0]               tuple_in_sume_metadata_DATA,

    // AXI-LITE CONTROL INTERFACE
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]        control_S_AXI_AWADDR,
    input                                        control_S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]        control_S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]      control_S_AXI_WSTRB,
    input                                        control_S_AXI_WVALID,
    input                                        control_S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]        control_S_AXI_ARADDR,
    input                                        control_S_AXI_ARVALID,
    input                                        control_S_AXI_RREADY,
    output                                       control_S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]        control_S_AXI_RDATA,
    output     [1 : 0]                           control_S_AXI_RRESP,
    output                                       control_S_AXI_RVALID,
    output                                       control_S_AXI_WREADY,
    output     [1 :0]                            control_S_AXI_BRESP,
    output                                       control_S_AXI_BVALID,
    output                                       control_S_AXI_AWREADY,

    // ENABLE SIGNAL
    input                                        enable_processing,

    // AXIS PACKET OUTPUT INTERFACE
    output     [C_AXIS_DATA_WIDTH - 1:0]         packet_out_packet_out_TDATA,
    output     [((C_AXIS_DATA_WIDTH / 8)) - 1:0] packet_out_packet_out_TKEEP,
    output                                       packet_out_packet_out_TVALID,
    input                                        packet_out_packet_out_TREADY,
    output                                       packet_out_packet_out_TLAST,

    // TUPLE OUTPUT INTERFACE
    output                                       tuple_out_sume_metadata_VALID,
    output     [C_AXIS_TUSER_WIDTH-1:0]          tuple_out_sume_metadata_DATA,
    output                                       tuple_out_digest_data_VALID,
    output     [C_AXIS_TUSER_WIDTH-1:0]          tuple_out_digest_data_DATA,

    // LINE CLK & RST SIGNALS
    input                                        clk_line_rst,
    input                                        clk_line,

    // PACKET CLK & RST SIGNALS
    input                                        clk_lookup_rst,
    input                                        clk_lookup,

    // CONTROL CLK & RST SIGNALS
    input                                        clk_control_rst,
    input                                        clk_control,

    // RST DONE SIGNAL
    output                                       internal_rst_done

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

   //--------------------- Internal Parameters -------------------------
   /* For Insertion FSM */
   localparam WAIT_START     = 0;
   localparam RCV_WORD       = 1;
   localparam L2_IFSM_STATES = 1;

   /* For Removal FSM */
   localparam RFSM_START = 0;
   localparam RFSM_FINISH_PKT = 1;
   localparam L2_RFSM_STATES = 1;   

   localparam MAX_PKT_SIZE = 2048;
   localparam MIN_PKT_SIZE = 64;
   localparam MAX_PKTS = MAX_PKT_SIZE/MIN_PKT_SIZE;

   localparam MAX_DEPTH = MAX_PKT_SIZE/C_AXIS_DATA_WIDTH; 
   localparam L2_MAX_DEPTH = log2(MAX_DEPTH);
   localparam L2_MAX_PKTS = log2(MAX_PKTS);

   //---------------------- Wires and Regs ---------------------------- 

   wire [C_AXIS_DATA_WIDTH - 1:0]         s_axis_tdata;
   wire [((C_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep;
   wire                                   s_axis_tvalid;
   wire                                   s_axis_tready;
   wire                                   s_axis_tlast;

   wire [C_AXIS_TUSER_WIDTH-1:0]          s_axis_tuser;
   wire                                   s_axis_tuser_valid;

   wire [C_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata;
   wire [((C_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep;
   reg                                    m_axis_tvalid;
   wire                                   m_axis_tready;
   wire                                   m_axis_tlast;

   wire [C_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser;
   wire                                   m_axis_tuser_valid;

   reg  d_fifo_wr_en;
   reg  d_fifo_rd_en;
   wire d_fifo_nearly_full;
   wire d_fifo_empty;

   wire m_fifo_wr_en;
   reg  m_fifo_rd_en;
   wire m_fifo_nearly_full;
   wire m_fifo_empty;

   reg [L2_IFSM_STATES-1:0] ifsm_state, ifsm_state_next;
   reg [L2_RFSM_STATES-1:0] rfsm_state, rfsm_state_next;

   //-------------------- Modules and Logic ---------------------------

   assign s_axis_tready = ~d_fifo_nearly_full & ~m_fifo_nearly_full;

   // convert packet_in_* into s_axis_*
   assign s_axis_tdata       = packet_in_packet_in_TDATA;
   assign s_axis_tkeep       = packet_in_packet_in_TKEEP;
   assign s_axis_tvalid      = packet_in_packet_in_TVALID;
   assign s_axis_tlast       = packet_in_packet_in_TLAST;
   assign packet_in_packet_in_TREADY = s_axis_tready;

   assign s_axis_tuser        = tuple_in_sume_metadata_DATA;
   assign s_axis_tuser_valid  = tuple_in_sume_metadata_VALID;

   // convert m_axis_* packet_out_*
   assign packet_out_packet_out_TDATA  = m_axis_tdata;
   assign packet_out_packet_out_TKEEP  = m_axis_tkeep;
   assign packet_out_packet_out_TVALID = m_axis_tvalid;
   assign packet_out_packet_out_TLAST  = m_axis_tlast;
   assign m_axis_tready = packet_out_packet_out_TREADY;

   assign tuple_out_sume_metadata_DATA  = m_axis_tuser;
   assign tuple_out_sume_metadata_VALID = m_axis_tuser_valid;
   assign tuple_out_digest_data_DATA  = 0; // UNUSED
   assign tuple_out_digest_data_VALID = m_axis_tuser_valid;

   // logic for tuser_valid signals
   assign m_fifo_wr_en = s_axis_tuser_valid;
   assign m_axis_tuser_valid = m_fifo_rd_en;

   assign internal_rst_done = ~clk_line_rst;

   fallthrough_small_fifo 
      #(
          .WIDTH(C_AXIS_DATA_WIDTH+C_AXIS_DATA_WIDTH/8+1),
          .MAX_DEPTH_BITS(L2_MAX_DEPTH)
      )
      data_fifo
        (.din         ({s_axis_tlast, s_axis_tkeep, s_axis_tdata}), // Data in
         .wr_en       (d_fifo_wr_en),       // Write enable
         .rd_en       (d_fifo_rd_en),       // Read the next word
         .dout        ({m_axis_tlast, m_axis_tkeep, m_axis_tdata}),
         .full        (),
         .prog_full   (),
         .nearly_full (d_fifo_nearly_full),
         .empty       (d_fifo_empty),
         .reset       (clk_line_rst),
         .clk         (clk_line)
         );

   fallthrough_small_fifo 
      #(
          .WIDTH(C_AXIS_TUSER_WIDTH),
          .MAX_DEPTH_BITS(L2_MAX_PKTS)
      )
      meta_fifo
        (.din         (s_axis_tuser),     // Data in
         .wr_en       (m_fifo_wr_en),     // Write enable
         .rd_en       (m_fifo_rd_en),     // Read the next word
         .dout        (m_axis_tuser),
         .full        (),
         .prog_full   (),
         .nearly_full (m_fifo_nearly_full),
         .empty       (m_fifo_empty),
         .reset       (clk_line_rst),
         .clk         (clk_line)
         );

    /* Insertion State Machine */
    always @(*) begin
        // defaults
        ifsm_state_next = ifsm_state;
        d_fifo_wr_en = 0;

        case(ifsm_state)
            WAIT_START: begin
                if (s_axis_tvalid & s_axis_tready) begin
                    d_fifo_wr_en = 1;
                    if (~s_axis_tlast) begin
                        ifsm_state_next = RCV_WORD;
                    end
                end
            end

            RCV_WORD: begin
                if (s_axis_tvalid & s_axis_tready) begin
                    d_fifo_wr_en = 1;
                    if (s_axis_tlast) begin
                        ifsm_state_next = WAIT_START;
                    end
                end
            end
        endcase
    end

    always @(posedge clk_line) begin
        if (clk_line_rst) begin
            ifsm_state <= WAIT_START;
        end
        else begin
            ifsm_state <= ifsm_state_next;
        end
    end

    /* Removal State Machine */
    always @(*) begin
        // defaults
        rfsm_state_next = rfsm_state;

        d_fifo_rd_en = 0;
        m_fifo_rd_en = 0;

        m_axis_tvalid = 0;

        case(rfsm_state)
            RFSM_START: begin
               if (~d_fifo_empty & ~m_fifo_empty) begin
                   m_axis_tvalid = 1;
                   if (m_axis_tready) begin
                       d_fifo_rd_en = 1;
                       m_fifo_rd_en = 1;
                       if (~m_axis_tlast) begin
                           rfsm_state_next = RFSM_FINISH_PKT;
                       end
                   end
               end 
            end

            RFSM_FINISH_PKT: begin
               if (~d_fifo_empty) begin
                   m_axis_tvalid = 1;
                   if (m_axis_tready) begin
                       d_fifo_rd_en = 1;
                       if (m_axis_tlast) begin
                           rfsm_state_next = RFSM_START;
                       end
                   end
               end
            end
        endcase
    end

    always @(posedge clk_line) begin
        if (clk_line_rst) begin
            rfsm_state <= RFSM_START;
        end
        else begin
            rfsm_state <= rfsm_state_next;
        end
    end

//`ifdef COCOTB_SIM
//initial begin
//  $dumpfile ("XilinxSwitch_dummy_waveform.vcd");
//  $dumpvars (0, XilinxSwitch_dummy);
//  #1 $display("Sim running...");
//end
//`endif
   
endmodule

