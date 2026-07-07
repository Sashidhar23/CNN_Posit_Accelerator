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
    parameter ROWS = 3,
    parameter COLS = 3,
    parameter QW = 48,
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
    input  wire ext_input_write_en,
    input  wire [31:0] ext_input_addr,
    input  wire [N-1:0] ext_input_data,
    input  wire ext_weight_write_en,
    input  wire [31:0] ext_weight_addr,
    input  wire [N-1:0] ext_weight_data,
    input  wire ext_bias_write_en,
    input  wire [31:0] ext_bias_addr,
    input  wire [N-1:0] ext_bias_data,
    input  wire [31:0] ext_output_addr,
    output reg  [N-1:0] ext_output_data,
    output reg  busy,
    output reg  done
);

    localparam integer DOT_LEN = IN_CH * K * K;
    localparam integer PIPE_CYCLES = (2*ROWS) + (2*COLS) + 4;
    localparam integer ROW_ADDR_W = (ROWS <= 2) ? 1 : $clog2(ROWS);
    localparam integer COL_ADDR_W = (COLS <= 2) ? 1 : $clog2(COLS);
    localparam integer WEIGHT_ADDR_W = (ROWS*COLS <= 2) ? 1 : $clog2(ROWS*COLS);

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

    (* ram_style = "block" *) reg [N-1:0] input_mem  [0:IN_CH*IN_H*IN_W-1];
    (* ram_style = "block" *) reg [N-1:0] weight_mem [0:OUT_CH*IN_CH*K*K-1];
    (* ram_style = "block" *) reg [N-1:0] bias_mem   [0:OUT_CH-1];
    (* ram_style = "block" *) reg [N-1:0] output_mem [0:OUT_CH*OUT_H*OUT_W-1];

    always @(posedge clk) begin
        if (!busy) begin
            if (ext_input_write_en && (ext_input_addr < IN_CH*IN_H*IN_W))
                input_mem[ext_input_addr] <= ext_input_data;

            if (ext_weight_write_en && (ext_weight_addr < OUT_CH*IN_CH*K*K))
                weight_mem[ext_weight_addr] <= ext_weight_data;

            if (ext_bias_write_en && (ext_bias_addr < OUT_CH))
                bias_mem[ext_bias_addr] <= ext_bias_data;
        end

        if (ext_output_addr < OUT_CH*OUT_H*OUT_W)
            ext_output_data <= output_mem[ext_output_addr];
        else
            ext_output_data <= {N{1'b0}};
    end

    reg [3:0] state;
    reg [31:0] oh;
    reg [31:0] ow;
    reg [31:0] oc_base;
    reg [31:0] dot_base;
    reg [31:0] run_count;
    reg [31:0] load_index;
    reg [31:0] accum_col;
    reg [COL_ADDR_W:0] store_col;

    reg core_pe_en;
    reg core_clear_acc;
    reg core_wshift;
    reg core_input_clear;
    reg core_input_write_en;
    reg core_input_read_en;
    reg core_output_clear;
    reg core_output_write_en;
    reg core_output_read_en;

    reg core_activation_load_en;
    reg [ROW_ADDR_W-1:0] core_activation_row;
    reg [N-1:0] core_activation_data;
    reg core_activation_vector_load_en;
    reg [ROWS*N-1:0] core_activation_vector_data;
    reg core_weight_load_en;
    reg [WEIGHT_ADDR_W-1:0] core_weight_addr;
    reg [N-1:0] core_weight_data;
    reg [COL_ADDR_W-1:0] core_output_col;
    reg [N-1:0] acc_reg [0:COLS-1];

    wire [N-1:0] core_output_data;
    wire core_output_is_nar;
    wire [COLS*N-1:0] core_output_vector_data;
    wire [COLS-1:0] core_output_vector_is_nar;
    wire [N-1:0] accum_selected_sum;
    wire [ROWS-1:0] input_full;
    wire [ROWS-1:0] input_empty;

    integer i;
    integer dot_idx;
    integer load_row;
    integer load_col;
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

    posit_adder #(
        .N(N),
        .ES(ES)
    ) TILE_ACCUM_ADDER (
        .posit_a(acc_reg[accum_col]),
        .posit_b(core_output_data),
        .posit_out(accum_selected_sum)
    );

    systolic_core_quire_sp701 #(
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
        .activation_load_en(core_activation_load_en),
        .activation_row(core_activation_row),
        .activation_data(core_activation_data),
        .activation_vector_load_en(core_activation_vector_load_en),
        .activation_vector_data(core_activation_vector_data),
        .weight_load_en(core_weight_load_en),
        .weight_addr(core_weight_addr),
        .weight_data(core_weight_data),
        .input_clear(core_input_clear),
        .input_write_en(core_input_write_en),
        .input_read_en(core_input_read_en),
        .output_clear(core_output_clear),
        .output_write_en(core_output_write_en),
        .output_read_en(core_output_read_en),
        .output_col(core_output_col),
        .output_data(core_output_data),
        .output_is_nar(core_output_is_nar),
        .output_vector_data(core_output_vector_data),
        .output_vector_is_nar(core_output_vector_is_nar),
        .input_full(input_full),
        .input_empty(input_empty)
    );

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
            load_index <= 0;
            accum_col <= 0;
            store_col <= 0;
            core_pe_en <= 1'b0;
            core_clear_acc <= 1'b0;
            core_wshift <= 1'b0;
            core_input_clear <= 1'b1;
            core_input_write_en <= 1'b0;
            core_input_read_en <= 1'b0;
            core_output_clear <= 1'b1;
            core_output_write_en <= 1'b0;
            core_output_read_en <= 1'b0;
            core_activation_load_en <= 1'b0;
            core_activation_row <= {ROW_ADDR_W{1'b0}};
            core_activation_data <= {N{1'b0}};
            core_activation_vector_load_en <= 1'b0;
            core_activation_vector_data <= {ROWS*N{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_addr <= {WEIGHT_ADDR_W{1'b0}};
            core_weight_data <= {N{1'b0}};
            core_output_col <= {COL_ADDR_W{1'b0}};
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
            core_activation_load_en <= 1'b0;
            core_activation_data <= {N{1'b0}};
            core_activation_vector_load_en <= 1'b0;
            core_activation_vector_data <= {ROWS*N{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_data <= {N{1'b0}};
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
                    load_index <= 0;
                    state <= ST_LOAD;
                end

                ST_LOAD: begin
                    if (load_index < ROWS*COLS) begin
                        load_row = load_index / COLS;
                        load_col = load_index - (load_row * COLS);
                        dot_idx = dot_base + load_row;
                        out_ch_idx = oc_base + load_col;

                        core_weight_load_en <= 1'b1;
                        core_weight_addr <= load_index[WEIGHT_ADDR_W-1:0];

                        if ((dot_idx < DOT_LEN) && (out_ch_idx < OUT_CH))
                            core_weight_data <= weight_mem[(out_ch_idx * DOT_LEN) + dot_idx];
                        else
                            core_weight_data <= {N{1'b0}};

                        load_index <= load_index + 1;
                    end
                    else begin
                        core_clear_acc <= 1'b1;
                        core_wshift <= 1'b1;
                        load_index <= 0;
                        state <= ST_WRITE;
                    end
                end

                ST_WRITE: begin
                    if (load_index < ROWS) begin
                        dot_idx = dot_base + load_index;
                        core_activation_load_en <= 1'b1;
                        core_activation_row <= load_index[ROW_ADDR_W-1:0];
                        core_activation_data <= activation_at(dot_idx, oh, ow);
                        load_index <= load_index + 1;
                    end
                    else begin
                        core_input_write_en <= 1'b1;
                        load_index <= 0;
                        state <= ST_READ;
                    end
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
                        accum_col <= 0;
                        core_output_col <= {COL_ADDR_W{1'b0}};
                        state <= ST_ACCUM;
                    end
                    else begin
                        run_count <= run_count + 1;
                    end
                end

                ST_ACCUM: begin
                    if ((oc_base + accum_col) < OUT_CH)
                        acc_reg[accum_col] <= core_output_is_nar ? {1'b1, {(N-1){1'b0}}} : accum_selected_sum;

                    if (accum_col == COLS-1) begin
                        state <= ST_NEXT_DOT;
                    end
                    else begin
                        accum_col <= accum_col + 1;
                        core_output_col <= core_output_col + 1'b1;
                    end
                end

                ST_NEXT_DOT: begin
                    if ((dot_base + ROWS) < DOT_LEN) begin
                        dot_base <= dot_base + ROWS;
                        core_input_clear <= 1'b1;
                        core_output_clear <= 1'b1;
                        load_index <= 0;
                        state <= ST_LOAD;
                    end
                    else begin
                        store_col <= 0;
                        state <= ST_STORE;
                    end
                end

                ST_STORE: begin
                    if (store_col < COLS) begin
                        if ((oc_base + store_col) < OUT_CH) begin
                            out_index = ((oc_base + store_col) * OUT_H * OUT_W) + (oh * OUT_W) + ow;
                            output_mem[out_index] <= acc_reg[store_col];
                        end
                        store_col <= store_col + 1;
                    end
                    else begin
                        state <= ST_NEXT_TILE;
                    end
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
