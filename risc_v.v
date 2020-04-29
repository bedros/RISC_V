module risc_v(
output [31:0]code_addr_bus,
input [31:0]code_data_bus,
input code_data_already,

input reset,

output DATA_HCLK,
output DATA_HRESETn,
output [31:0]DATA_HADDR,  //地址线
output [1:0]DATA_HTRANS,  //传输类型
output [31:0]DATA_HWDATA, //写数据线
input [31:0]DATA_HRDATA,  //读数据线
output DATA_HWRITE,       //读写信号线,高为写，低为读
output [2:0]DATA_HSIZE,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
output [2:0]DATA_HBUST,   //bust传输方式，默认3'b000
input [1:0]DATA_HRESP,    //传输应答信号
input DATA_HREADY,        //传输完成信号

input clk
);

wire [31:0]ir;
wire ir_already;
wire addr_en;

wire [31:0]addr_IFUtoBIU;
wire addr_IFUtoBIU_en;
wire addr_ALUtoBIU_en;

wire [31:0]data_IFUtoBIU;
wire data_IFUtoBIU_en;
wire BIU_data_already;
wire IFU_ir_already;
wire IFU_pc_add;
wire IFU_load_pc_en;
wire [31:0]ALU_addr_out;
wire [31:0]pc_IFU_to_DECODE;

wire [31:0]MAU_data_toREG;
wire [31:0]ALU_addr_toMAU;
wire [31:0]ALU_data_toMAU;


wire [4:0]index_rs1;
wire [4:0]index_rs2;
wire [4:0]index_rd;
wire [31:0]DECODE_imm;
wire enable_rs1;
wire enable_rs2;
wire enable_rd;
wire DECODE_imm_en;
wire [2:0]fun3;
wire [6:0]fun7;

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

wire [31:0]data_rs1;
wire [31:0]data_rs2;
wire [31:0]data_rd;
wire [31:0]pc_DECODE_to_ALU;

wire pipeline_flush;

wire [4:0]rdmau;
wire [31:0]data_mau_to_reg;
wire rdmau_en;


assign data_IFUtoBIU_en = 1'b1;
assign data_ALUtoBIU_en = 1'b0;





//BIU _blu(
 //.reset         ( reset            ) ,
 //.clk           ( clk              ) ,
 //.addr_bus      ( addr_bus         ) ,
 //.kaddrpc        ( addr_IFUtoBIU    ) ,
 //.addralu       ( ALU_addr_out     ) ,
 //.addrpc_en     ( addr_IFUtoBIU_en ) ,
 //.addralu_en    ( addr_ALUtoBIU_en ) ,
 //.data_bus      ( data_bus         ) ,
 //.data_toIFU    ( data_IFUtoBIU    ) ,
 //.data_toALU    ( data_ALUtoBIU    ) ,
 //.data_toIFU_en ( data_IFUtoBIU_en ) ,
 //.data_toALU_en ( data_ALUtoBIU_en ) ,
 //.data_already  ( BIU_data_already )
//);


IFU _ifu(
	//.addr_toBIU    ( addr_IFUtoBIU    ) ,
	//.data          ( data_IFUtoBIU    ) ,
	.addr_out      ( code_addr_bus    ) ,
	.data          ( code_data_bus    ) ,
	.load_pc       ( ALU_addr_out     ) ,
	.pc_to_DECODE      ( pc_IFU_to_DECODE      ) ,
	.data_already  ( BIU_data_already ) ,
	.ir_already    ( IFU_ir_already   ) ,
	.IFU_addr_en   ( addr_IFUtoBIU_en ) ,
	.ALU_addr_en   ( addr_ALUtoBIU_en ) ,
	.clk           ( clk              ) ,
	.reset         ( reset            ) ,
	.pc_add        ( IFU_pc_add       ) ,
	.load_pc_en    ( IFU_load_pc_en   ) ,
	.ir            ( ir               )
);

assign BIU_data_already = code_data_already;

DECODE _decode(
	.clk           ( clk              ) ,
	.reset         ( reset            ) ,
	.flush			(pipeline_flush    ) ,
	.ir            ( ir               ) ,
	.ir_already    ( IFU_ir_already   ) ,
	.pc				(pc_IFU_to_DECODE),
	.dec_rs1_reg       ( index_rs1        ) ,//源寄存器1
	.dec_rs2_reg       ( index_rs2        ) ,//源寄存器2
	.dec_rd_reg        ( index_rd         ) ,//目标寄存器
	.dec_imm_reg       ( DECODE_imm       ) ,
	.dec_rs1en_reg     ( enable_rs1       ) ,
	.dec_rs2en_reg     ( enable_rs2       ) ,
	.dec_rden_reg      ( enable_rd        ) ,
	.dec_immen_reg     ( DECODE_imm_en    ) ,
	.funct3_reg        ( fun3				 ) ,
	.funct7_reg        ( fun7				 ) ,
  .riscv_LOAD_reg    ( riscv_LOAD       ) ,
  .riscv_OPIMM_reg   ( riscv_OPIMM      ) ,
  .riscv_AUIPC_reg   ( riscv_AUIPC      ) ,
  .riscv_STORE_reg   ( riscv_STORE      ) ,
  .riscv_OP_reg      ( riscv_OP         ) ,
  .riscv_LUI_reg     ( riscv_LUI        ) ,
  .riscv_BRANCH_reg  ( riscv_BRANCH     ) ,
  .riscv_JALR_reg    ( riscv_JALR       ) ,
  .riscv_JAL_reg     ( riscv_JAL        ) ,
  .riscv_SYSTEM_reg  ( riscv_SYSTEM     ) ,
  .riscv_MISCMEM_reg ( riscv_MISCMEM    ) ,
  .dec_pcen_reg     	( dec_pcen),
  .pc_reg				(pc_DECODE_to_ALU)
);


ALU _alu(
	.addr_toMAU    ( ALU_addr_toMAU       ) ,
	.data_toMAU    ( ALU_data_toMAU       ) ,
	
	
	.data_in1      ( data_rs1         ) ,
	.data_in2      ( data_rs2         ) ,
	.imm           ( DECODE_imm       ) ,
	.data_toReg    ( data_rd          ) ,
	.pc            ( pc_DECODE_to_ALU      ) ,
	.addr_fromALU  ( ALU_addr_out     ) ,
	.funct3        ( fun3				 ) ,
	.funct7        ( fun7				 ) ,
	.clk           ( clk              ) ,
	.reset         ( reset            ) ,
	.dec_rs1en     ( enable_rs1       ) ,
	.dec_rs2en     ( enable_rs2       ) ,
	.dec_rden      ( enable_rd        ) ,
	.dec_immen     ( DECODE_imm_en    ) ,
	.riscv_LOAD    ( riscv_LOAD       ) ,
	.riscv_OPIMM   ( riscv_OPIMM      ) ,
	.riscv_AUIPC   ( riscv_AUIPC      ) ,
	.riscv_STORE   ( riscv_STORE      ) ,
	.riscv_OP      ( riscv_OP         ) ,
	.riscv_LUI     ( riscv_LUI        ) ,
	.riscv_BRANCH  ( riscv_BRANCH     ) ,
	.riscv_JALR    ( riscv_JALR       ) ,
	.riscv_JAL     ( riscv_JAL        ) ,
	.riscv_SYSTEM  ( riscv_SYSTEM     ) ,
	.riscv_MISCMEM ( riscv_MISCMEM    ) ,
	.dec_pcen      ( dec_pcen         ) ,
	.pc_load       ( IFU_load_pc_en   ) ,
	.pc_add        ( IFU_pc_add       ) ,
	.flush			(pipeline_flush    ) ,
	.addrpc_en     ( addr_IFUtoBIU_en ) ,
	.addralu_en    ( addr_ALUtoBIU_en )

);


REGFILE _regfile(
	.rdmau			(rdmau				),
	.data_mau_in	(MAU_data_toREG	),
	.rdmau_en		(rdmau_en			),
	.data_in  		( data_rd    		),
	.data_out1 		( data_rs1  		),
	.data_out2 		( data_rs2   		),
	.rd        		( index_rd   		),
	.rs1       		( index_rs1  		),
	.rs2       		( index_rs2  		),
	.rd_en     		( enable_rd  		),
	.rs1_en    		( enable_rs1 		),
	.rs2_en    		( enable_rs2 		),
	.clk       		( clk        		),
	.reset     		( reset      		)
);



MAU _mau(
//自定总线接口信号
	.HCLK(DATA_HCLK),
	.HRESETn(DATA_HRESETn),
	.HADDR(DATA_HADDR),  //地址线
	.HTRANS(DATA_HTRANS),  //传输状态，考虑是否使用
	.HWDATA(DATA_HWDATA), //写数据线
	.HRDATA(DATA_HRDATA),  //读数据线
	.HWRITE(DATA_HWRITE),       //读写信号线,高为写，低为读
	.HSIZE(DATA_HSIZE),   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
	.HBUST(DATA_HBUST),   //bust传输方式，默认3'b000
	.HBUSREQ(),      //总线请求信号
	.HLOCK(),        //总线锁定信号
	.HRESP(DATA_HRESP),    //传输应答信号
	.HGRANT(),        //总线应答信号
	.HREADY(DATA_HREADY),        //传输完成信号

//CPU内部请求信号
	.riscv_LOAD(riscv_LOAD),
	.riscv_STORE(riscv_STORE),
	.addr(ALU_addr_toMAU),
	.data_in(ALU_data_toMAU),
	.data_out(MAU_data_toREG),
	.data_size(fun3),
	.clk(clk),
	.reset(reset),
	.LOAD_READY(rdmau_en),
	.STORE_READY(),
	.wait_ready(),
	.rd(index_rd),
	.rd_mau(rdmau),
	.load_addr_misaligned(),	//读取地址未对齐
	.store_addr_misaligned()

);

















endmodule
