module id_stage(
  input clk,
  input reset,
  
  input [0:0] op_en,
  //output reg [0:0] op_en_out,
  
  output reg [0:0] pc_en,

  output reg [6:0] next_stage_flag, //{exe_flag,mem_flag,wb_flag}

  // main parameter
  output reg [6:0] param_out, //{alu_src,alu_op,mem_to_reg}
  output reg [3:0] mem_width_out, //1111,0011,0001,0000
  // main parameter

  input [31:0] pc_in,
  output reg [31:0] pc_out,

  //main input
  input [31:0] instr,
  //main input

  //main output
  output [31:0] rs1_data_out,
  output [31:0] rs2_data_out,
  output reg [31:0] imm,
  output reg [3:0] instr30_funct,
  output reg [4:0] rd_addr,
  
  output [31:0] csr_rd_data_out,
  //main output

  output reg [0:0] trap, //trap
  output reg [0:0] flush, //flush->fence

  //reg_file
  output reg [0:0] rs1_en,
  output reg [0:0] rs2_en,

  output [4:0] rs1_addr,
  output [4:0] rs2_addr,

  input [31:0] rs1_data_in,
  input [31:0] rs2_data_in,
  //reg_file
  
  //csr_rd
  output reg [0:0] csr_rd_en,
  output reg [11:0] csr_rd_addr,
  output reg [11:0] csr_addr_out,


  input [31:0] csr_rd_data_in,
  //csr_rd
  
  //csr_statu_update
  //output reg [0:0] csr_su_en,
  //output reg [11:0] csr_su_addr,
  //output reg [31:0] csr_su_data
  //csr_statu_update

  output reg [0:0] ecall,
  output reg [0:0] ebreak,
  output reg [0:0] mret
  
); 
 
  logic [6:0] opcode;
  assign opcode = instr[6:0];

  assign rs1_addr = instr[19:15];
  assign rs2_addr = instr[24:20];

  assign rs1_data_out = rs1_data_in;
  assign rs2_data_out = rs2_data_in;
  
  assign csr_rd_addr = instr[31:20];
  assign csr_rd_data_out = csr_rd_data_in;


  logic [0:0] rd_en, alu_en, adder32_en, mem_rd_en, mem_wr_en, branch_en, alu_src, mem_to_reg, csr_wr_en; //fence??
  logic [3:0] alu_op;
  
  logic [0:0] load_unsigned;

  logic [31:0] imm_temp;
  
  logic [3:0] mem_width;

  logic [1:0] stage_counter;

  /*always_comb begin
    if (reset) begin
      if (opcode == 7'b1110011) begin
        if (instr[14:12] == 3'b000) begin
          if (instr[21] == 1'b0) begin
            csr_rd_addr = 12'h305; //mtvec for trap
          end
          else if (instr[21] == 1'b1) begin
            csr_rd_addr = 12'h341; //mpec for mret
          end
          else begin
            csr_rd_addr = 12'b0;
          end
        end
        else begin
          csr_rd_addr = instr[31:20];
        end
      end
      else begin
        csr_rd_addr = 12'b0;
      end
    end
    else begin
      csr_rd_addr = 12'b0;
    end
  end*/
  
  /*
  always_comb begin
    if (reset) begin
      if (opcode == 7'b1110011) begin
        if (instr[14:12] == 3'b000) begin
          if (instr[21] == 1'b0) begin
            if (instr[20] == 1'b1) begin
              csr_su_addr = 12'h342; //mcause for ebreak
              csr_su_data = 32'h00000003;
            end
            else if (instr[20] == 1'b0) begin
              csr_su_addr = 12'h342; //mcause for ecall
              csr_su_data = 32'h0000000b;
            end
            else begin
              csr_su_addr = 12'b0; 
              csr_su_data = 32'b0;
            end
          end
          else if (instr[21] == 1'b1) begin
            csr_su_addr = 12'b0; //mpec for mret
            csr_su_data = 32'b0;
          end
          else begin
            csr_su_addr = 12'b0;
            csr_su_data = 32'b0;
          end
        end
        else begin
          csr_su_addr = 12'b0;
          csr_su_data = 32'b0;
        end
      end
      else begin
        csr_su_addr = 12'b0;
        csr_su_data = 32'b0;
      end
    end
    else begin
      csr_su_addr = 12'b0;
      csr_su_data = 32'b0;
    end
  end */
  
  logic [11:0] instr_3120;
  assign instr_3120 = instr[31:20]; 
  
  always_comb begin
    if (reset) begin
      if ((opcode == 7'b1110011) && (instr[14:12] == 3'b000)) begin
        case(instr_3120)
          12'h000: begin
            ecall = 1'b1;
            ebreak = 1'b0;
            mret = 1'b0;
          end
          12'h001: begin
            ecall = 1'b0;
            ebreak = 1'b1;
            mret = 1'b0;
          end
          12'h302: begin
            ebreak = 1'b0;
            ecall = 1'b0;
            mret = 1'b1;
          end
          default: begin
            ebreak = 1'b0;
            ecall = 1'b0;
            mret = 1'b0;
          end
        endcase
      end
      else begin
        ebreak = 1'b0;
        ecall = 1'b0;
        mret = 1'b0;
      end
    end
    else begin
      ebreak = 1'b0;
      ecall = 1'b0;
      mret = 1'b0;
    end
  end

  /*always_comb begin
    if (reset) begin
      if (opcode == 7'b1110011) begin
        if (instr[14:12] == 3'b000) begin
          if (instr[21] == 1'b0) begin
            if (instr[20] == 1'b1) begin
              ebreak = 1'b1;
              ecall = 1'b0;
            end
            else if (instr[20] == 1'b0) begin
              ebreak = 1'b0;
              ecall = 1'b1;
            end
            else begin
              ebreak = 1'b0;
              ecall = 1'b0;
            end
          end
          else if (instr[21] == 1'b1) begin
            ebreak = 1'b0;
            ecall = 1'b0;
          end
          else begin
            ebreak = 1'b0;
            ecall = 1'b0;
          end
        end
        else begin
          ebreak = 1'b0;
          ecall = 1'b0;
        end
      end
      else begin
        ebreak = 1'b0;
        ecall = 1'b0;
      end
    end
    else begin
      ebreak = 1'b0;
      ecall = 1'b0;
    end
  end*/
  
  always_comb begin
    if (reset) begin
      case (opcode)
        7'b0110111: begin //lui
          imm_temp = {instr[31:12],12'b0};
        end
        7'b0010111: begin //auipc          
          imm_temp = {instr[31:12],12'b0};
        end
        7'b1101111: begin//jal          
          imm_temp = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
        end
        7'b1100111: begin //jalr          
          imm_temp = {{21{instr[31]}},instr[30:20]};
        end
        7'b1100011: begin //branch          
          imm_temp = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
        end
        7'b0000011: begin //load        
          imm_temp = {{21{instr[31]}},instr[30:20]};
        end
        7'b0100011: begin //save    
          imm_temp = {{21{instr[31]}},instr[30:25],instr[11:8],instr[7]};
        end
        7'b0010011: begin //opimm          
          imm_temp = (instr[13:12] == 2'b01) ? {27'b0,instr[24:20]} : {{21{instr[31]}},instr[30:20]};
        end
        7'b0110011: begin //op          
          imm_temp = 32'b0;
        end
        7'b0001111: begin //misc          
          imm_temp = 32'b0; //???
        end
        7'b1110011: begin //system          
          if (instr[14:12] != 3'b000) begin
            if (instr[14] == 1'b1) begin
              imm_temp = {27'b0,instr[19:15]};
            end
            else begin
              imm_temp = 32'b0;
            end
          end
          else begin
            imm_temp = 32'b0;
          end
        end
        default: begin
          imm_temp = 32'b0;
        end
      endcase
    end
    else begin
      imm_temp = 32'b0;
    end
  end

  always_comb begin
    if (reset) begin
      case (opcode)
        7'b0110111: begin //lui
          rs1_en = 1'b0;
          rs2_en = 1'b0;

          alu_en = 1'b0;
          adder32_en = 1'b1;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b0010111: begin //auipc          
          rs1_en = 1'b0;
          rs2_en = 1'b0;

          alu_en = 1'b0;
          adder32_en = 1'b1;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b1101111: begin//jal          
          rs1_en = 1'b0;
          rs2_en = 1'b0;

          alu_en = 1'b1;
          adder32_en = 1'b1;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b1;//

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b1100111: begin //jalr          
          rs1_en = 1'b1;
          rs2_en = 1'b0;

          alu_en = 1'b1;
          adder32_en = 1'b1;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b1;//

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b1100011: begin //branch          
          rs1_en = 1'b1;
          rs2_en = 1'b1;

          alu_en = 1'b1;
          adder32_en = 1'b1;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b1;

          rd_en = 1'b0;
          
          stage_counter = 2;
        end
        7'b0000011: begin //load        
          rs1_en = 1'b1;
          rs2_en = 1'b0;

          alu_en = 1'b1;
          adder32_en = 1'b0;

          mem_rd_en = 1'b1;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b0100011: begin //save    
          rs1_en = 1'b1;
          rs2_en = 1'b1;

          alu_en = 1'b1;
          adder32_en = 1'b0;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b1;
          branch_en = 1'b0;

          rd_en = 1'b0;
          
          stage_counter = 2;
        end
        7'b0010011: begin //opimm          
          rs1_en = 1'b1;
          rs2_en = 1'b0;

          alu_en = 1'b1;
          adder32_en = 1'b0;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b0110011: begin //op          
          rs1_en = 1'b1;
          rs2_en = 1'b1;

          alu_en = 1'b1;
          adder32_en = 1'b0;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b1;
          
          stage_counter = 3;
        end
        7'b0001111: begin //misc
          if (instr[14:12] == 3'b000) begin
          end
          else if (instr[14:12] == 3'b001) begin
          end
          else begin
          end
          rs1_en = 1'b0;
          rs2_en = 1'b0;

          alu_en = 1'b0;
          adder32_en = 1'b0;
          
          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b0;
          
          stage_counter = 0;
        end
        7'b1110011: begin //system 
          if (instr[14:12] != 3'b000) begin
            
            
            rs1_en = 1'b1;
            rs2_en = 1'b0;

            alu_en = 1'b1;
            adder32_en = 1'b0;

            mem_rd_en = 1'b0;
            mem_wr_en = 1'b0;
            branch_en = 1'b0;
            
            if ((instr[13] == 1'b0) && (instr[11:7] == 5'b0)) begin
              rd_en = 1'b0;
              stage_counter = 2;
            end
            else begin
              rd_en = 1'b1;
              stage_counter = 3;
            end

            //rd_en = 1'b1;

            //stage_counter = 3;            
          end
          else begin
            rs1_en = 1'b0;
            rs2_en = 1'b0;

            alu_en = 1'b0;
            adder32_en = 1'b0;

            mem_rd_en = 1'b0;
            mem_wr_en = 1'b0;
            branch_en = 1'b0;

            rd_en = 1'b0;

            stage_counter = 0;
          end
          /*else begin
            if (instr[21] == 1'b0) begin //trap
              rs1_en = 1'b0;
              rs2_en = 1'b0;

              alu_en = 1'b1;
              adder32_en = 1'b1;

              mem_rd_en = 1'b0;
              mem_wr_en = 1'b0;
              branch_en = 1'b1;

              rd_en = 1'b0;

              stage_counter = 2;
            end
            else begin //rest mret
              rs1_en = 1'b0;
              rs2_en = 1'b0;

              alu_en = 1'b0;
              adder32_en = 1'b1;

              mem_rd_en = 1'b0;
              mem_wr_en = 1'b0;
              branch_en = 1'b1;

              rd_en = 1'b0;

              stage_counter = 2;
            end
          end*/
        end
        default: begin
          rs1_en = 1'b0;
          rs2_en = 1'b0;

          alu_en = 1'b0;
          adder32_en = 1'b0;

          mem_rd_en = 1'b0;
          mem_wr_en = 1'b0;
          branch_en = 1'b0;

          rd_en = 1'b0;
          
          stage_counter = 0;
        end
      endcase
    end
    else begin
      rs1_en = 1'b0;
      rs2_en = 1'b0;

      alu_en = 1'b0;
      adder32_en = 1'b0;

      mem_rd_en = 1'b0;
      mem_wr_en = 1'b0;
      branch_en = 1'b0;

      rd_en = 1'b0;
      
      stage_counter = 0;
    end
  end
  
  always_comb begin
    if (reset) begin
      case (opcode)
        7'b0001111: begin
          if (instr[14:12] == 3'b000) begin
            flush = 1'b0;
          end
          else if (instr[14:12] == 3'b001) begin
            flush = 1'b1;
          end
          else begin
            flush = 1'b0;
          end
        end
        default: begin
          flush = 1'b0;
        end
      endcase
    end
    else begin
      flush = 1'b0;
    end
  end
  
  always_comb begin
    if (reset) begin
      case (opcode)
        7'b1110011: begin
          if (instr[14:12] != 3'b000) begin
            if ((instr[13] == 1'b0) && (instr[11:7] == 5'b0)) begin
              csr_rd_en = 1'b0;
              csr_wr_en = 1'b1;
            end
            else begin
              csr_rd_en = 1'b1;
              csr_wr_en = 1'b1;
            end
            
            if ((instr[13] == 1'b1) && (instr[19:15] == 5'b0)) begin
              csr_rd_en = 1'b1;
              csr_wr_en = 1'b0;
            end
            else begin
              csr_rd_en = 1'b1;
              csr_wr_en = 1'b1;
            end
            
            //csr_su_en = 1'b0;
          end
          /*else if (instr[14:12] == 3'b000) begin
            if (instr[21] == 1'b1) begin
              csr_rd_en = 1'b1; //mret
              csr_wr_en = 1'b0;
              //csr_su_en = 1'b0;
            end
            else if (instr[21] == 1'b0) begin
              //if (instr[20] == 1'b1) begin
              csr_rd_en = 1'b1; //trap
              csr_wr_en = 1'b1;
              //csr_su_en = 1'b1;
            end
            else begin
              csr_rd_en = 1'b0;
              csr_wr_en = 1'b0;
              //csr_su_en = 1'b0;
            end
          end*/
          else begin
            csr_rd_en = 1'b0;
            csr_wr_en = 1'b0;
            //csr_su_en = 1'b0;
          end
        end
        default: begin
          csr_rd_en = 1'b0;
          csr_wr_en = 1'b0;
          //csr_su_en = 1'b0;
        end
      endcase
    end
    else begin
      csr_rd_en = 1'b0; 
      csr_wr_en = 1'b0;
      //csr_su_en = 1'b0;
    end
  end
  
  ////
  // alu_op
  // Others: 000 
  // LUI:0001, AUIPC:0010, JAL:0011, JALR:0100, B:0101, L/S:0110, OP:0111, 
  // fence:11??, trap,mret:1000, CSR:1001

  always_comb begin
    if (reset) begin
      case (opcode)
        7'b0110111: begin //lui
          alu_src = 1'b1;
          alu_op = 4'b0001;

          mem_to_reg = 1'b0;
        end
        7'b0010111: begin //auipc          
          alu_src = 1'b1;
          alu_op = 4'b0010;

          mem_to_reg = 1'b0;
        end
        7'b1101111: begin//jal          
          alu_src = 1'b1;
          alu_op = 4'b0011;

          mem_to_reg = 1'b0;
        end
        7'b1100111: begin //jalr          
          alu_src = 1'b1;
          alu_op = 4'b0100;

          mem_to_reg = 1'b0;
        end
        7'b1100011: begin //branch          
          alu_src = 1'b0;
          alu_op = 4'b0101;

          mem_to_reg = 1'b0;
        end
        7'b0000011: begin //load        
          alu_src = 1'b1;
          alu_op = 4'b0110;

          mem_to_reg = 1'b1;
        end
        7'b0100011: begin //save    
          alu_src = 1'b1;
          alu_op = 4'b0110;

          mem_to_reg = 1'b0;
        end
        7'b0010011: begin //opimm          
          alu_src = 1'b1;
          alu_op = 4'b0111;

          mem_to_reg = 1'b0;
        end
        7'b0110011: begin //op          
          alu_src = 1'b0;
          alu_op = 4'b0111;

          mem_to_reg = 1'b0;
        end
        7'b0001111: begin //misc          
          alu_src = 1'b0;
          alu_op = 4'b0000;

          mem_to_reg = 1'b0;
        end
        7'b1110011: begin //system
          if (instr[14:12] != 3'b000) begin
            if (instr[14] == 1'b1) begin
              alu_src = 1'b1;
              alu_op = 4'b1001;
            end
            else begin
              alu_src = 1'b0;
              alu_op = 4'b1001;
            end
            
            mem_to_reg = 1'b0;           
          end
          else if (instr[14:12] == 3'b000) begin
            alu_src = 1'b0;
            alu_op = 4'b1000;
            
            mem_to_reg = 1'b0;
          end
          else begin
            alu_src = 1'b0;
            alu_op = 4'b0;

            mem_to_reg = 1'b0;
          end
        end
        default: begin
          alu_src = 1'b0;
          alu_op = 4'b0;

          mem_to_reg = 1'b0;
        end
      endcase
    end
    else begin
      alu_src = 1'b0;
      alu_op = 4'b0;

      mem_to_reg = 1'b0;
    end
  end
  
  always_comb begin
    if (reset) begin
      case (opcode)
        7'b0000011: begin //load
          if (instr[13:12] == 2'b00) begin
            mem_width = 4'b0001;
          end
          else if (instr[13:12] == 2'b01) begin
            mem_width = 4'b0011;
          end
          else if (instr[13:12] == 2'b10) begin
            mem_width = 4'b1111;
          end
          else begin
            mem_width = 4'b0000;
          end
          
          if (instr[14] == 1'b1) begin
            load_unsigned = 1'b1;
          end
          else begin
            load_unsigned = 1'b0;
          end
        end
        7'b0100011: begin //save    
          if (instr[13:12] == 2'b00) begin
            mem_width = 4'b0001;
          end
          else if (instr[13:12] == 2'b01) begin
            mem_width = 4'b0011;
          end
          else if (instr[13:12] == 2'b10) begin
            mem_width = 4'b1111;
          end
          else begin
            mem_width = 4'b0000;
          end
          
          load_unsigned = 1'b0;
        end
        default: begin
          mem_width = 4'b0;
          load_unsigned = 1'b0;
        end
      endcase
    end
    else begin
      mem_width = 4'b0;
      load_unsigned = 1'b0;
    end
  end

  //flag
  logic [1:0] exe_flag;
  assign exe_flag = {alu_en,adder32_en};

  logic [3:0] mem_flag;
  assign mem_flag = {csr_wr_en,mem_rd_en,mem_wr_en,branch_en};
  
  logic [0:0] wb_flag;
  assign wb_flag = {rd_en};

  //logic [6:0] next_stage_flag_temp;
  //assign next_stage_flag_temp = {exe_flag,mem_flag,wb_flag};

  //flag
  
  logic [1:0] counter;
  logic [0:0] counter_en;
  logic [1:0] target_counter;
  
  always_latch begin // change it to clock? reset to? and rest of them to fsm?
    if(reset) begin
      if (op_en) begin
        target_counter = stage_counter;
      end
    end
  end
  
  always_ff @(posedge clk) begin
    if(reset) begin
      if (op_en) begin
        if (counter == target_counter) begin
          pc_en <= 1'b1;
          counter_en <= 1'b0;
          counter <= 2'b0;
        end
        else begin
          pc_en <= 1'b0;
          counter_en <= 1'b1;
          counter <= counter + 1;
        end
      end
      else begin
        if (counter_en) begin
          if (counter == target_counter) begin
            pc_en <= 1'b1;
            counter_en <= 1'b0;
            counter <= 2'b0;
          end
          else begin
            pc_en <= 1'b0;
            counter <= counter + 1;
          end
        end
        else begin
          pc_en<= 1'b0;
        end
      end
    end
    else begin
      counter <= 2'b0;
      counter_en <= 1'b0;
      pc_en <= 1'b0;
    end
  end
  
  always_ff @(posedge clk) begin
    if(reset) begin
      if (opcode == 7'b1110011) begin
        if ((instr[31:7] == 25'b0) || (instr[31:7] == 25'h0002000)) begin
          trap <= 1'b1;
          // mret <= 1'b0;
        end 
        else if (instr[31:7] == {7'b0011000,5'b00010,13'b0}) begin
          trap <= 1'b0;
          // mret <= 1'b1;
        end
      end
      else begin
        trap <= 1'b0;
        // mret <= 1'b0;
      end
    end
    else begin
      trap <= 1'b0;
      // mret <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      pc_out <= pc_in;
      imm <= imm_temp;
      instr30_funct <= {instr[30],instr[14:12]};
      rd_addr <= instr[11:7];

      next_stage_flag <= {exe_flag,mem_flag,wb_flag};
      param_out <= {alu_src,alu_op,mem_to_reg,load_unsigned};
      
      mem_width_out <= mem_width;

      csr_addr_out <= instr[31:20];
      
      /*if (opcode == 7'b1110011) begin
        if (instr[14:12] == 3'b0) begin
          if (instr[21] == 1'b0) begin 
            csr_addr_out <= 12'h341;
          end
          else begin
            csr_addr_out <= 12'h0;
          end
        end
        else begin
          csr_addr_out <= instr[31:20];
        end
      end
      else begin
        csr_addr_out <= 12'b0;
      end*/
    end
    else begin
      pc_out <= 32'b0;
      imm <= 32'b0;
      instr30_funct <= 4'b0;
      rd_addr <= 5'b0;

      next_stage_flag <= 7'b0;
      param_out <= 7'b0;
      
      mem_width_out <= 4'b0;

      csr_addr_out <= 12'b0;
    end
  end

endmodule // control_unit

