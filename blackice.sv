`include "blink.sv"
`include "w6debug.sv"
`include "debounce.sv"

module blackice (
    // 100MHz clock input
    input clk,
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
  assign PMOD[51:0] = {52{1'bz}};

  assign PMOD[52] = B2;

  wire rst;

  debounce db_rst (
      .clk(clk),
      .button(B2),
      .state(rst)
  );

  blink my_blink (
      .clk (clk),
      .rst (rst),
      .but (B1),
      .led (PMOD[55]),
      .led2(PMOD[54]),
      .led3(PMOD[53])
  );

  w6debug w6debug_inst (
      .clk(clk),
      .rst(rst),
      .io_clk(QSPICK),
      .io_dir(QSPICSN),
      .io_cts(QSPIDQ[0]),
      .io_rts(QSPIDQ[1]),
      .io_in(QSPIDQ[2]),
      .io_out(QSPIDQ[3])
  );

endmodule
