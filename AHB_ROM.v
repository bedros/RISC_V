module AHB_ROM(
	input HCLK,
	input HRESETn,
	input HSEL,
	input [9:0]HADDR,  //地址线
	input [1:0]HTRANS,  //传输类型
	input [31:0]HWDATA, //写数据线
	output [31:0]HRDATA,  //读数据线
	input HWRITE,       //读写信号线,高为写，低为读
	input [2:0]HSIZE,   //传输大小,3'b000 Byte,3'b001 HalfWord,3'b010 Word
	input [2:0]HBUST,   //bust传输方式，默认3'b000
	output [1:0]HRESP,    //传输应答信号
	output HREADY        //传输完成信号

);

wire	[7:0]  address;
wire	clock;
wire	[31:0]  data;
wire	wren;
wire	[31:0]  q;
wire  NONSEQ;
wire ROM_REQ;
reg 	ready;

assign clock = HCLK;
assign address = {HADDR[9:2]};
assign NONSEQ = (HTRANS == 2'b10)?1'b1:1'b0;
assign ROM_REQ = NONSEQ&HSEL;
assign HRESP = (ready == 1'b1)?2'b00:2'b00;
assign HREADY = ready;

always@(posedge clock)begin
	if(ready == 1'b1)begin
		if(ROM_REQ == 1'b1)begin
			ready <= 1'b1;
		end
		else begin
			ready <= 1'b0;
		end
	end
	else begin
		if(ROM_REQ == 1'b1)begin
			ready <= 1'b1;
		end
		else begin
			ready <= 1'b0;
		end
	end
end




rom_32bit _rom(
	.address(address),
	.clock(clock),
	.q(HRDATA));

endmodule
