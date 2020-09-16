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

module demux #(
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter USER_ID_WIDTH=8
) (
    input                                                           axis_aclk,
    input                                                           axis_resetn,

    // Master ports
    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_0_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_0_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_0_tuser,
    output reg                                                      m_axis_0_tvalid,
    output reg                                                      m_axis_0_tlast,
    input                                                           m_axis_0_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_1_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_1_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_1_tuser,
    output reg                                                      m_axis_1_tvalid,
    output reg                                                      m_axis_1_tlast,
    input                                                           m_axis_1_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_2_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_2_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_2_tuser,
    output reg                                                      m_axis_2_tvalid,
    output reg                                                      m_axis_2_tlast,
    input                                                           m_axis_2_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_3_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_3_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_3_tuser,
    output reg                                                      m_axis_3_tvalid,
    output reg                                                      m_axis_3_tlast,
    input                                                           m_axis_3_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_4_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_4_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_4_tuser,
    output reg                                                      m_axis_4_tvalid,
    output reg                                                      m_axis_4_tlast,
    input                                                           m_axis_4_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_5_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_5_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_5_tuser,
    output reg                                                      m_axis_5_tvalid,
    output reg                                                      m_axis_5_tlast,
    input                                                           m_axis_5_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_6_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_6_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_6_tuser,
    output reg                                                      m_axis_6_tvalid,
    output reg                                                      m_axis_6_tlast,
    input                                                           m_axis_6_tready,

    output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_7_tdata,
    output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_7_tkeep,
    output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_7_tuser,
    output reg                                                      m_axis_7_tvalid,
    output reg                                                      m_axis_7_tlast,
    input                                                           m_axis_7_tready,

    // Slave ports
    input   [C_M_AXIS_DATA_WIDTH - 1:0]                             s_axis_tdata,
    input   [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_tkeep,
    input   [C_M_AXIS_TUSER_WIDTH-1:0]                              s_axis_tuser,
    input                                                           s_axis_tvalid,
    input                                                           s_axis_tlast,
    output reg                                                      s_axis_tready,

    input [USER_ID_WIDTH-1:0]                                       user_id
);

    localparam NUM_STATES  = 3;
    localparam WAIT        = 0;
    localparam WRITE_BEGIN = 1;
    localparam WRITE_END   = 2;

    reg [USER_ID_WIDTH - 1:0]                 demux_user_id;
    reg [NUM_STATES-1:0]                      demux_state;
    reg                                       demux_end_pkt;

    reg [C_S_AXIS_DATA_WIDTH - 1:0]           demux_tdata;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   demux_tkeep;
    reg [C_M_AXIS_TUSER_WIDTH-1:0]            demux_tuser;
    reg                                       demux_tvalid;
    reg                                       demux_tlast;

    reg [C_S_AXIS_DATA_WIDTH - 1:0]           demux_tdata_next;
    reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   demux_tkeep_next;
    reg [C_M_AXIS_TUSER_WIDTH-1:0]            demux_tuser_next;
    reg                                       demux_tvalid_next;
    reg                                       demux_tlast_next;

    always @(posedge axis_aclk) begin
        if (axis_resetn) begin
            case (demux_state)
                WAIT: begin
                    s_axis_tready <= 1;

                    demux_end_pkt <= 0;
                    demux_user_id <= user_id;

                    demux_tdata  <= s_axis_tdata;
                    demux_tuser  <= s_axis_tuser;
                    demux_tkeep  <= s_axis_tkeep;
                    demux_tvalid <= s_axis_tvalid;
                    demux_tlast  <= s_axis_tlast;

                    demux_tdata_next <= 0;
                    demux_tkeep_next <= 0;
                    demux_tuser_next <= 0;
                    demux_tvalid_next<= 0;
                    demux_tlast_next <= 0;

                    m_axis_0_tdata  <= 0;
                    m_axis_0_tkeep  <= 0;
                    m_axis_0_tuser  <= 0;
                    m_axis_0_tvalid <= 0;
                    m_axis_0_tlast  <= 0;

                    m_axis_1_tdata  <= 0;
                    m_axis_1_tkeep  <= 0;
                    m_axis_1_tuser  <= 0;
                    m_axis_1_tvalid <= 0;
                    m_axis_1_tlast  <= 0;

                    m_axis_2_tdata  <= 0;
                    m_axis_2_tkeep  <= 0;
                    m_axis_2_tuser  <= 0;
                    m_axis_2_tvalid <= 0;
                    m_axis_2_tlast  <= 0;

                    m_axis_3_tdata  <= 0;
                    m_axis_3_tkeep  <= 0;
                    m_axis_3_tuser  <= 0;
                    m_axis_3_tvalid <= 0;
                    m_axis_3_tlast  <= 0;

                    m_axis_4_tdata  <= 0;
                    m_axis_4_tkeep  <= 0;
                    m_axis_4_tuser  <= 0;
                    m_axis_4_tvalid <= 0;
                    m_axis_4_tlast  <= 0;

                    m_axis_5_tdata  <= 0;
                    m_axis_5_tkeep  <= 0;
                    m_axis_5_tuser  <= 0;
                    m_axis_5_tvalid <= 0;
                    m_axis_5_tlast  <= 0;

                    m_axis_6_tdata  <= 0;
                    m_axis_6_tkeep  <= 0;
                    m_axis_6_tuser  <= 0;
                    m_axis_6_tvalid <= 0;
                    m_axis_6_tlast  <= 0;

                    m_axis_7_tdata  <= 0;
                    m_axis_7_tkeep  <= 0;
                    m_axis_7_tuser  <= 0;
                    m_axis_7_tvalid <= 0;
                    m_axis_7_tlast  <= 0;

                    if (s_axis_tvalid)
                        demux_state = WRITE_BEGIN;
                    else
                        demux_state = WAIT;
                end

                WRITE_BEGIN: begin
                    s_axis_tready <= 1;
                    demux_tdata_next  <= s_axis_tdata;
                    demux_tuser_next  <= s_axis_tuser;
                    demux_tkeep_next  <= s_axis_tkeep;
                    demux_tvalid_next <= s_axis_tvalid;
                    demux_tlast_next  <= s_axis_tlast;

                    demux_state = WRITE_END;

                    if (demux_user_id == 8'h00) begin
                        if ( m_axis_0_tready == 1 ) begin
                            m_axis_0_tdata  <= demux_tdata;
                            m_axis_0_tuser  <= demux_tuser;
                            m_axis_0_tkeep  <= demux_tkeep;
                            m_axis_0_tvalid <= demux_tvalid;
                            m_axis_0_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h01) begin
                        if (m_axis_1_tready == 1) begin
                            m_axis_1_tdata  <= demux_tdata;
                            m_axis_1_tuser  <= demux_tuser;
                            m_axis_1_tkeep  <= demux_tkeep;
                            m_axis_1_tvalid <= demux_tvalid;
                            m_axis_1_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h02) begin
                        if (m_axis_2_tready == 1) begin
                            m_axis_2_tdata  <= demux_tdata;
                            m_axis_2_tuser  <= demux_tuser;
                            m_axis_2_tkeep  <= demux_tkeep;
                            m_axis_2_tvalid <= demux_tvalid;
                            m_axis_2_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h03) begin
                        if (m_axis_3_tready == 1) begin
                            m_axis_3_tdata  <= demux_tdata;
                            m_axis_3_tuser  <= demux_tuser;
                            m_axis_3_tkeep  <= demux_tkeep;
                            m_axis_3_tvalid <= demux_tvalid;
                            m_axis_3_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h04) begin
                        if (m_axis_4_tready == 1) begin
                            m_axis_4_tdata  <= demux_tdata;
                            m_axis_4_tuser  <= demux_tuser;
                            m_axis_4_tkeep  <= demux_tkeep;
                            m_axis_4_tvalid <= demux_tvalid;
                            m_axis_4_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h05) begin
                        if (m_axis_5_tready == 1) begin
                            m_axis_5_tdata  <= demux_tdata;
                            m_axis_5_tuser  <= demux_tuser;
                            m_axis_5_tkeep  <= demux_tkeep;
                            m_axis_5_tvalid <= demux_tvalid;
                            m_axis_5_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h06) begin
                        if (m_axis_6_tready == 1) begin
                            m_axis_6_tdata  <= demux_tdata;
                            m_axis_6_tuser  <= demux_tuser;
                            m_axis_6_tkeep  <= demux_tkeep;
                            m_axis_6_tvalid <= demux_tvalid;
                            m_axis_6_tlast  <= demux_tlast;
                        end
                    end else if (demux_user_id == 8'h07) begin
                        if (m_axis_7_tready == 1) begin
                            m_axis_7_tdata  <= demux_tdata;
                            m_axis_7_tuser  <= demux_tuser;
                            m_axis_7_tkeep  <= demux_tkeep;
                            m_axis_7_tvalid <= demux_tvalid;
                            m_axis_7_tlast  <= demux_tlast;
                        end
                    end else begin
                        demux_state = WAIT;
                    end

                    if (s_axis_tlast) begin
                        demux_state = WRITE_END;
                        s_axis_tready <= 0;
                        demux_end_pkt <= 1;
                    end else begin
                        if (demux_end_pkt) begin
                            demux_state = WAIT;
                            s_axis_tready <= 1;
                        end
                    end
                end // case: WRITE_BEGIN

                WRITE_END: begin
                    s_axis_tready <= 1;

                    demux_tdata <= s_axis_tdata;
                    demux_tuser <= s_axis_tuser;
                    demux_tkeep <= s_axis_tkeep;
                    demux_tvalid <= s_axis_tvalid;
                    demux_tlast <= s_axis_tlast;

                    demux_state = WRITE_BEGIN;

                    if (demux_user_id == 8'h00) begin
                        if (m_axis_0_tready == 1) begin
                            m_axis_0_tdata  <= demux_tdata_next;
                            m_axis_0_tuser  <= demux_tuser_next;
                            m_axis_0_tkeep  <= demux_tkeep_next;
                            m_axis_0_tvalid <= demux_tvalid_next;
                            m_axis_0_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h01) begin
                        if (m_axis_1_tready == 1) begin
                            m_axis_1_tdata  <= demux_tdata_next;
                            m_axis_1_tuser  <= demux_tuser_next;
                            m_axis_1_tkeep  <= demux_tkeep_next;
                            m_axis_1_tvalid <= demux_tvalid_next;
                            m_axis_1_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h02) begin
                        if (m_axis_2_tready == 1) begin
                            m_axis_2_tdata  <= demux_tdata_next;
                            m_axis_2_tuser  <= demux_tuser_next;
                            m_axis_2_tkeep  <= demux_tkeep_next;
                            m_axis_2_tvalid <= demux_tvalid_next;
                            m_axis_2_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h03) begin
                        if (m_axis_3_tready == 1) begin
                            m_axis_3_tdata  <= demux_tdata_next;
                            m_axis_3_tuser  <= demux_tuser_next;
                            m_axis_3_tkeep  <= demux_tkeep_next;
                            m_axis_3_tvalid <= demux_tvalid_next;
                            m_axis_3_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h04) begin
                        if (m_axis_4_tready == 1) begin
                            m_axis_4_tdata  <= demux_tdata_next;
                            m_axis_4_tuser  <= demux_tuser_next;
                            m_axis_4_tkeep  <= demux_tkeep_next;
                            m_axis_4_tvalid <= demux_tvalid_next;
                            m_axis_4_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h05) begin
                        if (m_axis_5_tready == 1) begin
                            m_axis_5_tdata  <= demux_tdata_next;
                            m_axis_5_tuser  <= demux_tuser_next;
                            m_axis_5_tkeep  <= demux_tkeep_next;
                            m_axis_5_tvalid <= demux_tvalid_next;
                            m_axis_5_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h06) begin
                        if (m_axis_6_tready == 1) begin
                            m_axis_6_tdata  <= demux_tdata_next;
                            m_axis_6_tuser  <= demux_tuser_next;
                            m_axis_6_tkeep  <= demux_tkeep_next;
                            m_axis_6_tvalid <= demux_tvalid_next;
                            m_axis_6_tlast  <= demux_tlast_next;
                        end
                    end else if (demux_user_id == 8'h07) begin
                        if (m_axis_7_tready == 1) begin
                            m_axis_7_tdata  <= demux_tdata_next;
                            m_axis_7_tuser  <= demux_tuser_next;
                            m_axis_7_tkeep  <= demux_tkeep_next;
                            m_axis_7_tvalid <= demux_tvalid_next;
                            m_axis_7_tlast  <= demux_tlast_next;
                        end
                    end else begin
                        demux_state = WAIT;
                    end

                    if ( s_axis_tlast ) begin
                        demux_state = WRITE_BEGIN;
                        s_axis_tready <= 0;
                        demux_end_pkt <= 1;
                    end else begin
                        if(demux_end_pkt) begin
                            demux_state = WAIT;
                            s_axis_tready <= 1;
                        end
                    end

                end
            endcase
        end else begin // if ( axis_resetn )
            s_axis_tready <= 0;

            demux_user_id <= 0;
            demux_tdata <= 0;
            demux_tkeep <= 0;
            demux_tuser <= 0;
            demux_tvalid <= 0;
            demux_tlast <= 0;

            demux_tdata_next <= 0;
            demux_tkeep_next <= 0;
            demux_tuser_next <= 0;
            demux_tvalid_next <= 0;
            demux_tlast_next <= 0;

            m_axis_0_tdata  <= 0;
            m_axis_0_tkeep  <= 0;
            m_axis_0_tuser  <= 0;
            m_axis_0_tvalid <= 0;
            m_axis_0_tlast  <= 0;

            m_axis_1_tdata  <= 0;
            m_axis_1_tkeep  <= 0;
            m_axis_1_tuser  <= 0;
            m_axis_1_tvalid <= 0;
            m_axis_1_tlast  <= 0;

            m_axis_2_tdata  <= 0;
            m_axis_2_tkeep  <= 0;
            m_axis_2_tuser  <= 0;
            m_axis_2_tvalid <= 0;
            m_axis_2_tlast  <= 0;

            m_axis_3_tdata  <= 0;
            m_axis_3_tkeep  <= 0;
            m_axis_3_tuser  <= 0;
            m_axis_3_tvalid <= 0;
            m_axis_3_tlast  <= 0;

            m_axis_4_tdata  <= 0;
            m_axis_4_tkeep  <= 0;
            m_axis_4_tuser  <= 0;
            m_axis_4_tvalid <= 0;
            m_axis_4_tlast  <= 0;

            m_axis_5_tdata  <= 0;
            m_axis_5_tkeep  <= 0;
            m_axis_5_tuser  <= 0;
            m_axis_5_tvalid <= 0;
            m_axis_5_tlast  <= 0;

            m_axis_6_tdata  <= 0;
            m_axis_6_tkeep  <= 0;
            m_axis_6_tuser  <= 0;
            m_axis_6_tvalid <= 0;
            m_axis_6_tlast  <= 0;

            m_axis_7_tdata  <= 0;
            m_axis_7_tkeep  <= 0;
            m_axis_7_tuser  <= 0;
            m_axis_7_tvalid <= 0;
            m_axis_7_tlast  <= 0;

            demux_end_pkt <= 0;
            demux_state = WAIT;
        end // // if ( axis_resetn )
    end // always @(posedge axis_aclk)
endmodule
