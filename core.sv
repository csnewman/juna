
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
      .bus_accepted(debug_bus_accepted),
      .hlt_req(hlt_req),
      .hlt_state(hlt_state)
  );

  reg hlt_state;
  wire hlt_req;

  reg  [ 3:0] state;

  wire [18:0] next_pc = r_a_rdata[18:0] + 18'd2;

  reg  [15:0] instruction;
  reg  [31:0] reg_a;
  reg  [31:0] reg_b;
  // reg  [31:0] reg_d;

  wire signed [31:0] reg_a_signed;
  wire signed [31:0] r_a_rdata_signed;

  assign reg_a_signed = reg_a;
  assign r_a_rdata_signed = r_a_rdata;

  reg [1:0] mem_op_left;
  reg mem_offset;
  reg mem_single;


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

          if (hlt_req) begin
            hlt_state <= 1;
          end else begin
            hlt_state <= 0;
            state <= `STATE_FETCH1;
          end
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
            8'b1100_xxxx: begin  // BLT
              if (reg_a < r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end
            8'b1101_xxxx: begin  // BLE
              if (reg_a <= r_a_rdata) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end
             8'b1110_xxxx: begin  // BLTS
              if (reg_a_signed < r_a_rdata_signed) begin
                r_a_addr <= instruction[3:0];
                state <= `STATE_EXEC2;
              end else begin
                state <= `STATE_FETCH0;
              end
            end

            8'b1111_0xx0: begin  // LD
              // TODO: Handle port version

              // Mem address
              m_a_req <= 1;
              m_a_write <= 0;
              m_a_sel   <= 2'b11;

              // Init loaded value to zero
              r_a_wdata <= 0;

              mem_offset <= 0;
              mem_single <= 0;

              if (r_a_rdata[0]) begin
                mem_single <= 1;

                case (instruction[10:9])
                  2'b00: begin
                    mem_op_left <= 0;
                    m_a_adr <= r_a_rdata[18:1];
                    mem_offset <= 1;
                  end
                  2'b01: begin
                    mem_op_left <= 1;

                    reg_b <= r_a_rdata[18:1]; // Next addr
                    m_a_adr <= r_a_rdata[18:1] + 1;
                  end
                  2'b10: begin
                    mem_op_left <= 3;

                    reg_b <= r_a_rdata[18:1] + 1; // Next addr
                    m_a_adr <= r_a_rdata[18:1] + 2;
                  end
                  default: begin
                    mem_op_left <= 0;
                  end
                endcase
              end else begin

                case (instruction[10:9])
                2'b00: begin
                  mem_op_left <= 0;
                  mem_single <= 1;
                  m_a_adr <= r_a_rdata[18:1];
                end
                2'b01: begin
                  mem_op_left <= 0;
                  m_a_adr <= r_a_rdata[18:1];
                end
                2'b10: begin
                  mem_op_left <= 2;
                  reg_b <= r_a_rdata[18:1]; // Next addr
                  m_a_adr <= r_a_rdata[18:1] + 1;
                end
                default: begin
                  mem_op_left <= 0;
                end
              endcase
              end

              state <= `STATE_EXEC3;
            end

            8'b1111_0xx1: begin  // ST
              // TODO: Handle port version

              // Mem address
              reg_b <= r_a_rdata[18:1] + 1;
              m_a_adr <= r_a_rdata[18:1];
              m_a_req <= 1;
              m_a_write <= 1;

              if (r_a_rdata[0]) begin
                m_a_sel   <= 2'b10;
                m_a_wdata <= {reg_a[7:0], {8{1'b0}}};
                reg_a <= {{8{1'b0}}, reg_a[31:8]};
                mem_single <= 1;
                mem_offset <= 1;

                case (instruction[10:9])
                  2'b00: begin
                    mem_op_left <= 0;
                  end
                  2'b01: begin
                    mem_op_left <= 1;
                  end
                  2'b10: begin
                    mem_op_left <= 3;
                  end
                  default: begin
                    mem_op_left <= 0;
                  end
                endcase
              end else begin
                mem_offset <= 0;
                mem_single <= 0;
                reg_a <= {{16{1'b0}}, reg_a[31:16]};
                m_a_wdata <= reg_a[15:0];

                case (instruction[10:9])
                2'b00: begin
                  mem_op_left <= 0;
                  mem_single <= 1;
                  m_a_sel   <= 2'b01;
                end
                2'b01: begin
                  mem_op_left <= 0;
                  m_a_sel   <= 2'b11;
                end
                2'b10: begin
                  mem_op_left <= 2;
                  m_a_sel   <= 2'b11;
                end
                default: begin
                  mem_op_left <= 0;
                end
              endcase
              end

              state <= `STATE_EXEC3;
            end

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
            mem_offset <= 0;
            mem_single <= 0;


            if (instruction[8]) begin // Store
              reg_a <= {{16{1'b0}}, reg_a[31:16]};
              m_a_wdata <= reg_a[15:0];

              reg_b <= reg_b + 1;

              case (mem_op_left)
              2'd0: begin
                // Done
                state <= `STATE_FETCH0;
              end
              2'd1: begin
                m_a_sel   <= 2'b01;
                mem_single <= 1;
                m_a_write <= 1;
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 0;

              end
              2'd2: begin
                m_a_sel   <= 2'b11;
                m_a_write <= 1;
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 0;
              end
              2'd3: begin
                m_a_sel   <= 2'b11;
                m_a_write <= 1;
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 1;
              end
              default: begin

              end
              endcase

            end else begin // Load
              if (mem_offset) begin
                r_a_wdata <= {r_a_wdata[23:0], m_a_rdata[15:8]};
              end else if (mem_single) begin
                r_a_wdata <= {r_a_wdata[23:0], m_a_rdata[7:0]};
              end else begin
                r_a_wdata <= {r_a_wdata[15:0], m_a_rdata[15:0]};
              end

              reg_b <= reg_b - 1;

              case (mem_op_left)
              2'd0: begin
                // Done
                r_a_addr  <= instruction[3:0];
                r_a_write <= 1;
                state <= `STATE_FETCH0;
              end
              2'd1: begin
                mem_single <= 1;
                mem_offset <= 1;
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 0;
              end
              2'd2: begin
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 0;
              end
              2'd3: begin
                m_a_adr <= reg_b;
                m_a_req <= 1;
                mem_op_left <= 1;
              end
              default: begin

              end
              endcase
            end
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
    output bus_accepted,

    output reg hlt_req,
    input  hlt_state
);

  reg [3:0] state;
  reg accepted;
  reg available;
  reg [63:0] value;
  reg [63:0] request;

  assign bus_data = bus_addr == 3 && state != 0 ? value : 'z;
  assign bus_available = bus_addr == 3 ? available : 'z;
  assign bus_accepted = bus_addr == 3 ? accepted : 'z;


  always @(posedge clk) begin
    if (rst) begin
      state <= 0;
      accepted <= 0;
      available <= 0;
      value <= 0;
      hlt_req <= 1;
    end else begin
      case (state)
        0: begin
          accepted  <= 0;
          available <= 0;

          if (bus_addr == 3 && bus_start) begin
            accepted <= 1;
            state <= 1;
            request <= bus_data;

            case (bus_data[7:0])
              8'd0: begin  // State
                // Nothing
              end
              8'd1: begin  // Halt
                hlt_req <= 1;
              end
              8'd2: begin  // Resume
                hlt_req <= 0;
              end
              default: begin
                // TODO
              end
            endcase
          end
        end
        1: begin
          accepted <= 0;
          case (request[7:0])
            8'd0: begin  // Halt
              available <= 1;
              state <= 2;
              value <= {{63{1'b0}}, hlt_state};
            end
            8'd1: begin  // Halt
              if (hlt_state) begin
                available <= 1;
                state <= 2;
                value <= 1;
              end
            end
            8'd2: begin  // Resume
              if (!hlt_state) begin
                available <= 1;
                state <= 2;
                value <= 1;
              end
            end
            default: begin
              // TODO
            end
          endcase
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
