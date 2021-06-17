
module if_im_stage(
  input clk, 
  input reset,
  
  input [0:0] op_en_in,
  output reg [0:0] op_en_out,
 
  input [31:0] pc_in,
  output reg [31:0] pc_out,

  input [31:0] instr_in,
  output [31:0] instr_out
); 

  assign instr_out = instr_in;

  always_ff @(posedge clk) begin
    if (reset) begin
      op_en_out <= op_en_in;
      pc_out <= pc_in;
    end 
    else begin
      op_en_out <= 1'b0;
      pc_out <= 32'b0;
    end
  end
 
endmodule // control_unit

