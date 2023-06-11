`include "debounce.sv"

module blink (
    input  clk,
    input  rst,
    input  but,
    output led,
    output led2,
    output led3
);

  reg [2:0] count;

  assign led  = count[0];
  assign led2 = count[1];
  assign led3 = count[2];

  wire click;

  reg  done;

  debounce dbbut (
      .clk(clk),
      .button(but),
      .state(click)
  );

  always @(posedge clk)
    if (rst) count <= 0;
    else begin
      if (click) begin
        if (!done) begin
            count <= count + 1;
            done  <= 1;
        end
      end else done <= 0;
    end

endmodule
