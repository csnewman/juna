module w6debug (
    input rst,
    input clk,
    input io_clk,
    input io_dir,
    output reg io_cts,
    output reg io_rts,
    input io_in,
    output reg io_out,
    output led
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

  wire in_available;
  reg  in_accepted;

  assign in_available = in_count == 8 && !in_accepted;

  wire out_possible;
  wire out_request;
  wire [7:0] out_requested;
  assign out_possible = out_count == 0 && !out_request;

  wire [7:0] bus_addr;
  wire [31:0] bus_data;
  wire bus_available;
  wire bus_accepted;

  debug_control controller (
      .clk(clk),
      .rst(rst),
      .in_buffer(in_buffer),
      .in_available(in_available),
      .in_accepted(in_accepted),
      .out_possible(out_possible),
      .out_request(out_request),
      .out_buffer(out_requested),
      .bus_addr(bus_addr),
      .bus_data(bus_data),
      .bus_available(bus_available),
      .bus_accepted(bus_accepted)
  );

  debug_example ex (
      .clk(clk),
      .rst(rst),
      .bus_addr(bus_addr),
      .bus_data(bus_data),
      .bus_available(bus_available),
      .bus_accepted(bus_accepted),
      .led(led)
  );

  always @(posedge clk) begin
    if (rst) begin
      in_buffer <= 0;
      in_count <= 0;
      io_cts <= 1;

      out_buffer <= 0;
      out_count <= 0;
      io_rts <= 0;

      clock_state <= 0;
    end else begin
      if (io_clk_deb) begin
        if (!clock_state) begin
          clock_state <= 1;

          if (io_dir) begin
            in_buffer <= in_buffer << 1 | {{7{1'b0}}, io_in};
            in_count <= in_count + 1;
            io_cts <= 0;
          end else begin
            io_out <= out_buffer[7];
            out_buffer <= out_buffer << 1 | 8'b0;
            out_count <= out_count - 1;
            io_rts <= 0;
          end
        end
      end else begin
        clock_state <= 0;
      end

      if (in_accepted) begin
        in_buffer <= 0;
        in_count <= 0;
        io_cts <= 1;
      end

      if (out_request) begin
        out_buffer <= out_requested;
        out_count <= 8;
        io_rts <= 1;
      end
    end
  end

endmodule

module debug_example (
    input rst,
    input clk,

    input [7:0] bus_addr,
    inout [31:0] bus_data,
    output bus_available,
    output bus_accepted,

    output led
);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [31:0] value;

  assign bus_data = bus_addr == 1 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 1 ? available : 'z;
  assign bus_accepted = bus_addr == 1 ? accepted : 'z;
  assign led = value[0];

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          if (bus_addr == 1) begin
            accepted <= 1;
            value <= bus_data + 32'd12;
            state <= 1;
          end
        end
        1: begin
          state <= 2;
          accepted <= 0;
          available <= 1;
        end
        2: begin
          accepted <= 0;
          available <= 0;
          state <= 0;
        end

        default: begin

        end

      endcase
    end
  end

endmodule

module debug_control (
    input rst,
    input clk,

    input [7:0] in_buffer,
    input in_available,
    output reg in_accepted,


    input out_possible,
    output reg out_request,
    output reg [7:0] out_buffer,

    output [7:0] bus_addr,
    inout [31:0] bus_data,
    input bus_available,
    input bus_accepted
);

  reg [ 3:0] state;
  reg [ 1:0] count;

  reg [ 7:0] target;
  reg [31:0] ldata;

  assign bus_data = state == 2 ? ldata : 'z;
  assign bus_addr = (state != 0 && state != 1) ? target : 0;

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      target <= 0;
      out_request <= 0;
    end else begin
      case (state)
        4'd0: begin  // Waiting for cmd
          if (in_available) begin
            state <= 1;
            in_accepted <= 1;
            target <= in_buffer;
            count <= 0;
          end
        end
        1: begin  // Reading
          if (in_available) begin
            in_accepted <= 1;

            case (count)
              0: begin
                ldata[7:0] <= in_buffer;
                count <= 1;
              end
              1: begin
                ldata[15:8] <= in_buffer;
                count <= 2;
              end
              2: begin
                ldata[23:16] <= in_buffer;
                count <= 3;
              end
              3: begin
                ldata[31:24] <= in_buffer;
                state <= 2;
                count <= 0;
              end
              default: begin

              end
            endcase
          end

        end

        4'd2: begin
          if (bus_accepted) begin
            state <= 3;
          end
        end

        4'd3: begin
          if (bus_available) begin
            ldata <= bus_data;
            state <= 4;
            count <= 0;
          end
        end

        4'd4: begin
          if (out_possible) begin
            out_request <= 1;

            case (count)
              0: begin
                out_buffer <= ldata[7:0];
                count <= 1;
              end
              1: begin
                out_buffer <= ldata[15:8];
                count <= 2;
              end
              2: begin
                out_buffer <= ldata[23:16];
                count <= 3;
              end
              3: begin
                out_buffer <= ldata[31:24];
                state <= 0;
                count <= 0;
              end
              default: begin

              end
            endcase
          end

        end

        4'd5: begin

        end

        default: begin

        end
      endcase


      if (out_request) begin
        out_request <= 0;
      end

    end

    if (in_accepted) begin
      in_accepted <= 0;
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
