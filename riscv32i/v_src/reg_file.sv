module register_file(
  input clk,
  input reset,
  input [0:0] rd_en,
  input [0:0] rs1_en,
  input [0:0] rs2_en,
  input [4:0] rs1_addr,
  input [4:0] rs2_addr,
  input [4:0] rd_addr,
  input [31:0] rd_data,
  output reg [31:0] rs1_data,
  output reg [31:0] rs2_data
);
 
  logic [31:0] register [31:1];
  
  // test only
  integer index;
  //
  
  always_ff @(posedge clk) begin
    if (reset) begin
      if (rd_en & (rd_addr!=5'b0)) begin
        register[rd_addr] <= rd_data;
      end

      if (rs1_en & (rs1_addr!=5'b0)) begin
        rs1_data <= register[rs1_addr];
      end
      else begin
        rs1_data <= 32'h0;
      end

      if (rs2_en &(rs2_addr!=5'b0)) begin
        rs2_data <= register[rs2_addr];
      end
      else begin
        rs2_data <= 32'h0;
      end
    end
    else begin
      rs1_data <= 32'h0;
      rs2_data <= 32'h0;
      // initial
      for (index=1; index<32; index=index+1) begin
        register[index] <= 32'b0;
      end
      // initial
    end
  end
  
endmodule // registers