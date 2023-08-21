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
    output [15:0] m_a_wdata
);

  assign m_a_write = 0;
  assign m_a_sel   = 2'b11;
  assign m_a_wdata = 'z;

  //   reg out_value;


  reg [4:0] time_count;
  reg [4:0] bits;
  reg [8:0] pos;
  reg [15:0] out_data;
  reg [15:0] next_out_data;

  wire out_active = pos[0] ? out_data[15-bits] : out_data[7-bits];

  reg [2:0] state;

  always @(posedge clk) begin
    if (rst) begin
      bits <= 0;
      pos <= 0;
      out_data <= 0;
      ctrl_out <= 0;
      state <= `STATE_IDLE;
      m_a_req <= 0;
      time_count <= 0;
    end else begin
      case (state)
        `STATE_IDLE: begin
          ctrl_out <= 0;
          m_a_req <= 0;
          m_a_adr <= 0;

          state <= `STATE_START;
        end
        `STATE_START: begin
          ctrl_out <= 0;
          m_a_adr  <= 500;  // BASE
          m_a_req  <= 1;

          if (m_a_ack) begin
            m_a_req <= 1;
            m_a_adr <= m_a_adr + 1;


            pos <= 0;
            bits <= 0;
            time_count <= 0;
            out_data <= m_a_rdata;
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
