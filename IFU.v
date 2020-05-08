module IFU(
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


	input run_en,
	input [31:0]load_pc,
	output reg[31:0]pc_to_DECODE,
	output ir_already,
	input IFU_addr_en,
	input ALU_addr_en,
	input clk,
	input reset,
	input pc_add,
	input load_pc_en,
	output [31:0]ir,
	input data_conflict
);

reg [31:0]pc_register;

assign ir_already = HREADY;
assign ir = (HREADY == 1'b1)?HRDATA:32'h00000000;
assign HADDR = (data_conflict == 1'b1)?pc_to_DECODE:
							(({32{IFU_addr_en}}&pc_register)|
						   ({32{ALU_addr_en}}&load_pc));
assign HCLK =clk;
assign HSIZE = 3'b010;
assign HWRITE = 1'b0;
assign HBUST = 3'b000;
assign HTRANS = 2'b10;

always@(posedge clk)begin
if(run_en == 1'b1)begin
	if(load_pc_en)
		pc_to_DECODE <= load_pc;
    else
      pc_to_DECODE <= pc_register;
end
end		
						  
						  
always@(posedge clk,negedge reset)begin
if(~reset)begin//复位
	pc_register <= 32'h00000000;
end
else begin
	if(data_conflict == 1'b1)begin
			pc_register <= pc_to_DECODE;
	end
	else begin
	if(run_en == 1'b1)begin
			if(pc_add)begin//如果正常取指，pc每次自加4
				if(load_pc_en)
					pc_register <= load_pc + 32'd4;
				else
					pc_register <= pc_register + 32'd4;
			end
		end
	end
end
end

endmodule
