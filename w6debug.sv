module w6debug (
    input rst,
    input clk,
    input io_clk,
    input io_dir,
    output reg io_cts,
    output reg io_rts,
    input io_in,
    output reg io_out
);
  reg clock_state = 0;

  reg [7:0] in_buffer;
  reg [3:0] in_count;
  reg [7:0] out_buffer;
  reg [3:0] out_count;

  wire io_clk_deb;

  debug_debounce clk_debouncer (
      .clk(clk),
      .target(io_clk),
      .state(io_clk_deb)
  );

  always @(posedge clk) begin
    if (rst) begin
      in_buffer <= 0;
      in_count <= 0;
      io_cts <= 1;

      out_buffer <= 8'd123;
      out_count <= 8;
      io_rts <= 1;

      clock_state <= 0;
    end else if (io_clk_deb) begin
      if (!clock_state) begin
        clock_state <= 1;

        if (io_dir) begin
          in_buffer <= in_buffer << 1 | {{7{1'b0}}, io_in};
          in_count  <= in_count + 1;
        end else begin
          io_out <= out_buffer[7];
          out_buffer <= out_buffer << 1;
          out_count <= out_count - 1;
          io_rts <= 0;
        end
      end
    end else begin
      clock_state <= 0;
    end
  end

endmodule

module debug_debounce (
    input clk,
    input target,
    output reg state
);
  reg [3:0] count;

  always @(posedge clk) begin
    count <= state == target ? 0 : count + 1;
    if (&count) state <= ~state;
  end
endmodule
