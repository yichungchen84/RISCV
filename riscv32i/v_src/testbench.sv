// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

// `timescale 1 ns / 1 ps

module top #(
    // parameter AXI_TEST = 0,
    // parameter VERBOSE = 0
)
(
    input clk,
    input reset,

    output flush,

    output reg [31:0] mem_addr,
    output reg [7:0] dump_data_0,
    output reg [7:0] dump_data_1,
    output reg [7:0] dump_data_2,
    output reg [7:0] dump_data_3

);
  logic [0:0] trap;
  // logic [0:0] flush;
  logic [31:0] pc;
  // logic [31:0] mem_addr;
  logic [31:0] mem_wr_data;
  logic [0:0] mem_instr_en;
  logic [0:0] mem_rd_en;
  logic [0:0] mem_wr_en;
  logic [31:0] instr;
  logic [31:0] instr_next;
  logic [31:0] mem_rd_data;
  logic [3:0] mem_width;

  riscv_wrapper uut (
    .clk(clk),
    .reset(reset),
    
    .trap(trap),
    .flush(flush),
    
    .instr(instr),    
    .pc(pc),
    .mem_instr_en(mem_instr_en),

    .mem_rd_data(mem_rd_data),
    .mem_addr(mem_addr),
    .mem_wr_data(mem_wr_data),
    .mem_rd_en(mem_rd_en),
    .mem_wr_en(mem_wr_en),
    .mem_width(mem_width)
  );
  

    // input clk,
    // input reset,
  
  // output trap,
  
  // output [31:0] pc,
  // input [31:0] instr,

  // input [31:0]m_addr,
  // input [31:0]m_wr_dat,
  // input rd_en,
  // input wr_en,
  // output [31:0]m_rd_dat

  reg [31:0] memory_temp [0:(64*1024)/4-1];
  reg [7:0] memory [0:(64*1024)-1];

  reg [1023:0] memdata_file;
  integer index;

  initial begin
    if (!$value$plusargs("memdata_file=%s", memdata_file)) begin
      memdata_file = "foo.hex";
    end
    $readmemh(memdata_file, memory_temp);
    
    for (index=0; index<((32*1024)/4); index=index+1) begin
      memory[(index*4)+0] = memory_temp[index][7:0];
      memory[(index*4)+1] = memory_temp[index][15:8];
      memory[(index*4)+2] = memory_temp[index][23:16];
      memory[(index*4)+3] = memory_temp[index][31:24];
    end

    $display("====== data: loaded ======");
  end

  

    // always @(mem_addr) begin
    // 	mem_ready = 0;
    // 	if (mem_valid && !mem_ready) begin
    // 		// if (mem_addr < (1*1024/4) ) begin
    // 			mem_ready = 1;
    // 			mem_rdata = memory[mem_addr >> 2];
    // 			if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] = mem_wdata[ 7: 0];
    // 			if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] = mem_wdata[15: 8];
    // 			if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] = mem_wdata[23:16];
    // 			if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] = mem_wdata[31:24];
    // 		// end
    // 		/* add memory-mapped IO here */
    // 	end
    // end
  
  // always_comb begin
  //   m_rd_dat =  (reset & (rd_en == 1 && wr_en == 0)) ? memory [m_addr >> 2] : 32'h0;
  //     // rd2 =  (reset & (rs2!=5'b0)) ? registry[rs2] : 32'h0;
  //   // uvm_config_db #(reg[31:0])::set(uvm_root::get(),"*","rd1", rd1);
  // end
  

  // always @(m_addr, pc) begin
  // csr_wr_en & reset
  
  always @(posedge clk) begin
    if (reset) begin
      if (mem_instr_en) begin
        instr[7:0] <= memory [pc];
        instr[15:8] <= memory [pc+1];
        instr[23:16] <= memory [pc+2];
        instr[31:24] <= memory [pc+3];
        // $display("mem_c = %h", instr);
      end
      else begin
        instr <= 32'b0;
        // instr <= instr;
        // $display("mem_s = %h", instr);
      end
    end
    else begin
      instr <= 32'b0;
    end
  end

  always_comb begin
    if (mem_width == 4'b0001) begin
      dump_data_0 = mem_wr_data[7:0];
      dump_data_1 = memory[mem_addr+1];
      dump_data_2 = memory[mem_addr+2];
      dump_data_3 = memory[mem_addr+3];
    end
    else if (mem_width == 4'b0011) begin
      dump_data_0 = mem_wr_data[7:0];
      dump_data_1 = mem_wr_data[15:8];
      dump_data_2 = memory[mem_addr+2];
      dump_data_3 = memory[mem_addr+3];
    end
    else begin
      dump_data_0 = mem_wr_data[7:0];
      dump_data_1 = mem_wr_data[15:8];
      dump_data_2 = mem_wr_data[23:16];
      dump_data_3 = mem_wr_data[31:24];
    end
  end


  always @(posedge clk) begin
    if (reset) begin
      if (mem_rd_en & ~mem_wr_en) begin
        mem_rd_data[7:0] <= memory [mem_addr];
        mem_rd_data[15:8] <= memory [mem_addr+1];
        mem_rd_data[23:16] <= memory [mem_addr+2];
        mem_rd_data[31:24] <= memory [mem_addr+3];
      end
      else if (~mem_rd_en & mem_wr_en) begin
        if (mem_width == 4'b0001) begin
          memory [mem_addr] <= mem_wr_data[7:0];
          // dump_data = {memory[mem_addr+3],memory[mem_addr+2],memory[mem_addr+1],mem_wr_data[7:0]};
        end
        else if (mem_width == 4'b0011) begin
          memory [mem_addr] <= mem_wr_data[7:0];
          memory [mem_addr+1] <= mem_wr_data[15:8];
          // dump_data = {memory[mem_addr+3],memory[mem_addr+2],mem_wr_data[15:0]};
        end
        else begin
          memory [mem_addr] <= mem_wr_data[7:0];
          memory [mem_addr+1] <= mem_wr_data[15:8];
          memory [mem_addr+2] <= mem_wr_data[23:16];
          memory [mem_addr+3] <= mem_wr_data[31:24];
          // dump_data = {mem_wr_data[31:0]};
        end
      end
      else begin
        mem_rd_data <= 32'b0;
        // memory [mem_addr >> 2] <= mem_wr_data;
      end
    end
    else begin
      mem_rd_data <= 32'b0;
      // memory [mem_addr >> 2] <= mem_wr_data;
    end
    // mem_ready = 0;
  end
        // if (rd_en && !mem_ready) begin
        // 	// if (mem_addr < (1*1024/4) ) begin
        // 		mem_ready = 1;
        // 		mem_rdata = memory[mem_addr >> 2];
        // 		if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] = mem_wdata[ 7: 0];
        // 		if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] = mem_wdata[15: 8];
        // 		if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] = mem_wdata[23:16];
        // 		if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] = mem_wdata[31:24];
        // 	// end
        // 	/* add memory-mapped IO here */
        // end



  // always @(posedge clk) begin
  //   if (trap == 1'b1) begin
  //       // $finish;
  //   end
  // end

  // always @(posedge clk) begin
  //   if (instr == 32'hc0001073) begin
  //     $finish;
  //   end
  // end

  always_comb begin
    if (instr == 32'h00000073) begin
      instr_next[7:0] = memory [pc+4];
      instr_next[15:8] = memory [pc+5];
      instr_next[23:16] = memory [pc+6];
      instr_next[31:24] = memory [pc+7];
      if (instr_next == 32'hc0001073) begin
        $finish;
      end
    end
  end


    // always @(posedge clk) begin
    // 	if (mem_valid && mem_ready) begin
    // 		if (mem_instr)
    // 			$display("ifetch 0x%h: 0x%h", mem_addr, mem_rdata);
    // 		else if (mem_wstrb)
    // 			$display("write  0x%08x: 0x%08x (wstrb=%b)", mem_addr, mem_wdata, mem_wstrb);
    // 		else
    // 			$display("read   0x%08x: 0x%08x", mem_addr, mem_rdata);
    // 	end
    // end

  always @(posedge clk) begin
    if (!(mem_rd_en || mem_wr_en)) begin
        if ((pc >>2) >= 32'h00004000 ) begin
          $finish;
        end
    end
  end
  

  //ycc


endmodule
