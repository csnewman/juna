
`define STATE_STOPPED 4'd0
`define STATE_FETCH0 4'd1
`define STATE_FETCH1 4'd2
`define STATE_DECODE1 4'd3
`define STATE_DECODE2 4'd4
`define STATE_DECODE3 4'd5
`define STATE_EXEC1 4'd6
`define STATE_EXEC2 4'd7
`define STATE_EXEC3 4'd8
`define STATE_EXEC4 4'd9

module core (
    input rst,
    input clk,

    input [7:0] debug_bus_addr,
    input debug_bus_start,
    inout [63:0] debug_bus_data,
    output debug_bus_available,
    output debug_bus_accepted,

    output reg [3:0] r_a_addr,
    output reg r_a_write,
    output reg [31:0] r_a_wdata,
    input [31:0] r_a_rdata,

    output [17:0] m_a_adr,
    output reg m_a_req,
    input m_a_ack,
    output reg m_a_write,
    output [1:0] m_a_sel,
    input [15:0] m_a_rdata,
    output [15:0] m_a_wdata
);

  debug_core debug_core_inst (
      .rst(rst),
      .clk(clk),
      .bus_addr(debug_bus_addr),
      .bus_start(debug_bus_start),
      .bus_data(debug_bus_data),
      .bus_available(debug_bus_available),
      .bus_accepted(debug_bus_accepted)
  );

  reg  [ 3:0] state;

  wire [18:0] next_pc = r_a_rdata[18:0] + 18'd2;

  reg  [15:0] instruction;
  reg  [31:0] reg_a;
  reg  [31:0] reg_b;
  // reg  [31:0] reg_d;

  always @(posedge clk) begin
    if (rst) begin
      //   state <= `STATE_STOPPED;
      state <= `STATE_FETCH0;
      r_a_write <= 0;

      m_a_req <= 0;
      m_a_write <= 0;
      m_a_sel <= 2'b11;
    end else begin
      case (state)
        `STATE_STOPPED: begin
          // Do nothing
          r_a_write <= 0;
          m_a_req   <= 0;

        end
        `STATE_FETCH0: begin
          r_a_addr <= 15;
          r_a_write <= 0;
          state <= `STATE_FETCH1;
        end
        `STATE_FETCH1: begin
          r_a_addr <= 15;
          r_a_write <= 1;
          r_a_wdata <= {{13{1'b0}}, next_pc};

          m_a_adr <= r_a_rdata[18:1];
          m_a_req <= 1;
          m_a_write <= 0;

          m_a_sel <= 2'b11;
          state <= `STATE_DECODE1;
        end
        `STATE_DECODE1: begin
          if (m_a_ack) begin
            m_a_req <= 0;
            r_a_write <= 0;

            instruction <= m_a_rdata;

            // if (m_a_rdata == 16'b1101_0100_0000_0000) begin
            //   state <= `STATE_STOPPED;
            // end else 
            // begin
            priority casex (m_a_rdata[15:8])
              8'b1010_xxxx: begin  // Constant byte
                // Write to D
                r_a_addr <= m_a_rdata[3:0];
                r_a_wdata <= {{24{1'b0}}, m_a_rdata[11:4]};
                r_a_write <= 1;
                state <= `STATE_FETCH0;
              end

              8'b1111_xxx0: begin  // Memory read
                // Skip A
                r_a_addr <= m_a_rdata[7:4];
                state <= `STATE_EXEC1;
              end

              8'b1111_xxx1: begin  // Memory write
                // Load D (into a)
                r_a_addr <= m_a_rdata[3:0];
                state <= `STATE_DECODE3;
              end

              default: begin
                // Load A
                r_a_addr <= m_a_rdata[11:8];
                state <= `STATE_DECODE2;
              end
            endcase
            // end
          end
        end

        `STATE_DECODE2: begin
          // Store a
          reg_a <= r_a_rdata;
          // Load b
          r_a_addr <= instruction[7:4];
          state <= `STATE_EXEC1;
        end
        `STATE_DECODE3: begin
          // Store d into a
          reg_a <= r_a_rdata;
          // Load b
          r_a_addr <= instruction[7:4];
          state <= `STATE_EXEC1;
        end

        `STATE_EXEC1: begin
          reg_b <= r_a_rdata;


          casex (instruction[15:8])
            8'b0000_xxxx: begin : AND_INST  // ADD
              r_a_addr <= instruction[3:0];
              r_a_wdata <= reg_a + r_a_rdata;
              r_a_write <= 1;
              state <= `STATE_FETCH0;
            end
            8'b0001_xxxx: begin  // SUB
              r_a_addr <= instruction[3:0];
              r_a_wdata <= reg_a - r_a_rdata;
              r_a_write <= 1;
              state <= `STATE_FETCH0;
            end
            8'b0010_xxxx: begin  // XOR
              r_a_addr <= instruction[3:0];
              r_a_wdata <= reg_a ^ r_a_rdata;
              r_a_write <= 1;
              state <= `STATE_FETCH0;
            end
            8'b0011_xxxx: begin  // AND
              r_a_addr <= instruction[3:0];
              r_a_wdata <= reg_a & r_a_rdata;
              r_a_write <= 1;
              state <= `STATE_FETCH0;
            end
            8'b0100_xxxx: begin  // ORR
              r_a_addr <= instruction[3:0];
              r_a_wdata <= reg_a | r_a_rdata;
              r_a_write <= 1;
              state <= `STATE_FETCH0;
            end
            8'b0101_xxxx: begin  // SHF
              state <= `STATE_EXEC4;
            end
            8'b1011_xxxx: begin  // BEQ
              if (reg_a == r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end
            8'b1100_xxxx: begin  // BNE
              if (reg_a != r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end
            8'b1101_xxxx: begin  // BLT
              if (reg_a < r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end
            8'b1110_xxxx: begin  // BLE
              if (reg_a <= r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end

            8'b1111_0000: begin  // LDB
              m_a_adr <= r_a_rdata[18:1];
              m_a_req <= 1;
              m_a_write <= 0;
              m_a_sel <= r_a_rdata[0] ? 2'b10 : 2'b01;
              state <= `STATE_EXEC3;
            end

            8'b1111_0001: begin  // STB
              m_a_adr   <= r_a_rdata[18:1];
              m_a_req   <= 1;
              m_a_write <= 1;

              if (r_a_rdata[0]) begin
                m_a_sel   <= 2'b10;
                m_a_wdata <= {reg_a[7:0], {8{1'b0}}};
              end else begin
                m_a_sel   <= 2'b01;
                m_a_wdata <= {{8{1'b0}}, reg_a[7:0]};
              end

              state <= `STATE_EXEC3;
            end

            // 8'b1111_xxx0: begin  // Memory read
            // end
            // 8'b1111_xxx1: begin  // Memory write
            // end

            default: begin
              // TODO
              // r_a_addr <= m_a_rdata[3:0];
              // state <= `STATE_DECODE2;
            end
          endcase

        end

        `STATE_EXEC2: begin
          // Jump
          r_a_addr <= 15;
          r_a_write <= 1;
          r_a_wdata <= r_a_rdata;
          state <= `STATE_FETCH0;
        end

        `STATE_EXEC3: begin
          if (m_a_ack) begin
            m_a_req <= 0;
            m_a_write <= 0;


            case (instruction[15:8])
              8'b1111_0000: begin  // LDB
                r_a_addr  <= instruction[3:0];
                r_a_write <= 1;

                if (reg_b[0]) begin
                  r_a_wdata <= {{24{1'b0}}, m_a_rdata[15:8]};
                end else begin
                  r_a_wdata <= {{24{1'b0}}, m_a_rdata[7:0]};
                end

                state <= `STATE_FETCH0;
              end

              8'b1111_0001: begin  // LDB
                state <= `STATE_FETCH0;
              end

              // 8'b1111_xxx0: begin  // Memory read
              // end
              // 8'b1111_xxx1: begin  // Memory write
              // end

              default: begin
                // TODO
                // r_a_addr <= m_a_rdata[3:0];
                // state <= `STATE_DECODE2;
              end
            endcase

          end
        end

        `STATE_EXEC4: begin
          if (reg_b == 0) begin
            r_a_addr <= instruction[3:0];
            r_a_wdata <= reg_a;
            r_a_write <= 1;
            state <= `STATE_FETCH0;
          end else if (reg_b[31] == 0) begin
            reg_b <= reg_b - 1;
            reg_a <= reg_a << 1;
          end else begin
            reg_b <= reg_b + 1;
            reg_a <= reg_a >> 1;
          end
        end

        default begin
        end

      endcase
    end
  end

endmodule

module debug_core (
    input rst,
    input clk,

    input [7:0] bus_addr,
    input bus_start,
    inout [63:0] bus_data,
    output bus_available,
    output bus_accepted

);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [63:0] value;

  assign bus_data = bus_addr == 3 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 3 ? available : 'z;
  assign bus_accepted = bus_addr == 3 ? accepted : 'z;


  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
      value <= 0;


    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          // && ram_ready
          if (bus_addr == 3 && bus_start) begin
            accepted <= 1;
            state <= 1;

          end
        end
        1: begin
          accepted <= 0;

          available <= 1;
          state <= 2;
          value <= 2;
        end

        2: begin
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