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
 *        event_merger.v
 *
 *  Library:
 *
 *  Module:
 *        event_merger
 *
 *  Author:
 *        Stephen Ibanez
 * 		
 *  Description:
 *        Combines enqueue, dequeue, drop, timer, and ingress packet events into
 *        packets that are then transferred to the SDNet module.
 *
 */

/*

Output metadata format:
[15:0]    pkt_len        (bit<32>)
[23:16]   src_port       (bit<8>)
[31:24]   dst_port       (bit<8>)
[63:32]   enq_data       (bit<32>)
[95:64]   deq_data       (bit<32>)
[127:96]  drop_data      (bit<32>)
[135:128] enq_port       (bit<8>)
[143:136] deq_port       (bit<8>)
[151:144] drop_port      (bit<8>)
[183:152] timer_period   (bit<32>) - measured in 20ns increments
[231:184] timer_now      (bit<48>) - measured in 20ns increments
[235:232] link_status    (bit<4>) - <nf3>-<nf2>-<nf1>-<nf0>
[236]     pkt_trigger    (bit<1>)
[237]     enq_trigger    (bit<1>)
[238]     deq_trigger    (bit<1>)
[239]     drop_trigger   (bit<1>)
[240]     timer_trigger  (bit<1>)
[241]     link_trigger   (bit<1>)
[242]     gen_packet     (bit<1>)
[247:243] unused         (bit<5>)

 */

module event_merger
#(
    parameter PKT_LEN_WIDTH = 16,
    parameter PORT_WIDTH = 8,
    parameter STD_SUME_META_WIDTH = PKT_LEN_WIDTH + 2*PORT_WIDTH,

    // User enqueue data
    parameter USER_ENQ_DATA_WIDTH  = 32,
    // User dequeue data
    parameter USER_DEQ_DATA_WIDTH  = 32,
    // User drop data
    parameter USER_DROP_DATA_WIDTH = 32,

    // timer params
    parameter TIMER_PERIOD_WIDTH = 32,
    parameter TIMER_WIDTH        = 48,

    // link status params
    parameter NUM_LINKS = 4,

    parameter NUM_EVENTS = 6,

    // Pkt AXI Stream params 
    parameter C_S_AXIS_DATA_WIDTH  = 256,
    parameter C_S_AXIS_TUSER_WIDTH = 128,

    parameter C_M_AXIS_DATA_WIDTH  = 256,
    parameter C_M_AXIS_TUSER_WIDTH = STD_SUME_META_WIDTH
                                      + USER_ENQ_DATA_WIDTH + USER_DEQ_DATA_WIDTH + USER_DROP_DATA_WIDTH
                                      + 3*PORT_WIDTH
                                      + TIMER_PERIOD_WIDTH + TIMER_WIDTH
                                      + NUM_LINKS
                                      + NUM_EVENTS
                                      + 6 

)
(
    // Global Ports
    input                                          axis_aclk,
    input                                          axis_resetn,

    // Master Pkt Stream (outgoing pkts) 
    output     [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata,
    output     [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output reg                                     m_axis_tvalid,
    input                                          m_axis_tready,
    output                                         m_axis_tlast,

    // Master Metadata Stream
    // NOTE: SDNet requires a separate tuser_valid signal
    //       which is non-standard
    output                                         m_axis_tuser_valid,
    output     [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser,

    // Slave Pkt Stream Ports (incomming pkts)
    input [C_S_AXIS_DATA_WIDTH - 1:0]              s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]      s_axis_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]               s_axis_tuser,
    input                                          s_axis_tvalid,
    output reg                                     s_axis_tready,
    input                                          s_axis_tlast,

    // Incomming Enqueue Events
    input                                          enq_trigger,
    output                                         enq_event_rd,
    input [USER_ENQ_DATA_WIDTH+PORT_WIDTH-1:0]     enq_event_data,

    // Incomming Dequeue Events
    input                                          deq_trigger,
    output                                         deq_event_rd,
    input [USER_DEQ_DATA_WIDTH+PORT_WIDTH-1:0]     deq_event_data,

    // Incomming Drop Events
    input                                          drop_trigger,
    output                                         drop_event_rd,
    input [USER_DROP_DATA_WIDTH+PORT_WIDTH-1:0]    drop_event_data,

    // Incomming Timer Event Configuration
    input                                          s_timer_period_valid,
    input [TIMER_PERIOD_WIDTH-1:0]                 s_timer_period,

    // Link Status Signals
    input [NUM_LINKS-1:0]                          link_status

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
   /* For Insertion FSM */
   localparam IFSM_START       = 0;
   localparam IFSM_FINISH_PKT  = 1;
   localparam L2_IFSM_STATES   = 1;

   /* For Removal FSM */
   localparam RFSM_START       = 0;
   localparam RFSM_FINISH_PKT  = 1;
   localparam L2_RFSM_STATES   = 1;   

   localparam MAX_PKT_SIZE = 2048; // bytes
   localparam L2_PKT_FIFO_DEPTH = log2(MAX_PKT_SIZE/(C_S_AXIS_DATA_WIDTH/8));
   localparam L2_META_FIFO_DEPTH = 2; // up to 4 packets

   //---------------------- Wires and Regs ---------------------------- 
   reg  d_fifo_wr_en;
   reg  d_fifo_rd_en;
   wire d_fifo_nearly_full;
   wire d_fifo_empty;

   reg  m_fifo_wr_en;
   reg  m_fifo_rd_en;
   wire m_fifo_nearly_full;
   wire m_fifo_empty;

   reg [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_fifo_tdata;
   reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_fifo_tkeep;
   reg                                     s_axis_fifo_tlast;

   reg [L2_IFSM_STATES-1:0] ifsm_state, ifsm_state_next;
   reg [L2_RFSM_STATES-1:0] rfsm_state, rfsm_state_next;

   reg [STD_SUME_META_WIDTH-1:0] std_sume_meta, std_sume_meta_r, std_sume_meta_r_next;

   // timer signals
   wire                          timer_trigger;
   wire [TIMER_PERIOD_WIDTH-1:0] timer_period; 
   wire [TIMER_WIDTH-1:0]        timer_now; 

   wire timer_event_rd;
   wire link_event_rd;
   
   wire meta_event_trigger;
   reg pkt_trigger;
   
   wire [USER_ENQ_DATA_WIDTH-1:0]  enq_user_data;
   wire [USER_DEQ_DATA_WIDTH-1:0]  deq_user_data;
   wire [USER_DROP_DATA_WIDTH-1:0] drop_user_data;
   
   wire [PORT_WIDTH-1:0] enq_port;
   wire [PORT_WIDTH-1:0] deq_port;
   wire [PORT_WIDTH-1:0] drop_port;
   
   wire [C_M_AXIS_TUSER_WIDTH-1:0] packet_metadata;

   wire link_trigger;
   reg link_trigger_r, link_trigger_r_next;
   reg [NUM_LINKS-1:0] link_status_r;

   // debugging signals
   wire [4:0]                       debug_unused;
   wire                             debug_gen_pkt;
   wire                             debug_link_trigger;
   wire                             debug_timer_trigger;
   wire                             debug_drop_trigger;
   wire                             debug_deq_trigger;
   wire                             debug_enq_trigger;
   wire                             debug_pkt_trigger;
   wire [NUM_LINKS-1:0]             debug_link_status;
   wire [TIMER_WIDTH-1:0]           debug_timer_now;
   wire [TIMER_PERIOD_WIDTH-1:0]    debug_timer_period;
   wire [PORT_WIDTH-1:0]            debug_drop_port;
   wire [PORT_WIDTH-1:0]            debug_deq_port;
   wire [PORT_WIDTH-1:0]            debug_enq_port;
   wire [USER_DROP_DATA_WIDTH-1:0]  debug_drop_user_data;
   wire [USER_DEQ_DATA_WIDTH-1:0]   debug_deq_user_data;
   wire [USER_ENQ_DATA_WIDTH-1:0]   debug_enq_user_data;
   wire [PORT_WIDTH-1:0]            debug_dst_port;
   wire [PORT_WIDTH-1:0]            debug_src_port;
   wire [PKT_LEN_WIDTH-1:0]         debug_pkt_len;

   //-------------------- Modules and Logic ---------------------------

   timer_module
     #(
       .TIMER_WIDTH        (TIMER_WIDTH),
       .TIMER_PERIOD_WIDTH (TIMER_PERIOD_WIDTH)
     )
     timer_inst
     (
       .axis_aclk                (axis_aclk),
       .axis_resetn              (axis_resetn),
       .s_timer_period_valid     (s_timer_period_valid),
       .s_timer_period           (s_timer_period),
       .m_timer_trigger          (timer_trigger),
       .m_timer_event_rd         (timer_event_rd),
       .m_timer_period           (timer_period),
       .m_timer_now              (timer_now)
     );

   /* Packet FIFO */
   fallthrough_small_fifo 
     #(
       .WIDTH(C_S_AXIS_DATA_WIDTH+C_S_AXIS_DATA_WIDTH/8+1),
       .MAX_DEPTH_BITS(L2_PKT_FIFO_DEPTH)
     )
     data_fifo
     (
       .din         ({s_axis_fifo_tlast, s_axis_fifo_tkeep, s_axis_fifo_tdata}),     // Data in
       .wr_en       (d_fifo_wr_en),       // Write enable
       .rd_en       (d_fifo_rd_en),       // Read the next word
       .dout        ({m_axis_tlast, m_axis_tkeep, m_axis_tdata}),
       .full        (),
       .prog_full   (),
       .nearly_full (d_fifo_nearly_full),
       .empty       (d_fifo_empty),
       .reset       (~axis_resetn),
       .clk         (axis_aclk)
      );

   /* Metadata FIFO */
   fallthrough_small_fifo 
     #(
       .WIDTH(C_M_AXIS_TUSER_WIDTH),
       .MAX_DEPTH_BITS(L2_META_FIFO_DEPTH)
     )
     meta_fifo
     (
       .din         (packet_metadata),  // Data in
       .wr_en       (m_fifo_wr_en),     // Write enable
       .rd_en       (m_fifo_rd_en),     // Read the next word
       .dout        (m_axis_tuser),
       .full        (),
       .prog_full   (),
       .nearly_full (m_fifo_nearly_full),
       .empty       (m_fifo_empty),
       .reset       (~axis_resetn),
       .clk         (axis_aclk)
     );

    // metadata valid signal for SDNet
    assign m_axis_tuser_valid = m_fifo_rd_en;

    assign enq_event_rd = m_fifo_wr_en & enq_trigger;
    assign deq_event_rd = m_fifo_wr_en & deq_trigger;
    assign drop_event_rd = m_fifo_wr_en & drop_trigger;

    assign timer_event_rd = m_fifo_wr_en & timer_trigger;
    assign link_event_rd = m_fifo_wr_en & link_trigger;

    assign meta_event_trigger = enq_trigger | deq_trigger | drop_trigger | timer_trigger | link_trigger;

    assign {enq_user_data,  enq_port}   = enq_event_data;
    assign {deq_user_data,  deq_port}   = deq_event_data;
    assign {drop_user_data, drop_port}  = drop_event_data;

    assign packet_metadata = {6'b0,
                              link_trigger,
                              timer_trigger,
                              drop_trigger,
                              deq_trigger,
                              enq_trigger,
                              pkt_trigger,
                              link_status,
                              timer_now,
                              timer_period,
                              drop_port,
                              deq_port,
                              enq_port,
                              drop_user_data,
                              deq_user_data,
                              enq_user_data,
                              std_sume_meta}; // {dst_port, src_port, pkt_len}

    assign link_trigger = link_trigger_r;

    // debugging signals
    assign {debug_unused,
            debug_gen_pkt,
            debug_link_trigger,
            debug_timer_trigger,
            debug_drop_trigger,
            debug_deq_trigger,
            debug_enq_trigger,
            debug_pkt_trigger,
            debug_link_status,
            debug_timer_now,
            debug_timer_period,
            debug_drop_port,
            debug_deq_port,
            debug_enq_port,
            debug_drop_user_data,
            debug_deq_user_data,
            debug_enq_user_data,
            debug_dst_port,
            debug_src_port,
            debug_pkt_len} = m_axis_tuser;

    /* Generate link status change events */
    always @(*) begin
        // defaults
        link_trigger_r_next = link_trigger_r;

        if (link_status != link_status_r) begin
            link_trigger_r_next = 1;
        end
        else if (link_event_rd) begin
            link_trigger_r_next = 0;
        end
    end

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            link_status_r <= 0;
            link_trigger_r <= 0;
        end
        else begin
            link_status_r <= link_status;
            link_trigger_r <= link_trigger_r_next;
        end
    end

    /*-------------------------*/
    /* Insertion State Machine */
    /*-------------------------*/
    always @(*) begin
        // defaults
        ifsm_state_next = ifsm_state;

        d_fifo_wr_en = 0;
        m_fifo_wr_en = 0;

        s_axis_fifo_tdata = s_axis_tdata;
        s_axis_fifo_tkeep = s_axis_tkeep;
        s_axis_fifo_tlast = s_axis_tlast;

        std_sume_meta = std_sume_meta_r;
        std_sume_meta_r_next = std_sume_meta_r;

        s_axis_tready = ~d_fifo_nearly_full & ~m_fifo_nearly_full;

        pkt_trigger = 0;

        case(ifsm_state)
            IFSM_START: begin
                if (s_axis_tvalid & s_axis_tready) begin
                    // first word of an actual packet
                    d_fifo_wr_en = 1;
                    pkt_trigger = 1;
                    std_sume_meta_r_next = s_axis_tuser[STD_SUME_META_WIDTH-1:0];
                    ifsm_state_next = IFSM_FINISH_PKT;
                end
                else if (s_axis_tready & meta_event_trigger) begin
                    // there is no packet, but one or more metadata event fires so write a
                    // single cycle packet
                    s_axis_fifo_tdata = 0;
                    s_axis_fifo_tkeep = 0;
                    s_axis_fifo_tlast = 1;
                    std_sume_meta = 0;
                    d_fifo_wr_en = 1;
                    m_fifo_wr_en = 1;
                end
            end

            IFSM_FINISH_PKT: begin
                pkt_trigger = 1;
                if (s_axis_tvalid & s_axis_tready) begin
                    d_fifo_wr_en = 1;
                    if (s_axis_tlast) begin
                        m_fifo_wr_en = 1;
                        ifsm_state_next = IFSM_START;
                    end
                end
            end
        endcase
    end

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            ifsm_state <= IFSM_START;
            std_sume_meta_r <= 0;
        end
        else begin
            ifsm_state <= ifsm_state_next;
            std_sume_meta_r <= std_sume_meta_r_next;
        end
    end

    /*-----------------------*/
    /* Removal State Machine */
    /*-----------------------*/
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
                           // only transition if it's not a single cycle packet
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

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            rfsm_state <= RFSM_START;
        end
        else begin
            rfsm_state <= rfsm_state_next;
        end
    end

//`ifdef COCOTB_SIM
//initial begin
//  $dumpfile ("event_merger_waveform.vcd");
//  $dumpvars (0, event_merger);
//  #1 $display("Sim running...");
//end
//`endif
   
endmodule
