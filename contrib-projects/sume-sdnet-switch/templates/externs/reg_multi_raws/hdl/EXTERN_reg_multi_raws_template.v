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
 * reg_multi_raws
 *
 */

/* P4 extern function prototype:

extern void <name>_reg_multi_raws(in bit<INDEX_WIDTH> index_0,
                                  in bit<REG_WIDTH> data_0,
                                  in bit<OP_WIDTH> opCode_0,
                                  in bit<INDEX_WIDTH> index_1,
                                  in bit<REG_WIDTH> data_1,
                                  in bit<OP_WIDTH> opCode_1,
                                  in bit<INDEX_WIDTH> index_2,
                                  in bit<REG_WIDTH> data_2,
                                  in bit<OP_WIDTH> opCode_2,
                                  out bit<REG_WIDTH> result);
*/

`timescale 1 ps / 1 ps
`define READ_OP        8'd0
`define WRITE_OP       8'd1
`define ADD_OP         8'd2
`define SUB_OP         8'd3
`define NULL_OP        8'd4
`define READ_WRITE_OP  8'd5
`define ADD_SAT_OP     8'd6
`define SUB_SAT_OP     8'd7

`include "@PREFIX_NAME@_cpu_regs_defines.v"
module @MODULE_NAME@ 
#(
    parameter INDEX_WIDTH = @INDEX_WIDTH@,
    parameter REG_WIDTH = @REG_WIDTH@,
    parameter OP_WIDTH = 8,
    parameter SINGLE_INPUT_WIDTH = INDEX_WIDTH + REG_WIDTH + OP_WIDTH,
    parameter INPUT_WIDTH = 3*SINGLE_INPUT_WIDTH + 1,
    parameter OUTPUT_WIDTH = REG_WIDTH,

    parameter C_S_AXI_ADDR_WIDTH = @ADDR_WIDTH@,
    parameter C_S_AXI_DATA_WIDTH = 32
)
(
    // Data Path I/O
    input                                           clk_lookup,
    input                                           clk_lookup_rst_high, 
    input                                           tuple_in_@EXTERN_NAME@_input_VALID,
    input   [INPUT_WIDTH-1:0]                       tuple_in_@EXTERN_NAME@_input_DATA,
    output                                          tuple_out_@EXTERN_NAME@_output_VALID,
    output  [OUTPUT_WIDTH-1:0]                      tuple_out_@EXTERN_NAME@_output_DATA,

    // Control Path I/O
    input                                     clk_control,
    input                                     clk_control_rst_low,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     control_S_AXI_AWADDR,
    input                                     control_S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     control_S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   control_S_AXI_WSTRB,
    input                                     control_S_AXI_WVALID,
    input                                     control_S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     control_S_AXI_ARADDR,
    input                                     control_S_AXI_ARVALID,
    input                                     control_S_AXI_RREADY,
    output                                    control_S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     control_S_AXI_RDATA,
    output     [1 : 0]                        control_S_AXI_RRESP,
    output                                    control_S_AXI_RVALID,
    output                                    control_S_AXI_WREADY,
    output     [1 :0]                         control_S_AXI_BRESP,
    output                                    control_S_AXI_BVALID,
    output                                    control_S_AXI_AWREADY

);

    localparam MAX_VAL = 2**REG_WIDTH-1;
    localparam MIN_VAL = 0;

    localparam L2_PKT_FIFO_DEPTH = 6;
    localparam L2_META_FIFO_DEPTH = 6;
    localparam REG_DEPTH = 2**INDEX_WIDTH;

    // data plane state machine states
    localparam RMW_START = 0;
    localparam WAIT_BRAM = 1;
    localparam L2_RMW_STATES = 1;

    // control plane state machine states
    localparam WAIT_REQ = 0;
    localparam WAIT_BRAM_CTRL = 1;
    localparam WRITE_READ_RESULT = 2;
    localparam L2_CTRL_STATES = 2;

    // parsed input signals
    wire                           req_in_valid;
    wire                           stateful_valid;
    wire [SINGLE_INPUT_WIDTH-1:0]  din_pfifo;
    wire [SINGLE_INPUT_WIDTH-1:0]  din_mfifo_0;
    wire [SINGLE_INPUT_WIDTH-1:0]  din_mfifo_1;
    wire [INDEX_WIDTH-1:0]         pkt_index_in;
    wire [REG_WIDTH-1:0]           pkt_data_in;
    wire [OP_WIDTH-1:0]            pkt_opCode_in;
    wire [INDEX_WIDTH-1:0]         meta_index_0_in;
    wire [REG_WIDTH-1:0]           meta_data_0_in;
    wire [OP_WIDTH-1:0]            meta_opCode_0_in;
    wire [INDEX_WIDTH-1:0]         meta_index_1_in;
    wire [REG_WIDTH-1:0]           meta_data_1_in;
    wire [OP_WIDTH-1:0]            meta_opCode_1_in;

    // request_fifo output signals 
    wire                           stateful_valid_fifo; 
    wire    [INDEX_WIDTH-1:0]      index_pfifo;
    wire    [REG_WIDTH-1:0]        data_pfifo;
    wire    [OP_WIDTH-1:0]         opCode_pfifo;
    wire    [INDEX_WIDTH-1:0]      index_mfifo  [1:0];
    wire    [REG_WIDTH-1:0]        data_mfifo   [1:0];
    wire    [OP_WIDTH-1:0]         opCode_mfifo [1:0];

    // packet event fifo signals
    wire empty_pfifo;
    wire full_pfifo;
    reg  rd_en_pfifo;
    wire wr_en_pfifo;

    // metadata event fifo signals
    wire empty_mfifo;
    wire full_mfifo;
    reg  rd_en_mfifo;
    wire wr_en_mfifo;

    // RMW state machine signals
    reg [L2_RMW_STATES-1:0]       rmw_state, rmw_state_next;
    reg [INDEX_WIDTH-1:0]         index, index_r, index_r_next;
    reg [OP_WIDTH-1:0]            opCode, opCode_r, opCode_r_next;
    reg [REG_WIDTH-1:0]           data, data_r, data_r_next;
    reg [REG_WIDTH-1:0]           result_r, result_r_next;
    reg                           result_valid_r, result_valid_r_next;
    reg [1:0]                     cycle_cnt_r, cycle_cnt_r_next;
    reg                           set_result_valid_r, set_result_valid_r_next;
    reg                           mfifo_slot_r, mfifo_slot_r_next;

    // control plane state machine signals
    reg [L2_CTRL_STATES-1:0]      c_state, c_state_next;
    reg [REG_WIDTH-1:0]           ip2cpu_data_r, ip2cpu_data_r_next;
    reg [INDEX_WIDTH-1:0]         ip2cpu_index_r, ip2cpu_index_r_next;
    reg [1:0]                     cycle_cnt_ctrl, cycle_cnt_ctrl_next;

    // BRAM signals
    reg                       c_we_bram;
    reg   [INDEX_WIDTH-1:0]   c_addr_in_bram, c_addr_in_bram_r, c_addr_in_bram_r_next;
    reg   [REG_WIDTH-1:0]     c_data_in_bram;
    wire  [REG_WIDTH-1:0]     c_data_out_bram;

    reg                      d_we_bram;
    reg  [INDEX_WIDTH-1:0]   d_addr_in_bram, d_addr_in_bram_r, d_addr_in_bram_r_next;
    reg  [REG_WIDTH-1:0]     d_data_in_bram;
    wire [REG_WIDTH-1:0]     d_data_out_bram;

    // control signals
    // CPU reads IP interface
    wire      [C_S_AXI_DATA_WIDTH-1:0]         ip2cpu_@PREFIX_NAME@_reg_data;
    reg       [REG_WIDTH-1:0]                  ip2cpu_@PREFIX_NAME@_reg_data_adj;
    reg       [INDEX_WIDTH-1:0]                ip2cpu_@PREFIX_NAME@_reg_index;
    reg                                        ip2cpu_@PREFIX_NAME@_reg_valid;
    wire      [INDEX_WIDTH-1:0]                ipReadReq_@PREFIX_NAME@_reg_index;
    wire                                       ipReadReq_@PREFIX_NAME@_reg_valid;

    // CPU writes IP interface
    wire     [C_S_AXI_DATA_WIDTH-1:0]          cpu2ip_@PREFIX_NAME@_reg_data;
    wire     [REG_WIDTH-1:0]                   cpu2ip_@PREFIX_NAME@_reg_data_adj;
    wire     [INDEX_WIDTH-1:0]                 cpu2ip_@PREFIX_NAME@_reg_index;
    wire                                       cpu2ip_@PREFIX_NAME@_reg_valid;

    reg      [INDEX_WIDTH-1:0]                 ipReadReq_index_r0;
    reg                                        ipReadReq_valid_r0;
    reg      [REG_WIDTH-1:0]                   cpu2ip_data_r0;
    reg      [INDEX_WIDTH-1:0]                 cpu2ip_index_r0;
    reg                                        cpu2ip_valid_r0;

    reg      [INDEX_WIDTH-1:0]                 ipReadReq_index_r1;
    reg                                        ipReadReq_valid_r1;
    reg      [REG_WIDTH-1:0]                   cpu2ip_data_r1;
    reg      [INDEX_WIDTH-1:0]                 cpu2ip_index_r1;
    reg                                        cpu2ip_valid_r1;

    wire resetn_sync;

    /*------------------------------------------------------*/
    /* Packet Event RMW Request FIFO (Strict High Priority) */
    /*------------------------------------------------------*/
    fallthrough_small_fifo
    #(
        .WIDTH(SINGLE_INPUT_WIDTH + 1),
        .MAX_DEPTH_BITS(L2_PKT_FIFO_DEPTH)
    )
    packet_fifo
    (
       // Outputs
       .dout                           ({stateful_valid_fifo, index_pfifo, data_pfifo, opCode_pfifo}),
       .full                           (full_pfifo),
       .nearly_full                    (),
       .prog_full                      (),
       .empty                          (empty_pfifo),
       // Inputs
       .din                            ({stateful_valid, din_pfifo}),
       .wr_en                          (wr_en_pfifo),
       .rd_en                          (rd_en_pfifo),
       .reset                          (~resetn_sync),
       .clk                            (clk_lookup)
    );

    /*-------------------------------------------------------*/
    /* Metadata Event RMW Request FIFO (Strict Low Priority) */
    /*-------------------------------------------------------*/
    fallthrough_small_fifo
    #(
        .WIDTH(2*SINGLE_INPUT_WIDTH),
        .MAX_DEPTH_BITS(L2_META_FIFO_DEPTH)
    )
    metadata_fifo
    (
       // Outputs
       .dout                           ({index_mfifo[0], data_mfifo[0], opCode_mfifo[0], index_mfifo[1], data_mfifo[1], opCode_mfifo[1]}),
       .full                           (full_mfifo),
       .nearly_full                    (),
       .prog_full                      (),
       .empty                          (empty_mfifo),
       // Inputs
       .din                            ({din_mfifo_0, din_mfifo_1}),
       .wr_en                          (wr_en_mfifo),
       .rd_en                          (rd_en_mfifo),
       .reset                          (~resetn_sync),
       .clk                            (clk_lookup)
    );

    /*---------------------*/
    /* BRAM Register Array */
    /*---------------------*/
    true_dp_bram
    #(
        .L2_DEPTH(INDEX_WIDTH),
        .WIDTH(REG_WIDTH)
    ) @PREFIX_NAME@_bram
    (
        .clk               (clk_lookup),
        // control plane R/W interface
        .we1               (c_we_bram),
        .en1               (1'b1),
        .addr1             (c_addr_in_bram),
        .din1              (c_data_in_bram),
        .rst1              (~resetn_sync),
        .regce1            (1'b1),
        .dout1             (c_data_out_bram),
        // data plane R/W interface
        .we2               (d_we_bram),
        .en2               (1'b1),
        .addr2             (d_addr_in_bram),
        .din2              (d_data_in_bram),
        .rst2              (~resetn_sync),
        .regce2            (1'b1),
        .dout2             (d_data_out_bram)
    );

    /*-----------------------*/
    /* Logic to parse inputs */
    /*-----------------------*/
    assign req_in_valid       = tuple_in_@EXTERN_NAME@_input_VALID;

    assign {stateful_valid,
            din_pfifo,
            din_mfifo_0,
            din_mfifo_1}      = tuple_in_@EXTERN_NAME@_input_DATA;

    assign {pkt_index_in,
            pkt_data_in,
            pkt_opCode_in}    = din_pfifo; 

    assign {meta_index_0_in,
            meta_data_0_in,
            meta_opCode_0_in} = din_mfifo_0;

    assign {meta_index_1_in,
            meta_data_1_in,
            meta_opCode_1_in} = din_mfifo_1;

    /*----------------------------*/
    /* Logic to write packet FIFO */
    /*----------------------------*/
    assign wr_en_pfifo = ~full_pfifo & req_in_valid;

    /*------------------------------*/
    /* Logic to write metadata FIFO */
    /*------------------------------*/
    // Requests will arrive on back-to-back cycles in the SDNet
    // simulations so we need to be able to write to the FIFOs
    // every cycle
    assign wr_en_mfifo = ~full_mfifo & req_in_valid & stateful_valid
                         & ( (meta_opCode_0_in != `NULL_OP) || (meta_opCode_1_in != `NULL_OP) );

    /*--------------------------------------------------*/
    /* Logic to read FIFOs, perform RMW operations, and */
    /* drive outputs                                    */
    /*--------------------------------------------------*/
    always @(*) begin
        // defaults
        rmw_state_next = rmw_state;

        // FIFO read signals
        rd_en_pfifo = 0;
        rd_en_mfifo = 0;

        // track which metadata fifo slot to read
        mfifo_slot_r_next = mfifo_slot_r;

        // BRAM read signals
        d_addr_in_bram = 0;
        d_addr_in_bram_r_next = d_addr_in_bram_r;
        // BRAM write signals
        d_we_bram = 0;
        d_data_in_bram = 0;

        // output signals
        result_valid_r_next = 0;
        result_r_next = 0;

        // BRAM cycle counter
        cycle_cnt_r_next = cycle_cnt_r;

        // RMW data
        index = 0;
        index_r_next = index_r;
        opCode = `NULL_OP; // default: do nothing
        opCode_r_next = opCode_r;
        data = 0;
        data_r_next = data_r;

        // to remember if we need to set result_valid after performing
        // the RMW operation
        set_result_valid_r_next = set_result_valid_r;

        case(rmw_state)
            RMW_START: begin
                // choose the index, opCode, and data to use
                rd_en_pfifo = ~empty_pfifo;
                // need to set result_valid anytime we read from the packet FIFO
                set_result_valid_r_next = rd_en_pfifo;
                if (~empty_pfifo & stateful_valid_fifo & (opCode_pfifo != `NULL_OP) & (index_pfifo < REG_DEPTH)) begin
                    // the result of the RMW operation at the head of the packet
                    // FIFO will actually be used
                    index = index_pfifo;
                    opCode = opCode_pfifo;
                    data = data_pfifo;
                end
                else if (~empty_mfifo & (index_mfifo[mfifo_slot_r] < REG_DEPTH)) begin
                    // perform a RMW operation from the metadata FIFO
                    index = index_mfifo[mfifo_slot_r];
                    opCode = opCode_mfifo[mfifo_slot_r];
                    data = data_mfifo[mfifo_slot_r];
                    if ( (mfifo_slot_r == 1) || ( (mfifo_slot_r == 0) && (opCode_mfifo[1] == `NULL_OP) ) ) begin
                        // only read from the metadata FIFO if we are already at the second slot or we are at
                        // the first slot and there's nothing to do in the next slot
                        rd_en_mfifo = 1;
                        mfifo_slot_r_next = 0;
                    end
                    else begin
                        mfifo_slot_r_next = 1;
                    end
                end

                // next state logic
                if (opCode == `WRITE_OP) begin
                    d_we_bram = 1;
                    d_addr_in_bram = index;
                    d_addr_in_bram_r_next = index;
                    d_data_in_bram = data;
                    // set result and result_valid regs immediately
                    result_r_next = data;
                    result_valid_r_next = rd_en_pfifo;
                    set_result_valid_r_next = 0;
                    // stay in same state
                    // assuming it's ok to submit back to back write ops
                end
                else if ( (opCode == `READ_OP) || (opCode == `ADD_OP) || (opCode == `SUB_OP) || (opCode == `READ_WRITE_OP) || (opCode == `ADD_SAT_OP) || (opCode == `SUB_SAT_OP)) begin
                    d_addr_in_bram = index;
                    d_addr_in_bram_r_next = index;
                    index_r_next = index;
                    data_r_next = data;
                    opCode_r_next = opCode;
                    rmw_state_next = WAIT_BRAM;
                end
                else begin
                    // still need to set result_valid reg
                    result_valid_r_next = rd_en_pfifo;
                    set_result_valid_r_next = 0;
                    if (opCode != `NULL_OP) begin
                        $display("ERROR: rmw_state = RMW_START, unsupported opCode: %0d\n", opCode);
                    end
                end
            end

            WAIT_BRAM: begin
                if (cycle_cnt_r == 1'b1) begin // 2 cycle BRAM read latency
                    cycle_cnt_r_next = 0;
                    if (opCode_r == `READ_OP) begin
                        result_r_next = d_data_out_bram;
                    end
                    else if (opCode_r == `ADD_OP) begin
                        d_we_bram = 1;
                        d_addr_in_bram = index_r;
                        d_addr_in_bram_r_next = index_r;
                        d_data_in_bram = d_data_out_bram + data_r;
                        result_r_next = d_data_out_bram + data_r;
                    end
                    else if (opCode_r == `SUB_OP) begin
                        d_we_bram = 1;
                        d_addr_in_bram = index_r;
                        d_addr_in_bram_r_next = index_r;
                        d_data_in_bram = d_data_out_bram - data_r;
                        result_r_next = d_data_out_bram - data_r;
                    end
                    else if (opCode_r == `READ_WRITE_OP) begin
                        d_we_bram = 1;
                        d_addr_in_bram = index_r;
                        d_addr_in_bram_r_next = index_r;
                        d_data_in_bram = data_r;
                        result_r_next = d_data_out_bram;
                    end
                    else if (opCode_r == `ADD_SAT_OP) begin
                        d_we_bram = 1;
                        d_addr_in_bram = index_r;
                        d_addr_in_bram_r_next = index_r;
                        if (data_r > (MAX_VAL - d_data_out_bram)) begin
                            d_data_in_bram = MAX_VAL;
                            result_r_next = MAX_VAL;
                        end
                        else begin
                            d_data_in_bram = d_data_out_bram + data_r;
                            result_r_next = d_data_out_bram + data_r;
                        end
                    end
                    else if (opCode_r == `SUB_SAT_OP) begin
                        d_we_bram = 1;
                        d_addr_in_bram = index_r;
                        d_addr_in_bram_r_next = index_r;
                        if (data_r > d_data_out_bram) begin
                            d_data_in_bram = MIN_VAL;
                            result_r_next = MIN_VAL;
                        end
                        else begin
                            d_data_in_bram = d_data_out_bram - data_r;
                            result_r_next = d_data_out_bram - data_r;
                        end
                    end
                    else begin
                        $display("ERROR: rmw_state = WAIT_BRAM, unsupported opCode: %0d\n", opCode_r);
                    end
                    rmw_state_next = RMW_START;
                    // only need to set result_valid if we originally read from the packet FIFO
                    result_valid_r_next = set_result_valid_r;
                    set_result_valid_r_next = 0;
                end
                else begin
                    cycle_cnt_r_next = cycle_cnt_r + 1;
                end
            end
        endcase
    end

    always @(posedge clk_lookup) begin
        if (~resetn_sync) begin
            rmw_state <= RMW_START;
            index_r <= 0;
            opCode_r <= 0;
            data_r <= 0;
            result_r <= 0;
            result_valid_r <= 0;
            d_addr_in_bram_r <= 0;
            cycle_cnt_r <= 0;
            set_result_valid_r <= 0;
            mfifo_slot_r <= 0;
        end
        else begin
            rmw_state <= rmw_state_next;
            index_r <= index_r_next;
            opCode_r <= opCode_r_next;
            data_r <= data_r_next;
            result_r <= result_r_next;
            result_valid_r <= result_valid_r_next;
            d_addr_in_bram_r <= d_addr_in_bram_r_next;
            cycle_cnt_r <= cycle_cnt_r_next;
            set_result_valid_r <= set_result_valid_r_next;
            mfifo_slot_r <= mfifo_slot_r_next;
        end
    end

    /*---------------------*/
    /* Wire up the outputs */
    /*---------------------*/
    assign tuple_out_@EXTERN_NAME@_output_VALID = result_valid_r;
    assign tuple_out_@EXTERN_NAME@_output_DATA  = result_r;

    ////////////////////////
    //// CPU REGS START ////
    ////////////////////////

    /*-----------------*/
    /* CPU Regs module */
    /*-----------------*/
    @PREFIX_NAME@_cpu_regs
    #(
        .C_BASE_ADDRESS        (0),
        .C_S_AXI_DATA_WIDTH    (C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH    (C_S_AXI_ADDR_WIDTH)
    ) @PREFIX_NAME@_cpu_regs_inst
    (
      // General ports
       .clk                    ( clk_lookup),
       .resetn                 (~clk_lookup_rst_high),
      // AXI Lite ports
       .S_AXI_ACLK             (clk_control),
       .S_AXI_ARESETN          (clk_control_rst_low),
       .S_AXI_AWADDR           (control_S_AXI_AWADDR),
       .S_AXI_AWVALID          (control_S_AXI_AWVALID),
       .S_AXI_WDATA            (control_S_AXI_WDATA),
       .S_AXI_WSTRB            (control_S_AXI_WSTRB),
       .S_AXI_WVALID           (control_S_AXI_WVALID),
       .S_AXI_BREADY           (control_S_AXI_BREADY),
       .S_AXI_ARADDR           (control_S_AXI_ARADDR),
       .S_AXI_ARVALID          (control_S_AXI_ARVALID),
       .S_AXI_RREADY           (control_S_AXI_RREADY),
       .S_AXI_ARREADY          (control_S_AXI_ARREADY),
       .S_AXI_RDATA            (control_S_AXI_RDATA),
       .S_AXI_RRESP            (control_S_AXI_RRESP),
       .S_AXI_RVALID           (control_S_AXI_RVALID),
       .S_AXI_WREADY           (control_S_AXI_WREADY),
       .S_AXI_BRESP            (control_S_AXI_BRESP),
       .S_AXI_BVALID           (control_S_AXI_BVALID),
       .S_AXI_AWREADY          (control_S_AXI_AWREADY),
    
      // Register ports
      // CPU reads IP interface
      .ip2cpu_@PREFIX_NAME@_reg_data          (ip2cpu_@PREFIX_NAME@_reg_data),
      .ip2cpu_@PREFIX_NAME@_reg_index         (ip2cpu_@PREFIX_NAME@_reg_index),
      .ip2cpu_@PREFIX_NAME@_reg_valid         (ip2cpu_@PREFIX_NAME@_reg_valid),
      .ipReadReq_@PREFIX_NAME@_reg_index       (ipReadReq_@PREFIX_NAME@_reg_index),
      .ipReadReq_@PREFIX_NAME@_reg_valid      (ipReadReq_@PREFIX_NAME@_reg_valid),
      // CPU writes IP interface
      .cpu2ip_@PREFIX_NAME@_reg_data          (cpu2ip_@PREFIX_NAME@_reg_data),
      .cpu2ip_@PREFIX_NAME@_reg_index         (cpu2ip_@PREFIX_NAME@_reg_index),
      .cpu2ip_@PREFIX_NAME@_reg_valid         (cpu2ip_@PREFIX_NAME@_reg_valid),
      // Global Registers - user can select if to use
      .cpu_resetn_soft(),//software reset, after cpu module
      .resetn_soft    (),//software reset to cpu module (from central reset management)
      .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
    );

    /*---------------------------------------------------*/
    /* Logic to adjust bus widths based on register size */
    /*---------------------------------------------------*/
    generate
    if (C_S_AXI_DATA_WIDTH > REG_WIDTH) begin: SMALL_REG
        assign ip2cpu_@PREFIX_NAME@_reg_data = {'d0, ip2cpu_@PREFIX_NAME@_reg_data_adj};
        assign cpu2ip_@PREFIX_NAME@_reg_data_adj = cpu2ip_@PREFIX_NAME@_reg_data[C_S_AXI_DATA_WIDTH-1:0];
    end
    else if (C_S_AXI_DATA_WIDTH < REG_WIDTH) begin: LARGE_REG
        assign ip2cpu_@PREFIX_NAME@_reg_data = ip2cpu_@PREFIX_NAME@_reg_data_adj[C_S_AXI_DATA_WIDTH-1:0];
        assign cpu2ip_@PREFIX_NAME@_reg_data_adj = {'d0, cpu2ip_@PREFIX_NAME@_reg_data};
    end
    else begin: NORMAL_REG
        assign ip2cpu_@PREFIX_NAME@_reg_data = ip2cpu_@PREFIX_NAME@_reg_data_adj;
        assign cpu2ip_@PREFIX_NAME@_reg_data_adj = cpu2ip_@PREFIX_NAME@_reg_data;
    end
    endgenerate

    /*-----------------------------------------*/
    /* Logic to pipeline control-plane signals */
    /* (this is probably unnecessary ...)      */
    /*-----------------------------------------*/
    always @ (posedge clk_lookup) begin
        if (~resetn_sync) begin
            cpu2ip_data_r0 <= 0;
            cpu2ip_index_r0 <= 0;
            cpu2ip_valid_r0 <= 0;

            ipReadReq_index_r0 <= 0;
            ipReadReq_valid_r0 <= 0;

            cpu2ip_data_r1 <= 0;
            cpu2ip_index_r1 <= 0;
            cpu2ip_valid_r1 <= 0;

            ipReadReq_index_r1 <= 0;
            ipReadReq_valid_r1 <= 0;
        end
        else begin
            cpu2ip_data_r0 <= cpu2ip_@PREFIX_NAME@_reg_data_adj;
            cpu2ip_index_r0 <= cpu2ip_@PREFIX_NAME@_reg_index;
            cpu2ip_valid_r0 <= cpu2ip_@PREFIX_NAME@_reg_valid;

            ipReadReq_index_r0 <= ipReadReq_@PREFIX_NAME@_reg_index;
            ipReadReq_valid_r0 <= ipReadReq_@PREFIX_NAME@_reg_valid;

            cpu2ip_data_r1 <=  cpu2ip_data_r0;
            cpu2ip_index_r1 <= cpu2ip_index_r0;
            cpu2ip_valid_r1 <= cpu2ip_valid_r0;

            ipReadReq_index_r1 <= ipReadReq_index_r0;
            ipReadReq_valid_r1 <= ipReadReq_valid_r0;
        end
    end

    /*---------------------------------*/
    /* Control Plane R/W state machine */
    /*---------------------------------*/
    always @(*) begin
       // default values
       c_state_next   = c_state;

       c_we_bram = 0;
       c_addr_in_bram = c_addr_in_bram_r;
       c_addr_in_bram_r_next = c_addr_in_bram_r;
       c_data_in_bram = 0;

       ip2cpu_data_r_next = ip2cpu_data_r;
       ip2cpu_index_r_next = ip2cpu_index_r;

       cycle_cnt_ctrl_next = cycle_cnt_ctrl;

       ip2cpu_@PREFIX_NAME@_reg_valid = 0;
       ip2cpu_@PREFIX_NAME@_reg_data_adj = 0;
       ip2cpu_@PREFIX_NAME@_reg_index = 0;

       case(c_state)
           WAIT_REQ: begin
               if (cpu2ip_valid_r1 && cpu2ip_index_r1 < REG_DEPTH) begin
                   c_we_bram = 1;
                   c_addr_in_bram = cpu2ip_index_r1;
                   c_addr_in_bram_r_next = cpu2ip_index_r1;
                   c_data_in_bram = cpu2ip_data_r1;
               end
               else if (ipReadReq_valid_r1) begin
                   if (ipReadReq_index_r1 < REG_DEPTH) begin
                       c_addr_in_bram = ipReadReq_index_r1;
                       c_addr_in_bram_r_next = ipReadReq_index_r1;
                       c_state_next = WAIT_BRAM_CTRL;
                   end
                   else begin
                       $display("ERROR: c_state = WAIT_REQ, requested read index out of range: %0d\n", ipReadReq_index_r1);
                       ip2cpu_data_r_next = 0;
                       ip2cpu_index_r_next = 0;
                       c_state_next = WRITE_READ_RESULT;
                   end
               end
           end

           WAIT_BRAM_CTRL: begin
               if (cycle_cnt_ctrl == 1'b1) begin // 2 cycle BRAM read latency
                   cycle_cnt_ctrl_next = 0;
                   ip2cpu_data_r_next = c_data_out_bram;
                   ip2cpu_index_r_next = c_addr_in_bram_r;
                   c_state_next = WRITE_READ_RESULT;
               end
               else begin
                   cycle_cnt_ctrl_next = cycle_cnt_ctrl + 1;
               end
           end

           WRITE_READ_RESULT: begin
               ip2cpu_@PREFIX_NAME@_reg_valid = 1;
               ip2cpu_@PREFIX_NAME@_reg_data_adj = ip2cpu_data_r;
               ip2cpu_@PREFIX_NAME@_reg_index = ip2cpu_index_r;
               c_state_next = WAIT_REQ;
           end
       endcase // case(c_state)
    end // always @ (*)

    // state machine is running on clk_lookup because the cpu_regs module
    // should be synchronized to this clock internally (also, the clks are
    // the same anyways...)
    always @(posedge clk_lookup) begin
       if(~resetn_sync) begin
          c_state <= WAIT_REQ;
          c_addr_in_bram_r <= 0;

          ip2cpu_data_r <= 0;
          ip2cpu_index_r <= 0;
          cycle_cnt_ctrl <= 0;
       end
       else begin
          c_state <= c_state_next;
          c_addr_in_bram_r <= c_addr_in_bram_r_next;

          ip2cpu_data_r <= ip2cpu_data_r_next;
          ip2cpu_index_r <= ip2cpu_index_r_next;
          cycle_cnt_ctrl <= cycle_cnt_ctrl_next;
       end
    end

endmodule
