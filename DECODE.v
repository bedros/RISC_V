`define LOAD_code 	7'b0000011
`define OPIMM_code 	7'b0010011
`define AUIPC_code 	7'b0010111
`define STORE_code 	7'b0100011
`define OP_code 		7'b0110011
`define LUI_code 		7'b0110111
`define BRANCH_code 	7'b1100011
`define JALR_code 	7'b1100111
`define JAL_code 		7'b1101111
`define SYSTEM_code 	7'b1110011
`define MISCMEM_code 7'b0001111


module DECODE(
  input run_en,
  input clk				  ,
  input reset			  ,
  input flush			  ,
  input [31:0]ir       ,
  input ir_already     ,
  input [31:0]pc       ,
  output reg [4:0]dec_rs1_reg  ,
  output reg [4:0]dec_rs2_reg  ,
  output reg [4:0]dec_rd_reg   ,
  output reg [31:0]dec_imm_reg ,
  output reg dec_rs1en_reg     ,
  output reg dec_rs2en_reg     ,
  output reg dec_rden_reg      ,
  output reg dec_immen_reg     ,
  output reg dec_pcen_reg		 ,
  output reg [2:0]funct3_reg   ,
  output reg [6:0]funct7_reg   ,

  output reg riscv_LOAD_reg    ,
  output reg riscv_OPIMM_reg   ,
  output reg riscv_AUIPC_reg   ,
  output reg riscv_STORE_reg   ,
  output reg riscv_OP_reg      ,
  output reg riscv_LUI_reg     ,
  output reg riscv_BRANCH_reg  ,
  output reg riscv_JALR_reg    ,
  output reg riscv_JAL_reg     ,
  output reg riscv_SYSTEM_reg  ,
  output reg riscv_MISCMEM_reg ,
  output reg [31:0]pc_reg	,	 

  input ACCESS_data_conflict
);

wire [6:0]opcode;
wire [4:0]rd;
wire [4:0]rs1;
wire [4:0]rs2;

wire [31:0] dec_imm;

wire [31:0]inst;
wire imm_en;

wire rs1_en;
wire rs2_en;
wire rd_en;
wire pc_en;

wire dec_rs1en;
wire dec_rs2en;
wire dec_rden;
wire dec_immen;
wire dec_pcen;

wire [4:0]dec_rs1;
wire [4:0]dec_rs2;
wire [4:0]dec_rd;

wire [2:0]funct3;
wire [6:0]funct7;

wire riscv_LOAD;
wire riscv_OPIMM;
wire riscv_AUIPC;
wire riscv_STORE;
wire riscv_OP;
wire riscv_LUI;
wire riscv_BRANCH;
wire riscv_JALR;
wire riscv_JAL;
wire riscv_SYSTEM;
wire riscv_MISCMEM;


//指令结构
assign opcode = (ir_already)?ir[6:0]:7'b0000000;
assign rd     = (ir_already)?ir[11:7]:5'bzzzzz;
assign funct3 = (ir_already)?ir[14:12]:3'bzzz;
assign rs1    = (ir_already)?ir[19:15]:5'bzzzzz;
assign rs2    = (ir_already)?ir[24:20]:5'bzzzzz;
assign funct7 = (ir_already)?ir[31:25]:7'bzzzzzzz;

//指令译码
assign riscv_LOAD    = (opcode  == `LOAD_code)?1'b1:1'b0;
assign riscv_OPIMM   = (opcode  == `OPIMM_code)?1'b1:1'b0;
assign riscv_AUIPC   = (opcode  == `AUIPC_code)?1'b1:1'b0;
assign riscv_STORE   = (opcode  == `STORE_code)?1'b1:1'b0;
assign riscv_OP      = (opcode  == `OP_code)?1'b1:1'b0;
assign riscv_LUI     = (opcode  == `LUI_code)?1'b1:1'b0;
assign riscv_BRANCH  = (opcode  == `BRANCH_code)?1'b1:1'b0;
assign riscv_JALR    = ((opcode == `JALR_code)&&(funct3 == 3'b000))?1'b1:1'b0;
assign riscv_JAL     = (opcode  == `JAL_code)?1'b1:1'b0;
assign riscv_SYSTEM  = (opcode  == `SYSTEM_code)?1'b1:1'b0;
assign riscv_MISCMEM = (opcode  == `MISCMEM_code)?1'b1:1'b0;

//立即数拼接
wire [31:0]imm_i = {{21{inst[31]}},inst[30:20]};
wire [31:0]imm_s = {{21{inst[31]}},inst[30:25],inst[11:7]};
wire [31:0]imm_b = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
wire [31:0]imm_u = {inst[31:12],{12{1'b0}}};
wire [31:0]imm_j = {{12{inst[31]}},inst[19:12],inst[20],inst[30:25],inst[24:21],1'b0};
wire imm_i_en    = riscv_JALR|riscv_LOAD|riscv_OPIMM|riscv_SYSTEM;
wire imm_s_en    = riscv_STORE;
wire imm_b_en    = riscv_BRANCH;
wire imm_u_en    = riscv_LUI|riscv_AUIPC;
wire imm_j_en    = riscv_JAL;

//立即数选择
assign dec_imm = (imm_i & {32{imm_i_en}})
|(imm_s & {32{imm_s_en}})
|(imm_b & {32{imm_b_en}})
|(imm_u & {32{imm_u_en}})
|(imm_j & {32{imm_j_en}});

//立即数使能
assign imm_en    = riscv_LUI|riscv_AUIPC|riscv_JALR|riscv_JAL|riscv_BRANCH|riscv_OPIMM|riscv_STORE|riscv_LOAD|riscv_SYSTEM;
assign inst      = (imm_en)?ir:32'h00000000;

//寄存器使能
assign rs1_en    = riscv_JALR|riscv_BRANCH|riscv_LOAD|riscv_STORE|riscv_OP|riscv_OPIMM;
assign rs2_en    = riscv_BRANCH|riscv_STORE|riscv_OP;
assign rd_en     = riscv_LUI|riscv_AUIPC|riscv_JALR|riscv_JAL|riscv_LOAD|riscv_OP|riscv_OPIMM;
assign pc_en     = riscv_JAL|riscv_BRANCH|riscv_AUIPC;//对于跳转指令，需要pc的值参与计算
assign dec_rs1   = (rs1_en)?rs1:5'bzzzzz;
assign dec_rs2   = (rs2_en)?rs2:5'bzzzzz;
assign dec_rd    = (rd_en)?rd:5'bzzzzz;

//连接到外部信号
assign dec_rs1en = rs1_en;
assign dec_rs2en = rs2_en;
assign dec_rden  = rd_en;
assign dec_immen = imm_en;
assign dec_pcen = pc_en;

always@(posedge clk,negedge reset)begin
if(!reset)begin
	dec_rs1_reg	 	<= 5'b00000;
	dec_rs2_reg	 	<= 5'b00000 ;
	dec_rd_reg	 	<= 5'b00000;
	dec_imm_reg 	<= 1'b0;
	dec_rs1en_reg  <= 1'b0;
	dec_rs2en_reg  <= 1'b0;
	dec_rden_reg 	<= 1'b0;
	dec_immen_reg	<= 1'b0;
	dec_pcen_reg	<= 1'b0;
	funct3_reg 		<= 3'b000;
	funct7_reg 		<= 7'b0000000;

	riscv_LOAD_reg		<= 1'b0;
	riscv_OPIMM_reg 	<= 1'b0;
	riscv_AUIPC_reg 	<= 1'b0;
	riscv_STORE_reg	<= 1'b0;
	riscv_OP_reg 		<= 1'b0;
	riscv_LUI_reg 		<= 1'b0;
	riscv_BRANCH_reg 	<= 1'b0;
	riscv_JALR_reg 	<= 1'b0;
	riscv_JAL_reg 		<= 1'b0;
	riscv_SYSTEM_reg 	<= 1'b0;
	riscv_MISCMEM_reg <= 1'b0;

end 
else begin
if(ACCESS_data_conflict == 1'b1)begin
riscv_LOAD_reg		<= 1'b0;
riscv_STORE_reg	<= 1'b0;
dec_rs1_reg	 	<= 5'b00000;
dec_rs2_reg	 	<= 5'b00000 ;
dec_rd_reg	 	<= 5'b00000;
dec_imm_reg 	<= 1'b0;
dec_rs1en_reg  <= 1'b0;
dec_rs2en_reg  <= 1'b0;
dec_rden_reg 	<= 1'b0;
dec_immen_reg	<= 1'b0;
dec_pcen_reg	<= 1'b0;
funct3_reg 		<= 3'b000;
funct7_reg 		<= 7'b0000000;

end
else begin
if(run_en == 1'b1)begin
	if(ir_already)begin
		if(flush == 1'b1) begin
			dec_rs1_reg	 	<= 5'b00000;
			dec_rs2_reg	 	<= 5'b00000 ;
			dec_rd_reg	 	<= 5'b00000;
			dec_imm_reg 	<= 1'b0;
			dec_rs1en_reg  <= 1'b0;
			dec_rs2en_reg  <= 1'b0;
			dec_rden_reg 	<= 1'b0;
			dec_immen_reg	<= 1'b0;
			dec_pcen_reg	<= 1'b0;
			funct3_reg 		<= 3'b000;
			funct7_reg 		<= 7'b0000000;

			riscv_LOAD_reg		<= 1'b0;
			riscv_OPIMM_reg 	<= 1'b0;
			riscv_AUIPC_reg 	<= 1'b0;
			riscv_STORE_reg	<= 1'b0;
			riscv_OP_reg 		<= 1'b0;
			riscv_LUI_reg 		<= 1'b0;
			riscv_BRANCH_reg 	<= 1'b0;
			riscv_JALR_reg 	<= 1'b0;
			riscv_JAL_reg 		<= 1'b0;
			riscv_SYSTEM_reg 	<= 1'b0;
			riscv_MISCMEM_reg <= 1'b0;
		end 
		else begin
			dec_rs1_reg	 	<= dec_rs1;
			dec_rs2_reg	 	<= dec_rs2 ;
			dec_rd_reg	 	<= dec_rd;
			dec_imm_reg 	<= dec_imm;
			dec_rs1en_reg  <= dec_rs1en;
			dec_rs2en_reg  <= dec_rs2en;
			dec_rden_reg 	<= dec_rden;
			dec_immen_reg	<= dec_immen;
			dec_pcen_reg	<= dec_pcen;
			funct3_reg 		<= funct3;
			funct7_reg 		<= funct7;

			riscv_LOAD_reg		<= riscv_LOAD;
			riscv_OPIMM_reg 	<= riscv_OPIMM;
			riscv_AUIPC_reg 	<= riscv_AUIPC;
			riscv_STORE_reg	<= riscv_STORE;
			riscv_OP_reg 		<= riscv_OP;
			riscv_LUI_reg 		<= riscv_LUI;
			riscv_BRANCH_reg 	<= riscv_BRANCH;
			riscv_JALR_reg 	<= riscv_JALR;
			riscv_JAL_reg 		<= riscv_JAL;
			riscv_SYSTEM_reg 	<= riscv_SYSTEM;
			riscv_MISCMEM_reg <= riscv_MISCMEM;
		end
	end
	pc_reg <= pc;
	end
end
end
end

endmodule
