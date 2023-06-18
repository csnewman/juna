module w6debug (
    input rst,
    input clk,
    input io_clk,
    input io_dir,
    output reg io_cts,
    output reg io_rts,
    input io_in,
    output reg io_out,

    output [7:0] bus_addr,
    output bus_start,
    inout [63:0] bus_data,
    input bus_available,
    input bus_accepted
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
      .bus_start(bus_start),
      .bus_data(bus_data),
      .bus_available(bus_available),
      .bus_accepted(bus_accepted)
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

module debug_control (
    input rst,
    input clk,

    input [7:0] in_buffer,
    input in_available,
    output reg in_accepted,


    input out_possible,
    output reg out_request,
    output reg [7:0] out_buffer,

    output reg [7:0] bus_addr,
    output reg bus_start,
    inout [63:0] bus_data,
    input bus_available,
    input bus_accepted
);

  reg [ 3:0] state;
  reg [ 2:0] count;
  reg [63:0] ldata;
  assign bus_data = state == 2 ? ldata : 'z;

  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      bus_addr <= 0;
      out_request <= 0;
      bus_start <= 0;
    end else begin
      case (state)
        4'd0: begin  // Waiting for cmd
          if (in_available) begin
            state <= 1;
            in_accepted <= 1;
            bus_addr <= in_buffer;
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
                count <= 4;
              end
              4: begin
                ldata[39:32] <= in_buffer;
                count <= 5;
              end
              5: begin
                ldata[47:40] <= in_buffer;
                count <= 6;
              end
              6: begin
                ldata[55:48] <= in_buffer;
                count <= 7;
              end
              7: begin
                ldata[63:56] <= in_buffer;
                state <= 2;
                count <= 0;
                bus_start <= 1;
              end
              default: begin

              end
            endcase
          end

        end

        4'd2: begin
          if (bus_accepted) begin
            state <= 3;
            bus_start <= 0;
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
                count <= 4;
              end
              4: begin
                out_buffer <= ldata[39:32];
                count <= 5;
              end
              5: begin
                out_buffer <= ldata[47:40];
                count <= 6;
              end
              6: begin
                out_buffer <= ldata[55:48];
                count <= 7;
              end
              7: begin
                out_buffer <= ldata[63:56];
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


      if (in_accepted) begin
        in_accepted <= 0;
      end

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
