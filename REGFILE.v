module REGFILE(
	input run_en,
	input [31:0]data_in,
	input [31:0]data_mau_in,
	output reg [31:0]data_out1,
	output reg [31:0]data_out2,
	input [4:0]rd,
	input [4:0]rdmau,
	input [4:0]rs1,
	input [4:0]rs2,
	input rd_en,
	input rdmau_en,
	input rs1_en,
	input rs2_en,
	input clk,
	input reset
);



reg [31:0]register[31:1];

generate
genvar i;
for(i = 1;i<32;i=i+1)begin :_register_reset
  
    always@(posedge clk,negedge reset)begin
      if(~reset)begin
        register[i] <= 32'h00000000;
      end
      else begin
			if(rdmau_en == 1'b1)begin
				if(rdmau == i) begin
					if(!((rd_en == 1'b1)&&(rd == i)))begin
						register[i] <= data_mau_in;
					end
				end
			end
			if(run_en == 1'b1)begin
				if(rd_en == 1'b1)begin
					if(rd == i) begin
						register[i] <= data_in;
					end
				end
			end
      end
    end
	 
	 
end
endgenerate


always@(*)begin
  if(rs1_en)begin
    if(rs1 == 5'b0)begin
      data_out1 = 32'h00000000;
    end
    else begin
      data_out1 = register[rs1];
    end
  end
  else begin
    data_out1 = 32'h00000000;
  end
end

always@(*)begin
  if(rs2_en)begin
    if(rs2 == 5'b0)begin
      data_out2 = 32'h00000000;
    end
    else begin
      data_out2 = register[rs2];
    end
  end
  else begin
    data_out2 = 32'h00000000;
  end
end

endmodule
