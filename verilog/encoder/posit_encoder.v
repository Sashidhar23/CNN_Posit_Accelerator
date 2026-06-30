`timescale 1ns / 1ps

module posit_encoder #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire sign,
    input  wire is_zero,
    input  wire is_nar,

    input  wire signed [$clog2(N):0] k,
    input  wire [ES-1:0] exponent,

    input  wire [N-1:0] fraction,
    input  wire [$clog2(N):0] frac_len,

    output reg  [N-1:0] posit_out
);

    integer i;
    integer idx;
    integer reg_len;

    reg [N-1:0] mag;

    always @(*) begin
        mag       = {N{1'b0}};
        posit_out = {N{1'b0}};
        idx       = 0;
        reg_len   = 0;

        if (is_zero) begin
            posit_out = {N{1'b0}};
        end
        else if (is_nar) begin
            posit_out = {1'b1, {(N-1){1'b0}}};
        end
        else begin
            // Build magnitude first, then apply sign at the end
            idx = N-2;

            //--------------------------------------------------
            // Regime
            //--------------------------------------------------
            if (k >= 0) begin
                reg_len = k + 1;

                for (i = 0; i < N; i = i + 1) begin
                    if ((i < reg_len) && (idx >= 0)) begin
                        mag[idx] = 1'b1;
                        idx = idx - 1;
                    end
                end

                if (idx >= 0) begin
                    mag[idx] = 1'b0;
                    idx = idx - 1;
                end
            end
            else begin
                reg_len = -k;

                for (i = 0; i < N; i = i + 1) begin
                    if ((i < reg_len) && (idx >= 0)) begin
                        mag[idx] = 1'b0;
                        idx = idx - 1;
                    end
                end

                if (idx >= 0) begin
                    mag[idx] = 1'b1;
                    idx = idx - 1;
                end
            end

            //--------------------------------------------------
            // Exponent
            //--------------------------------------------------
            for (i = 0; i < ES; i = i + 1) begin
                if (idx >= 0) begin
                    mag[idx] = exponent[ES-1-i];
                    idx = idx - 1;
                end
            end

            //--------------------------------------------------
            // Fraction
            // Decoder stores valid bits as fraction[N-1 : N-frac_len]
            // Example: 101 -> fraction = 10100000, frac_len = 3
            //--------------------------------------------------
            for (i = 0; i < N; i = i + 1) begin
                if ((i < frac_len) && (idx >= 0)) begin
                    mag[idx] = fraction[N-1-i];
                    idx = idx - 1;
                end
            end

            //--------------------------------------------------
            // Apply sign
            //--------------------------------------------------
            if (sign)
                posit_out = (~mag) + 1'b1;
            else
                posit_out = mag;
        end
    end

endmodule
