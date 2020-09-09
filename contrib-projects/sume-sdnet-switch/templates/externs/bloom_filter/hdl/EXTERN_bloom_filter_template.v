
//
// Copyright (c) 2018 Yoann Desmouceaux, Ecole Polytechnique
// Copyright (c) 2017 Stephen Ibanez
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
 * Author: Yoann Desmouceaux
 * 
 * Auto-generated file.
 *
 * bloom
 *
 * Bloom filter.
 *
 */



`timescale 1 ps / 1 ps


module @MODULE_NAME@ 
#(
    parameter KEY_WIDTH = @KEY_WIDTH@,
    parameter INPUT_WIDTH = KEY_WIDTH + 2/*OP_WIDTH*/ + 1,
    parameter HASH_WIDTH = @HASH_WIDTH@,
    parameter HASH_COUNT = @HASH_COUNT@
)
(
    // Data Path I/O
    input                                           clk_lookup,
    input                                           rst, 
    input                                           tuple_in_@EXTERN_NAME@_input_VALID,
    input   [INPUT_WIDTH-1:0]                       tuple_in_@EXTERN_NAME@_input_DATA,
    output                                          tuple_out_@EXTERN_NAME@_output_VALID,
    output  [0:0]                                   tuple_out_@EXTERN_NAME@_output_DATA

);


/* Tuple format for input:
        [KEY_WIDTH+OP_WIDTH        : KEY_WIDTH+OP_WIDTH       ] : statefulValid
        [KEY_WIDTH+OP_WIDTH-1      : KEY_WIDTH                ] : opcode
        [KEY_WIDTH-1               : 0                        ] : key
*/
    
    // parameters
    localparam HASH_WIDTH_MAX = 24;
    localparam HASH_COUNT_MAX = 16;
    localparam HASH_COUNT_MAX_L2 = 4;
    localparam BRAM_WIDTH = 1;

    // opcodes
    localparam OP_WIDTH = 2;
    localparam OP_READ = 0;
    localparam OP_SET = 1;
    localparam OP_RESET = 2;
    localparam OP_INVALID = 3;

    // data plane state machine states
    localparam START_REQ = 0;
    localparam CONTINUE_REQ = 1;
    localparam WAIT_BRAM = 2;
    localparam WRITE_RESULT = 3;

    // request_fifo output signals 
    wire                           statefulValid_fifo; 
    wire    [OP_WIDTH-1:0]         opcode_fifo;
    reg     [OP_WIDTH-1:0]         opcode_fifo_reg, opcode_fifo_reg_next;
    wire    [KEY_WIDTH-1:0]        key_fifo;
    reg     [KEY_WIDTH-1:0]        key_fifo_reg, key_fifo_reg_next;
    
    wire empty_fifo;
    wire full_fifo;
    reg rd_en_fifo;

    localparam L2_REQ_BUF_DEPTH = 7;
    
    // Data plane state machine signals
    reg [2:0]                     d_state, d_state_next;
    reg                           result_r, result_r_next;
    reg [HASH_COUNT_MAX_L2-1:0]   cycle_cnt, cycle_cnt_next;
    reg                           valid_out;
    reg                           result_out;
    reg                           reset_in_progress_r, reset_in_progress_r_next;

    // BRAM signals
    reg                      d_we_bram;
    reg                      d_en_bram;
    reg  [HASH_WIDTH-1:0]    d_addr_in_bram, d_addr_in_bram_r, d_addr_in_bram_r_next;
    reg  [BRAM_WIDTH-1:0]    d_data_in_bram;
    wire [BRAM_WIDTH-1:0]    d_data_out_bram;
    wire [BRAM_WIDTH-1:0]    d_data_out_bram_dummy;


    //// Input buffer to hold requests ////
    fallthrough_small_fifo
    #(
        .WIDTH(INPUT_WIDTH),
        .MAX_DEPTH_BITS(L2_REQ_BUF_DEPTH)
    )
    request_fifo
    (
       // Outputs
       .dout                           ({statefulValid_fifo, opcode_fifo, key_fifo}),
       .full                           (full_fifo),
       .nearly_full                    (),
       .prog_full                      (),
       .empty                          (empty_fifo),
       // Inputs
       .din                            (tuple_in_@EXTERN_NAME@_input_DATA),
       .wr_en                          (tuple_in_@EXTERN_NAME@_input_VALID),
       .rd_en                          (rd_en_fifo),
       .reset                          (rst),
       .clk                            (clk_lookup)
    );

    //// Read-first BRAM to hold state ////
    true_dp_bram_readfirst
    #(
        .L2_DEPTH(HASH_WIDTH),
        .WIDTH(BRAM_WIDTH)
    ) bloom_bram
    (
        .clk               (clk_lookup),
        // data plane R/W interface
        .we2               (d_we_bram),
        .en2               (d_en_bram),
        .addr2             (d_addr_in_bram),
        .din2              (d_data_in_bram),
        .rst2              (rst),
        .regce2            (d_en_bram),
        .dout2             (d_data_out_bram),

        .we1               (0),
        .en1               (0),
        .addr1             (0),
        .din1              (0),
        .rst1              (rst),
        .regce1            (0),
        .dout1             (d_data_out_bram_dummy)        
    );

    localparam MULT_WORD_SIZE = 24, MULT_WORD_SMALL_SIZE = 18; //DSP48E1 has 18*24 multiplier
    localparam NUM_MULT_WORDS_IN_KEY = (KEY_WIDTH + MULT_WORD_SIZE - 1)/MULT_WORD_SIZE; //ceil(KEY_WIDTH/MULT_WORD_SIZE)
    wire [MULT_WORD_SMALL_SIZE-1:0] hash_seeds[199:0] = {18'h041a7, 18'h23af1, 18'h3acd9, 18'h10c2b, 18'h1b783, 18'h2dac9, 18'h18ed9, 18'h109ff, 18'h32f43, 18'h0044d, 18'h29899, 18'h03c55, 18'h1128d, 18'h0dbe3, 18'h3d4b3, 18'h13747, 18'h03917, 18'h04111, 18'h3c399, 18'h24955, 18'h02e2f, 18'h02b11, 18'h3962d, 18'h08b05, 18'h33259, 18'h266f5, 18'h1816b, 18'h39dd7, 18'h37789, 18'h09d07, 18'h16499, 18'h3b493, 18'h00f49, 18'h35133, 18'h3ee63, 18'h39441, 18'h24cf3, 18'h20f0d, 18'h25023, 18'h36ae5, 18'h2f85f, 18'h03531, 18'h022d1, 18'h1f6c9, 18'h0f5ed, 18'h1c561, 18'h1680d, 18'h2154b, 18'h02903, 18'h05435, 18'h08039, 18'h25081, 18'h36485, 18'h025b9, 18'h06515, 18'h01ba3, 18'h2339d, 18'h266b5, 18'h0ee5b, 18'h09267, 18'h3ac2b, 18'h034cb, 18'h1dae5, 18'h21249, 18'h249e9, 18'h2a0c5, 18'h105f1, 18'h122b1, 18'h056c5, 18'h09c15, 18'h32b8b, 18'h391e5, 18'h36a9b, 18'h3f84d, 18'h2c339, 18'h2f5f7, 18'h207f7, 18'h126e9, 18'h14ca1, 18'h21005, 18'h1ead3, 18'h3f8ff, 18'h3f3ed, 18'h34da5, 18'h2b8d5, 18'h0e0f3, 18'h09ad9, 18'h24ce5, 18'h23c5b, 18'h0bbfb, 18'h1546d, 18'h18dc3, 18'h21151, 18'h2f3e3, 18'h19c21, 18'h11faf, 18'h3100d, 18'h29ee1, 18'h0fd07, 18'h3a699, 18'h2606d, 18'h0b761, 18'h35fff, 18'h37135, 18'h118a1, 18'h3fc1f, 18'h13b19, 18'h31afd, 18'h0da37, 18'h23251, 18'h142e9, 18'h00db7, 18'h09a81, 18'h3af8f, 18'h30fc3, 18'h3f43b, 18'h3431f, 18'h3710f, 18'h39dc1, 18'h1d72d, 18'h19245, 18'h1b455, 18'h24a7b, 18'h38fc9, 18'h0aeab, 18'h35e51, 18'h104c9, 18'h165b3, 18'h398df, 18'h122b3, 18'h0e8f7, 18'h2a8b5, 18'h22de3, 18'h25a4d, 18'h2604f, 18'h0fbdd, 18'h3839f, 18'h25c89, 18'h0ee67, 18'h3d2bd, 18'h0adcf, 18'h2d61f, 18'h3cbf3, 18'h2a161, 18'h0f101, 18'h2778f, 18'h32679, 18'h29997, 18'h1ad97, 18'h3a50f, 18'h15a35, 18'h12a63, 18'h1c707, 18'h1a4d7, 18'h12c5f, 18'h3e447, 18'h01aa1, 18'h04859, 18'h1b429, 18'h3188f, 18'h1475b, 18'h3b7a3, 18'h10bf5, 18'h01b63, 18'h1cc47, 18'h20987, 18'h3779d, 18'h1bec5, 18'h33f2f, 18'h12337, 18'h2c92b, 18'h0ed03, 18'h05873, 18'h2ec13, 18'h09c65, 18'h36de7, 18'h02f07, 18'h34387, 18'h25cef, 18'h38253, 18'h13509, 18'h0f8d1, 18'h37f09, 18'h11b53, 18'h1234f, 18'h14251, 18'h0e1f9, 18'h38d65, 18'h01d8f, 18'h0a7b5, 18'h252f1, 18'h32981, 18'h1b3b7, 18'h1dacb, 18'h37b19, 18'h2d7ef, 18'h2689b, 18'h194eb, 18'h3f9d7, 18'h3af18};
    reg [MULT_WORD_SIZE-1:0] key_mult_word;

    function [HASH_WIDTH-1:0] hash;
      input [KEY_WIDTH-1:0] key;
      input [HASH_COUNT_MAX_L2-1:0] version;
      integer k;
      begin
        // "Universal hashing" with multiply and shift
        hash = 0;
        for (k=0; k<NUM_MULT_WORDS_IN_KEY; k=k+1) begin
          key_mult_word = (key >> k*MULT_WORD_SIZE);
          hash = hash ^ ((key_mult_word * hash_seeds[version*NUM_MULT_WORDS_IN_KEY + k]) >> (MULT_WORD_SIZE - HASH_WIDTH));
        end
      end
    endfunction



   /* data plane R/W State Machine */ 
   always @(*) begin
      // default values
      d_state_next = d_state;
      rd_en_fifo = 0;
      d_en_bram = 1;

      key_fifo_reg_next = key_fifo_reg;
      opcode_fifo_reg_next = opcode_fifo_reg;
      reset_in_progress_r_next = reset_in_progress_r;

      d_we_bram = 0;
      d_addr_in_bram = d_addr_in_bram_r;
      d_addr_in_bram_r_next = d_addr_in_bram_r;
      d_data_in_bram = 0;
      
      result_r_next = result_r;
      
      cycle_cnt_next = cycle_cnt;
      valid_out = 0;
      result_out = 0;

      if (reset_in_progress_r) begin
        d_we_bram = 1'b1;
        d_data_in_bram = 1'b0;
        d_addr_in_bram_r_next = d_addr_in_bram_r + 1; //reset RAM bit per bit
        if (d_addr_in_bram_r == 2**HASH_WIDTH-1) begin
          reset_in_progress_r_next = 0;
        end
      end 
      // State machine with 3-cycle pipelining (one to compute the hash and two for the read latency of the BRAM)
      case(d_state)
          START_REQ: begin
              if (~empty_fifo) begin
                  // Cycle 0: we compute hash[0] and save it in order to query the BRAM for that bit at cycle 1
                  // We'll get the value two cycles later, i.e. at cycle 3
                  rd_en_fifo = 1;
                  if (statefulValid_fifo) begin
                      if (reset_in_progress_r) begin
                        // Report 0 while there is a reset in progress
                        result_r_next = 0;
                        d_state_next = WRITE_RESULT;                        
                      end 
                      else begin
                        if (opcode_fifo == OP_READ || opcode_fifo == OP_SET) begin
                        opcode_fifo_reg_next = opcode_fifo;
                        key_fifo_reg_next = key_fifo; // Save the key for further hash computation
                        d_addr_in_bram_r_next = hash(key_fifo, 0 /* == cycle_cnt */);
                        d_state_next = CONTINUE_REQ;
                        cycle_cnt_next = 1;
                        result_r_next = 1; // Initialize the result to 1 (neutral element for AND operation)
                        end
                        else if (opcode_fifo == OP_RESET) begin
                            reset_in_progress_r_next = 1;
                            d_addr_in_bram_r_next = 0;
                            result_r_next = 0;
                            d_state_next = WRITE_RESULT;
                        end
                      end
                  end
                  else begin
                      result_r_next = 0;
                      d_state_next = WRITE_RESULT;
                  end
              end
          end
 
          CONTINUE_REQ: begin
            // Cycle i (1 <= i <= HASH_COUNT):
            //        * We compute hash[i] and save it in order to query the BRAM for that bit at cycle i+1
            //         (we'll get the value two cycles later, i.e. at cycle i+3)
            //        * We retrieve the bit queried at cycle i-2
            d_we_bram = (opcode_fifo_reg == OP_SET) ? 1 : 0;
            d_addr_in_bram_r_next = (cycle_cnt < HASH_COUNT) ? hash(key_fifo_reg, cycle_cnt) : 0;
            d_data_in_bram = 1'b1;
            cycle_cnt_next = cycle_cnt + 1;         
            if (cycle_cnt >= 3) begin
              result_r_next = d_data_out_bram & result_r; // AND the value of all retrieved bits
            end
            if (cycle_cnt == HASH_COUNT) begin
              d_state_next = WAIT_BRAM;
            end
          end

          WAIT_BRAM: begin
            // Cycle i (i == HASH_COUNT + 1):
            //     We simply retrieve the bit queried at cycle i-2
            cycle_cnt_next = cycle_cnt + 1;         
            result_r_next = d_data_out_bram & result_r; // AND the value of all retrieved bits
            d_state_next = WRITE_RESULT;
            key_fifo_reg_next = 0;
          end

          WRITE_RESULT: begin
              valid_out = 1;
              result_out = d_data_out_bram & result_r; // AND the value of all retrieved bits
              d_state_next = START_REQ;
              cycle_cnt_next = 0;
              opcode_fifo_reg_next = OP_INVALID;
          end
      endcase // case(d_state)
   end // always @ (*)




   assign tuple_out_@EXTERN_NAME@_output_VALID = valid_out;
   assign tuple_out_@EXTERN_NAME@_output_DATA  = result_out;

   always @(posedge clk_lookup) begin
      if (rst) begin
          d_state <= START_REQ;
          d_addr_in_bram_r <= 0;
          result_r <= 0;
          cycle_cnt <= 0;
          key_fifo_reg <= 0;
          opcode_fifo_reg <= OP_INVALID;
          reset_in_progress_r <= 0;
      end
      else begin
          d_state <= d_state_next;
          d_addr_in_bram_r <= d_addr_in_bram_r_next;
          result_r <= result_r_next;
          cycle_cnt <= cycle_cnt_next;
          key_fifo_reg <= key_fifo_reg_next;
          opcode_fifo_reg <= opcode_fifo_reg_next;
          reset_in_progress_r <= reset_in_progress_r_next;
      end
   end

endmodule
