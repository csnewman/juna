`include "w6debug.sv"
`include "debounce.sv"

module Clock_divider (
    clock_in,
    clock_out
);
  input clock_in;  // input clock on FPGA
  output reg clock_out;  // output clock after dividing the input clock by divisor
  reg [3:0] counter = 4'd0;
  parameter DIVISOR = 4'd2;
  always @(posedge clock_in) begin
    counter <= counter + 4'd1;
    if (counter >= (DIVISOR - 1)) counter <= 4'd0;
    clock_out <= (counter < DIVISOR / 2) ? 1'b1 : 1'b0;
  end
endmodule

module blackice (
    // 100MHz clock input
    input clk100,
    // Global internal reset connected to RTS on ch340 and also PMOD[1]
    input greset,

    // Input lines from STM32/Done can be used to signal to Ice40 logic
    input DONE,  // could be used as interupt in post programming
    input DBG1,  // Could be used to select coms via STM32 or RPi etc..

    // SRAM Memory lines
    output [17:0] ADR,
    output [15:0] DAT,
    output RAMOE,
    output RAMWE,
    output RAMCS,
    output RAMLB,
    output RAMUB,

    // QSPI lines
    input QSPICK,
    input QSPICSN,
    inout [3:0] QSPIDQ,

    // All PMOD outputs
    output [55:0] PMOD,
    input B1,
    input B2
);
  assign ADR[17:0] = {18{1'bz}};
  assign DAT[15:0] = {16{1'bz}};
  assign RAMOE = 1'b1;
  assign RAMWE = 1'b1;
  assign RAMCS = 1'b1;
  assign RAMLB = 1'bz;
  assign RAMUB = 1'bz;
  assign PMOD[54:0] = {55{1'bz}};

  //   assign PMOD[52] = B2;

  wire clk;

//   assign clk = clk100;

  Clock_divider clkdiv (
      .clock_in (clk100),
      .clock_out(clk)
  );

  wire rst;

  debounce db_rst (
      .clk(clk),
      .button(B2),
      .state(rst)
  );

  w6debug w6debug_inst (
      .clk(clk),
      .rst(rst),
      .io_clk(QSPICK),
      .io_dir(QSPICSN),
      .io_cts(QSPIDQ[0]),
      .io_rts(QSPIDQ[1]),
      .io_in(QSPIDQ[2]),
      .io_out(QSPIDQ[3]),
      .led(PMOD[55])
  );

endmodule
