`define STATE_IDLE 3'd0
`define STATE_START 3'd1
`define STATE_ACT 3'd2

module lights_controller (
    input clk,
    input rst,
    output reg ctrl_out,

    output reg [17:0] m_a_adr,
    output reg m_a_req,
    input m_a_ack,
    output m_a_write,
    output [1:0] m_a_sel,
    input [15:0] m_a_rdata,
    output [15:0] m_a_wdata,

    input [7:0] port_addr,
    input port_req,
    output port_ack,
    output [31:0] port_rdata,
    input [31:0] port_wdata
);

  assign m_a_write = 0;
  assign m_a_sel   = 2'b11;
  assign m_a_wdata = 'z;

  wire port_sel;
  assign port_sel = port_addr == 8'd1;
  reg [31:0] port_rdata_value;
  assign port_rdata = port_sel ? port_rdata_value : 'z;
  reg port_ack_value;
  assign port_ack = port_sel ? port_ack_value : 'z;

  reg [4:0] time_count;
  reg [4:0] bits;
  reg [8:0] pos;
  reg [15:0] out_data;
  reg [15:0] next_out_data;

  wire out_active = pos[0] ? out_data[15-bits] : out_data[7-bits];

  reg [2:0] state;

  reg [17:0] next_base;
  reg next_avail;

  always @(posedge clk) begin
    if (rst) begin
      bits <= 0;
      pos <= 0;
      out_data <= 0;
      ctrl_out <= 0;
      state <= `STATE_IDLE;
      m_a_req <= 0;
      time_count <= 0;
      next_base <= 0;
      next_avail <= 0;
      port_ack_value <= 0;
      port_rdata_value <= 0;
    end else begin
      port_ack_value <= 0;

      if (port_req) begin
        next_base <= port_wdata[18:1];
        port_rdata_value <= port_wdata;
        next_avail <= 1;
      end

      case (state)
        `STATE_IDLE: begin
          ctrl_out <= 0;
          m_a_req <= 0;
          m_a_adr <= 0;

          if (next_avail) begin
            state <= `STATE_START;
            m_a_adr <= next_base;
            port_ack_value <= 1;
          end

        end
        `STATE_START: begin
          ctrl_out <= 0;
          // m_a_adr  <= 500;  // BASE
          m_a_req  <= 1;

          if (m_a_ack) begin
            m_a_req <= 1;
            m_a_adr <= m_a_adr + 1;


            pos <= 0;
            bits <= 0;
            time_count <= 0;
            out_data <= m_a_rdata;
            // next_out_data <= 16'b1111111111111111;
            state <= `STATE_ACT;
          end
        end
        `STATE_ACT: begin
          if (pos < 300) begin
            if (out_active) begin
              ctrl_out <= time_count < 6;
            end else begin
              ctrl_out <= time_count < 3;
            end
          end else begin
            ctrl_out <= 0;
          end

          if (m_a_ack) begin
            m_a_req <= 0;
            next_out_data <= m_a_rdata;
          end

          if (time_count == 12) begin
            time_count <= 0;


            if (bits == 7) begin
              bits <= 0;
              pos  <= pos + 1;

              if (pos < 299) begin
                if (pos[0]) begin
                  out_data <= next_out_data;
                  // next_out_data <= 16'b1111111111111111;

                  m_a_req  <= 1;
                  m_a_adr  <= m_a_adr + 1;  // BASE
                end
              end else begin
                out_data <= 0;

                if (pos == 306) begin
                    state <= `STATE_IDLE;
                end
              end
            end else begin
              bits <= bits + 1;
            end
          end else begin
            time_count <= time_count + 1;
          end
        end
      endcase
    end
  end


endmodule
