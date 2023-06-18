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
    output [17:0] ADR,
    inout [15:0]    DAT
);

  assign RAMCS = 0;  // active low
  assign RAMLB = !bytesel[0];  // active low
  assign RAMUB = !bytesel[1];  // active low

  assign RAMWE = !isout;  // active low
  assign RAMOE = 0;  // active low

  reg [1:0] bytesel;

  reg isout;
  assign isout = !ram_rd;

  reg [15:0] outdata;
  assign DAT = isout ? outdata : 'z;

  // assign outdata = 60;

  reg ram_rd;


  debug_ram debug_ram_inst (
      .rst(rst),
      .clk(clk),
      .bus_addr(debug_bus_addr),
      .bus_start(debug_bus_start),
      .bus_data(debug_bus_data),
      .bus_available(debug_bus_available),
      .bus_accepted(debug_bus_accepted),


      .ram_rd(ram_rd),
      .ram_addr(ADR),
      .ram_be(bytesel),
      .ram_rd_data(DAT),
      .ram_wr_data(outdata)
  );

  always @(posedge clk) begin
    if (rst) begin
      // isout

    end else begin
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

    // input ram_ready,
    // output reg ram_req,
    // input ram_act,

    output reg ram_rd,
    output [17:0] ram_addr,
    output [1:0] ram_be,


    output [15:0] ram_wr_data,
    // input ram_rd_data_vld,
    input  [15:0] ram_rd_data



);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [63:0] value;

  assign bus_data = bus_addr == 2 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 2 ? available : 'z;
  assign bus_accepted = bus_addr == 2 ? accepted : 'z;


  reg [18:0] target;
  assign ram_addr = target[18:1];
  assign ram_be   = target[0] ? 2 : 1;

  reg [7:0] write_value;
  assign ram_wr_data = {write_value, write_value};

  // assign ram_wr_data = 0;

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
      value <= 0;

      // ram_req <= 0;
      target <= 0;
      ram_rd <= 1;

    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          // && ram_ready
          if (bus_addr == 2 && bus_start) begin
            accepted <= 1;

            ram_rd <= bus_data[0:0] == 0;
            target <= bus_data[26:8];
            write_value <= bus_data[63:56];

            // ram_req <= 1;
            state <= 1;
          end
        end
        1: begin
          accepted <= 0;
          write_value <= 0;
          ram_rd <= 1;

          if (ram_rd) begin
            if (target[0]) begin
              value <= {{56{1'b1}}, ram_rd_data[15:8]};
            end else begin
              value <= {{56{1'b1}}, ram_rd_data[7:0]};
            end

            // value <= 3;
            available <= 1;
            state <= 2;

            // end
          end else begin
            value <= 123;
            available <= 1;
            state <= 2;
          end

          // available <= 1;
          // state <= 2;
          // value <= 2;
        end

        2: begin
          available <= 0;
          state <= 0;
        end

        3: begin
          accepted <= 0;
          available <= 0;
          state <= 0;
        end

        default: begin
          //   state <= 'z;
          //   accepted <= 'z;
          //   available <= 'z;
        end

      endcase
    end
  end

endmodule
