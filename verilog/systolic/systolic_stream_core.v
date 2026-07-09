`timescale 1ns / 1ps

module systolic_stream_core #(
    parameter N = 8,
    parameter ES = 1,
    parameter ROWS = 3,
    parameter COLS = 3,
    parameter TAG_W = 1,
    parameter ROW_ADDR_W = (ROWS <= 2) ? 1 : $clog2(ROWS),
    parameter COL_ADDR_W = (COLS <= 2) ? 1 : $clog2(COLS),
    parameter WEIGHT_ADDR_W = (ROWS*COLS <= 2) ? 1 : $clog2(ROWS*COLS),
    parameter MAX_ROW_DELAY = (ROWS <= 1) ? 1 : (2*(ROWS-1)),
    parameter OUT_DELAY_DEPTH = (COLS <= 1) ? 1 : (COLS-1),
    parameter RESULT_LATENCY = (2*ROWS) + COLS
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         pe_en,
    input  wire                         clear_pipe,
    input  wire                         wshift,

    input  wire [ROWS*N-1:0]            activation_in,
    input  wire                         stream_valid,
    input  wire [TAG_W-1:0]             stream_tag,

    input  wire                         weight_load_en,
    input  wire [WEIGHT_ADDR_W-1:0]     weight_addr,
    input  wire [N-1:0]                 weight_data,

    output reg                          result_valid,
    output reg  [TAG_W-1:0]             result_tag,
    output reg  [COLS*N-1:0]            result_data
);

    reg [ROWS*COLS*N-1:0] weight_regs;
    reg [N-1:0] row_delay [0:ROWS-1][0:MAX_ROW_DELAY-1];
    reg [N-1:0] output_delay [0:COLS-1][0:OUT_DELAY_DEPTH-1];
    reg [RESULT_LATENCY-1:0] valid_pipe;
    reg [TAG_W-1:0] tag_pipe [0:RESULT_LATENCY-1];

    wire [ROWS*N-1:0] array_activation;
    wire [COLS*N-1:0] column_psum_out;
    wire [COLS*N-1:0] aligned_output;

    integer i;
    integer r;
    integer d;
    integer c;

    genvar gr;
    genvar gc;

    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : ROW_DELAY_GEN
            if (gr == 0) begin : ROW0
                assign array_activation[gr*N +: N] = activation_in[gr*N +: N];
            end
            else begin : ROW_DELAYED
                assign array_activation[gr*N +: N] =
                    row_delay[gr][(2*gr)-1];
            end
        end

        for (gc = 0; gc < COLS; gc = gc + 1) begin : OUT_ALIGN_GEN
            if (gc == COLS-1) begin : LAST_COL
                assign aligned_output[gc*N +: N] = column_psum_out[gc*N +: N];
            end
            else begin : DELAYED_COL
                assign aligned_output[gc*N +: N] =
                    output_delay[gc][COLS-gc-2];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            weight_regs <= {ROWS*COLS*N{1'b0}};
        end
        else if (weight_load_en && weight_addr < ROWS*COLS) begin
            weight_regs[weight_addr*N +: N] <= weight_data;
        end
    end

    always @(posedge clk) begin
        if (reset || clear_pipe) begin
            for (r = 0; r < ROWS; r = r + 1) begin
                for (d = 0; d < MAX_ROW_DELAY; d = d + 1)
                    row_delay[r][d] <= {N{1'b0}};
            end

            for (c = 0; c < COLS; c = c + 1) begin
                for (d = 0; d < OUT_DELAY_DEPTH; d = d + 1)
                    output_delay[c][d] <= {N{1'b0}};
            end

            valid_pipe <= {RESULT_LATENCY{1'b0}};
            for (i = 0; i < RESULT_LATENCY; i = i + 1)
                tag_pipe[i] <= {TAG_W{1'b0}};

            result_valid <= 1'b0;
            result_tag <= {TAG_W{1'b0}};
            result_data <= {COLS*N{1'b0}};
        end
        else if (pe_en) begin
            for (r = 1; r < ROWS; r = r + 1) begin
                row_delay[r][0] <= activation_in[r*N +: N];
                for (d = 1; d < 2*r; d = d + 1)
                    row_delay[r][d] <= row_delay[r][d-1];
            end

            for (c = 0; c < COLS-1; c = c + 1) begin
                output_delay[c][0] <= column_psum_out[c*N +: N];
                for (d = 1; d < COLS-c-1; d = d + 1)
                    output_delay[c][d] <= output_delay[c][d-1];
            end

            valid_pipe[0] <= stream_valid;
            tag_pipe[0] <= stream_tag;
            for (i = 1; i < RESULT_LATENCY; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                tag_pipe[i] <= tag_pipe[i-1];
            end

            result_valid <= valid_pipe[RESULT_LATENCY-1];
            result_tag <= tag_pipe[RESULT_LATENCY-1];
            result_data <= aligned_output;
        end
        else begin
            result_valid <= 1'b0;
        end
    end

    systolic_array #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS)
    ) ARRAY (
        .clk            (clk),
        .reset          (reset),
        .pe_en          (pe_en),
        .clear_acc      (clear_pipe),
        .wshift         (wshift),
        .activation_in  (array_activation),
        .weight_in      (weight_regs),
        .activation_out (),
        .weight_out     (),
        .product_out    (),
        .mac_out        (),
        .psum_out       (column_psum_out),
        .pe_output      ()
    );

endmodule
