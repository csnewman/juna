`define RAM_STATE_IDLE 3'd0
`define RAM_STATE_BUSY1 3'd1
`define RAM_STATE_BUSY2 3'd2

module ram (
    input rst,
    input clk,

    input [7:0] debug_bus_addr,
    input debug_bus_start,
    inout [63:0] debug_bus_data,
    output debug_bus_available,
    output debug_bus_accepted,

    // IO pins
    output   RAMCS,
    output   RAMWE,
    output   RAMOE,
    output   RAMLB,
    output   RAMUB,
    output reg [17:0] ADR,
    inout [15:0]    DAT,

    input [17:0] a_adr,
    input a_req,
    output a_ack,
    input a_write,
    input [1:0] a_sel,
    output [15:0] a_rdata,
    input [15:0] a_wdata,

    input [17:0] c_adr,
    input c_req,
    output c_ack,
    input c_write,
    input [1:0] c_sel,
    output [15:0] c_rdata,
    input [15:0] c_wdata
);

  reg [17:0] b_adr;
  reg b_req;
  reg b_ack;
  reg b_write;
  reg [1:0] b_sel;
  reg [15:0] b_rdata;
  reg [15:0] b_wdata;


  assign RAMCS = 0;  // active low
  assign RAMOE = 0;  // active low

  reg [1:0] bytesel;
  assign RAMLB = !bytesel[0];  // active low
  assign RAMUB = !bytesel[1];  // active low

  assign RAMWE = !isout;  // active low

  reg isout;
  reg [15:0] outdata;

  assign DAT = isout ? outdata : 'z;
  assign a_rdata = DAT;
  assign b_rdata = DAT;
  assign c_rdata = DAT;

  reg [2:0] state;


  debug_ram debug_ram_inst (
      .rst(rst),
      .clk(clk),
      .bus_addr(debug_bus_addr),
      .bus_start(debug_bus_start),
      .bus_data(debug_bus_data),
      .bus_available(debug_bus_available),
      .bus_accepted(debug_bus_accepted),

      .a_adr  (b_adr),
      .a_req  (b_req),
      .a_ack  (b_ack),
      .a_write(b_write),
      .a_sel  (b_sel),
      .a_rdata(b_rdata),
      .a_wdata(b_wdata)
  );

  // reg next_a;
  // reg next_b;

  always @(posedge clk) begin
    a_ack <= 0;
    b_ack <= 0;
    c_ack <= 0;

    if (rst) begin
      state <= `RAM_STATE_IDLE;
      isout <= 0;
      a_ack <= 0;
      b_ack <= 0;
      c_ack <= 0;
    end else begin
      case (state)
        `RAM_STATE_IDLE: begin
          isout <= 0;

          if (c_req && !c_ack) begin
            ADR <= c_adr;
            bytesel <= c_sel;
            outdata <= c_wdata;
            isout <= c_write;
            c_ack <= 1;
          end else if (b_req && !b_ack) begin
            ADR <= b_adr;
            bytesel <= b_sel;
            outdata <= b_wdata;
            isout <= b_write;
            b_ack <= 1;
            // state <= `RAM_STATE_BUSY1;
          end else if (a_req && !a_ack) begin
            ADR <= a_adr;
            bytesel <= a_sel;
            outdata <= a_wdata;
            isout <= a_write;
            a_ack <= 1;
            // state <= `RAM_STATE_BUSY1;
          end

        end
        `RAM_STATE_BUSY1: begin
          state <= `RAM_STATE_IDLE;
        end
        default: begin

        end
      endcase
    end


  end

endmodule

module debug_ram (
    input rst,
    input clk,

    input [7:0] bus_addr,
    input bus_start,
    inout [63:0] bus_data,
    output bus_available,
    output bus_accepted,

    output [17:0] a_adr,
    output reg a_req,
    input a_ack,
    output reg a_write,
    output [1:0] a_sel,
    input [15:0] a_rdata,
    output [15:0] a_wdata
);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [63:0] value;

  assign bus_data = bus_addr == 2 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 2 ? available : 'z;
  assign bus_accepted = bus_addr == 2 ? accepted : 'z;


  reg [18:0] target;
  assign a_adr = target[18:1];
  assign a_sel = target[0] ? 2 : 1;

  reg [7:0] write_value;
  assign a_wdata = {write_value, write_value};

  // assign ram_wr_data = 0;

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
      value <= 0;

      // ram_req <= 0;
      target <= 0;
      a_write <= 0;
      a_req <= 0;

    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          // && ram_ready
          if (bus_addr == 2 && bus_start) begin
            accepted <= 1;
            a_req <= 1;

            a_write <= bus_data[0:0] == 1;
            target <= bus_data[26:8];
            write_value <= bus_data[63:56];

            // ram_req <= 1;
            state <= 1;
          end
        end
        1: begin
          accepted <= 0;
          // write_value <= 0;

          if (a_ack) begin
            a_req   <= 0;
            a_write <= 0;

            if (a_write) begin
              value <= 123;
            end else begin
              if (target[0]) begin
                value <= {{56{1'b1}}, a_rdata[15:8]};
              end else begin
                value <= {{56{1'b1}}, a_rdata[7:0]};
              end
            end

            available <= 1;
            state <= 2;
          end
        end

        2: begin
          available <= 0;
          state <= 0;
        end

        // 3: begin
        //   accepted <= 0;
        //   available <= 0;
        //   state <= 0;
        // end

        default: begin
          //   state <= 'z;
          //   accepted <= 'z;
          //   available <= 'z;
        end

      endcase
    end
  end

endmodule
