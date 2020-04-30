`define ADD_funct3 	3'b000
`define SUB_funct3 	3'b000
`define SLT_funct3 	3'b010
`define SLTU_funct3 	3'b011
`define XOR_funct3 	3'b100
`define OR_funct3 	3'b110
`define AND_funct3 	3'b111
`define SLL_funct3 	3'b001
`define SRL_funct3 	3'b101
`define SRA_funct3 	3'b101

`define BEQ_funct3 3'b000
`define BNE_funct3 3'b001
`define BLT_funct3 3'b100
`define BLTU_funct3 3'b110
`define BGE_funct3 3'b101
`define BGEU_funct3 3'b111


`define ADD_funct7 	7'b0
`define SUB_funct7 	7'b0100000
`define SLT_funct7 	7'b0
`define SLTU_funct7 	7'b0
`define XOR_funct7	7'b0
`define OR_funct7 	7'b0
`define AND_funct7 	7'b0
`define SLL_funct7 	7'b0
`define SRL_funct7 	7'b0
`define SRA_funct7 	7'b0100000


module ALU(
output [31:0]addr_toMAU,
output [31:0]data_toMAU,

input [31:0]data_in1,//操作数1
input [31:0]data_in2,//操作数2
input [31:0]imm,//立即数
output [31:0]data_toReg,//计算结果输出
input [31:0]pc,//pc指针输入
output [31:0]addr_fromALU,//alu计算生成的地址
input [2:0]funct3,
input [6:0]funct7,
input clk,
input reset,

input dec_rs1en,
input dec_rs2en,
input dec_rden,
input dec_immen,
input dec_pcen,

input riscv_LOAD,
input riscv_OPIMM,
input riscv_AUIPC,
input riscv_STORE,
input riscv_OP,
input riscv_LUI,
input riscv_BRANCH,
input riscv_JALR,
input riscv_JAL,
input riscv_SYSTEM,
input riscv_MISCMEM,

output pc_load,
output pc_add,
output flush,//流水线冲刷
output addrpc_en,
output addralu_en,

input MAU_data_conflict
);

//定义常规数据运算
wire [31:0]alu_op1;
wire [31:0]alu_op2;
wire [31:0]alu_addin1;
wire [31:0]alu_addin2;
wire [31:0]alu_out;
wire alu_outen;

wire [31:0]alu_add;
wire [31:0]alu_sub;
wire [31:0]alu_xor;
wire [31:0]alu_sll;
wire [31:0]alu_srl;
wire [31:0]alu_sra;
wire [31:0]alu_or;
wire [31:0]alu_and;
wire [31:0]alu_slt;
wire [31:0]alu_sltu;

wire alu_adden;
wire alu_suben;
wire alu_xoren;
wire alu_sllen;
wire alu_srlen;
wire alu_sraen;
wire alu_oren;
wire alu_anden;
wire alu_slten;
wire alu_sltuen;
wire alu_op_en = riscv_OPIMM|riscv_OP;
wire alu_op_need_funct7;

wire [31:0]pc_toREG;
wire addr_fromALU_en;

wire branch_en;
wire branch_eq_op;
wire branch_ne_op;
wire branch_lt_op;
wire branch_ltu_op;
wire branch_ge_op;
wire branch_geu_op;

wire branch_eq;
wire branch_ne;
wire branch_lt;
wire branch_ltu;
wire branch_ge;
wire branch_geu;

wire addr_toMAU_en;

wire pc_toREG_en;





assign branch_en = (branch_eq_op &branch_eq)
                  |(branch_ne_op &branch_ne )
                  |(branch_lt_op &branch_lt )
                  |(branch_ltu_op&branch_ltu)
                  |(branch_ge_op &branch_ge )
                  |(branch_geu_op&branch_geu);

assign branch_eq_op  =((riscv_BRANCH==1'b1)&&(funct3 == `BEQ_funct3))?1'b1:1'b0;
assign branch_ne_op  =((riscv_BRANCH==1'b1)&&(funct3 == `BNE_funct3))?1'b1:1'b0;
assign branch_lt_op  =((riscv_BRANCH==1'b1)&&(funct3 == `BLT_funct3))?1'b1:1'b0;
assign branch_ltu_op =((riscv_BRANCH==1'b1)&&(funct3 == `BLTU_funct3))?1'b1:1'b0;
assign branch_ge_op  =((riscv_BRANCH==1'b1)&&(funct3 == `BGE_funct3))?1'b1:1'b0;
assign branch_geu_op =((riscv_BRANCH==1'b1)&&(funct3 == `BGEU_funct3))?1'b1:1'b0;

assign branch_eq = (alu_sub == 32'h00000000)?1'b1:1'b0;
assign branch_ne = ~branch_eq;
assign branch_lt = alu_slt[0];
assign branch_ge = ~branch_lt;
assign branch_ltu = alu_sltu[0];
assign branch_geu = ~branch_ltu;



assign alu_add = alu_addin1 + alu_addin2;
assign alu_xor = alu_op1 ^ alu_op2;
assign alu_or = alu_op1 | alu_op2;
assign alu_and = alu_op1 & alu_op2;
assign alu_sll = alu_op1 << alu_op2[4:0];
assign alu_srl = alu_op1 >> alu_op2[4:0];
assign alu_sra = ($signed(alu_op1)) >>> alu_op2[4:0];
assign alu_slt = (($signed(alu_op1)) < ($signed(alu_op2)))?32'h00000001:32'h00000000;
assign alu_sltu = (alu_op1 < alu_op2)?32'h00000001:32'h00000000;
assign alu_sub = alu_op1 - alu_op2;

assign alu_out = (alu_outen)?(({32{alu_adden}}&alu_add)|
										({32{alu_suben}}&alu_sub)|
										({32{alu_anden}}&alu_and)|
										({32{alu_xoren}}&alu_xor)|
										({32{alu_sllen}}&alu_sll)|
										({32{alu_srlen}}&alu_srl)|
										({32{alu_sraen}}&alu_sra)|
										({32{alu_oren}}&alu_or)|
										({32{alu_slten}}&alu_slt)|
										({32{alu_sltuen}}&alu_sltu)):32'h00000000;

//译码对应的操作类型
assign alu_adden = ((riscv_OP == 1'b1)&&(funct3 == `ADD_funct3)&&(funct7 == `ADD_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `ADD_funct3))||
                   (dec_pcen == 1'b1)||
                   (riscv_JALR == 1'b1)||
						 (riscv_LOAD == 1'b1)||
						 (riscv_STORE == 1'b1)?1'b1:1'b0;//如果需要pc的值进行计算，必定为加计算


assign alu_xoren = ((riscv_OP == 1'b1)&&(funct3 == `XOR_funct3)&&(funct7 == `XOR_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `XOR_funct3))?1'b1:1'b0;

assign alu_oren = ((riscv_OP == 1'b1)&&(funct3 == `OR_funct3)&&(funct7 == `OR_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `OR_funct3))?1'b1:1'b0;

assign alu_anden = ((riscv_OP == 1'b1)&&(funct3 == `AND_funct3)&&(funct7 == `AND_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `AND_funct3))?1'b1:1'b0;

assign alu_slten = ((riscv_OP == 1'b1)&&(funct3 == `SLT_funct3)&&(funct7 == `SLT_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `SLT_funct3))?1'b1:1'b0;

assign alu_sltuen = ((riscv_OP == 1'b1)&&(funct3 == `SLTU_funct3)&&(funct7 == `SLTU_funct7))||
                   ((riscv_OPIMM == 1'b1)&&(funct3 == `SLTU_funct3))?1'b1:1'b0;

assign alu_suben = ((riscv_OP == 1'b1)&&(funct3 == `SUB_funct3)&&(funct7 == `SUB_funct7))?1'b1:1'b0;

assign alu_sllen = ((alu_op_en == 1'b1)&&(funct3 == `SLL_funct3)&&(funct7 == `SLL_funct7))?1'b1:1'b0;

assign alu_srlen = ((alu_op_en == 1'b1)&&(funct3 == `SRL_funct3)&&(funct7 == `SRL_funct7))?1'b1:1'b0;

assign alu_sraen = ((alu_op_en == 1'b1)&&(funct3 == `SRA_funct3)&&(funct7 == `SRA_funct7))?1'b1:1'b0;



assign alu_addin1 =(pc&{32{dec_pcen}})|
                (data_in1&{32{dec_rs1en}}&{32{~dec_pcen}});
assign alu_addin2 = (imm&{32{dec_immen}})|
                (data_in2&{32{dec_rs2en}}&{32{~dec_immen}});
assign alu_op1 = (data_in1&{32{dec_rs1en}});
assign alu_op2 = (data_in2&{32{dec_rs2en}});


assign data_toReg = ({32{alu_outen}}&alu_out)|
                    ({32{riscv_LUI}}&imm)|
                    ({32{pc_toREG_en}}&pc_toREG);

//待修改debug用
assign alu_outen = alu_op_en|riscv_AUIPC;

//alu一共有两路输出
//一路为寄存器输出，将运算结果输入给寄存器
//另一路为地址计算输出，主要进行跳转指令和访问寄存器指令
assign pc_toREG = ({32{pc_toREG_en}}&(pc + 32'd4));
assign pc_toREG_en = riscv_JAL|riscv_JALR;


assign addr_fromALU = {32{addr_fromALU_en}}&{alu_add[31:1],(riscv_JALR==1'b0)?alu_add[0]:1'b0};
assign addr_fromALU_en = pc_load;

assign pc_load = riscv_JAL|riscv_JALR|branch_en;
assign pc_add = 1'b1;


assign addrpc_en = ~addralu_en;
assign addralu_en = pc_load;

assign flush = pc_load;



assign addr_toMAU_en = riscv_LOAD|riscv_STORE;
assign addr_toMAU = {32{addr_toMAU_en}}&alu_add;
assign data_toMAU = {32{riscv_STORE}}&alu_op2;


endmodule
