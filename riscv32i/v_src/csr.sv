module cs_reg(
  input clk,
  input reset,
  input csr_rd_en,
  input csr_wr_en,
  input [11:0] csr_rd_addr,
  input [11:0] csr_wr_addr,
  input [31:0] csr_wr_data,
  output reg [31:0] csr_rd_data,
  
  output reg [0:0] csr_delay,
  input [31:0] pc,
  
  input [31:0] pc_addr_in,
  input [31:0] mem_addr_in,
  
  input [0:0] ecall,
  input [0:0] ebreak,
  input [0:0] mret,
  input [0:0] i_misalign,
  input [0:0] l_misalign,
  input [0:0] s_misalign,
  
  output reg [31:0] pc_csr
);

  reg [31:0] csrm[4095:0];
  
  integer index;
  always_comb begin
    if (reset) begin
      if ( {i_misalign,l_misalign,s_misalign,ebreak,ecall,mret} != 6'b0) begin
        csr_delay = 1'b1;
      end
      else begin
        csr_delay = 1'b0;
      end
    end
    else begin
      csr_delay = 1'b0;
    end
  end
            
  always @(posedge clk) begin
    if (reset) begin   
      if (ecall) begin 
        csrm[12'h341] <= pc;
        csrm[12'h342] <= 32'h0000000b;
        pc_csr <= csrm[12'h305];
      end
      else if (ebreak) begin 
        csrm[12'h341] <= pc;
        csrm[12'h342] <= 32'h00000003;
        pc_csr <= csrm[12'h305];
      end
      else if (i_misalign) begin
        csrm[12'h341] <= pc; //mepc
        csrm[12'h342] <= 32'h00000000;
        csrm[12'h343] <= pc_addr_in; //mtval
        pc_csr <= csrm[12'h305];
      end
      else if (l_misalign) begin
        csrm[12'h341] <= pc; //mepc
        csrm[12'h342] <= 32'h00000004;
        csrm[12'h343] <= mem_addr_in; //mtval
        pc_csr <= csrm[12'h305];
      end
      else if (s_misalign) begin
        csrm[12'h341] <= pc; //mepc
        csrm[12'h342] <= 32'h00000006;
        csrm[12'h343] <= mem_addr_in; //mtval
        pc_csr <= csrm[12'h305];
      end
      else if (mret) begin 
        pc_csr <= csrm[12'h341];
      end
      else begin
        pc_csr <= 32'b0;
      end
    end
    else begin
      pc_csr <= 32'b0;
    end
  end
  
  always @(posedge clk) begin
    if (reset) begin
      if (csr_wr_en) begin 
        csrm[csr_wr_addr] <= csr_wr_data;
      end
      
      if (csr_rd_en) begin
        csr_rd_data <= csrm[csr_rd_addr];
      end
    end
    else begin
      for (index=0; index<4096; index=index+1) begin
        csrm[index] = 32'b0;
      end
    end
  end
  
endmodule