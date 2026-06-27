`timescale 1ns / 1ps

module systolic_array_quire #(
    parameter N = 8,
    parameter ES = 1,
    parameter ROWS = 6,
    parameter COLS = 6,
    parameter QW = 128,
    parameter QF = QW / 2
)(
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         pe_en,
    input  wire                         clear_acc,
    input  wire                         wshift,

    input  wire [ROWS*N-1:0]            activation_in,
    input  wire [ROWS*COLS*N-1:0]       weight_in,

    output wire [ROWS*N-1:0]            activation_out,
    output wire [ROWS*COLS*N-1:0]       weight_out,
    output wire [ROWS*COLS*QW-1:0]      quire_out,
    output wire [ROWS*COLS-1:0]         is_nar,
    output wire [ROWS*COLS*N-1:0]       pe_output
);

    wire [ROWS*(COLS+1)*N-1:0] act_bus;

    genvar r;
    genvar c;

    generate
        for (r = 0; r < ROWS; r = r + 1) begin : ROW_GEN
            assign act_bus[(r*(COLS+1))*N +: N] = activation_in[r*N +: N];
            assign activation_out[r*N +: N] = act_bus[(r*(COLS+1)+COLS)*N +: N];

            for (c = 0; c < COLS; c = c + 1) begin : COL_GEN
                pe_quire #(
                    .N(N),
                    .ES(ES),
                    .QW(QW),
                    .QF(QF)
                ) PE_QUIRE_INST (
                    .clk       (clk),
                    .reset     (reset),
                    .pe_en     (pe_en),
                    .clear_acc (clear_acc),
                    .wshift    (wshift),
                    .input_in  (act_bus[(r*(COLS+1)+c)*N +: N]),
                    .weight_in (weight_in[(r*COLS+c)*N +: N]),
                    .input_out (act_bus[(r*(COLS+1)+c+1)*N +: N]),
                    .weight_out(weight_out[(r*COLS+c)*N +: N]),
                    .quire_out (quire_out[(r*COLS+c)*QW +: QW]),
                    .is_nar    (is_nar[r*COLS+c]),
                    .pe_output (pe_output[(r*COLS+c)*N +: N])
                );
            end
        end
    endgenerate

endmodule
