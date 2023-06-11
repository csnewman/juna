module debounce (
    input clk,
    input button,
    output reg state
);
  reg [15:0] count;

  always @(posedge clk) begin
    count <= state == ~button ? 0 : count + 1;
    if (&count) state <= ~state;
  end
endmodule
