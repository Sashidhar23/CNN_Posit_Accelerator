`timescale 1ns / 1ps

module posit_decoder #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire [N-1:0] posit_in,

    output reg sign,
    output reg is_zero,
    output reg is_nar,

    output reg signed [$clog2(N):0] k,
    output reg [ES-1:0] exponent,

    output reg [N-1:0] fraction,
    output reg [$clog2(N):0] frac_len
);

    integer i;
    integer run_length;
    integer exp_start;
    integer frac_start;

    reg [N-1:0] mag;
    reg regime_bit;
    reg done;

    always @(*) begin
        sign      = 1'b0;
        is_zero   = 1'b0;
        is_nar    = 1'b0;

        k         = 0;
        exponent  = 0;
        fraction  = 0;
        frac_len  = 0;
        mag       = 0;
        regime_bit = 0;
        done      = 0;
        run_length = 0;
        exp_start  = 0;
        frac_start = 0;

        if (posit_in == {N{1'b0}}) begin
            is_zero = 1'b1;
        end
        else if (posit_in == {1'b1, {(N-1){1'b0}}}) begin
            is_nar = 1'b1;
        end
        else begin
            sign = posit_in[N-1];

            // Undo posit sign encoding
            if (sign)
                mag = (~posit_in) + 1'b1;
            else
                mag = posit_in;

            // Regime starts at bit N-2
            regime_bit = mag[N-2];

            done       = 0;
            run_length = 0;

            for (i = 0; i < N-1; i = i + 1) begin
                if (!done) begin
                    if (mag[N-2-i] == regime_bit)
                        run_length = run_length + 1;
                    else
                        done = 1;
                end
            end

            if (regime_bit)
                k = run_length - 1;
            else
                k = -run_length;

            // Exponent starts after regime run + terminating bit
            exp_start = run_length + 2;

            for (i = 0; i < ES; i = i + 1) begin
                if (exp_start + i < N)
                    exponent[ES-1-i] = mag[N-1-(exp_start+i)];
            end

            // Fraction bits come after exponent
            frac_start = exp_start + ES;

            if (frac_start < N) begin
                // Trim zero padding left by the encoder after the valid bits.
                for (i = 0; i < N; i = i + 1) begin
                    if ((i >= frac_start) && mag[N-1-i])
                        frac_len = i - frac_start + 1;
                end

                // Store fraction left-justified:
                // first fraction bit goes to fraction[N-1]
                for (i = 0; i < N; i = i + 1) begin
                    if ((i >= frac_start) && (i < frac_start + frac_len))
                        fraction[N-1-(i-frac_start)] = mag[N-1-i];
                end
            end
        end
    end

endmodule
