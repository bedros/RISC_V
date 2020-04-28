//内存访问单元，与总线进行数据交换，符合简化后的AHB总线接口

//定义传输应答
`define OKAY  2'b00
`define ERROR 2'b01
`define RETRY 2'b10
`define SPLIT 2'b11

//定义传输类型
`define IDLE 	2'b00 //空闲，无传输
`define BUSY 	2'b01 
`define NONSEQ 2'b10 //单次传输
`define SEQ 	2'b11

/*
ahb总线基本控制信号说明
HTRANS 	控制传输类型，主要控制是否开始传输
HWRITE 	传输方向 高为写，低为读
HSIZE		传输字节大小
HBUST		是否为突发传输，基本不进行突发读写
HRESP		传输应答，主要反映是否传输正确
HREADY	传输就绪信号，证明本次传输结束

*/

module MAU (
//自定总线接口信号
	output HCLK,
	input HRESETn,
	output [31:0]HADDR,  //地址线
	output [1:0]HTRANS,  //传输类型
	output [31:0]HWDATA, //写数据线
	input [31:0]HRDATA,  //读数据线
	output HWRITE,       //读写信号线,高为写，低为读
	output [2:0]HSIZE,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
	output [2:0]HBUST,   //bust传输方式，默认3'b000
	output HBUSREQ,      //总线请求信号
	output HLOCK,        //总线锁定信号
	input [1:0]HRESP,    //传输应答信号
	input HGRANT,        //总线应答信号
	input HREADY,        //传输完成信号

//CPU内部请求信号
	input riscv_LOAD,
	input riscv_STORE,
	input [31:0]addr,
	input [31:0]data_in,
	output [31:0]data_out,
	input [2:0]data_size,
	input clk,
	input reset,
	output LOAD_READY,
	output STORE_READY,
	output reg wait_ready,
	output load_addr_misaligned,	//读取地址未对齐
	output store_addr_misaligned
);

reg [31:0]addr_buf;
reg [31:0]data_buf;
reg [2:0]data_size_buf;
//定义两个标志，记录当前是否有读写正在进行
reg read_flag;
reg write_flag;
wire [31:0]addr_out;

wire mau_req;
wire four_byte_misaligned;
wire two_byte_misaligned;
wire misaligned;


wire lbu_buf;
wire lhu_buf;
wire HADDR_outen;


assign mau_req = riscv_LOAD|riscv_STORE;
assign HTRANS = (mau_req == 1'b1)?`NONSEQ:`IDLE;
assign HSIZE = {1'b0,data_size[1:0]};
assign HCLK = clk;
assign HBUST = 3'b000;//非突发传输
assign HWRITE = (riscv_STORE == 1'b1)?1'b1:(riscv_LOAD == 1'b1)?1'b0:1'b0;
//-------------------非对齐访问异常----------------------------------------------------\\
assign four_byte_misaligned = (mau_req == 1'b1)?
										(addr[1:0] != 2'b00)?1'b1:1'b0
										:1'b0;
assign two_byte_misaligned = (mau_req == 1'b1)?
										(addr[0] != 1'b0)?1'b1:1'b0
										:1'b0;
assign misaligned = four_byte_misaligned|two_byte_misaligned;


assign load_addr_misaligned = (riscv_LOAD == 1'b1)?misaligned:1'b0;
assign store_addr_misaligned = (riscv_STORE == 1'b1)?misaligned:1'b0;

//-------------------传输大小设置-------------------------------------------------------\\
wire byte;
wire half_word;
wire word;

wire byte_buf;
wire half_word_buf;
wire word_buf;

assign byte = (data_size == 3'b000)?1'b1:1'b0;
assign half_word  = (data_size == 3'b001)?1'b1:1'b0;
assign word  = (data_size == 3'b010)?1'b1:1'b0;

assign byte_buf = (data_size_buf == 3'b000)?1'b1:1'b0;
assign half_word_buf  = (data_size_buf == 3'b001)?1'b1:1'b0;
assign word_buf  = (data_size_buf == 3'b010)?1'b1:1'b0;
assign lbu_buf =  (data_size_buf == 3'b100)?1'b1:1'b0;
assign lhu_buf =  (data_size_buf == 3'b101)?1'b1:1'b0;



//-------------------load数据拼接-----------------------------------------------------\\
wire addr_buf_one;
wire addr_buf_two;
wire addr_buf_three;
wire addr_buf_four;

assign addr_buf_one = (addr_buf[1:0] == 2'b00)?1'b1:1'b0;
assign addr_buf_two = (addr_buf[1:0] == 2'b01)?1'b1:1'b0;
assign addr_buf_three = (addr_buf[1:0] == 2'b10)?1'b1:1'b0;
assign addr_buf_four = (addr_buf[1:0] == 2'b11)?1'b1:1'b0;

wire [7:0]byte_in;
wire [15:0]half_word_in;
wire [31:0]word_in;
wire [31:0]load_data_in;

assign byte_in = 	(HRDATA[7:0]&{8{addr_buf_one}})|
						(HRDATA[15:8]&{8{addr_buf_two}})|
						(HRDATA[23:16]&{8{addr_buf_three}})|
						(HRDATA[31:24]&{8{addr_buf_four}});
assign half_word_in = 	(HRDATA[15:0]&{16{addr_buf_one}})|
								(HRDATA[31:16]&{16{addr_buf_three}});
assign word_in = (HRDATA[31:0]&{32{addr_buf_one}});

assign load_data_in = 	({{24{byte_in[7]}},byte_in[7:0]} & {32{byte_buf}})|
								({{16{half_word_in[15]}},half_word_in[15:0]} & {32{half_word_buf}})|
								(word_in & {32{word_buf}})|
								({{24{1'b0}},byte_in[7:0]} & {32{lbu_buf}})|
								({{16{1'b0}},half_word_in[15:0]} & {32{lhu_buf}});

//-------------------store数据拼接----------------------------------------------------\\
wire addr_one;
wire addr_two;
wire addr_three;
wire addr_four;
wire [31:0]store_data_out;
wire [31:0]byte_out;
wire [31:0]half_word_out;
wire [31:0]word_out;

assign addr_one = (addr[1:0] == 2'b00)?1'b1:1'b0;
assign addr_two = (addr[1:0] == 2'b01)?1'b1:1'b0;
assign addr_three = (addr[1:0] == 2'b10)?1'b1:1'b0;
assign addr_four = (addr[1:0] == 2'b11)?1'b1:1'b0;

assign byte_out = ({{24{1'b0}},data_in[7:0]}&{32{addr_one}})|
						({{16{1'b0}},data_in[7:0],{8{1'b0}}}&{32{addr_two}})|
						({{8{1'b0}},data_in[7:0],{16{1'b0}}}&{32{addr_three}})|
						({data_in[7:0],{24{1'b0}}}&{32{addr_four}});
						
assign half_word_out = ({{16{1'b0}},data_in[15:0]}&{32{addr_one}})|
							  ({data_in[15:0],{16{1'b0}}}&{32{addr_three}});

assign word_out = {data_in & {32{addr_one}}};

assign store_data_out = (byte_out & {32{byte}})|
								(half_word_out & {32{half_word}})|
								(word_out & {32{word}});

								
assign addr_out = addr;
assign HADDR_outen = mau_req;
assign HWDATA = (write_flag == 1'b1)?data_buf:32'h00000000;
assign HADDR = (HADDR_outen == 1'b1)?addr_out:32'h00000000;


//-------------------读写请求处理----------------------------------------------------\\
always@(posedge clk) begin
	if(read_flag == 1'b1)begin
		if(HREADY == 1'b1) begin
			if(riscv_STORE == 1'b1)begin
				read_flag <= 1'b1;
			end
			else begin
				read_flag <= 1'b0;
			end
		end
		else begin
		end
	end
	else begin
		if(riscv_LOAD == 1'b1)begin
				read_flag <= 1'b1;
		end
	end
end


always@(posedge clk) begin
	if(write_flag == 1'b1)begin
		if(HREADY == 1'b1) begin
			if(riscv_STORE == 1'b1)begin
				write_flag <= 1'b1;
			end
			else begin
				write_flag <= 1'b0;
			end
		end
		else begin
		end
	end
	else begin
		if(riscv_STORE == 1'b1)begin
				write_flag <= 1'b1;
		end
	end
end






always@(posedge clk,negedge reset)begin
	if (~reset) begin
		data_size_buf <= 3'b111;
	end

end

always@(posedge clk,negedge reset)begin
	if (~reset) begin
		addr_buf <= 32'h00000000;
	end



end

always@(posedge clk,negedge reset)begin
	if (~reset) begin
		data_buf <= 32'h00000000;
	end
	else begin
	if(riscv_STORE)
		data_buf <= store_data_out;
	end
end

endmodule
