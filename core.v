module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	output [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	output                  o_d_wen,
	output [ ADDR_W-1 : 0 ] o_d_addr,
	output [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	output [        1 : 0 ] o_status,
	output                  o_status_valid
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
wire 		PC_valid,	PCSrc,	branch,	PC_address_overflow;	//PC
wire 		RegWrite,	MemtoReg,	RegDst,	ALUSrc;	
wire[31:0]	Read_data1,	Read_data2,	ALU_result;	//RegFile
wire[5:0]		ALU_operation;	//controller

PC	ProgramCounter(	.i_clk(i_clk),	
					.i_rst_n(i_rst_n),	
					.i_PC_valid(PC_valid),	
					.i_PCSrc(PCSrc),	
					.i_branch(branch),	
					.i_PC_im({ {16{1'b0}},	i_i_inst[15:0] }),	
					.o_i_addr(o_i_addr),	
					.o_PC_address_overflow(PC_address_overflow)	
					);
RegisterFile	RegFile( 	.i_clk(i_clk),	
							.i_rst_n(i_rst_n),
							.i_i_inst(i_i_inst),
							.RegWrite(RegWrite),
							.i_d_rdata(i_d_rdata),
							.i_ALU_result(ALU_result),
							.MemtoReg(MemtoReg),
							.i_RegDst(RegDst),
							.o_d_wdata(o_d_wdata),
							.Read_data1(Read_data1),
							.Read_data2(Read_data2),
							.i_ALUSrc(ALUSrc)
						);
Controller		Control(	.i_clk(i_clk),	
							.i_rst_n(i_rst_n),
							.i_i_inst_opcode(i_i_inst[31:26]),
							.i_PC_address_overflow(PC_address_overflow),
							.i_alu_overflow(alu_overflow),
							.o_PC_valid(PC_valid),
							.o_status_valid(o_status_valid),
							.o_status(o_status),
							.PCSrc(PCSrc),
							.o_ALU_operation(ALU_operation),
							.o_RegDst(RegDst),
							.o_d_wen(o_d_wen),
							.o_MemtoReg(MemtoReg),
							.o_RegWrite(RegWrite),
							.o_ALUSrc(ALUSrc)
						);
alu				alu_1	(	.i_clk(i_clk),	
							.i_rst_n(i_rst_n),
							.i_Read_data1(Read_data1),
							.i_Read_data2(Read_data2),
							.i_ALU_operation(ALU_operation),
							.o_ALU_result(ALU_result),
							.o_branch(branch),
							.o_overflow(alu_overflow),
							.o_d_addr(o_d_addr)
						);



// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //



// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //


/*
always @(*) begin
	$display("o_status	",o_status);
$display("ALU_operation	",ALU_operation);
$display("PC_valid	",PC_valid);
$display("i_i_inst_opcode	",i_i_inst[31:26]);
$display("o_i_addr",	o_i_addr);	
end
*/

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //



endmodule

module alu (
	input							i_clk,
	input							i_rst_n,
	input[31:0]						i_Read_data1,			//from Register File	
	input[31:0]						i_Read_data2,			//from Register File
	input[5:0]						i_ALU_operation,		//from controller
	output[31:0]					o_ALU_result,
	output							o_branch,				//for branch		
	output							o_overflow,
	output[31:0]					o_d_addr		
);
	reg[31:0]						o_ALU_result_r, o_ALU_result_w;
	reg 							o_overflow_r, o_overflow_w;
	reg 							o_branch_r, o_branch_w;
		

	assign		o_ALU_result 	= 	o_ALU_result_r;
	assign		o_branch 		=	o_branch_r; 
	assign		o_overflow   	=	o_overflow_r;
	assign		o_d_addr		=	o_ALU_result;	//seems two wire are equal 

	always @(*) begin
		o_overflow_w	=	1'b0;
		o_ALU_result_w	=	32'b0;
		o_branch_w		=	1'b0;

		case (i_ALU_operation)
			`OP_ADD:		begin
				{o_overflow_w, o_ALU_result_w}	=	{{1'b0},i_Read_data1}	+	{{1'b0},i_Read_data2};
			end
			`OP_SUB:		begin

				o_ALU_result_w	=	i_Read_data1	-	i_Read_data2;
				if (i_Read_data1	<	i_Read_data2) begin
					o_overflow_w	=	1'b1;
				end
				else
					o_overflow_w	=	1'b0;
				
				//{o_overflow_w, o_ALU_result_w}	=	{i_Read_data1	-	i_Read_data2};	
			end		 
			`OP_ADDI:	begin
				{o_overflow_w, o_ALU_result_w}	=	{{1'b0},i_Read_data1}	+	{{1'b0},i_Read_data2};
			end
			`OP_LW:		begin
				{o_overflow_w, o_ALU_result_w}	=	{{1'b0},i_Read_data1}	+	{{1'b0},i_Read_data2};
				if (o_ALU_result_w[31:8]	!= 24'b0) begin
					o_overflow_w	=	1'b1;	//data memory overflow
				end
				else
					o_overflow_w	=	1'b0;
			end
			`OP_SW:		begin
				{o_overflow_w, o_ALU_result_w}	=	{{1'b0},i_Read_data1}	+	{{1'b0},i_Read_data2};
				if (o_ALU_result_w[31:8]	!= 24'b0) begin
					o_overflow_w	=	1'b1;	//data memory overflow
				end
				else
					o_overflow_w	=	1'b0;
			end
			`OP_AND:		begin
				o_ALU_result_w	=	i_Read_data1	&	i_Read_data2;
			end
			`OP_OR:		begin
				o_ALU_result_w	=	i_Read_data1	|	i_Read_data2;
			end
			`OP_NOR:		begin
				o_ALU_result_w	=	~(i_Read_data1	|	i_Read_data2);
			end
			`OP_BEQ:		begin
				if (i_Read_data1	==	i_Read_data2) begin
					o_branch_w	=	1'b1;
				end
				else
					o_branch_w	=	1'b0;
			end
			`OP_BNE:		begin
				if (i_Read_data1	!=	i_Read_data2) begin
					o_branch_w	=	1'b1;
				end
				else
					o_branch_w	=	1'b0;
			end
			`OP_SLT:		begin
				if (i_Read_data1	<	i_Read_data2) begin
					o_ALU_result_w	=	32'b1;
				end
				else
					o_ALU_result_w	=	32'b0;	
			end
			
			default: begin
				o_overflow_w	=	1'b0;
				o_ALU_result_w	=	32'b0;
				o_branch_w		=	1'b0;
			end
		endcase
	end

	always@(posedge i_clk or negedge i_rst_n) begin //SEQUENTIAL PART : CURRENT　STATE
		if(!i_rst_n) begin
			o_ALU_result_r 	<= 32'b0;
			o_overflow_r   	<= 1'b0;
			o_branch_r	   	<= 1'b0;
			//PC_valid_r <= 1'b0;
		end
		else begin
			o_ALU_result_r 	<= 	o_ALU_result_w;
			o_overflow_r   	<= 	o_overflow_w;
			o_branch_r		<=	o_branch_w;
		end
	end

endmodule

module RegisterFile (
	input							i_rst_n,
	input							i_clk,
	input[ 31 : 0 ] 				i_i_inst,	//from instruction memory
	input							RegWrite,	//from controller (determine whether write register)
	input[31:0]						i_d_rdata,	//from data memory
	input[31:0]						i_ALU_result,//from alu 
	input							MemtoReg,	//from controller	(determine write data come from mem or alu)
	input							i_ALUSrc,		//from controller (determine whether im or not)	seems to NOT qual to the i_RegDst
	input							i_RegDst,	//from controller (determine whether im or not)
	//input[31:0]						Write_data, //from ALU	
	//output[31:0]					o_d_addr,	//to data memory(write addres)
	output[31:0]					o_d_wdata,	//to data memory(write data)
	output[31:0]					Read_data1,
	output[31:0]					Read_data2
	//output							o_d_wen shoud be put in controller
);

reg [31:0]	Register_r	[0:31];
reg [31:0]	Register_w	[0:31];
reg [31:0]	o_d_wdata_r, o_d_wdata_w;
reg [31:0]	Read_data1_r, Read_data1_w;
reg [31:0]	Read_data2_r, Read_data2_w;
reg [31:0]	Write_data;
reg [4:0]	Write_register;
integer i;

assign		o_d_wdata = o_d_wdata_r;
assign		Read_data1 = Read_data1_r;
assign		Read_data2 = Read_data2_r;

always @(*) begin
	Read_data1_w 	=	Register_r[ i_i_inst[25:21]	];
	o_d_wdata_w		=	Register_r[ i_i_inst[20:16]	];		//for write datamem, seems not equal to Read_data1 !!!!!!!!!!!!!!
	/*
	if (ALUSrc == 1'b0) begin	//no im
		Read_data2_w = Register_r[ i_i_inst[20:16] ];					//output
	end
	else begin	//IM -> sign extension
		Read_data2_w = { { 16{1'b0} },i_i_inst[15:0] };					//output
	end
	*/
	if (i_ALUSrc	== 	1'b0) begin
		Read_data2_w = Register_r[ i_i_inst[20:16] ];					//output	ALUSrc 1'b0, not sign extend
	end
	else	begin
		Read_data2_w = { { 16{1'b0} },i_i_inst[15:0] };					//output
	end
	if (i_RegDst	== 	1'b0) begin
		Write_register =  i_i_inst[15:11];								//input write register(1'b0	=> Rtype)
	end
	else	begin
		Write_register =  i_i_inst[20:16];								//input write register
	end

	if (MemtoReg == 1'b1) begin
		Write_data = i_d_rdata;
	end
	else begin
		Write_data = i_ALU_result;
	end



	for ( i = 0 ; i < 32 ; i = i + 1) begin		//this line seems indispensable
		Register_w[i]	=	Register_r[i];
	end
	if (RegWrite == 1'b1) begin	//write register
		Register_w[ Write_register ] = Write_data;
	end
	else begin		//no write, do nothing
		Register_w[ Write_register ] = Register_r[ Write_register ] ;
	end

end


always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for ( i = 0 ; i < 32 ; i = i+1) begin
			Register_r[i] <= 32'b0; 
		end
		o_d_wdata_r 	<= 	32'b0;
		Read_data1_r 	<= 	32'b0;
		Read_data2_r 	<= 	32'b0;
		end

	else begin
		for ( i = 0 ; i < 32 ; i = i+1) begin
			Register_r[i] <= Register_w[i]; 
		end
		o_d_wdata_r 	<= 	o_d_wdata_w;
		Read_data1_r 	<= 	Read_data1_w;
		Read_data2_r 	<= 	Read_data2_w;
	end
end
	
endmodule


module PC (
	input               	    i_clk,
	input           	        i_rst_n,
	input						i_PC_valid,	//from controller
	input						i_PCSrc,	//from controller determine branch or not
	input						i_branch,	//from ALU
	//input[31:0]					i_PC_addFour, 
	input[31:0]					i_PC_im,	//from i_i_inst
	output[31:0] 				o_i_addr,
	output						o_PC_address_overflow		//to controller
);
	
	reg [31:0]					o_i_addr_r, o_i_addr_w;
	reg [31:0]					o_PC_address_overflow_r, o_PC_address_overflow_w;	
	wire[31:0]					i_PC_addFour;				

	assign		o_i_addr = o_i_addr_r;		
	assign 		i_PC_addFour = o_i_addr_r + 4;
	assign		o_PC_address_overflow	=	o_PC_address_overflow_r;
	always @(*) begin

		//i_PC_addFour = o_i_addr_r + 4; 
		if(i_PC_valid == 1'b0) begin
			o_i_addr_w = o_i_addr_r;
		end

		else begin
			if (i_PCSrc == 1'b1 && i_branch == 1'b1) begin
				o_i_addr_w = i_PC_addFour	+	i_PC_im;
			end
			else begin
				o_i_addr_w = i_PC_addFour;
			end
			if (o_i_addr_w[31:12]	!= 20'b0) begin
				o_PC_address_overflow_w	=	1'b1;		//instruction overflow
			end
			else
				o_PC_address_overflow_w	=	1'b0;
			
		end
		
	end

	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			o_i_addr_r <= 32'b1111_1111_1111_1111_1111_1111_1111_1100;
			o_PC_address_overflow_r	<=	1'b0;
		end

		else begin
			o_i_addr_r <= o_i_addr_w;
			o_PC_address_overflow_r	<=	o_PC_address_overflow_w;
		end
		
	end

endmodule

module Controller(
	input                   i_clk,
	input                   i_rst_n,
	input	[5:0]			i_i_inst_opcode,
	input					i_PC_address_overflow,
	input					i_alu_overflow,
	output					o_PC_valid,			//TO PC
	output					o_status_valid,
	output					[1:0] o_status,
	output					PCSrc,
	output[5:0]				o_ALU_operation,
	output					o_RegDst,		//To RegisterFile (determine whether im or not)
	output					o_d_wen,
	output					o_MemtoReg,
	output					o_RegWrite,
	output					o_ALUSrc		//1'b1 if use sign extended
);
	parameter S_reset = 5'd31;
	parameter S_i_start = 5'd5;
	parameter S_wait1 = 5'd6;
	parameter S_wait2 = 5'd7;
	parameter S_WriteAndOverflow = 5'd8;
	parameter S_wait3 =	5'd9;
	parameter S_i_finish = 5'd10;
	parameter S_i_finish_wait1 = 5'd11;
	parameter S_i_finish_wait2 = 5'd12;
	parameter S_i_finish_wait3 = 5'd13;
	//reset wait??
	parameter S_reset_wait1 = 5'd30;
	parameter S_reset_wait2 = 5'd29;
	parameter S_reset_wait3 = 5'd28;
	//pc_valid_start
	parameter S_pc_valid_start = 5'd1;
	parameter S_pc_valid_start_wait1 = 5'd2;
	parameter S_pc_valid_start_wait2 = 5'd3;
	parameter S_pc_valid_start_wait3 = 5'd4;
	//end processing
	parameter S_end_processing = 5'd27;

	reg 		PC_valid_r, PC_valid_w;
	reg 		status_valid_r, status_valid_w;
	reg [4:0] 	next_state, current_state;
	reg [1:0] 	status_r, status_w;
	reg 		PCSrc_r, PCSrc_w;
	reg [3:0]	o_ALU_operation_r,	o_ALU_operation_w;
	reg 		RegDst_r,	RegDst_w;
	reg 		d_wen_r,	d_wen_w;
	reg 		MemtoReg_r,	MemtoReg_w;		
	reg 		RegWrite_r,	RegWrite_w;	
	reg 		ALUSrc_r,	ALUSrc_w;	

	assign	o_PC_valid		=	PC_valid_r;
	assign	o_status_valid	=	status_valid_r;
	assign	o_status		=	status_r;	
	assign	PCSrc			=	PCSrc_r;
	assign	o_ALU_operation	=	o_ALU_operation_r;
	assign	o_RegDst		=	RegDst_r;
	assign	o_d_wen			=	d_wen_r;
	assign	o_MemtoReg		=	MemtoReg_r;
	assign	o_RegWrite		=	RegWrite_r;
	assign	o_ALUSrc		=	ALUSrc_r;

	always @(*) begin		//OUTPUT LOGIC
		//Program Counter
		PC_valid_w 	= 	PC_valid_r;	
		/////output status
		status_valid_w	=	status_valid_r;
		status_w		=	status_r;
		/////Control signal
		PCSrc_w		=	PCSrc_r;
		RegDst_w	=	RegDst_r;
		PCSrc_w		=	PCSrc_r;
		d_wen_w		=	d_wen_r;
		MemtoReg_w	=	MemtoReg_r;
		RegWrite_w	=	RegWrite_r;
		ALUSrc_w	=	ALUSrc_r;

		case (current_state)
			S_reset: begin
				PC_valid_w = 1'b0;	
				/////output status
				status_w	=	`R_TYPE_SUCCESS;
				status_valid_w = 1'b0;
				/////Control signal
				PCSrc_w		=	1'b0;
				RegDst_w	=	1'b0;
				PCSrc_w		=	1'b0;
				d_wen_w		=	1'b0;
				MemtoReg_w	=	1'b0;
				RegWrite_w	=	1'b0;
				ALUSrc_w	=	1'b0;
			end 	
			S_reset_wait1:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_reset_wait2:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_reset_wait3:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_pc_valid_start:	begin
				PC_valid_w = 1'b1;
				status_valid_w = 1'b0;
				RegWrite_w	=	1'b0;
				d_wen_w		=	1'b0;
			end
			S_pc_valid_start_wait1:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_pc_valid_start_wait2:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_pc_valid_start_wait3:	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_i_start: 	begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
				case (i_i_inst_opcode)
				`OP_ADD:	begin
					o_ALU_operation_w	=	`OP_ADD;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_SUB:	begin
					o_ALU_operation_w	=	`OP_SUB;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_ADDI:	begin
					o_ALU_operation_w	=	`OP_ADDI;
					RegDst_w	=	1'b1;
					//RegWrite_w	=	1'b1;
					status_w	=	`I_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b1;
				end
				`OP_LW:		begin
					o_ALU_operation_w	=	`OP_LW;
					RegDst_w	=	1'b1;
					//d_wen_w		=	1'b0;
					MemtoReg_w	=	1'b1;
					//RegWrite_w	=	1'b1;
					status_w	=	`I_TYPE_SUCCESS;
					ALUSrc_w	=	1'b1;
				end
				`OP_SW:		begin
					o_ALU_operation_w	=	`OP_SW;
					RegDst_w	=	1'b1;
					//d_wen_w	=	1'b1;
					//RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b1;
				end
				`OP_AND:	begin
					o_ALU_operation_w	=	`OP_AND;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_OR:		begin
					o_ALU_operation_w	=	`OP_OR;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_NOR:	begin
					o_ALU_operation_w	=	`OP_NOR;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_BEQ:	begin
					o_ALU_operation_w	=	`OP_BEQ;
					PCSrc_w				=	1'b1;
					RegDst_w	=	1'b1;
					PCSrc_w		=	1'b1;
					//RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				
				`OP_BNE:	begin
					o_ALU_operation_w	=	`OP_BNE;
					PCSrc_w				=	1'b1;
					RegDst_w	=	1'b1;
					PCSrc_w		=	1'b1;
					//RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_SLT:	begin
					o_ALU_operation_w	=	`OP_SLT;
					RegDst_w	=	1'b0;
					//RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
					MemtoReg_w	=	1'b0;
					ALUSrc_w	=	1'b0;
				end
				`OP_EOF:	begin
					o_ALU_operation_w	=	`OP_EOF;
					status_w	=	`MIPS_END;
				end

				default: 
					o_ALU_operation_w	=	`OP_ADD;
				endcase
			end 
			S_wait1: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end	
			S_wait2: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end
			S_WriteAndOverflow: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
				case (i_i_inst_opcode)
				`OP_ADD:	begin
					o_ALU_operation_w	=	`OP_ADD;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_SUB:	begin
					o_ALU_operation_w	=	`OP_SUB;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_ADDI:	begin
					o_ALU_operation_w	=	`OP_ADDI;
					RegDst_w	=	1'b1;
					RegWrite_w	=	1'b1;
					status_w	=	`I_TYPE_SUCCESS;
				end
				`OP_LW:		begin
					o_ALU_operation_w	=	`OP_LW;
					RegDst_w	=	1'b1;
					d_wen_w		=	1'b0;
					MemtoReg_w	=	1'b1;
					RegWrite_w	=	1'b1;
					status_w	=	`I_TYPE_SUCCESS;
				end
				`OP_SW:		begin
					o_ALU_operation_w	=	`OP_SW;
					RegDst_w	=	1'b1;
					d_wen_w	=	1'b1;
					RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
				end
				`OP_AND:	begin
					o_ALU_operation_w	=	`OP_AND;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_OR:		begin
					o_ALU_operation_w	=	`OP_OR;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_NOR:	begin
					o_ALU_operation_w	=	`OP_NOR;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_BEQ:	begin
					o_ALU_operation_w	=	`OP_BEQ;
					PCSrc_w				=	1'b1;
					RegDst_w	=	1'b1;
					PCSrc_w		=	1'b1;
					RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
				end
				
				`OP_BNE:	begin
					o_ALU_operation_w	=	`OP_BNE;
					PCSrc_w				=	1'b1;
					RegDst_w	=	1'b1;
					PCSrc_w		=	1'b1;
					RegWrite_w	=	1'b0;
					status_w	=	`I_TYPE_SUCCESS;
				end
				`OP_SLT:	begin
					o_ALU_operation_w	=	`OP_SLT;
					RegDst_w	=	1'b0;
					RegWrite_w	=	1'b1;
					status_w	=	`R_TYPE_SUCCESS;
				end
				`OP_EOF:	begin
					o_ALU_operation_w	=	`OP_EOF;
					status_w	=	`MIPS_END;
				end

				default: 
					o_ALU_operation_w	=	`OP_ADD;
				endcase

				//overflow
				if (i_PC_address_overflow	==	1'b1 ||	i_alu_overflow	==	1'b1) 
					status_w	=	`MIPS_OVERFLOW;
				else
					status_w	=	status_r;
				
			end		
			S_wait3: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
				RegWrite_w	=	1'b0;	//to prevent double write
				d_wen_w	=	1'b0;

			end	
			S_i_finish: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b1;
			end
			S_i_finish_wait1: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end 
			S_i_finish_wait2: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end  
			S_i_finish_wait3: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end   
			S_i_finish_wait3: begin
				PC_valid_w = 1'b0;
				status_valid_w = 1'b0;
			end   
			S_end_processing: begin
				PC_valid_w	=	1'b0;
				status_valid_w = 1'b1;
				status_w	=	`MIPS_END;
			end
			default:	begin
				//Program Counter
				PC_valid_w 	= 	PC_valid_r;	
				/////output status
				status_valid_w	=	status_valid_r;
				status_w		=	status_r;
				/////Control signal
				PCSrc_w		=	PCSrc_r;
				RegDst_w	=	RegDst_r;
				PCSrc_w		=	PCSrc_r;
				d_wen_w		=	d_wen_r;
				MemtoReg_w	=	MemtoReg_r;
				RegWrite_w	=	RegWrite_r;
				ALUSrc_w	=	ALUSrc_r;
			end
		endcase
		
	end

	always @(*) begin		//NEXT STATE LOGIC
		case (current_state)
			S_reset: 			next_state 	= 	S_reset_wait1;
			S_reset_wait1:		next_state	=	S_reset_wait2;
			S_reset_wait2:		next_state	=	S_reset_wait3;
			S_reset_wait3:		next_state	=	S_pc_valid_start;
			S_pc_valid_start:	next_state	=	S_pc_valid_start_wait1;
			S_pc_valid_start_wait1: next_state	=	S_pc_valid_start_wait2;
			S_pc_valid_start_wait2: next_state	=	S_pc_valid_start_wait3;
			S_pc_valid_start_wait3: next_state	=	S_i_start;	
			S_i_start:	begin
				if (i_i_inst_opcode	!= `OP_EOF) 
					next_state 	= 	S_wait1;	
				else
					next_state 	= 	S_end_processing;
			end 			
			
			S_wait1: 			next_state 	= 	S_wait2;
			S_wait2: 			next_state 	= 	S_WriteAndOverflow;
			S_WriteAndOverflow: next_state 	= 	S_wait3;
			S_wait3: 			next_state 	= 	S_i_finish;
			S_i_finish: 		next_state 	= 	S_i_finish_wait1;
			S_i_finish_wait1:	next_state	=	S_i_finish_wait2;
			S_i_finish_wait2:	next_state	=	S_i_finish_wait3;
			S_i_finish_wait3:	next_state	=	S_pc_valid_start;
			S_end_processing:	next_state	=	S_end_processing;
		endcase
	end

	always@(posedge i_clk or negedge i_rst_n) begin //SEQUENTIAL PART : CURRENT　STATE
		if(!i_rst_n) begin
			current_state <= S_reset;
			PC_valid_r <= 1'b0;
		end
		
		else begin
			current_state 	<= next_state;
			////////////////one cycle latency 
			PC_valid_r 			<= 	PC_valid_w;
			status_valid_r 		<= 	status_valid_w;
			status_r			<=	status_w;
			PCSrc_r 			<= 	PCSrc_w;
			o_ALU_operation_r	<=	o_ALU_operation_w;
			RegDst_r			<=	RegDst_w;
			d_wen_r				<=	d_wen_w;
			MemtoReg_r			<=	MemtoReg_w;
			RegWrite_r			<=	RegWrite_w;
			ALUSrc_r			<=	ALUSrc_w;
			
		end

	end
endmodule