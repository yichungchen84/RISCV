module riscv_wrapper(
  input clk,
  input reset,
  
  output [0:0] trap,
  output [0:0] flush,

  input [31:0] instr,  
  output [31:0] pc,
  output [0:0] mem_instr_en,

  input [31:0] mem_rd_data,
  output [31:0] mem_addr,
  output [31:0] mem_wr_data,
  output reg [0:0] mem_rd_en,
  output reg [0:0] mem_wr_en,
  output [3:0] mem_width
);
  
  logic [31:0] csr_wr_data, csr_rd_data;
  logic [11:0] csr_rd_addr, csr_wr_addr;

  logic [0:0] csr_rd_en, csr_wr_en;
  logic [0:0] ebreak, ecall, mret, i_misalign, l_misalign, s_misalign;
  logic [0:0] csr_delay;
  
  logic [31:0] pc_csr;
  logic [31:0] pc_addr_in;

  
  riscv_core core(
    .clk(clk),
    .reset(reset),

    .pc(pc),
    .mem_instr_en(mem_instr_en),
    .instr(instr),
    
    .trap(trap),
    .flush(flush),

    .csr_rd_en(csr_rd_en),
    .csr_wr_en(csr_wr_en),
    .csr_rd_addr(csr_rd_addr),
    .csr_wr_addr(csr_wr_addr),
    .csr_wr_data(csr_wr_data),
    .csr_rd_data(csr_rd_data),
    
    .csr_delay(csr_delay),
    .pc_addr_in(pc_addr_in),
    .ecall(ecall),
    .ebreak(ebreak),
    .mret(mret),
    .i_misalign(i_misalign),
    .l_misalign(l_misalign),
    .s_misalign(s_misalign),
    .pc_csr(pc_csr),
    
    .mem_rd_en(mem_rd_en),
    .mem_wr_en(mem_wr_en),
    .mem_addr(mem_addr),
    .mem_wr_data(mem_wr_data),
    .mem_width(mem_width),
    .mem_rd_data(mem_rd_data)
  );
    
  cs_reg csre(
    .clk(clk),
    .reset(reset),       
    .csr_rd_en(csr_rd_en),
    .csr_wr_en(csr_wr_en),
    .csr_rd_addr(csr_rd_addr),
    .csr_wr_addr(csr_wr_addr),
    .csr_wr_data(csr_wr_data),
    .csr_rd_data(csr_rd_data),
    
    .csr_delay(csr_delay),
    .pc(pc),
    
    .pc_addr_in(pc_addr_in),
    .mem_addr_in(mem_addr),
    
    .ecall(ecall),
    .ebreak(ebreak),
    .mret(mret),
    .i_misalign(i_misalign),
    .l_misalign(l_misalign),
    .s_misalign(s_misalign),

    
    .pc_csr(pc_csr)
    
    
  );
  
endmodule