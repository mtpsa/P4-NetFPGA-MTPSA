`timescale 1 ps / 1 ps

module @MODULE_NAME@
#(
    parameter BITMASK_WIDTH = @BITMASK_WIDTH@,
    parameter PKT_LEN_WIDTH = @PKT_LEN_WIDTH@
)
(
    input clk_lookup,
    input rst,

    input                                  tuple_in_@EXTERN_NAME@_input_VALID,
    input [BITMASK_WIDTH+PKT_LEN_WIDTH:0]  tuple_in_@EXTERN_NAME@_input_DATA,

    output                     tuple_out_@EXTERN_NAME@_output_VALID,
    output [BITMASK_WIDTH-1:0] tuple_out_@EXTERN_NAME@_output_DATA
);
    localparam INPUT_WIDTH = BITMASK_WIDTH+PKT_LEN_WIDTH;

    wire [BITMASK_WIDTH-1:0] bitmask = tuple_in_@EXTERN_NAME@_input_DATA[INPUT_WIDTH:PKT_LEN_WIDTH];
    wire [PKT_LEN_WIDTH-1:0] pkt_len = tuple_in_@EXTERN_NAME@_input_DATA[PKT_LEN_WIDTH-1:0];

    wire valid_in       = tuple_in_@EXTERN_NAME@_input_VALID;

    reg result_valid_r, result_valid_r_next;
    reg [BITMASK_WIDTH-1:0] result_r, result_r_next;

    integer k;
    /* State Machine to drive outputs */
    always @(*) begin
        // default values
        result_valid_r_next = valid_in;
        result_r_next = 0;

        for (k=0; k<BITMASK_WIDTH; k=k+1) begin
            if (bitmask[k] == 0) begin
                result_r_next = k+1;
                break;
            end
        end
    end

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
