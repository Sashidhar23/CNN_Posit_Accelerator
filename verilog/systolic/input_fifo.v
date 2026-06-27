`timescale 1ns / 1ps

module input_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_W = (DEPTH <= 2) ? 1 : $clog2(DEPTH),
    parameter COUNT_W = $clog2(DEPTH + 1)
)(
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 clear,
    input  wire                 write_en,
    input  wire                 read_en,
    input  wire [WIDTH-1:0]     data_in,
    output reg  [WIDTH-1:0]     data_out,
    output wire                 full,
    output wire                 empty,
    output reg  [COUNT_W-1:0]   count
);

    localparam [ADDR_W-1:0] LAST_ADDR = DEPTH - 1;
    localparam [COUNT_W-1:0] DEPTH_COUNT = DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W-1:0] rd_ptr;

    wire read_ok;
    wire write_ok;

    assign empty = (count == 0);
    assign full  = (count == DEPTH_COUNT);

    assign read_ok  = read_en && !empty;
    assign write_ok = write_en && (!full || read_ok);

    always @(posedge clk) begin
        if (reset || clear) begin
            wr_ptr   <= {ADDR_W{1'b0}};
            rd_ptr   <= {ADDR_W{1'b0}};
            data_out <= {WIDTH{1'b0}};
            count    <= {COUNT_W{1'b0}};
        end
        else begin
            if (read_ok) begin
                data_out <= mem[rd_ptr];
                if (rd_ptr == LAST_ADDR)
                    rd_ptr <= {ADDR_W{1'b0}};
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            if (write_ok) begin
                mem[wr_ptr] <= data_in;
                if (wr_ptr == LAST_ADDR)
                    wr_ptr <= {ADDR_W{1'b0}};
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (write_ok && !read_ok)
                count <= count + 1'b1;
            else if (read_ok && !write_ok)
                count <= count - 1'b1;
        end
    end

endmodule
