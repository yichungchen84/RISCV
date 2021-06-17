module riscv_core#(
  parameter XLEN = 32,
  IRQ = 0)(
  input clk,
  input reset,
  
  output [31:0] pc,
  output [0:0] mem_instr_en,
  input [31:0] instr,
  
  output [0:0] trap,
  output [0:0] flush,




  // CSR
  output [0:0] csr_rd_en,
  output [0:0] csr_wr_en, 
  output [11:0]csr_rd_addr,
  output [11:0]csr_wr_addr,
  output [31:0] csr_wr_data,
  input [31:0]csr_rd_data,
  
  input [0:0] csr_delay,
  
  output [31:0] pc_addr_in,
  
  output [0:0] ecall,
  output [0:0] ebreak,
  output [0:0] mret,
  output [0:0] i_misalign,
  output [0:0] l_misalign,
  output [0:0] s_misalign,

  
  input [31:0] pc_csr,
  
  // DATA MEMORY
  output [0:0] mem_rd_en,
  output [0:0] mem_wr_en,
  output [31:0] mem_addr,
  output [31:0] mem_wr_data,
  output [3:0] mem_width,
  input [31:0] mem_rd_data
  
);

  logic [0:0] pc_en, pc_en_exe, pc_en_mem, pc_en_wb;
  logic [0:0] pc_src;
  //logic [31:0] pc_addr_in;

  logic [31:0] pc_id, pc_if_im;

  logic [31:0] instr_if;


  logic [31:0] pc_exe;

  logic [6:0] stage_flag_exe;
  logic [6:0] param_exe;
  logic [3:0] mem_width_exe;
  logic [31:0] rs1_data_exe, rs2_data_exe, imm;
  logic [3:0] instr30_funct;
  logic [4:0] rd_addr_exe;

  logic [0:0] rs1_en, rs2_en;
  logic [4:0] rs1_addr, rs2_addr;
  logic [31:0] rs1_data, rs2_data;
  
  logic [3:0] stage_flag_mem;
  logic [1:0] param_mem;
  logic [31:0] adder32_result, alu_result;
  logic [0:0] zero;

  logic [31:0] rs2_data_to_mem;
  logic [4:0] rd_addr_mem;

  logic [0:0] stage_flag_wb;
  logic [1:0] param_wb;
  logic [3:0] mem_width_wb;

 

  logic [31:0] alu_mem_data;
  logic [4:0] rd_addr_wb;

  logic [31:0] mem_rd_data_mem;

  logic [0:0] rd_en;

  logic [4:0] rd_addr;

  logic [31:0] rd_data;
  
  logic [0:0] op_en_if_im, op_en_id, op_en_exe, op_en_mem, op_en_wb;
  
  logic [31:0] csr_rd_data_out, csr_rd_data_exe;
  logic [11:0] csr_addr_exe;
 

  
////////////////////
//	IF
////////////////////
  if_stage if_stage(
    .clk(clk), 
    .reset(reset),
    .op_en(op_en_if_im),
    .pc(pc),
    .pc_en(pc_en), //pc advance
    //.trap(trap),
    //.mret(mret),
    .csr_delay(csr_delay),
    
    .pc_src(pc_src), //pc source
    .pc_addr_in(pc_addr_in),
    .mem_instr_en(mem_instr_en),
    
    .pc_csr(pc_csr)
  );
////////////////////
//	IF
////////////////////

////////////////////
//	IF_instr
////////////////////
  if_im_stage if_im_stage(
    .clk(clk), 
    .reset(reset),
    .op_en_in(op_en_if_im),
    .op_en_out(op_en_id),
    .pc_in(pc),
    .pc_out(pc_id),
    .instr_in(instr),
    .instr_out(instr_if)
  );
////////////////////
//	IF_instr
////////////////////

////////////////////
//	ID
////////////////////
  id_stage id_stage(
    .clk(clk),
    .reset(reset),
    .op_en(op_en_id),
    
    .pc_en(pc_en),
  
    .next_stage_flag(stage_flag_exe), //{exe_flag,mem_flag,wb_flag}
  
    // main parameter
    .param_out(param_exe), //{alu_src,alu_op,mem_to_reg}
    .mem_width_out(mem_width_exe),
    // main parameter
  
    .pc_in(pc_id),
    .pc_out(pc_exe),
  
    //main input
    .instr(instr_if),
    //main input
  
    //main output
    .rs1_data_out(rs1_data_exe),
    .rs2_data_out(rs2_data_exe),
    .imm(imm),
    .instr30_funct(instr30_funct),
    .rd_addr(rd_addr_exe),
    .csr_rd_data_out(csr_rd_data_exe),
    //main output
  
    .trap(trap), //trap
    .flush(flush), //trap

  
    //reg_file
    .rs1_en(rs1_en),
    .rs2_en(rs2_en),
  
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
  
    .rs1_data_in(rs1_data),
    .rs2_data_in(rs2_data),
    //reg_file
    
    //csr
    .csr_rd_en(csr_rd_en),
    .csr_rd_addr(csr_rd_addr),
    .csr_addr_out(csr_addr_exe),
    .csr_rd_data_in(csr_rd_data),
    
    .ecall(ecall),
    .ebreak(ebreak),
    .mret(mret)

    //csr
  
    
  ); 
////////////////////
//	ID
////////////////////


////////////////////
//	EXE
////////////////////
  exe_stage exe_stage(
    .clk(clk),
    .reset(reset),
    //.pc_en(pc_en),
    //.op_en_out(op_en_mem),
  
    .current_stage_flag(stage_flag_exe), //{exe_flag,mem_flag,wb_flag}
    .next_stage_flag(stage_flag_mem), //{mem_flag,wb_flag}
    //flag alu_en,adder32_en,mem_rd_en,mem_wr_en,branch_en,rd_en
  
    // main parameter
    .param_in(param_exe), //{alu_src,alu_op,mem_to_reg}
    .param_out(param_mem), //{mem_to_reg}
    // param: alu_src,alu_op,mem_to_reg
    // main parameter
    .mem_width_in(mem_width_exe),
    .mem_width(mem_width),

    .csr_addr_in(csr_addr_exe),
    .csr_addr_out(csr_wr_addr),
    
    .pc_in(pc_exe),
  
    //main input
    .rs1_data(rs1_data_exe),
    .rs2_data(rs2_data_exe),
    .imm(imm),
    .instr30_funct(instr30_funct),
    .rd_addr_in(rd_addr_exe),
    .csr_rd_data(csr_rd_data_exe),
    //main input
  
    //main output
    .adder32_out(adder32_result),
    .zero(zero),
    .alu_out(alu_result),
    .mem_wr_data(mem_wr_data),
    .rd_addr_out(rd_addr_mem),
    .csr_wr_data(csr_wr_data),
    .csr_wr_en(csr_wr_en)
    //main output

  );
////////////////////
//	EXE
////////////////////


////////////////////
//	MEM
////////////////////
  mem_stage mem_stage(
    .clk(clk),
    .reset(reset),
  
    .current_stage_flag(stage_flag_mem), //{mem_flag,wb_flag}
    .next_stage_flag(stage_flag_wb), //{wb_flag}
    //flag: mem_rd_en,mem_wr_en,branch_en,rd_en
  
    // main parameter
    .param_in(param_mem), //{mem_to_reg}
    .param_out(param_wb), //{mem_to_reg}
    //param: mem_to_reg
    // main parameter
    .mem_width_in(mem_width),
    .mem_width_out(mem_width_wb),
  
    //main input
    .adder32_in(adder32_result),
    .zero(zero),
    .mem_addr_in(alu_result),
    .rd_addr_in(rd_addr_mem),
    //main input
  
    //main output
    .adder32_out(pc_addr_in),
    .pc_src(pc_src),
    .mem_rd_data_out(mem_rd_data_mem),
    .alu_mem_data_out(alu_mem_data),
    .rd_addr_out(rd_addr_wb),
    .mem_rd_en(mem_rd_en),
    .mem_wr_en(mem_wr_en),
    //main output
  
    .mem_addr_out(mem_addr),
    .mem_rd_data_in(mem_rd_data),
    
    .i_misalign(i_misalign),
    .l_misalign(l_misalign),
    .s_misalign(s_misalign)

  );
////////////////////
//	MEM
////////////////////

////////////////////
//	WB
////////////////////
  wb_stage wb_stage(
    .clk(clk),
    .reset(reset),
  
    .current_stage_flag(stage_flag_wb),
    //flag: rd_en
  
    .param_in(param_wb), //{mem_to_reg}
    //param: mem_to_reg
    .mem_width_in(mem_width_wb),
  
    //main input
    .alu_mem_data(alu_mem_data),
    .mem_rd_data(mem_rd_data_mem),
    .rd_addr_in(rd_addr_wb),
    //main input

    .rd_en_out(rd_en),
    .rd_addr_out(rd_addr),
    .rd_data_out(rd_data)

  );

  register_file reg_fetch(
    .clk(clk),		
    .reset(reset),  
    .rd_en(rd_en),
    .rs1_en(rs1_en),
    .rs2_en(rs2_en),                
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
  );
////////////////////
//	WB
////////////////////
  
endmodule
