module RCU( //run control unit
input MAU_data_conflict,
input clk,
input reset,
output reg IFU_run,
output reg DECODE_run,
output reg REGFILE_run

);

always@(*)begin
	if(MAU_data_conflict == 1'b1)begin
		IFU_run = 1'b0;
	end
	else begin
		IFU_run = 1'b1;
	end
end

always@(*)begin
	if(MAU_data_conflict == 1'b1)begin
		DECODE_run = 1'b0;
	end
	else begin
		DECODE_run = 1'b1;
	end
end

always@(*)begin
	if(MAU_data_conflict == 1'b1)begin
			REGFILE_run = 1'b0;
	end
	else begin
		REGFILE_run = 1'b1;
	end
end


endmodule
