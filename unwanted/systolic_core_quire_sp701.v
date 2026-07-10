`timescale 1ns / 1ps

module systolic_core_quire_sp701 #(
    parameter N = 8,
    parameter ES = 1,
    parameter ROWS = 3,
    parameter COLS = 3,
    parameter QW = 48,
    parameter QF = QW / 2,
    parameter IN_FIFO_DEPTH = 16,
    parameter IN_COUNT_W = $clog2(IN_FIFO_DEPTH + 1),
    parameter OUT_FIFO_DEPTH = 16,
    parameter OUT_COUNT_W = $clog2(OUT_FIFO_DEPTH + 1),
    parameter ROW_ADDR_W = (ROWS <= 2) ? 1 : $clog2(ROWS),
    parameter COL_ADDR_W = (COLS <= 2) ? 1 : $clog2(COLS),
    parameter WEIGHT_ADDR_W = (ROWS*COLS <= 2) ? 1 : $clog2(ROWS*COLS)
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     pe_en,
    input  wire                     clear_acc,
    input  wire                     wshift,

    input  wire                     activation_load_en,
    input  wire [ROW_ADDR_W-1:0]    activation_row,
    input  wire [N-1:0]             activation_data,
    input  wire                     activation_vector_load_en,
    input  wire [ROWS*N-1:0]        activation_vector_data,

    input  wire                     weight_load_en,
    input  wire [WEIGHT_ADDR_W-1:0] weight_addr,
    input  wire [N-1:0]             weight_data,

    input  wire                     input_clear,
    input  wire                     input_write_en,
    input  wire                     input_read_en,
    input  wire                     output_clear,
    input  wire                     output_write_en,
    input  wire                     output_read_en,

    input  wire [COL_ADDR_W-1:0]    output_col,
    output reg  [N-1:0]             output_data,
    output reg                      output_is_nar,
    output wire [COLS*N-1:0]        output_vector_data,
    output wire [COLS-1:0]          output_vector_is_nar,
    output wire [ROWS-1:0]          input_full,
    output wire [ROWS-1:0]          input_empty
);

    reg [ROWS*N-1:0] activation_regs;
    reg [ROWS*COLS*N-1:0] weight_regs;
    reg [COLS*N-1:0] latched_output_regs;
    reg [COLS-1:0] latched_nar_regs;

    wire [COLS*N-1:0] buffered_pe_output;
    wire [COLS-1:0] column_is_nar;
    wire [ROWS*N-1:0] core_activation_in;

    integer i;

    assign core_activation_in = activation_vector_load_en ? activation_vector_data : activation_regs;
    assign output_vector_data = latched_output_regs;
    assign output_vector_is_nar = latched_nar_regs;

    always @(posedge clk) begin
        if (reset) begin
            activation_regs <= {ROWS*N{1'b0}};
            weight_regs <= {ROWS*COLS*N{1'b0}};
            latched_output_regs <= {COLS*N{1'b0}};
            latched_nar_regs <= {COLS{1'b0}};
        end
        else begin
            if (output_clear) begin
                latched_output_regs <= {COLS*N{1'b0}};
                latched_nar_regs <= {COLS{1'b0}};
            end
            else if (output_write_en) begin
                for (i = 0; i < COLS; i = i + 1) begin
                    if ((buffered_pe_output[i*N +: N] != {N{1'b0}}) || column_is_nar[i]) begin
                        latched_output_regs[i*N +: N] <= buffered_pe_output[i*N +: N];
                        latched_nar_regs[i] <= column_is_nar[i];
                    end
                end
            end

            if (activation_load_en && activation_row < ROWS)
                activation_regs[activation_row*N +: N] <= activation_data;

            if (weight_load_en && weight_addr < ROWS*COLS)
                weight_regs[weight_addr*N +: N] <= weight_data;
        end
    end

    always @(*) begin
        output_data = {N{1'b0}};
        output_is_nar = 1'b0;
        for (i = 0; i < COLS; i = i + 1) begin
            if (output_col == i[COL_ADDR_W-1:0]) begin
                output_data = latched_output_regs[i*N +: N];
                output_is_nar = latched_nar_regs[i];
            end
        end
    end

    systolic_core_quire #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS),
        .QW(QW),
        .QF(QF),
        .IN_FIFO_DEPTH(IN_FIFO_DEPTH),
        .IN_COUNT_W(IN_COUNT_W),
        .OUT_FIFO_DEPTH(OUT_FIFO_DEPTH),
        .OUT_COUNT_W(OUT_COUNT_W)
    ) CORE (
        .clk                (clk),
        .reset              (reset),
        .pe_en              (pe_en),
        .clear_acc          (clear_acc),
        .wshift             (wshift),
        .activation_in      (core_activation_in),
        .weight_in          (weight_regs),
        .input_clear        (input_clear),
        .input_write_en     (input_write_en),
        .input_read_en      (input_read_en),
        .output_clear       (output_clear),
        .output_write_en    (output_write_en),
        .output_read_en     (output_read_en),
        .fifo_activation    (),
        .skewed_activation  (),
        .activation_out     (),
        .weight_out         (),
        .quire_out          (),
        .is_nar             (),
        .pe_output          (),
        .column_quire_out   (),
        .column_is_nar      (column_is_nar),
        .column_psum_out    (),
        .buffered_pe_output (buffered_pe_output),
        .input_full         (input_full),
        .input_empty        (input_empty),
        .input_count        (),
        .output_full        (),
        .output_empty       (),
        .output_count       ()
    );

endmodule
