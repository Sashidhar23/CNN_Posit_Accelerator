`timescale 1ns / 1ps

module conv2D #(
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
    localparam integer OUT_PIXELS = OUT_H * OUT_W;
    localparam integer PIXEL_ADDR_W = (OUT_PIXELS <= 2) ? 1 : $clog2(OUT_PIXELS);
    localparam integer ROW_ADDR_W = (ROWS <= 2) ? 1 : $clog2(ROWS);
    localparam integer COL_ADDR_W = (COLS <= 2) ? 1 : $clog2(COLS);
    localparam integer WEIGHT_ADDR_W = (ROWS*COLS <= 2) ? 1 : $clog2(ROWS*COLS);

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_INIT_TILE  = 4'd1;
    localparam [3:0] ST_LOAD       = 4'd2;
    localparam [3:0] ST_STREAM     = 4'd3;
    localparam [3:0] ST_NEXT_DOT   = 4'd4;
    localparam [3:0] ST_NEXT_TILE  = 4'd5;
    localparam [3:0] ST_DONE       = 4'd6;

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
    reg [31:0] oc_base;
    reg [31:0] dot_base;
    reg [31:0] load_index;
    reg [31:0] init_index;
    reg [31:0] stream_send_count;
    reg [31:0] stream_recv_count;

    reg core_pe_en;
    reg core_clear_pipe;
    reg core_wshift;
    reg core_stream_valid;
    reg [PIXEL_ADDR_W-1:0] core_stream_tag;
    reg [ROWS*N-1:0] core_activation_vector_data;
    reg core_weight_load_en;
    reg [WEIGHT_ADDR_W-1:0] core_weight_addr;
    reg [N-1:0] core_weight_data;

    wire core_result_valid;
    wire [PIXEL_ADDR_W-1:0] core_result_tag;
    wire [COLS*N-1:0] core_result_data;

    wire [N-1:0] stream_acc_old [0:COLS-1];
    wire [N-1:0] stream_acc_sum [0:COLS-1];

    integer i;
    integer dot_idx;
    integer load_row;
    integer load_col;
    integer out_ch_idx;
    integer init_col;
    integer init_pix;
    integer stream_y;
    integer stream_x;
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

    genvar gc;
    generate
        for (gc = 0; gc < COLS; gc = gc + 1) begin : STREAM_ACC_GEN
            assign stream_acc_old[gc] =
                ((oc_base + gc) < OUT_CH) ?
                output_mem[((oc_base + gc) * OUT_PIXELS) + core_result_tag] :
                {N{1'b0}};

            posit_adder #(
                .N(N),
                .ES(ES)
            ) STREAM_ACCUM_ADDER (
                .posit_a(stream_acc_old[gc]),
                .posit_b(core_result_data[gc*N +: N]),
                .posit_out(stream_acc_sum[gc])
            );
        end
    endgenerate

    systolic_stream_core #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS),
        .TAG_W(PIXEL_ADDR_W),
        .ROW_ADDR_W(ROW_ADDR_W),
        .COL_ADDR_W(COL_ADDR_W),
        .WEIGHT_ADDR_W(WEIGHT_ADDR_W)
    ) STREAM_CORE (
        .clk(clk),
        .reset(reset),
        .pe_en(core_pe_en),
        .clear_pipe(core_clear_pipe),
        .wshift(core_wshift),
        .activation_in(core_activation_vector_data),
        .stream_valid(core_stream_valid),
        .stream_tag(core_stream_tag),
        .weight_load_en(core_weight_load_en),
        .weight_addr(core_weight_addr),
        .weight_data(core_weight_data),
        .result_valid(core_result_valid),
        .result_tag(core_result_tag),
        .result_data(core_result_data)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            oc_base <= 0;
            dot_base <= 0;
            load_index <= 0;
            init_index <= 0;
            stream_send_count <= 0;
            stream_recv_count <= 0;
            core_pe_en <= 1'b0;
            core_clear_pipe <= 1'b0;
            core_wshift <= 1'b0;
            core_stream_valid <= 1'b0;
            core_stream_tag <= {PIXEL_ADDR_W{1'b0}};
            core_activation_vector_data <= {ROWS*N{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_addr <= {WEIGHT_ADDR_W{1'b0}};
            core_weight_data <= {N{1'b0}};
        end
        else begin
            core_pe_en <= 1'b0;
            core_clear_pipe <= 1'b0;
            core_wshift <= 1'b0;
            core_stream_valid <= 1'b0;
            core_stream_tag <= {PIXEL_ADDR_W{1'b0}};
            core_activation_vector_data <= {ROWS*N{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_data <= {N{1'b0}};
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        oc_base <= 0;
                        dot_base <= 0;
                        init_index <= 0;
                        state <= ST_INIT_TILE;
                    end
                end

                ST_INIT_TILE: begin
                    if (init_index < OUT_PIXELS*COLS) begin
                        init_col = init_index / OUT_PIXELS;
                        init_pix = init_index - (init_col * OUT_PIXELS);
                        if ((oc_base + init_col) < OUT_CH) begin
                            out_index = ((oc_base + init_col) * OUT_PIXELS) + init_pix;
                            output_mem[out_index] <= bias_mem[oc_base + init_col];
                        end
                        init_index <= init_index + 1;
                    end
                    else begin
                        dot_base <= 0;
                        load_index <= 0;
                        state <= ST_LOAD;
                    end
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
                        core_clear_pipe <= 1'b1;
                        core_wshift <= 1'b1;
                        stream_send_count <= 0;
                        stream_recv_count <= 0;
                        state <= ST_STREAM;
                    end
                end

                ST_STREAM: begin
                    if (core_result_valid) begin
                        for (i = 0; i < COLS; i = i + 1) begin
                            if ((oc_base + i) < OUT_CH) begin
                                out_index = ((oc_base + i) * OUT_PIXELS) + core_result_tag;
                                output_mem[out_index] <= stream_acc_sum[i];
                            end
                        end
                        stream_recv_count <= stream_recv_count + 1;
                    end

                    if (stream_send_count < OUT_PIXELS) begin
                        stream_y = stream_send_count / OUT_W;
                        stream_x = stream_send_count - (stream_y * OUT_W);

                        for (i = 0; i < ROWS; i = i + 1) begin
                            dot_idx = dot_base + i;
                            core_activation_vector_data[i*N +: N] <= activation_at(dot_idx, stream_y, stream_x);
                        end

                        core_stream_valid <= 1'b1;
                        core_stream_tag <= stream_send_count[PIXEL_ADDR_W-1:0];
                        core_pe_en <= 1'b1;
                        stream_send_count <= stream_send_count + 1;
                    end
                    else if (!(core_result_valid && (stream_recv_count == OUT_PIXELS-1))) begin
                        core_pe_en <= 1'b1;
                    end

                    if (core_result_valid && (stream_recv_count == OUT_PIXELS-1)) begin
                        state <= ST_NEXT_DOT;
                    end
                end

                ST_NEXT_DOT: begin
                    if ((dot_base + ROWS) < DOT_LEN) begin
                        dot_base <= dot_base + ROWS;
                        load_index <= 0;
                        state <= ST_LOAD;
                    end
                    else begin
                        state <= ST_NEXT_TILE;
                    end
                end

                ST_NEXT_TILE: begin
                    if ((oc_base + COLS) < OUT_CH) begin
                        oc_base <= oc_base + COLS;
                        init_index <= 0;
                        state <= ST_INIT_TILE;
                    end
                    else begin
                        state <= ST_DONE;
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
