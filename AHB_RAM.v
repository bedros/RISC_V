module AHB_RAM(
	input HCLK,
	input HRESETn,
	input HSEL,
	input [7:0]HADDR,  //地址线
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
reg	[3:0]  byteena;
wire	clock;
wire	[31:0]  data;
wire	wren;
wire	[31:0]  q;
wire  NONSEQ;
wire RAM_REQ;
wire ram_wr;
wire [3:0]ram_byteena;
reg outen;
reg 	ready;

reg [7:0]HADDR_buf;
reg [3:0]byteena_buf;

reg write_flag;
reg read_flag;

assign NONSEQ = (HTRANS == 2'b10)?1'b1:1'b0;
assign RAM_REQ = NONSEQ|HSEL;
assign HREADY = ready;

assign address = (write_flag == 1'b1)?HADDR_buf:HADDR;
assign ram_byteena = (write_flag == 1'b1)?byteena_buf:byteena;
assign ram_wr = (write_flag == 1'b1)?1'b1:1'b0;


assign data = HWDATA;
assign HRDATA = (read_flag ==1'b1)?q:32'h00000000;
assign wren = (RAM_REQ)?HWRITE:1'b0;
assign clock = HCLK;
assign HRESP = (ready == 1'b1)?2'b00:2'b00;


always @(*)begin
	case({HSIZE,HADDR[1:0]})
	5'b000_00:byteena = 4'b0001;
	5'b000_01:byteena = 4'b0010;
	5'b000_10:byteena = 4'b0100;
	5'b000_11:byteena = 4'b1000;
	
	5'b001_00:byteena = 4'b0011;
	5'b001_10:byteena = 4'b1100;
	5'b010_00:byteena = 4'b1111;
	default :byteena = 4'b0000;
	endcase
end


always@(posedge clock)begin
	if(ready == 1'b1)begin
		if(RAM_REQ == 1'b1)begin
			ready <= 1'b1;
		end
		else begin
			ready <= 1'b0;
		end
	end
	else begin
		if(RAM_REQ == 1'b1)begin
			ready <= 1'b1;
		end
	end
end

ram ram_1 (
	.address(address),
	.byteena(ram_byteena),
	.clock(clock),
	.data(data),
	.wren(ram_wr),
	.q(q)
);

always@(posedge clock)begin
	if((RAM_REQ == 1'b1)&&(wren == 1'b0))begin
		read_flag <= 1'b1;
	end
	else begin
		read_flag <= 1'b0;
	
	end
end


always@(posedge clock)begin
	if(wren == 1'b1)begin
		HADDR_buf <= HADDR;
		byteena_buf <= byteena;
		write_flag <= 1'b1;
	end
	else begin
		write_flag <= 1'b0;
	end
end



endmodule
