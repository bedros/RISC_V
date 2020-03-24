//内存访问单元，与总线进行数据交换，符合简化后的AHB总线接口
module MAU (
//自定总线接口信号
	input HCLK,
	input HRESETn,
	output [31:0]HADDR,  //地址线
	output [1:0]HTRANS,  //传输状态，考虑是否使用
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
	input [1:0]data_size,
	output LOAD_READY,
	output STORE_READY,
	output wait_ready

);

reg [31:0]addr_buf;
reg [31:0]data_buf;

always@(posedge HCLK,negedge HRESETn)begin
	if (~HRESETn) begin
		addr_buf <= 32'h00000000;
	end



end

always@(posedge HCLK,negedge HRESETn)begin
	if (~HRESETn) begin
		data_buf <= 32'h00000000;
	end
	else begin
	if(riscv_STORE)
		data_buf <= data_in;


	end


end

endmodule
