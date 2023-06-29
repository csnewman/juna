module regfile (
    input rst,
    input clk,

    input [3:0] a_addr,
    input a_write,
    input [31:0] a_wdata,
    output reg [31:0] a_rdata,

    input [7:0] debug_bus_addr,
    input debug_bus_start,
    inout [63:0] debug_bus_data,
    output debug_bus_available,
    output debug_bus_accepted
);

  // 16 32bit registers
  reg [31:0] registers[0:15];

  reg [31:0] b_in;
  wire [31:0] b_out;
  wire [3:0] b_addr;
  wire b_write;

  debug_regfile debug_regfile_inst (
      .rst(rst),
      .clk(clk),
      .bus_addr(debug_bus_addr),
      .bus_start(debug_bus_start),
      .bus_data(debug_bus_data),
      .bus_available(debug_bus_available),
      .bus_accepted(debug_bus_accepted),
      .port_addr(b_addr),
      .port_write(b_write),
      .port_out(b_out),
      .port_in(b_in)
  );

  always @(posedge clk) begin
    if (rst) begin
      registers[0]  <= 0;
      registers[1]  <= 0;
      registers[2]  <= 0;
      registers[3]  <= 0;
      registers[4]  <= 0;
      registers[5]  <= 0;
      registers[6]  <= 0;
      registers[7]  <= 0;
      registers[8]  <= 0;
      registers[9]  <= 0;
      registers[10] <= 0;
      registers[11] <= 0;
      registers[12] <= 0;
      registers[13] <= 0;
      registers[14] <= 0;
      registers[15] <= 0;
    end else begin
      if (b_write) begin
        registers[b_addr] <= b_out;
      end

      if (a_write) begin
        registers[a_addr] <= a_wdata;
      end

      //  else begin
      //   b_in <= registers[b_addr];
      // end
    end


  end

  always @(negedge clk) begin
    // if (!rst) begin
    // if (!b_write) begin
    a_rdata <= registers[a_addr];
    b_in <= registers[b_addr];
    // end
    // end
  end

endmodule

module debug_regfile (
    input rst,
    input clk,

    input [7:0] bus_addr,
    input bus_start,
    inout [63:0] bus_data,
    output bus_available,
    output bus_accepted,

    output reg [3:0] port_addr,
    output reg port_write,
    output reg [31:0] port_out,
    input [31:0] port_in
);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [63:0] value;

  assign bus_data = bus_addr == 1 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 1 ? available : 'z;
  assign bus_accepted = bus_addr == 1 ? accepted : 'z;


  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
      value <= 0;
      port_addr <= 0;
      port_write <= 0;
      port_out <= 0;
    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          if (bus_addr == 1 && bus_start) begin
            accepted <= 1;
            port_write <= bus_data[0:0];
            port_addr <= bus_data[4:1];
            port_out <= bus_data[63:32];
            state <= 1;
          end
        end
        1: begin
          accepted <= 0;
          available <= 1;
          port_write <= 0;
          state <= 3;

          // state <= 2;

          if (port_write) begin
            value <= 1;
          end else begin
            value <= {{32{1'b0}}, port_in};
          end
        end


        // 2: begin
        //   state <= 4;
        //   // available <= 1;
        // end


        // 4: begin
        //   state <= 3;
        //   available <= 1;
        // end


        // 2: begin
        //   state <= 3;
        //   available <= 1;
        //   value <= {{32{1'b0}}, port_in};
        // end

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
