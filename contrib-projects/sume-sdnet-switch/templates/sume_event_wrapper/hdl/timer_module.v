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
 *        timer_module.v
 *
 *  Library:
 *
 *  Module:
 *        timer_module
 *
 *  Author:
 *        Stephen Ibanez
 * 		
 *  Description:
 *        Generates periodic timer events. Timer events will never fire if the
 *        period == 0
 *
 */

module timer_module
#(
    parameter TIMER_WIDTH = 48,
    parameter TIMER_PERIOD_WIDTH = 32
)
(
    // Global Ports
    input                                          axis_aclk,
    input                                          axis_resetn,

    input                                          s_timer_period_valid,
    input [TIMER_PERIOD_WIDTH-1:0]                 s_timer_period,

    // assert trigger when timer event fires, stays high until timer_event_rd asserted
    output                                         m_timer_trigger,
    input                                          m_timer_event_rd,
    output [TIMER_PERIOD_WIDTH-1:0]                m_timer_period,
    output [TIMER_WIDTH-1:0]                       m_timer_now

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

    //---------------------- Wires and Regs ---------------------------- 

    // timer period is specified in 20ns increments so we will use the least
    // significant 2 bits of this reg to count to 20ns (assuming clk with 5ns period)
    reg [TIMER_WIDTH+2-1:0] timer_r;

    reg [TIMER_WIDTH-1:0]        timer_last_r, timer_last_r_next;
    reg [TIMER_PERIOD_WIDTH-1:0] timer_period_r, timer_period_r_next;    
    reg                          timer_trigger_r, timer_trigger_r_next;

    wire [TIMER_WIDTH-1:0] cur_time;
    wire [1:0]             ctr_bits;

    //-------------------- Modules and Logic ---------------------------

    assign {cur_time, ctr_bits} = timer_r;

    // wire up the outputs
    assign m_timer_trigger = timer_trigger_r;
    assign m_timer_period = timer_period_r;
    assign m_timer_now = timer_last_r;

    always @(*) begin
        // defaults
        timer_last_r_next = timer_last_r;
        timer_period_r_next = timer_period_r;
        timer_trigger_r_next = timer_trigger_r;

        // set/reset timer trigger
        if ((cur_time >= timer_last_r + timer_period_r) && (timer_period_r > 0)) begin
            timer_trigger_r_next = 1;
            timer_last_r_next = cur_time;
        end
        else if (timer_trigger_r & m_timer_event_rd) begin
            timer_trigger_r_next = 0;
        end

        // set timer period
        if (s_timer_period_valid) begin
            timer_period_r_next = s_timer_period;
        end
    end

    always @(posedge axis_aclk) begin
        if (~axis_resetn) begin
            timer_r <= 0;
            timer_last_r <= 0;
            timer_period_r <= 0;
            timer_trigger_r <= 0;
        end
        else begin
            timer_r <= timer_r + 1;
            timer_last_r <= timer_last_r_next;
            timer_period_r <= timer_period_r_next;
            timer_trigger_r <= timer_trigger_r_next;
        end
    end

//`ifdef COCOTB_SIM
//initial begin
//  $dumpfile ("timer_module_waveform.vcd");
//  $dumpvars (0, timer_module);
//  #1 $display("Sim running...");
//end
//`endif
   
endmodule

