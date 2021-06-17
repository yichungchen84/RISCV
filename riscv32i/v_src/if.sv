module if_stage(
  input clk, 
  input reset, 
  
  output reg [0:0] op_en,

  output reg [31:0] pc,

  input [0:0] pc_en, //pc advance
  //input [0:0] trap,
  //input [0:0] mret,
  input [0:0] csr_delay,

  input [0:0] pc_src, //pc source
  input [31:0] pc_addr_in,
  output reg [0:0] mem_instr_en,
  
  input [31:0] pc_csr
);

  logic [31:0] pc_4;
  logic [31:0] pc_temp;

  logic [0:0] adder4_en;
  assign adder4_en = 1'b1;
  logic [31:0] imm_4;
  assign imm_4 = 32'd4;
  
  adder32 adder32_pc(
    .adder32_en(adder4_en),
    .adder32_in1(pc),
    .adder32_in2(imm_4),
    .adder32_out(pc_4)
  );

  mux2 mux_pc(
    .mux_in1(pc_4),
    .mux_in2(pc_addr_in),
    .mux_sel(pc_src),
    .mux_out(pc_temp)
  );
  
  logic [31:0] pc_stall;
  logic [0:0] stall_flag;
  logic [0:0] pc_en_delay;
  
  //logic [31:0] pc_temp;
  
  /*always_comb begin
    if ((pc_temp[1:0] != 2'b0) && (pc_src == 1'b1))begin
      i_misalign = 1'b1;
    end
    else begin
      i_misalign = 1'b0;
    end
  end*/
  
  /*always @ (posedge clk) begin
    if (reset) begin
      if (pc_en == 1'b1) begin
        op_en <= 1'b1;
        mem_instr_en <= 1'b1;
        pc_stall <= pc_temp;
      end
      else begin
        op_en <= 1'b0;
        mem_instr_en <= 1'b0;
      end
    end
    else begin
      op_en <= 1'b1;
      pc <= 0;
      mem_instr_en <= 1'b1;
    end
  end*/
  
  always_ff @(posedge clk) begin
    if (reset) begin
      if (pc_src == 1'b1) begin
        pc_stall <= pc_temp;
        stall_flag <= 1'b1;
      end
      //else begin
        //pc_stall <= 32'b0;
        //stall_flag <= 1'b0;
      //end
    end
    else begin
      pc_stall <= 32'b0;
      stall_flag <= 1'b0;
    end
  end
        
  
  always_ff @(posedge clk) begin
    if (reset) begin
      if (csr_delay == 1'b1) begin
        pc_en_delay <= 1'b1;

      end
      else begin
        if (pc_en_delay == 1'b1) begin
          pc_en_delay <= 1'b0;
          if (pc_en == 1'b1) begin
            op_en <= 1'b1;
            mem_instr_en <= 1'b1;
            
            pc <= pc_csr;
            stall_flag <= 1'b0;
            pc_stall <= 32'b0;
          end
          else begin
            op_en <= 1'b0;
            mem_instr_en <= 1'b0;

            //pc_en_delay <= 1'b0;
            pc_stall <= pc_csr;
            stall_flag <= 1'b1;
            pc <= pc;
          end
        end
        else if (pc_en_delay == 1'b0) begin
          if (pc_en == 1'b1) begin
            op_en <= 1'b1;
            mem_instr_en <= 1'b1;
            if(stall_flag == 1'b1) begin
              pc <= pc_stall;
              stall_flag <= 1'b0;
              pc_stall <= 32'b0;
            end
            else begin
              pc <= pc_temp;
            end
          end
          else begin
            op_en <= 1'b0;
            pc <= pc;
            mem_instr_en <= 1'b0;
          end
        end
        else begin
          op_en <= 1'b0;
          pc <= pc;
          mem_instr_en <= 1'b0;
        end
        /*pc_en_delay <= 1'b0;
        
        if ((pc_en == 1'b1) || (pc_en_delay == 1'b1)) begin
          op_en <= 1'b1;
          mem_instr_en <= 1'b1;
          if(stall_flag == 1'b1) begin
            pc <= pc_stall;
            stall_flag <= 1'b0;
            pc_stall <= 32'b0;
          end
          else if (pc_en_delay) begin
            pc <= pc_csr;
            stall_flag <= 1'b0;
            pc_stall <= 32'b0;
          end
          else begin
            pc <= pc_temp;
          end
        end
        else begin
          op_en <= 1'b0;
          pc <= pc;
          mem_instr_en <= 1'b0;
        end*/
      end
    end
    else begin
      op_en <= 1'b1;
      pc <= 0;
      mem_instr_en <= 1'b1;
      pc_en_delay <= 1'b0;
    end
  end
 
endmodule
