`timescale 1ns / 1ps

module mtpsa_to_sdnet (
    // clk/rst input
    input                               axis_aclk,
    input                               axis_resetn,
    // input axis signals
    input                               SUME_axis_tvalid,
    input                               SUME_axis_tlast,
    input                               SUME_axis_tready,
    // output signals
    output reg                          SDNet_tuple_VALID,
    output                              SDNet_axis_TLAST
);

reg [1:0]   state;
reg [1:0]   state_next;

wire [1:0] state_debug = state;

localparam FIRST = 0;
localparam WAIT = 1;

always @(*) begin
    state_next = state;
    SDNet_tuple_VALID = 0;

    case(state)
        /* wait to complete first cycle of packet */
        FIRST: begin
            if (SUME_axis_tvalid & SUME_axis_tready) begin
                SDNet_tuple_VALID = 1;
                state_next = WAIT;
            end
        end

        /* wait until last cycle of packet */
        WAIT: begin
            if (SUME_axis_tvalid & SUME_axis_tlast & SUME_axis_tready) begin
                state_next = FIRST;
            end
        end
    endcase
end


always @(posedge axis_aclk) begin
    if(~axis_resetn) begin
        state <= FIRST;
    end else begin
        state <= state_next;
    end
end

// the SDNet_TLAST signal should only go high when TVALID is high
assign SDNet_axis_TLAST = SUME_axis_tvalid & SUME_axis_tlast;

endmodule
