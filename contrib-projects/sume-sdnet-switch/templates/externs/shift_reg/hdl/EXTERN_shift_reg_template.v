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


/*
 * File: @MODULE_NAME@.v 
 * Author: Stephen Ibanez
 * 
 * Auto-generated file.
 *
 * shift_reg
 *
 * Simple shift register.
 *
 */

/* P4 extern function prototype:

extern void <name>_shift_reg(in bit<INDEX_WIDTH> index_in,
                             in bit<DATA_WIDTH> data_in,
                             out bit<DATA_WIDTH> data_out);
*/

`timescale 1 ps / 1 ps

module @MODULE_NAME@ 
#(
    parameter L2_DEPTH = @L2_DEPTH@,
    parameter INDEX_WIDTH = @INDEX_WIDTH@,
    parameter DATA_WIDTH = @DATA_WIDTH@,
    parameter NUM_SHIFT_REGS = @NUM_SHIFT_REGS@,
    parameter INPUT_WIDTH = INDEX_WIDTH + DATA_WIDTH
)
(
    // Data Path I/O
    input                                   clk_lookup,
    input                                   rst,
    input                                   tuple_in_@EXTERN_NAME@_input_VALID,
    input   [INPUT_WIDTH:0]                 tuple_in_@EXTERN_NAME@_input_DATA,
    output                                  tuple_out_@EXTERN_NAME@_output_VALID,
    output  [DATA_WIDTH-1:0]                tuple_out_@EXTERN_NAME@_output_DATA
);

    localparam SR_DEPTH = 2**L2_DEPTH;

    // data plane state machine states
    localparam SR_FILL = 0;
    localparam SR_FULL = 1;

    wire                   valid_in;
    wire                   statefulValid_in;
    wire [INDEX_WIDTH-1:0] index_in;
    wire [DATA_WIDTH-1:0]  data_in;

    reg [DATA_WIDTH-1:0]  result_r, result_r_next;
    reg                   result_valid_r, result_valid_r_next;

    // data plane state machine signals
    reg [NUM_SHIFT_REGS-1:0]      sr_state, sr_state_next;
    reg [L2_DEPTH:0]              sr_count_r       [NUM_SHIFT_REGS-1:0];
    reg [L2_DEPTH:0]              sr_count_r_next  [NUM_SHIFT_REGS-1:0];

    // shift register signals
    wire [DATA_WIDTH-1:0] sr_data_out [NUM_SHIFT_REGS-1:0];
    reg  [DATA_WIDTH-1:0] sr_data_in  [NUM_SHIFT_REGS-1:0];
    wire [NUM_SHIFT_REGS-1:0] sr_full;
    wire [NUM_SHIFT_REGS-1:0] sr_empty;
    reg  [NUM_SHIFT_REGS-1:0] sr_wr_en;
    reg  [NUM_SHIFT_REGS-1:0] sr_rd_en;

    // logic to parse inputs
    assign valid_in = tuple_in_@EXTERN_NAME@_input_VALID;
    assign {statefulValid_in, index_in, data_in} = tuple_in_@EXTERN_NAME@_input_DATA;

    integer j;
    /* Logic to drive shift register inputs */
    always@(*) begin
        for (j=0; j<NUM_SHIFT_REGS; j=j+1) begin
            if (j == index_in) begin
                sr_data_in[j] = data_in;
                sr_wr_en[j] = valid_in & statefulValid_in;
            end
            else begin
                sr_data_in[j] = 0;
                sr_wr_en[j] = 0;
            end
        end
    end

    /* Generate the parallel shift registers */
    genvar i;
    generate
    for (i=0; i<NUM_SHIFT_REGS; i=i+1) begin: shift_registers

        //// Shift Register ////
        fallthrough_small_fifo
        #(
            .WIDTH(DATA_WIDTH),
            .MAX_DEPTH_BITS(L2_DEPTH)
        )
        shift_reg_fifo
        (
           // Outputs
           .dout                           (sr_data_out[i]),
           .full                           (sr_full[i]),
           .nearly_full                    (),
           .prog_full                      (),
           .empty                          (sr_empty[i]),
           // Inputs
           .din                            (sr_data_in[i]),
           .wr_en                          (sr_wr_en[i]),
           .rd_en                          (sr_rd_en[i]),
           .reset                          (rst),
           .clk                            (clk_lookup)
        );

        /* Shift Register Read State Machine */ 
        always @(*) begin
           // default values
           sr_state_next[i] = sr_state[i];
           sr_count_r_next[i] = sr_count_r[i];
           sr_rd_en[i] = 0;

           case(sr_state[i])
               SR_FILL: begin
                   /* Shift register needs to fill up first */
                   if (sr_wr_en[i]) begin
                       sr_count_r_next[i] = sr_count_r[i] + 1;
                       if (sr_count_r[i] == SR_DEPTH-1) begin
                           sr_state_next[i] = SR_FULL;
                       end
                   end
               end

               SR_FULL: begin
                   /* Shift register is full */
                   if (sr_wr_en[i]) begin
                       sr_rd_en[i] = 1;
                       // NOTE: it should not be possible for shift reg to be empty here
                   end
               end
           endcase // case(sr_state[i])
        end // always @ (*)

        always @(posedge clk_lookup) begin
           if(rst) begin
              sr_state[i] <= SR_FILL;
              sr_count_r[i] <= 0;
           end
           else begin
              sr_state[i] <= sr_state_next[i];
              sr_count_r[i] <= sr_count_r_next[i];
           end
        end

    end
    endgenerate

    integer k;
    /* State Machine to drive outputs */
    always @(*) begin
        // default values
        result_valid_r_next = valid_in;
        result_r_next = 0;
        for (k=0; k<NUM_SHIFT_REGS; k=k+1) begin
            if (sr_wr_en[k] && (sr_state[k] == SR_FULL)) begin
                result_r_next = sr_data_out[k];
            end
        end
    end // always @ (*)

    always @(posedge clk_lookup) begin
        if(rst) begin
            result_valid_r <= 0;
            result_r <= 0;
        end
        else begin
            result_valid_r <= result_valid_r_next;
            result_r <= result_r_next;
        end
    end

    // Wire up the outputs
    assign tuple_out_@EXTERN_NAME@_output_VALID = result_valid_r;
    assign tuple_out_@EXTERN_NAME@_output_DATA  = result_r;

endmodule

