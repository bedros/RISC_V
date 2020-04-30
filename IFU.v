module IFU(
	input run_en,
	output [31:0]addr_out,
	input [31:0]data,
	input [31:0]load_pc,
	output reg[31:0]pc_to_DECODE,
	input data_already,
	output ir_already,
	input IFU_addr_en,
	input ALU_addr_en,
	input clk,
	input reset,
	input pc_add,
	input load_pc_en,
	output [31:0]ir
);

reg [31:0]pc_register;

assign ir_already = data_already;
assign ir = (data_already == 1'b1)?data:32'h00000000;
assign addr_out = ({32{IFU_addr_en}}&pc_register)|
						  ({32{ALU_addr_en}}&load_pc);
		


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

endmodule
