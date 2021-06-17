module wb_stage(
  input clk,
  input reset,

  input [0:0] current_stage_flag,
  //flag: rd_en

  input [1:0] param_in, //{mem_to_reg}
  //param: mem_to_reg
  input [3:0] mem_width_in,

  //main input
  input [31:0] alu_mem_data,
  input [31:0] mem_rd_data,
  input [4:0] rd_addr_in,
  //main input

  output [0:0] rd_en_out,
  output [4:0] rd_addr_out,
  output [31:0] rd_data_out

);
  logic [0:0] rd_en_in;
  logic [0:0] mem_to_reg;
  assign mem_to_reg = param_in[1];
  
  logic [0:0] load_unsigned;
  assign load_unsigned = param_in[0];
  
  assign rd_en_in = current_stage_flag;

  assign rd_en_out = rd_en_in;
  assign rd_addr_out = rd_addr_in;
  
  logic [31:0] mem_rd_data_temp; 
  
  always_comb begin
    if (reset) begin
      case (mem_width_in)
        4'b0011: begin //load H
          if (load_unsigned == 1'b1) begin
            mem_rd_data_temp = {16'b0,mem_rd_data[15:0]};
          end
          else begin
            mem_rd_data_temp = {{16{mem_rd_data[15]}},mem_rd_data[15:0]};
          end
        end
        4'b0001: begin //load B
          if (load_unsigned == 1'b1) begin
            mem_rd_data_temp = {24'b0,mem_rd_data[7:0]};
          end
          else begin
            mem_rd_data_temp = {{24{mem_rd_data[7]}},mem_rd_data[7:0]};
          end
        end
        4'b1111: begin //load full
          mem_rd_data_temp = mem_rd_data;
        end
        default: begin
          mem_rd_data_temp = mem_rd_data;
        end
      endcase
    end
    else begin
      mem_rd_data_temp = 32'b0;
    end
  end

  mux2 mux_wb(
    .mux_in1(alu_mem_data),
    .mux_in2(mem_rd_data_temp),
    .mux_sel(mem_to_reg),
    .mux_out(rd_data_out)
  );


endmodule

