`include "w6debug.sv"
`include "debounce.sv"
`include "regfile.sv"
`include "ram.sv"
`include "core.sv"

module Clock_divider (
    clock_in,
    clock_out
);
  input clock_in;  // input clock on FPGA
  output reg clock_out;  // output clock after dividing the input clock by divisor
  reg [3:0] counter = 4'd0;
  parameter DIVISOR = 4'd10;
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
    inout [17:0] ADR,
    inout [15:0] DAT,
    inout RAMOE,
    inout RAMWE,
    inout RAMCS,
    inout RAMLB,
    inout RAMUB,

    // QSPI lines
    input QSPICK,
    input QSPICSN,
    inout [3:0] QSPIDQ,

    // All PMOD outputs
    inout [55:0] PMOD,
    input B1,
    input B2
);
  // assign PMOD[54:0] = {55{1'bz}};


  assign PMOD[43:0] = {44{1'bz}};
  assign PMOD[44] = 1;
  assign PMOD[45] = 0;
  assign PMOD[46] = 0;
  assign PMOD[47] = 0;
  assign PMOD[54:48] = {7{1'bz}};


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

  wire [7:0] debug_bus_addr;
  wire debug_bus_start;
  wire [63:0] debug_bus_data;
  wire debug_bus_available;
  wire debug_bus_accepted;


  assign PMOD[55] = B1;

  // .led(PMOD[55]),

  w6debug w6debug_inst (
      .clk(clk),
      .rst(rst),
      .io_clk(QSPICK),
      .io_dir(QSPICSN),
      .io_cts(QSPIDQ[0]),
      .io_rts(QSPIDQ[1]),
      .io_in(QSPIDQ[2]),
      .io_out(QSPIDQ[3]),
      .bus_addr(debug_bus_addr),
      .bus_start(debug_bus_start),
      .bus_data(debug_bus_data),
      .bus_available(debug_bus_available),
      .bus_accepted(debug_bus_accepted)
  );

  regfile regfile_inst (
      .rst(rst),
      .clk(clk),

      .debug_bus_addr(debug_bus_addr),
      .debug_bus_start(debug_bus_start),
      .debug_bus_data(debug_bus_data),
      .debug_bus_available(debug_bus_available),
      .debug_bus_accepted(debug_bus_accepted),

      .a_addr (r_a_addr),
      .a_write(r_a_write),
      .a_wdata(r_a_wdata),
      .a_rdata(r_a_rdata)
  );

  ram ram_inst (
      .rst(rst),
      .clk(clk),

      .debug_bus_addr(debug_bus_addr),
      .debug_bus_start(debug_bus_start),
      .debug_bus_data(debug_bus_data),
      .debug_bus_available(debug_bus_available),
      .debug_bus_accepted(debug_bus_accepted),

      .RAMCS(RAMCS),
      .RAMWE(RAMWE),
      .RAMOE(RAMOE),
      .RAMLB(RAMLB),
      .RAMUB(RAMUB),
      .ADR  (ADR),
      .DAT  (DAT),

      .a_adr  (m_a_adr),
      .a_req  (m_a_req),
      .a_ack  (m_a_ack),
      .a_write(m_a_write),
      .a_sel  (m_a_sel),
      .a_rdata(m_a_rdata),
      .a_wdata(m_a_wdata)

  );


  reg [3:0] r_a_addr;
  reg r_a_write;
  reg [31:0] r_a_wdata;
  reg [31:0] r_a_rdata;

  reg [17:0] m_a_adr;
  reg m_a_req;
  reg m_a_ack;
  reg m_a_write;
  reg [1:0] m_a_sel;
  reg [15:0] m_a_rdata;
  reg [15:0] m_a_wdata;

//   assign m_a_adr = 0;
//   assign m_a_req = 0;
//   assign m_a_write = 0;
//   assign m_a_wdata = 0;
//   assign m_a_sel = 0;

  core core_inst (
      .rst(rst),
      .clk(clk),

      .debug_bus_addr(debug_bus_addr),
      .debug_bus_start(debug_bus_start),
      .debug_bus_data(debug_bus_data),
      .debug_bus_available(debug_bus_available),
      .debug_bus_accepted(debug_bus_accepted),

      .r_a_addr (r_a_addr),
      .r_a_write(r_a_write),
      .r_a_wdata(r_a_wdata),
      .r_a_rdata(r_a_rdata),

      .m_a_adr  (m_a_adr),
      .m_a_req  (m_a_req),
      .m_a_ack  (m_a_ack),
      .m_a_write(m_a_write),
      .m_a_sel  (m_a_sel),
      .m_a_rdata(m_a_rdata),
      .m_a_wdata(m_a_wdata)
  );

endmodule
