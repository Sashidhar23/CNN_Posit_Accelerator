`timescale 1ns / 1ps

module systolic_core #(
    parameter N = 8,
    parameter ES = 1,
    parameter ROWS = 6,
    parameter COLS = 6,
    parameter IN_FIFO_DEPTH = 16,
    parameter IN_COUNT_W = $clog2(IN_FIFO_DEPTH + 1),
    parameter OUT_FIFO_DEPTH = 16,
    parameter OUT_COUNT_W = $clog2(OUT_FIFO_DEPTH + 1)
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         pe_en,
    input  wire                         clear_acc,
    input  wire                         wshift,

    input  wire [ROWS*N-1:0]            activation_in,
    input  wire [ROWS*COLS*N-1:0]       weight_in,

    input  wire                         input_clear,
    input  wire                         input_write_en,
    input  wire                         input_read_en,

    input  wire                         output_clear,
    input  wire                         output_write_en,
    input  wire                         output_read_en,

    output wire [ROWS*N-1:0]            fifo_activation,
    output wire [ROWS*N-1:0]            skewed_activation,
    output wire [ROWS*N-1:0]            activation_out,
    output wire [ROWS*COLS*N-1:0]       weight_out,
    output wire [ROWS*COLS*N-1:0]       product_out,
    output wire [ROWS*COLS*N-1:0]       mac_out,
    output wire [ROWS*COLS*N-1:0]       pe_output,
    output wire [COLS*N-1:0]            column_psum_out,

    output wire [COLS*N-1:0]            buffered_pe_output,
    output wire [ROWS-1:0]              input_full,
    output wire [ROWS-1:0]              input_empty,
    output wire [ROWS*IN_COUNT_W-1:0]   input_count,
    output wire [COLS-1:0]              output_full,
    output wire [COLS-1:0]              output_empty,
    output wire [COLS*OUT_COUNT_W-1:0]  output_count
);

    reg [N-1:0] row_delay [0:ROWS-1][0:ROWS-1];
    reg [N-1:0] output_delay [0:COLS-1][0:COLS-1];
    reg [ROWS-1:0] fifo_valid;
    wire [ROWS*N-1:0] fifo_activation_gated;

    integer r;
    integer d;
    integer oc;
    integer od;

    always @(posedge clk) begin
        if (reset) begin
            fifo_valid <= {ROWS{1'b0}};
            for (r = 0; r < ROWS; r = r + 1) begin
                for (d = 0; d < ROWS; d = d + 1) begin
                    row_delay[r][d] <= {N{1'b0}};
                end
            end
        end
        else begin
            if (input_read_en) begin
                for (r = 0; r < ROWS; r = r + 1) begin
                    fifo_valid[r] <= !input_empty[r];
                end
            end
            else if (pe_en) begin
                fifo_valid <= {ROWS{1'b0}};
            end

            if (pe_en) begin
                for (r = 1; r < ROWS; r = r + 1) begin
                    row_delay[r][0] <= fifo_activation_gated[r*N +: N];
                    for (d = 1; d < r; d = d + 1) begin
                        row_delay[r][d] <= row_delay[r][d-1];
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset || output_clear) begin
            for (oc = 0; oc < COLS; oc = oc + 1) begin
                for (od = 0; od < COLS; od = od + 1) begin
                    output_delay[oc][od] <= {N{1'b0}};
                end
            end
        end
        else if (output_write_en) begin
            for (oc = 0; oc < COLS-1; oc = oc + 1) begin
                output_delay[oc][0] <= column_psum_out[oc*N +: N];
                for (od = 1; od < COLS-oc-1; od = od + 1) begin
                    output_delay[oc][od] <= output_delay[oc][od-1];
                end
            end
        end
    end

    genvar gr;
    genvar gc;

    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : SKEW_GEN
            input_fifo #(
                .WIDTH(N),
                .DEPTH((gr == 0) ? 1 : gr),
                .COUNT_W(IN_COUNT_W)
            ) ROW_INPUT_FIFO (
                .clk      (clk),
                .reset    (reset),
                .clear    (input_clear),
                .write_en (input_write_en),
                .read_en  (input_read_en),
                .data_in  (activation_in[gr*N +: N]),
                .data_out (fifo_activation[gr*N +: N]),
                .full     (input_full[gr]),
                .empty    (input_empty[gr]),
                .count    (input_count[gr*IN_COUNT_W +: IN_COUNT_W])
            );

            if (gr == 0) begin : ROW0
                assign skewed_activation[gr*N +: N] = fifo_activation_gated[gr*N +: N];
            end
            else begin : ROW_DELAYED
                assign skewed_activation[gr*N +: N] = row_delay[gr][gr-1];
            end

            assign fifo_activation_gated[gr*N +: N] =
                fifo_valid[gr] ? fifo_activation[gr*N +: N] : {N{1'b0}};
        end
    endgenerate

    systolic_array #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS)
    ) ARRAY (
        .clk            (clk),
        .reset          (reset),
        .pe_en          (pe_en),
        .clear_acc      (clear_acc),
        .wshift         (wshift),
        .activation_in  (skewed_activation),
        .weight_in      (weight_in),
        .activation_out (activation_out),
        .weight_out     (weight_out),
        .product_out    (product_out),
        .mac_out        (mac_out),
        .psum_out       (column_psum_out),
        .pe_output      (pe_output)
    );

    generate
        for (gc = 0; gc < COLS; gc = gc + 1) begin : OUTPUT_SYNC_GEN
            if (gc == COLS-1) begin : LAST_COL
                assign buffered_pe_output[gc*N +: N] = column_psum_out[gc*N +: N];
            end
            else begin : DELAYED_COL
                assign buffered_pe_output[gc*N +: N] = output_delay[gc][COLS-gc-2];
            end

            assign output_full[gc] = 1'b0;
            assign output_empty[gc] = 1'b0;
            assign output_count[gc*OUT_COUNT_W +: OUT_COUNT_W] = {OUT_COUNT_W{1'b0}};
        end
    endgenerate

endmodule
