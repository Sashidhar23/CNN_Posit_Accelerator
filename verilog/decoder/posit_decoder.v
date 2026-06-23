`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 15:03:21
// Design Name: 
// Module Name: posit_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
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
    output reg [N-1:0] mantissa
);

    integer i;
    integer run_length;
    integer exp_start;
    integer frac_start;
    integer frac_len;

    reg [N-1:0] mag;
    reg regime_bit;
    reg done;

    always @(*) begin

        //--------------------------------------------------
        // Defaults
        //--------------------------------------------------

        sign      = posit_in[N-1];
        is_zero   = 1'b0;
        is_nar    = 1'b0;

        k         = 0;
        exponent  = 0;
        mantissa  = 0;

        //--------------------------------------------------
        // Special cases
        //--------------------------------------------------

        if (posit_in == {N{1'b0}}) begin
            is_zero = 1'b1;
        end

        else if (posit_in == {1'b1,{(N-1){1'b0}}}) begin
            is_nar = 1'b1;
        end

        else begin

            //--------------------------------------------------
            // Undo two's complement if negative
            //--------------------------------------------------

            if (sign)
                mag = (~posit_in) + 1'b1;
            else
                mag = posit_in;

            //--------------------------------------------------
            // Determine regime
            //--------------------------------------------------

            regime_bit = mag[N-2];

            done = 0;
            run_length = 0;

            for(i = 0; i < N-1; i = i + 1) begin
                if(!done) begin
                    if(mag[N-2-i] == regime_bit)
                        run_length = run_length + 1;
                    else
                        done = 1;
                end
            end

            //--------------------------------------------------
            // Compute k
            //--------------------------------------------------

            if(regime_bit)
                k = run_length - 1;
            else
                k = -run_length;

            //--------------------------------------------------
            // Exponent extraction
            //--------------------------------------------------

            exp_start = run_length + 2;

            exponent = 0;

            for(i = 0; i < ES; i = i + 1) begin
                if(exp_start + i < N)
                    exponent[ES-1-i] =
                        mag[N-1-(exp_start+i)];
            end

            //--------------------------------------------------
            // Mantissa extraction
            // Stored as 1.fraction
            //--------------------------------------------------

            mantissa = 0;

            // Hidden bit
            mantissa[N-1] = 1'b1;

            frac_start = exp_start + ES;

            if(frac_start < N) begin

                frac_len = N - frac_start;

                for(i = 0; i < N-1; i = i + 1) begin
                    if(i < frac_len)
                        mantissa[N-2-i] =
                            mag[N-1-(frac_start+i)];
                end

            end

        end

    end

endmodule
