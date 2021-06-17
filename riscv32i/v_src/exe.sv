module exe_stage(
  input clk,
  input reset,


  input [6:0] current_stage_flag, //{exe_flag,mem_flag,wb_flag}
  output reg [3:0] next_stage_flag, //{mem_flag,wb_flag}
  //flag alu_en,adder32_en,mem_rd_en,csr_wr_en,mem_wr_en,branch_en,rd_en

  // main parameter
  input [6:0] param_in, //{alu_src,alu_op,mem_to_reg}
  output reg [1:0] param_out, //{mem_to_reg}
  // param: alu_src,alu_op,mem_to_reg
  // main parameter
  input [3:0] mem_width_in,
  output reg [3:0] mem_width,
  
  input [11:0] csr_addr_in,
  output reg [11:0] csr_addr_out,

  input [31:0] pc_in,

  //main input
  input [31:0] rs1_data,
  input [31:0] rs2_data,
  input [31:0] imm,
  input [3:0] instr30_funct,
  input [4:0] rd_addr_in,
  input [31:0] csr_rd_data,
  //main input

  //main output
  output reg [31:0] adder32_out,
  output reg [0:0] zero,
  output reg [31:0] alu_out,
  output reg [31:0] mem_wr_data,
  //output reg [0:0] mem_rd_en,
  //output reg [0:0] mem_wr_en,
  output reg [4:0] rd_addr_out,
  
  output reg [31:0] csr_wr_data,
  output reg [0:0] csr_wr_en
  
  //main output

);
  logic [0:0] alu_en,adder32_en;
  assign alu_en = current_stage_flag[6];
  assign adder32_en = current_stage_flag[5];

  logic [3:0] next_stage_flag_temp;
  assign next_stage_flag_temp = current_stage_flag[3:0];

  logic [0:0] alu_src;
  logic [3:0] alu_op;
  assign alu_src = param_in[6];
  assign alu_op = param_in[5:2];

  logic [31:0] alu_in1, alu_in2, alu_in1_temp, alu_in2_temp, alu_out_temp;
  logic [0:0] zero_temp;
  logic [31:0] adder32_in1, adder32_in2, adder32_out_temp;
  logic [3:0] alu_ctl;

  alu alu_core(
    .alu_en(alu_en),
    .alu_in1(alu_in1),
	.alu_in2(alu_in2),
	.alu_ctl(alu_ctl),
	.alu_out(alu_out_temp),
	.zero(zero_temp)
  );

  alu_ctrl alu_ctrl(
    .instr30_funct(instr30_funct), 
    .alu_src(alu_src),
    .alu_op(alu_op),
    .alu_ctl(alu_ctl)
  );

  mux2 mux_imm(
    .mux_in1(rs2_data),
    .mux_in2(imm),
    .mux_sel(alu_src),
    .mux_out(alu_in2_temp)
  );

  adder32 adder32_exe(
    .adder32_en(adder32_en),
    .adder32_in1(adder32_in1),
    .adder32_in2(adder32_in2),
    .adder32_out(adder32_out_temp)
  );

  assign alu_in1_temp = (alu_op == 4'b0011) ? pc_in : rs1_data;
  
  always_comb begin
    if (alu_op == 4'b1001) begin
      alu_in1 = csr_rd_data;
      if (instr30_funct[1:0] == 2'b01) begin
        alu_in2 = 32'b0;
      end
      else begin
        if (instr30_funct[2] == 1'b0) begin
          alu_in2 = rs1_data;
        end
        else begin
          alu_in2 = imm;
        end  
      end
    end
    else if (alu_op == 4'b1000) begin
      alu_in1 = alu_in1_temp;
      alu_in2 = 32'b0;
    end
    else begin
      alu_in1 = alu_in1_temp;
      alu_in2 = alu_in2_temp;
    end
  end

  assign adder32_in1 = (alu_op == 4'b0001) ? 32'b0 : pc_in;
  assign adder32_in2 = ((alu_op == 4'b0011) || (alu_op == 4'b0100)) ? 32'd4 : imm;
  
  always_ff @(posedge clk) begin
    if (reset) begin
      if ((alu_op == 4'b0011) || (alu_op == 4'b0100)) begin
        zero <= 1'b1;
      end
      else if (alu_op == 4'b0101) begin
        if (instr30_funct[2:1] == 2'b00) begin
          zero <= zero_temp ^ instr30_funct[0];
        end 
        else if (instr30_funct[2] == 1'b1) begin
          zero <= (~zero_temp) ^ instr30_funct[0];
        end
      end
      else begin
        zero <= 1'b0;
      end
    end
    else begin
      zero <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      if ((alu_op == 4'b0001) || (alu_op == 4'b0010) || (alu_op == 4'b0011) || (alu_op == 4'b0100)) begin
        alu_out <= adder32_out_temp;
        if (alu_op == 4'b0100) begin
          adder32_out <= {alu_out_temp[31:1],1'b0};
        end
        else begin
          adder32_out <= alu_out_temp;
        end
      end
      else if ((alu_op == 4'b1001) && (instr30_funct[2:0] != 3'b0)) begin // deal fence
        alu_out <= csr_rd_data;
        adder32_out <= adder32_out_temp;
      end
      else begin
        alu_out <= alu_out_temp;
        adder32_out <= adder32_out_temp;
      end
    end
    else begin
      alu_out <= 32'b0;
      adder32_out <= 32'b0;
    end 
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      if ((alu_op == 4'b1001) && (instr30_funct[1:0] == 2'b01)) begin
        if (instr30_funct[2] == 1'b0) begin
          csr_wr_data <= rs1_data;
        end
        else begin
          csr_wr_data <= imm;
        end
      end
      else begin
        csr_wr_data <= alu_out_temp;
      end
    end
    else begin
      csr_wr_data <= 32'b0;
    end
  end  

  //flag alu_en,adder32_en,mem_rd_en,mem_wr_en,csr_wr_en,branch_en,rd_en

  always_ff @(posedge clk) begin
    if (reset) begin
      mem_wr_data <= rs2_data;
      
      //mem_rd_en <= current_stage_flag[3];
      //mem_wr_en <= current_stage_flag[2];

      csr_wr_en <= current_stage_flag[4];

      rd_addr_out <= rd_addr_in;

      next_stage_flag <= next_stage_flag_temp;
      param_out <= param_in[1:0];
      
      mem_width <= mem_width_in;

      csr_addr_out <= csr_addr_in;

    end
    else begin
      mem_wr_data <= 32'b0;
      
      //mem_rd_en <= 1'b0;
      //mem_wr_en <= 1'b0;
      
      csr_wr_en <= 1'b0;
      
      rd_addr_out <= 5'b0;

      next_stage_flag <= 4'b0;
      param_out <= 2'b0;
      
      mem_width <= 4'b0;

      csr_addr_out <= 12'b0;
    end
  end

endmodule
 
module alu_ctrl(
  input [3:0] instr30_funct, 
  input [0:0] alu_src,
  input [3:0] alu_op,
  output reg [3:0] alu_ctl
);
  logic [0:0] invert; // instr_bit 30 take or not

  assign invert = alu_src? (instr30_funct[2:0]==3'b101 ? instr30_funct[3] : 1'b0) : instr30_funct[3];

  always_comb begin
    case (alu_op)
      4'b0001: begin
        alu_ctl = {1'b0,3'b000}; //lui
      end  
      4'b0010: begin 
        alu_ctl = {1'b0,3'b000}; //auipc
      end
      4'b0011: begin 
        alu_ctl = {1'b0,3'b000}; //jal
      end
      4'b0100: begin 
        alu_ctl = {1'b0,3'b000}; //jalr
      end
      4'b0110: begin //load, save
        alu_ctl = {1'b0,3'b000};
      end
      4'b0101: begin //branch
        if (instr30_funct[2:1] == 2'b00) begin
          alu_ctl = {1'b1,3'b000}; 
        end
        else if (instr30_funct[2:1] == 2'b10) begin
          alu_ctl = {1'b0,3'b010};
        end
        else if (instr30_funct[2:1] == 2'b11) begin
          alu_ctl = {1'b0,3'b011};
        end
        else begin
          alu_ctl = {1'b0,3'b000}; 
        end
      end
      4'b0111: begin // opimm, op
        alu_ctl = {invert, instr30_funct[2:0]};
      end
      /*4'b1000: begin // trap
        alu_ctl = {1'b0,3'b000};
      end*/
      4'b1001: begin // CSR
        //if (fence == 1'b0) begin (temp removed, restored it later)
        if (instr30_funct[1:0] == 2'b00) begin
          alu_ctl = {1'b0,3'b000};
        end
        else if (instr30_funct[1:0] == 2'b10) begin
          alu_ctl = {1'b0,3'b110};
        end
        else if (instr30_funct[1:0] == 2'b11) begin
          alu_ctl = {1'b1,3'b111};
        end
        else begin
          alu_ctl = {1'b0,3'b000}; 
        end
      end  
      4'b1100: begin // Fence
        alu_ctl = {1'b0,3'b000};
      end
      default: begin
        alu_ctl = {1'b0,3'b000};
      end
    endcase
  end
endmodule

module alu(
  input [0:0] alu_en,
  input [31:0] alu_in1,
  input [31:0] alu_in2,
  input [3:0] alu_ctl, //??
  output reg [31:0] alu_out,
  output reg [0:0] zero
);

  logic [32:0] alu_res;  
  //logic [31:0] alu_out_temp;
  logic less_than_temp, less_than, zero_temp;

  logic [31:0] alu_in2_temp_add, alu_in2_temp_and;  

  assign alu_in2_temp_add = alu_ctl[3] ? (~alu_in2 + 32'b1): alu_in2;
  
  assign alu_in2_temp_and = alu_ctl[3] ? (~alu_in2) : alu_in2;

  always_comb begin
    if (alu_en) begin    
      case (alu_ctl[2:0])
        3'b000: // add
          begin
            alu_res = (alu_in1 + alu_in2_temp_add);
            alu_res[32] = 1'b0;
          end
        3'b001: // Shift left
          begin
            alu_res[31:0] = (alu_in1) << alu_in2[4:0];
            alu_res[32] = 1'b0;
          end
        3'b010: // set if less
          begin
            if (alu_in1[31] == 1 && alu_in2[31] == 0) begin
              alu_res = 33'b1;
            end
            else if (alu_in1[31] == 0 && alu_in2[31] == 1) begin
              alu_res = 33'b0;
            end 
            else if (alu_in1[31] == alu_in2[31]) begin
              if (alu_in1[30:0] < alu_in2[30:0]) begin
                alu_res = 33'b1;
              end
              else begin
                alu_res = 33'b0;
              end
            end
            else begin
              alu_res = 33'b0;
            end
          end
        3'b011: // set if less Unsigned
          begin
            if (alu_in1[31:0] < alu_in2[31:0]) begin
              alu_res = 33'b1;
            end
            else begin
              alu_res = 33'b0;
            end
          end
            // alu_res = alu_in1 - alu2;						
        3'b100: // XOR
          begin
            alu_res[31:0] = alu_in1 ^ alu_in2;	
            alu_res[32] = 1'b0;
          end				
        3'b101: // Shift right
          begin 
            if (alu_ctl[3]) begin
              alu_res[31:0] = $signed(alu_in1)  >>> alu_in2[4:0];
              alu_res[32] = alu_res[31];
            end
            else begin
              alu_res[31:0] = alu_in1 >> alu_in2[4:0];
              alu_res[32] = alu_res[31];
            end
          end
        3'b110: // OR
          begin
            alu_res[31:0] = alu_in1 | alu_in2;
            alu_res[32] = 1'b0;
          end					
        3'b111: // AND
          begin
            alu_res[31:0] = alu_in1 & alu_in2_temp_and;
            alu_res[32] = 1'b0;
          end
        default: alu_res = 33'h0;  						// default
      endcase
      
      alu_out = alu_res [31:0];

      zero = (alu_res[31:0] == 32'b0) ? 1'b1 : 1'b0;
    end
    else begin
      alu_res = 33'b0;
      alu_out = 32'b0;
      zero = 1'b0;
    end
  end
endmodule

