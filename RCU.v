module RCU( //run control unit
input MAU_data_conflict,
input ACCESS_data_conflict,
input clk,
input reset,
output reg IFU_run,
output reg DECODE_run,
output reg REGFILE_run,
output data_conflict
);

assign data_conflict = MAU_data_conflict|ACCESS_data_conflict;

always@(*)begin
	if(data_conflict == 1'b1)begin
		IFU_run = 1'b0;
	end
	else begin
		IFU_run = 1'b1;
	end
end

always@(*)begin
	if(data_conflict == 1'b1)begin
		DECODE_run = 1'b0;
	end
	else begin
		DECODE_run = 1'b1;
	end
end

always@(*)begin
	if(data_conflict == 1'b1)begin
		REGFILE_run = 1'b0;
	end
	else begin
		REGFILE_run = 1'b1;
	end
end


endmodule
