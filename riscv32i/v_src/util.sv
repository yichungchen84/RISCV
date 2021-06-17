module mux2(
  input [31:0] mux_in1,
  input [31:0] mux_in2,
  input [0:0] mux_sel,
  output [31:0] mux_out
);
  assign mux_out = mux_sel? mux_in2 : mux_in1;
endmodule

module adder32(
  input [0:0] adder32_en,
  input [31:0] adder32_in1,
  input [31:0] adder32_in2,
  output [31:0] adder32_out
);

  logic [32:0] adder32_res;
  assign adder32_res = adder32_in1 + adder32_in2;
  assign adder32_out = adder32_en? adder32_res[31:0] : 32'b0;
endmodule