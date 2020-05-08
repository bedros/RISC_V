`define AHB_RAM_START 	32'hf0000000
`define AHB_RAM_SIZE		32'h00000400

`define AHB_ROM_START	32'h00000000
`define AHB_ROM_SIZE		32'h00000400



module AHB_ARB(

input HCLK,
input HRESETn,

input [31:0]DATA_HADDR,  //地址线
input [1:0]DATA_HTRANS,  //传输类型
input [31:0]DATA_HWDATA, //写数据线
output [31:0]DATA_HRDATA,  //读数据线
input DATA_HWRITE,       //读写信号线,高为写，低为读
input [2:0]DATA_HSIZE,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
input [2:0]DATA_HBUST,   //bust传输方式，默认3'b000
output [1:0]DATA_HRESP,    //传输应答信号
output DATA_HREADY,        //传输完成信号


input [31:0]CODE_HADDR,  //地址线
input [1:0]CODE_HTRANS,  //传输类型
input [31:0]CODE_HWDATA, //写数据线
output [31:0]CODE_HRDATA,  //读数据线
input CODE_HWRITE,       //读写信号线,高为写，低为读
input [2:0]CODE_HSIZE,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
input [2:0]CODE_HBUST,   //bust传输方式，默认3'b000
output [1:0]CODE_HRESP,    //传输应答信号
output CODE_HREADY,        //传输完成信号

output reg ACCESS_data_conflict,

//slave
	output HCLK_1,
	output HRESETn_1,
	output HSEL_1,
	output [31:0]HADDR_1,  //地址线
	output [1:0]HTRANS_1,  //传输类型
	output [31:0]HWDATA_1, //写数据线
	input [31:0]HRDATA_1,  //读数据线
	output HWRITE_1,       //读写信号线,高为写，低为读
	output [2:0]HSIZE_1,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
	output [2:0]HBUST_1,   //bust传输方式，默认3'b000
	input [1:0]HRESP_1,    //传输应答信号
	input HREADY_1,        //传输完成信号

	output HCLK_2,
	output HRESETn_2,
	output HSEL_2,
	output [31:0]HADDR_2,  //地址线
	output [1:0]HTRANS_2,  //传输类型
	output [31:0]HWDATA_2, //写数据线
	input [31:0]HRDATA_2,  //读数据线
	output HWRITE_2,       //读写信号线,高为写，低为读
	output [2:0]HSIZE_2,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
	output [2:0]HBUST_2,   //bust传输方式，默认3'b000
	input [1:0]HRESP_2,    //传输应答信号
	input HREADY_2        //传输完成信号
);

//定义设备所占用的地址
localparam DEVICE_1_START = `AHB_RAM_START;
localparam DEVICE_1_END = `AHB_RAM_START+`AHB_RAM_SIZE-1;

localparam DEVICE_2_START = `AHB_ROM_START;
localparam DEVICE_2_END = `AHB_ROM_START+`AHB_ROM_SIZE-1;

//是否访问某一存储体
wire CODE_ACCESS_DEVICE_1;
wire CODE_ACCESS_DEVICE_2;

wire DATA_ACCESS_DEVICE_1;
wire DATA_ACCESS_DEVICE_2;

assign CODE_ACCESS_DEVICE_1 = ((CODE_HADDR >= DEVICE_1_START)&&(CODE_HADDR <= DEVICE_1_END))?1'b1:1'b0;
assign CODE_ACCESS_DEVICE_2 = ((CODE_HADDR >= DEVICE_2_START)&&(CODE_HADDR <= DEVICE_2_END))?1'b1:1'b0;

assign DATA_ACCESS_DEVICE_1 = ((DATA_HADDR >= DEVICE_1_START)&&(DATA_HADDR <= DEVICE_1_END))?1'b1:1'b0;
assign DATA_ACCESS_DEVICE_2 = ((DATA_HADDR >= DEVICE_2_START)&&(DATA_HADDR <= DEVICE_2_END))?1'b1:1'b0;

assign HCLK_1 = HCLK;
assign HCLK_2 = HCLK;
//assign HRESETn_1 = HRESETn;
//assign HRESETn_2 = HRESETn;

assign HSEL_1 = 	CODE_ACCESS_DEVICE_1|DATA_ACCESS_DEVICE_1;
assign HSEL_2 = 	CODE_ACCESS_DEVICE_2|DATA_ACCESS_DEVICE_2;

//是否数据线优先
wire DATA_FIRST_DEVICE_1;
wire DATA_FIRST_DEVICE_2;

wire CODE_ACCESS;
wire DATA_ACCESS;

wire data_conflict;
reg data_conflict_buf;

//访问设备缓冲，用于记录当前访问最需要的数据通路
reg [3:0]DATA_ACCESS_DEVICE_buf;
reg [3:0]CODE_ACCESS_DEVICE_buf;


assign DATA_FIRST_DEVICE_1 = (((CODE_ACCESS_DEVICE_1 == 1'b1)&&(DATA_ACCESS_DEVICE_1 == 1'b1))?1'b1:1'b0)&DATA_ACCESS;
assign DATA_FIRST_DEVICE_2 = (((CODE_ACCESS_DEVICE_2 == 1'b1)&&(DATA_ACCESS_DEVICE_2 == 1'b1))?1'b1:1'b0)&DATA_ACCESS;
assign data_conflict = (DATA_HTRANS == 2'b10)?(DATA_FIRST_DEVICE_1|DATA_FIRST_DEVICE_2):1'b0;


//是否有传输请求

assign CODE_ACCESS = (CODE_HTRANS == 2'b10)?1'b1:1'b0;
assign DATA_ACCESS = (DATA_HTRANS == 2'b10)?1'b1:1'b0;


always@(*)begin
if(data_conflict_buf == 1'b1)begin
	case(DATA_ACCESS_DEVICE_buf)
		4'd0:ACCESS_data_conflict = 4'd1;
		4'd1: if(HREADY_1 == 1'b1) ACCESS_data_conflict = 4'd0;
		4'd2: if(HREADY_2 == 1'b1) ACCESS_data_conflict = 4'd0;
		4'd3:ACCESS_data_conflict = 4'd1;
		default:ACCESS_data_conflict = 4'd1;
	endcase
end
else begin
	if(data_conflict == 1'b1)begin
		ACCESS_data_conflict = 1'b1;
	end
	else begin
		ACCESS_data_conflict = 1'b0;
	end
end
end

always@(posedge HCLK)begin
if(data_conflict_buf == 1'b1)begin
	case(DATA_ACCESS_DEVICE_buf)
		4'd0:data_conflict_buf <= 4'd1;
		4'd1: if(HREADY_1 == 1'b1) data_conflict_buf <= 4'd0;
		4'd2: if(HREADY_2 == 1'b1) data_conflict_buf <= 4'd0;
		4'd3:data_conflict_buf <= 4'd1;
		default:data_conflict_buf <= 4'd1;
	endcase
end
else begin
	if(data_conflict == 1'b1)begin
		data_conflict_buf <= 4'd1;
	end
end
end

wire [1:0]DATA_ACCESS_REQ;
assign DATA_ACCESS_REQ = {DATA_ACCESS_DEVICE_2,DATA_ACCESS_DEVICE_1};

wire [1:0]CODE_ACCESS_REQ;
assign CODE_ACCESS_REQ = {CODE_ACCESS_DEVICE_2,CODE_ACCESS_DEVICE_1};


always@(posedge HCLK)begin
if(DATA_ACCESS_DEVICE_buf == 4'd0)begin
	if(DATA_ACCESS == 1'b1)begin
		case(DATA_ACCESS_REQ)
			2'b00:DATA_ACCESS_DEVICE_buf <= 4'd0;
			2'b01:DATA_ACCESS_DEVICE_buf <= 4'd1;
			2'b10:DATA_ACCESS_DEVICE_buf <= 4'd2;
			2'b11:DATA_ACCESS_DEVICE_buf <= 4'd0;
			default:DATA_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end
end
else begin
	if(DATA_ACCESS == 1'b1)begin
		case(DATA_ACCESS_REQ)
			2'b00:DATA_ACCESS_DEVICE_buf <= 4'd0;
			2'b01:DATA_ACCESS_DEVICE_buf <= 4'd1;
			2'b10:DATA_ACCESS_DEVICE_buf <= 4'd2;
			2'b11:DATA_ACCESS_DEVICE_buf <= 4'd0;
			default:DATA_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end 
	else begin
		case(DATA_ACCESS_DEVICE_buf)
			4'd0:DATA_ACCESS_DEVICE_buf <= 4'd0;
			4'd1: if(HREADY_1 == 1'b1) DATA_ACCESS_DEVICE_buf <= 4'd0;
			4'd2: if(HREADY_2 == 1'b1) DATA_ACCESS_DEVICE_buf <= 4'd0;
			4'd3:DATA_ACCESS_DEVICE_buf <= 4'd0;
			default:DATA_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end
end
end

always@(posedge HCLK)begin
if(CODE_ACCESS_DEVICE_buf == 4'd0)begin
	if(CODE_ACCESS == 1'b1)begin
		case(CODE_ACCESS_REQ)
			2'b00:CODE_ACCESS_DEVICE_buf <= 4'd0;
			2'b01:CODE_ACCESS_DEVICE_buf <= 4'd1;
			2'b10:CODE_ACCESS_DEVICE_buf <= 4'd2;
			2'b11:CODE_ACCESS_DEVICE_buf <= 4'd0;
			default:CODE_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end
end
else begin
	if(CODE_ACCESS == 1'b1)begin
		case(CODE_ACCESS_REQ)
			2'b00:CODE_ACCESS_DEVICE_buf <= 4'd0;
			2'b01:CODE_ACCESS_DEVICE_buf <= 4'd1;
			2'b10:CODE_ACCESS_DEVICE_buf <= 4'd2;
			2'b11:CODE_ACCESS_DEVICE_buf <= 4'd0;
			default:CODE_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end 
	else begin
		case(CODE_ACCESS_DEVICE_buf)
			4'd0:CODE_ACCESS_DEVICE_buf <= 4'd0;
			4'd1: if(HREADY_1 == 1'b1) CODE_ACCESS_DEVICE_buf <= 4'd0;
			4'd2: if(HREADY_2 == 1'b1) CODE_ACCESS_DEVICE_buf <= 4'd0;
			4'd3:CODE_ACCESS_DEVICE_buf <= 4'd0;
			default:CODE_ACCESS_DEVICE_buf <= 4'd0;
		endcase
	end
end
end


assign HADDR_1 = (DATA_FIRST_DEVICE_1 == 1'b1)?DATA_HADDR:(
						({32{CODE_ACCESS_DEVICE_1}}&CODE_HADDR)|
						({32{DATA_ACCESS_DEVICE_1}}&DATA_HADDR));
						
assign HADDR_2 = (DATA_FIRST_DEVICE_2 == 1'b1)?DATA_HADDR:(
						({32{CODE_ACCESS_DEVICE_2}}&CODE_HADDR)|
						({32{DATA_ACCESS_DEVICE_2}}&DATA_HADDR));

assign HTRANS_1 = (DATA_FIRST_DEVICE_1 == 1'b1)?DATA_HTRANS:(
						({2{CODE_ACCESS_DEVICE_1}}&CODE_HTRANS)|
						({2{DATA_ACCESS_DEVICE_1}}&DATA_HTRANS));	
						
assign HTRANS_2 = (DATA_FIRST_DEVICE_2 == 1'b1)?DATA_HTRANS:(
						({2{CODE_ACCESS_DEVICE_2}}&CODE_HTRANS)|
						({2{DATA_ACCESS_DEVICE_2}}&DATA_HTRANS));
	

assign HWDATA_1 = (DATA_ACCESS_DEVICE_buf == 4'd1)?DATA_HWDATA:
						(CODE_ACCESS_DEVICE_buf == 4'd1)?CODE_HWDATA:
						32'h00000000;
assign HWDATA_2 = (DATA_ACCESS_DEVICE_buf == 4'd2)?DATA_HWDATA:
						(CODE_ACCESS_DEVICE_buf == 4'd2)?CODE_HWDATA:
						32'h00000000;
	
assign DATA_HRDATA = (DATA_ACCESS_DEVICE_buf == 4'd1)?HRDATA_1:
							(DATA_ACCESS_DEVICE_buf == 4'd2)?HRDATA_2:
							32'h00000000;
							
assign CODE_HRDATA = (CODE_ACCESS_DEVICE_buf == 4'd1)?HRDATA_1:
							(CODE_ACCESS_DEVICE_buf == 4'd2)?HRDATA_2:
							32'h00000000;
assign HWRITE_1 = (DATA_FIRST_DEVICE_1 == 1'b1)?DATA_HWRITE:(
						(CODE_ACCESS_DEVICE_1&CODE_HWRITE)|
						(DATA_ACCESS_DEVICE_1&DATA_HWRITE));
assign HWRITE_2 = (DATA_FIRST_DEVICE_2 == 1'b1)?DATA_HWRITE:(
						(CODE_ACCESS_DEVICE_2&CODE_HWRITE)|
						(DATA_ACCESS_DEVICE_2&DATA_HWRITE));

assign HSIZE_1 = 	(DATA_FIRST_DEVICE_1 == 1'b1)?DATA_HSIZE:(
						({3{CODE_ACCESS_DEVICE_1}}&CODE_HSIZE)|
						({3{DATA_ACCESS_DEVICE_1}}&DATA_HSIZE));	
						
assign HSIZE_2 = 	(DATA_FIRST_DEVICE_2 == 1'b1)?DATA_HSIZE:(
						({3{CODE_ACCESS_DEVICE_2}}&CODE_HSIZE)|
						({3{DATA_ACCESS_DEVICE_2}}&DATA_HSIZE));
	
assign HBUST_1 = 	(DATA_FIRST_DEVICE_1 == 1'b1)?DATA_HBUST:(
						({3{CODE_ACCESS_DEVICE_1}}&CODE_HBUST)|
						({3{DATA_ACCESS_DEVICE_1}}&DATA_HBUST));	
						
assign HBUST_2 = 	(DATA_FIRST_DEVICE_2 == 1'b1)?DATA_HSIZE:(
						({3{CODE_ACCESS_DEVICE_2}}&CODE_HBUST)|
						({3{DATA_ACCESS_DEVICE_2}}&DATA_HBUST));
						

assign DATA_HRESP = 	(DATA_ACCESS_DEVICE_buf == 4'd1)?HRESP_1:
							(DATA_ACCESS_DEVICE_buf == 4'd2)?HRESP_2:
							3'b000;
							
assign CODE_HRESP = 	(CODE_ACCESS_DEVICE_buf == 4'd1)?HRESP_1:
							(CODE_ACCESS_DEVICE_buf == 4'd2)?HRESP_2:
							3'b000;						
						
assign DATA_HREADY = (DATA_ACCESS_DEVICE_buf == 4'd1)?HREADY_1:
							(DATA_ACCESS_DEVICE_buf == 4'd2)?HREADY_2:
							1'b0;
							
assign CODE_HREADY = (CODE_ACCESS_DEVICE_buf == 4'd1)?HREADY_1:
							(CODE_ACCESS_DEVICE_buf == 4'd2)?HREADY_2:
							1'b0;					


endmodule
