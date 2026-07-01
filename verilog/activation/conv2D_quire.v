`timescale 1ns / 1ps

module conv2D_quire #(
    parameter N = 8,
    parameter ES = 1,
    parameter IN_CH = 1,
    parameter IN_H = 28,
    parameter IN_W = 28,
    parameter OUT_CH = 64,
    parameter K = 3,
    parameter PADDING = 1,
    parameter STRIDE = 1,
    parameter ROWS = 6,
    parameter COLS = 6,
    parameter QW = 128,
    parameter QF = QW / 2,
    parameter OUT_H = ((IN_H + (2*PADDING) - K) / STRIDE) + 1,
    parameter OUT_W = ((IN_W + (2*PADDING) - K) / STRIDE) + 1,
    parameter IN_FIFO_DEPTH = 16,
    parameter IN_COUNT_W = $clog2(IN_FIFO_DEPTH + 1),
    parameter OUT_FIFO_DEPTH = 16,
    parameter OUT_COUNT_W = $clog2(OUT_FIFO_DEPTH + 1)
)(
    input  wire clk,
    input  wire reset,
    input  wire start,
    output reg  busy,
    output reg  done
);

    localparam integer DOT_LEN = IN_CH * K * K;
    localparam integer PIPE_CYCLES = ROWS + COLS + 4;

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_INIT_TILE  = 4'd1;
    localparam [3:0] ST_LOAD       = 4'd2;
    localparam [3:0] ST_WRITE      = 4'd3;
    localparam [3:0] ST_READ       = 4'd4;
    localparam [3:0] ST_RUN        = 4'd5;
    localparam [3:0] ST_ACCUM      = 4'd6;
    localparam [3:0] ST_NEXT_DOT   = 4'd7;
    localparam [3:0] ST_STORE      = 4'd8;
    localparam [3:0] ST_NEXT_TILE  = 4'd9;
    localparam [3:0] ST_DONE       = 4'd10;

    reg [N-1:0] input_mem  [0:IN_CH*IN_H*IN_W-1];
    reg [N-1:0] weight_mem [0:OUT_CH*IN_CH*K*K-1];
    reg [N-1:0] bias_mem   [0:OUT_CH-1];
    reg [N-1:0] output_mem [0:OUT_CH*OUT_H*OUT_W-1];

    reg [3:0] state;
    reg [31:0] oh;
    reg [31:0] ow;
    reg [31:0] oc_base;
    reg [31:0] dot_base;
    reg [31:0] run_count;

    reg core_pe_en;
    reg core_clear_acc;
    reg core_wshift;
    reg core_input_clear;
    reg core_input_write_en;
    reg core_input_read_en;
    reg core_output_clear;
    reg core_output_write_en;
    reg core_output_read_en;

    reg [ROWS*N-1:0] activation_bus;
    reg [ROWS*COLS*N-1:0] weight_bus;
    reg [N-1:0] acc_reg [0:COLS-1];

    wire [COLS*N-1:0] buffered_pe_output;
    wire [N-1:0] accum_sum [0:COLS-1];

    wire [ROWS*N-1:0] fifo_activation;
    wire [ROWS*N-1:0] skewed_activation;
    wire [ROWS*N-1:0] activation_out;
    wire [ROWS*COLS*N-1:0] weight_out;
    wire [ROWS*COLS*QW-1:0] quire_out;
    wire [ROWS*COLS-1:0] is_nar;
    wire [ROWS*COLS*N-1:0] pe_output;
    wire [COLS*QW-1:0] column_quire_out;
    wire [COLS-1:0] column_is_nar;
    wire [COLS*N-1:0] column_psum_out;
    wire [ROWS-1:0] input_full;
    wire [ROWS-1:0] input_empty;
    wire [ROWS*IN_COUNT_W-1:0] input_count;
    wire [COLS-1:0] output_full;
    wire [COLS-1:0] output_empty;
    wire [COLS*OUT_COUNT_W-1:0] output_count;

    integer i;
    integer rr;
    integer cc;
    integer dot_idx;
    integer out_ch_idx;
    integer out_index;

    function [N-1:0] activation_at;
        input integer dot;
        input integer y;
        input integer x;
        integer ch;
        integer rem;
        integer fy;
        integer fx;
        integer iy;
        integer ix;
        begin
            ch = dot / (K*K);
            rem = dot - (ch * K * K);
            fy = rem / K;
            fx = rem - (fy * K);
            iy = (y * STRIDE) + fy - PADDING;
            ix = (x * STRIDE) + fx - PADDING;

            if ((dot < DOT_LEN) && (iy >= 0) && (iy < IN_H) && (ix >= 0) && (ix < IN_W))
                activation_at = input_mem[(ch * IN_H * IN_W) + (iy * IN_W) + ix];
            else
                activation_at = {N{1'b0}};
        end
    endfunction

    generate
        genvar ga;
        for (ga = 0; ga < COLS; ga = ga + 1) begin : ACCUM_ADD_GEN
            posit_adder #(
                .N(N),
                .ES(ES)
            ) TILE_ACCUM_ADDER (
                .posit_a(acc_reg[ga]),
                .posit_b(buffered_pe_output[ga*N +: N]),
                .posit_out(accum_sum[ga])
            );
        end
    endgenerate

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
        .clk(clk),
        .reset(reset),
        .pe_en(core_pe_en),
        .clear_acc(core_clear_acc),
        .wshift(core_wshift),
        .activation_in(activation_bus),
        .weight_in(weight_bus),
        .input_clear(core_input_clear),
        .input_write_en(core_input_write_en),
        .input_read_en(core_input_read_en),
        .output_clear(core_output_clear),
        .output_write_en(core_output_write_en),
        .output_read_en(core_output_read_en),
        .fifo_activation(fifo_activation),
        .skewed_activation(skewed_activation),
        .activation_out(activation_out),
        .weight_out(weight_out),
        .quire_out(quire_out),
        .is_nar(is_nar),
        .pe_output(pe_output),
        .column_quire_out(column_quire_out),
        .column_is_nar(column_is_nar),
        .column_psum_out(column_psum_out),
        .buffered_pe_output(buffered_pe_output),
        .input_full(input_full),
        .input_empty(input_empty),
        .input_count(input_count),
        .output_full(output_full),
        .output_empty(output_empty),
        .output_count(output_count)
    );

    always @(*) begin
        activation_bus = {ROWS*N{1'b0}};
        weight_bus = {ROWS*COLS*N{1'b0}};

        for (rr = 0; rr < ROWS; rr = rr + 1) begin
            dot_idx = dot_base + rr;
            activation_bus[rr*N +: N] = activation_at(dot_idx, oh, ow);

            for (cc = 0; cc < COLS; cc = cc + 1) begin
                out_ch_idx = oc_base + cc;
                if ((dot_idx < DOT_LEN) && (out_ch_idx < OUT_CH))
                    weight_bus[(rr*COLS + cc)*N +: N] =
                        weight_mem[(out_ch_idx * DOT_LEN) + dot_idx];
                else
                    weight_bus[(rr*COLS + cc)*N +: N] = {N{1'b0}};
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            oh <= 0;
            ow <= 0;
            oc_base <= 0;
            dot_base <= 0;
            run_count <= 0;
            core_pe_en <= 1'b0;
            core_clear_acc <= 1'b0;
            core_wshift <= 1'b0;
            core_input_clear <= 1'b1;
            core_input_write_en <= 1'b0;
            core_input_read_en <= 1'b0;
            core_output_clear <= 1'b1;
            core_output_write_en <= 1'b0;
            core_output_read_en <= 1'b0;
            for (i = 0; i < COLS; i = i + 1)
                acc_reg[i] <= {N{1'b0}};
        end
        else begin
            core_pe_en <= 1'b0;
            core_clear_acc <= 1'b0;
            core_wshift <= 1'b0;
            core_input_clear <= 1'b0;
            core_input_write_en <= 1'b0;
            core_input_read_en <= 1'b0;
            core_output_clear <= 1'b0;
            core_output_write_en <= 1'b0;
            core_output_read_en <= 1'b0;
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        oh <= 0;
                        ow <= 0;
                        oc_base <= 0;
                        dot_base <= 0;
                        core_input_clear <= 1'b1;
                        core_output_clear <= 1'b1;
                        state <= ST_INIT_TILE;
                    end
                end

                ST_INIT_TILE: begin
                    for (i = 0; i < COLS; i = i + 1) begin
                        if ((oc_base + i) < OUT_CH)
                            acc_reg[i] <= bias_mem[oc_base + i];
                        else
                            acc_reg[i] <= {N{1'b0}};
                    end
                    dot_base <= 0;
                    core_input_clear <= 1'b1;
                    core_output_clear <= 1'b1;
                    state <= ST_LOAD;
                end

                ST_LOAD: begin
                    core_clear_acc <= 1'b1;
                    core_wshift <= 1'b1;
                    state <= ST_WRITE;
                end

                ST_WRITE: begin
                    core_input_write_en <= 1'b1;
                    state <= ST_READ;
                end

                ST_READ: begin
                    core_input_read_en <= 1'b1;
                    run_count <= 0;
                    state <= ST_RUN;
                end

                ST_RUN: begin
                    core_pe_en <= 1'b1;
                    core_output_write_en <= 1'b1;
                    if (run_count == PIPE_CYCLES-1) begin
                        for (i = 0; i < COLS; i = i + 1) begin
                            if ((oc_base + i) < OUT_CH)
                                acc_reg[i] <= accum_sum[i];
                        end
                        state <= ST_NEXT_DOT;
                    end
                    else begin
                        run_count <= run_count + 1;
                    end
                end

                ST_NEXT_DOT: begin
                    if ((dot_base + ROWS) < DOT_LEN) begin
                        dot_base <= dot_base + ROWS;
                        core_input_clear <= 1'b1;
                        core_output_clear <= 1'b1;
                        state <= ST_LOAD;
                    end
                    else begin
                        state <= ST_STORE;
                    end
                end

                ST_STORE: begin
                    for (i = 0; i < COLS; i = i + 1) begin
                        if ((oc_base + i) < OUT_CH) begin
                            out_index = ((oc_base + i) * OUT_H * OUT_W) + (oh * OUT_W) + ow;
                            output_mem[out_index] <= acc_reg[i];
                        end
                    end
                    state <= ST_NEXT_TILE;
                end

                ST_NEXT_TILE: begin
                    if ((oc_base + COLS) < OUT_CH) begin
                        oc_base <= oc_base + COLS;
                        state <= ST_INIT_TILE;
                    end
                    else begin
                        oc_base <= 0;
                        if (ow + 1 < OUT_W) begin
                            ow <= ow + 1;
                            state <= ST_INIT_TILE;
                        end
                        else begin
                            ow <= 0;
                            if (oh + 1 < OUT_H) begin
                                oh <= oh + 1;
                                state <= ST_INIT_TILE;
                            end
                            else begin
                                state <= ST_DONE;
                            end
                        end
                    end
                end

                ST_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
