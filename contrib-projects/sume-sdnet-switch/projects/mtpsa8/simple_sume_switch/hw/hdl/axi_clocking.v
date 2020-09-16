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

`timescale 1ps / 1ps
(* dont_touch = "yes" *)
module axi_clocking
(
    // Inputs
    input clk_in_p,
    input clk_in_n,
    input resetn,
    // Status outputs

    // IBUFDS 200MHz
    output locked,
    output clk_200
);
    // Signal declarations
    wire s_axi_dcm_aclk0;
    wire clkfbout;

    // 200MHz differencial into single-rail
    IBUFDS clkin1_buf
    (
        .O  (clkin1),
        .I  (clk_in_p),
        .IB (clk_in_n)
    );

    clk_wiz_ip clk_wiz_i
    (
        // Clock in ports
        .clk_in1(clkin1),      // input clk_in1
        // Clock out ports
        .clk_out1(clk_200),     // output clk_out1
        // Status and control signals
        .resetn(resetn), // input resetn
        .locked(locked)
    );
endmodule
