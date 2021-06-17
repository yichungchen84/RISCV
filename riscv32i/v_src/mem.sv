module mem_stage(
  input clk,
  input reset,
  
  input [3:0] current_stage_flag, //{mem_flag,wb_flag}
  output reg [0:0] next_stage_flag, //{wb_flag}
  //flag: mem_rd_en,mem_wr_en,branch_en,rd_en

  // main parameter
  input [1:0] param_in, //{mem_to_reg}
  output reg [1:0] param_out, //{mem_to_reg}
  //param: mem_to_reg
  // main parameter
  input [3:0] mem_width_in,
  output reg [3:0] mem_width_out,

  //main input
  input [31:0] adder32_in,
  input [0:0] zero,
  input [31:0] mem_addr_in,
  input [4:0] rd_addr_in,
  //main input

  //main output
  output [31:0] adder32_out,
  output [0:0] pc_src,
  output [31:0] mem_rd_data_out,
  output reg [31:0] alu_mem_data_out,
  output reg [4:0] rd_addr_out,
  
  output reg [0:0] mem_rd_en,
  output reg [0:0] mem_wr_en,
  //main output

  output [31:0] mem_addr_out,
  input [31:0] mem_rd_data_in,
  
  output reg [0:0] i_misalign,
  output reg [0:0] l_misalign,
  output reg [0:0] s_misalign

);
  assign mem_addr_out = mem_addr_in;

  logic [0:0] next_stage_flag_temp; // rd_en
  assign next_stage_flag_temp = current_stage_flag[0:0];

  assign mem_rd_data_out = mem_rd_data_in;

  assign pc_src = current_stage_flag[1] & zero; // current_stage_flag[0] >> branch_en
  
  assign adder32_out = adder32_in;
  
  logic [0:0] mem_rd_en_temp, mem_wr_en_temp;
  assign mem_rd_en_temp = current_stage_flag[3];
  assign mem_wr_en_temp = current_stage_flag[2];
  
  always_comb begin
    if ((adder32_in[1:0] != 2'b0) &&  (pc_src == 1'b1)) begin
      i_misalign = 1'b1;
    end
    else begin
      i_misalign = 1'b0;
    end
  end
  
  always_comb begin
    if (mem_width_in == 4'b1111) begin
      if (mem_addr_in[1:0] != 2'b0) begin
        if (mem_rd_en_temp == 1'b1) begin
          l_misalign = 1'b1;
          s_misalign = 1'b0;
        end
        else if (mem_wr_en_temp == 1'b1) begin
          l_misalign = 1'b0;
          s_misalign = 1'b1;
        end
        else begin
          l_misalign = 1'b0;
          s_misalign = 1'b0;
        end
      end
      else begin
        l_misalign = 1'b0;
        s_misalign = 1'b0;
      end
    end
    else if (mem_width_in == 4'b0011) begin
      if (mem_addr_in[0:0] != 1'b0) begin
        if (mem_rd_en_temp == 1'b1) begin
          l_misalign = 1'b1;
          s_misalign = 1'b0;
        end
        else if (mem_wr_en_temp == 1'b1) begin
          l_misalign = 1'b0;
          s_misalign = 1'b1;
        end
        else begin
          l_misalign = 1'b0;
          s_misalign = 1'b0;
        end
      end
      else begin
        l_misalign = 1'b0;
        s_misalign = 1'b0;
      end
    end
    else if (mem_width_in == 4'b0001) begin
      l_misalign = 1'b0;
      s_misalign = 1'b0;
    end
    else begin
      l_misalign = 1'b0;
      s_misalign = 1'b0;
    end
  end
  
  always_comb begin
    if (l_misalign == 1'b1) begin
      mem_rd_en = 1'b0;
    end
    else begin
      mem_rd_en = mem_rd_en_temp;
    end
  end

  always_comb begin
    if (s_misalign == 1'b1) begin
      mem_wr_en = 1'b0;
    end
    else begin
      mem_wr_en = mem_wr_en_temp;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin    
      rd_addr_out <= rd_addr_in;
      alu_mem_data_out <= mem_addr_in;
      
      if (l_misalign == 1'b1) begin
        next_stage_flag <= 1'b0; // wb_flag: rd_en
      end
      else begin
        next_stage_flag <= next_stage_flag_temp;
      end
      
      param_out <= param_in[1:0];
      mem_width_out <= mem_width_in;
    end
    else begin
      rd_addr_out <= 5'b0;
      alu_mem_data_out <= 32'b0;
      next_stage_flag <= 1'b0;
      param_out <= 2'b0;
      mem_width_out <= 4'b0;
    end
  end

endmodule

