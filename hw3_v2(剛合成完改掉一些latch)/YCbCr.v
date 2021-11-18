module YCbCr (
	input 	[7:0]		i_data_R,
	input 	[7:0]		i_data_G,
	input 	[7:0]		i_data_B,
	output	[23:0]		o_data_YCbCr
);
	reg 	[7:0]		w_Y;	
	reg 	[7:0]		w_Cb;	
	reg 	[7:0]		w_Cr;
	//Y
	reg 	[10:0]		w_Y_5G;
	reg 	[10:0]		w_Y_temp;
	//Cb
	reg		[11:0]		w_4B_add_1024;
	reg 	[11:0]		w_Cb_temp;
	reg 	[8:0]		w_Cb_round;
	//Cr
	reg 	[11:0]		w_4R_add_1024;
	reg 	[11:0]		w_Cr_temp;
	reg 	[8:0]		w_Cr_round;

	assign	o_data_YCbCr	=	{w_Y, w_Cb, w_Cr};

	always @(*) begin	//Y
		w_Y_5G		=	{i_data_G, 2'b0} + {i_data_G};
		w_Y_temp	=	w_Y_5G + {i_data_R, 1'b0};
		if (w_Y_temp[2] == 0) begin
			w_Y		=	w_Y_temp[10:3];	
		end	
		else
			w_Y		=	w_Y_temp[10:3] + 1;
	end

	always @(*) begin	//Cb
		w_4B_add_1024	=	{8'd128,3'b0} + {i_data_B, 2'b0};
		w_Cb_temp		=	w_4B_add_1024	-	i_data_R	-	{i_data_G, 1'b0};
		if (w_Cb_temp[2] == 1'b1) 
			w_Cb_round	=	w_Cb_temp[11:3] + 1;
		else
			w_Cb_round	=	w_Cb_temp[11:3];
		if (w_Cb_round[8] == 1'b1)
			w_Cb 	= 8'd255;
		else
			w_Cb	= w_Cb_round[7:0];	

	end
	
	always @(*) begin
		w_4R_add_1024	=	{8'd128,3'b0} + {i_data_R, 2'b0};
		w_Cr_temp		=	w_4R_add_1024 - i_data_B - {i_data_G, 1'b0} - i_data_G;
		if (w_Cr_temp[2] == 1'b1) 
			w_Cr_round	=	w_Cr_temp[11:3] + 1;
		else
			w_Cr_round	=	w_Cr_temp[11:3];
		if (w_Cr_round[8] == 1'b1)
			w_Cr 	= 8'd255;
		else
			w_Cr	= w_Cr_round[7:0];	
	end
endmodule