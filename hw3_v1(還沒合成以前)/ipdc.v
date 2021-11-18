`define IMAGE_LOADING  	4'b0000
`define SHIFT_RIGHT  	4'b0100
`define SHIFT_LEFT  	4'b0101
`define SHIFT_UP  		4'b0110
`define SHIFT_DOWN  	4'b0111
`define SCALE_DOWN		4'b1000
`define SCALE_UP		4'b1001
`define YCBCR			4'b1101
`define CENSUS			4'b1110
`define MEDIAN			4'b1100

`define FROM_MEM  		2'b11
`define FROM_YCBCR 		2'b10
`define FROM_CENSUS		2'b01
`define FROM_MEDIAN		2'b00


module ipdc (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [23:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [23:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
//MEM
wire [7:0]	mem_Q_R, mem_Q_G, mem_Q_B; 
wire [7:0]	mem_D_R, mem_D_G, mem_D_B; 
wire mem_WEN, mem_CEN;
wire [7:0]	mem_A;
//Display
wire [1:0] scale;
wire [7:0] origin;
//for filter
wire 	 	center;
wire 		padding;
//wire		filter_valid;	seemed reduntant
//output data from YCbCr
wire [23:0]	w_YCbCr;
wire [23:0]	w_CENSUS;
wire [23:0]	w_MEDIAN;
//output mux src
wire [1:0]	out_data_src;
//output data
reg  [23:0] o_out_data_r, o_out_data_w;
wire 		median_reset;	



// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign	o_out_data	=	o_out_data_r;
//MEM
assign	mem_D_R		=	i_in_data[23:16];
assign	mem_D_G		=	i_in_data[15: 8];	
assign	mem_D_B		=	i_in_data[ 7: 0];


sram_256x8 mem_R(.Q(mem_Q_R),	.CLK(i_clk),	.CEN(mem_CEN),	.WEN(mem_WEN),	.A(mem_A),	.D(mem_D_R)); 
sram_256x8 mem_G(.Q(mem_Q_G),	.CLK(i_clk),	.CEN(mem_CEN),	.WEN(mem_WEN),	.A(mem_A),	.D(mem_D_G));  
sram_256x8 mem_B(.Q(mem_Q_B),	.CLK(i_clk),	.CEN(mem_CEN),	.WEN(mem_WEN),	.A(mem_A),	.D(mem_D_B));  

YCbCr	ALU_YCbCr(	.i_data_R(mem_Q_R),
					.i_data_G(mem_Q_G),
					.i_data_B(mem_Q_B),
					.o_data_YCbCr(w_YCbCr)
				);
FSM	controller(	.i_clk(i_clk),
				.i_rst_n(i_rst_n),
				//operation
				.i_op_valid(i_op_valid),
				.i_op_mode(i_op_mode),
				.o_op_ready(o_op_ready),
				//output valid
				.o_out_valid(o_out_valid),
				//load Image
				.i_in_valid(i_in_valid),
				.o_in_ready(o_in_ready),
				//for filter
				.o_padding(padding),
				//for MEM
				.o_mem_Addr(mem_A),
				.o_mem_WEN(mem_WEN),
				.o_mem_CEN(mem_CEN),
				//for output MUX
				.o_out_data_src(out_data_src),
				//.o_filter_valid(filter_valid),
				.o_median_reset(median_reset),
				.o_center(center)
				);
CENSUS	ALU_CENSUS(	.i_clk(i_clk),
					.i_rst_n(i_rst_n),
					.i_data({mem_Q_R, mem_Q_G, mem_Q_B}),
					.i_center(center),
					.i_padding(padding),
					.o_data(w_CENSUS)
				  );

MEDIAN	ALU_MEDIAN(
					.i_clk(i_clk),
					.i_rst_n(i_rst_n),
					.i_data({mem_Q_R, mem_Q_G, mem_Q_B}),
					//.i_filter_valid(filter_valid),
					.i_median_reset(median_reset),
					.i_padding(padding),
					.o_data(w_MEDIAN)
				  );


// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*) begin
	case (out_data_src)
	`FROM_MEM:		o_out_data_w	=	{mem_Q_R, mem_Q_G, mem_Q_B};	
	`FROM_YCBCR: 	o_out_data_w	=	w_YCbCr;
	`FROM_CENSUS:	o_out_data_w	=	w_CENSUS;
	`FROM_MEDIAN:	o_out_data_w	=	w_MEDIAN;
	default: 		o_out_data_w	=	0;
	endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
	always@(posedge i_clk or negedge i_rst_n) begin //SEQUENTIAL PART 
		if(!i_rst_n) begin
			o_out_data_r	<= 0;

		end

		else begin
			o_out_data_r	<=	o_out_data_w;
		end
	end	
endmodule


module FSM (
	input           i_clk,
	input           i_rst_n,
	//operation
	input			i_op_valid,
	input	[ 3:0]	i_op_mode,
	output			o_op_ready,
	//output valid
	output			o_out_valid,

	//load image
	input			i_in_valid,
	output			o_in_ready,

	//display
	output	 			o_padding,
	//to MEM
	output 	reg[7:0]	o_mem_Addr,
	output	reg			o_mem_WEN,
	output	reg			o_mem_CEN,
	//output mux
	output 	reg [1:0]	o_out_data_src,
	//for filter
	//output 				o_filter_valid,
	output	reg			o_median_reset,
	output				o_center
	


	
);
	localparam S_reset 			= 7'd0 ;
	localparam S_start 			= 7'd1 ;
	localparam S_start_wait 	= 7'd2 ;

	//localparam S_idle = 7'd3;	//to prevent out_valid and op_ready high  in the same time 
	//Load Image
	localparam S_loading 		= 7'd4 ;
	//display image size
	//display 4x4
	localparam S_displayFour_readMem = 7'd5 ;
	localparam S_displayFour_wait = 7'd6 ;
	//display 2x2
	localparam S_displayTwo_readMem = 7'd7 ;
	localparam S_displayTwo_wait = 7'd8 ;
	//display 1x1
	localparam S_displayOne_readMem = 7'd9 ;
	localparam S_displayOne_wait = 7'd10 ;
	//filter
	localparam S_filter_read1 =	 7'd11;
	localparam S_filter_read2 =	 7'd12;
	localparam S_filter_read3 =	 7'd13;
	localparam S_filter_read4 =	 7'd14;
	localparam S_filter_read6 =	 7'd15;
	localparam S_filter_read7 =	 7'd16;
	localparam S_filter_read8 =	 7'd17;
	localparam S_filter_read9 =	 7'd18;
	localparam S_filter_wait  =	 7'd19;


	//display image size (not state)
	localparam displaySizeFour 		= 2'd0;	//1
	localparam displaySizeTwo	 	= 2'd1;	//2
	localparam displaySizeOne		= 2'd2;	//4
	

	reg [4:0] 	next_state, current_state;
	//for loadImgae
	reg [7:0]	counter_r, counter_w;
	//for display 4x4
	reg [2:0]	counter_i_r,	counter_i_w;
	reg [2:0]	counter_j_r,	counter_j_w;

	//output register
	reg		o_op_ready_r, o_op_ready_w;
	reg		o_out_valid_r, o_out_valid_w;
	reg 	o_in_ready_r, o_in_ready_w;	
	//for 4x4 display size
	reg [3:0]	origin_x,	origin_y;
	//display
	
	reg	[2:0]		s_scale_r, s_scale_w;
	reg	[7:0]		s_origin_r, s_origin_w;
	reg	[7:0]		s_center_addr_r, s_center_addr_w;
	reg				o_center_r,	o_center_w;
	
	//filter
	reg	 		o_padding_r, o_padding_w;	//to prevent critical path
	//reg			o_filter_valid_r,	o_filter_valid_w;
	//store inst
	reg [1:0]		s_op_mode_r,	s_op_mode_w;

	//for padding calculate
	reg [3:0]		center_x,	center_y;
	reg [2:0]		center_sizeTwo_x,	center_sizeTwo_y;
	reg [1:0]		center_sizeOne_x,	center_sizeOne_y;
	
	//for op and load
	assign		o_op_ready	=	o_op_ready_r;
	assign		o_out_valid	=	o_out_valid_r;
	assign 		o_in_ready	=	o_in_ready_r;	
	// for filter
	//assign		o_filter_valid	=	o_filter_valid_r;
	assign		o_center		=	o_center_r;
	assign		o_padding		=	o_padding_r;

	always @(*) begin		//NEXT STATE LOGIC
		//for load Imgae
		counter_w		=	counter_r;
		//for display 4x4
		counter_i_w		=	counter_i_r;
		counter_j_w		=	counter_j_r;

		s_scale_w		=	s_scale_r;
		s_origin_w		=	s_origin_r;
		s_center_addr_w	=	s_center_addr_r;
		//origin (equal to center size Four)
		origin_x		=	s_origin_r[3:0];		//o_origin % 16;
		origin_y		=	s_origin_r >> 4;

		

		//o_padding		=	0;
		//for store inst state
		s_op_mode_w		=	s_op_mode_r;
		
		case (current_state) 
			S_reset:	begin
				next_state 		= 	S_start;
				//for load Imgae
				counter_w 		= 	0;
				//for display 4x4
				counter_i_w		=	0;
				counter_j_w		=	0;

				s_scale_r		=	displaySizeFour;
				s_origin_r		=	0;
				s_center_addr_r		=	0;
				//for store inst state
				s_op_mode_r		=	0;

			end
			S_start:begin
				counter_w = 0;
				next_state	=	S_start_wait;
			end
				
			S_start_wait: 	begin	
				//for 4x4 display size	//put this block into the beginning of  the always block
				//origin_x	=	s_origin_r[3:0];		//o_origin % 16;
				//origin_y	=	s_origin_r >> 4;
				//counter for display
				counter_i_w	=	0;
				counter_j_w	=	0;
				//counter for load image
				counter_w = 0;

				if (i_op_valid == 1'b0) 
					next_state	=	S_start_wait;
				else	begin
					case (i_op_mode)
					`IMAGE_LOADING : next_state 	= 	S_loading;	
					`SHIFT_DOWN	: begin
						s_op_mode_w	=	`FROM_MEM;
						if (s_scale_r == displaySizeFour) begin
							if ( origin_y >= 12) //divide 16
								s_origin_w	=	s_origin_r;
							else
								s_origin_w	=	s_origin_r + 16;
							next_state	=	S_displayFour_readMem;
						end
						if (s_scale_r == displaySizeTwo) begin
							next_state	=	S_displayTwo_readMem;
							if (origin_y >= 12) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r + 32; 
							
						end
						if (s_scale_r == displaySizeOne) begin
							next_state	=	S_displayOne_readMem;
							if (origin_y >= 12) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r + 64; 
							
						end
					end
					`SHIFT_LEFT: begin
						s_op_mode_w	=	`FROM_MEM;
						if (s_scale_r == displaySizeFour) begin
							if ( origin_x == 0) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 1;
							next_state	=	S_displayFour_readMem;
						end
						if (s_scale_r == displaySizeTwo) begin
							next_state	=	S_displayTwo_readMem;
							if (origin_x <= 1) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 2;
							
						end
						if (s_scale_r == displaySizeOne) begin
							next_state	=	S_displayOne_readMem;
							if (origin_x <= 3) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 4;
							
						end
					end
					`SHIFT_UP: begin
						s_op_mode_w	=	`FROM_MEM;
						if (s_scale_r == displaySizeFour) begin
							if ( origin_y == 0) //divide 16
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 16;
							next_state	=	S_displayFour_readMem;
						end
						if (s_scale_r == displaySizeTwo) begin
							next_state	=	S_displayTwo_readMem;
							if (origin_y <= 1) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 32;
							
						end
						if (s_scale_r == displaySizeOne) begin
							next_state	=	S_displayOne_readMem;
							if (origin_y <= 3) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r - 64;
							
						end
					end
					`SHIFT_RIGHT: begin
						s_op_mode_w	=	`FROM_MEM;
						if (s_scale_r == displaySizeFour) begin
							if ( origin_x >= 12) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r + 1;
							next_state	=	S_displayFour_readMem;
						end
						if (s_scale_r == displaySizeTwo) begin
							next_state	=	S_displayTwo_readMem;
							if (origin_x >= 12) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r + 2; 
							
						end
						if (s_scale_r == displaySizeOne) begin
							next_state	=	S_displayOne_readMem;
							if (origin_x >= 12) 
								s_origin_w = s_origin_r;
							else
								s_origin_w = s_origin_r + 4;
							
						end
					end

					`SCALE_DOWN: begin
						s_op_mode_w	=	`FROM_MEM;
						case (s_scale_r)
							displaySizeFour:  begin
								s_scale_w	=	displaySizeTwo;
								next_state	=	S_displayTwo_readMem;
							end
							displaySizeTwo:  begin
								s_scale_w	=	displaySizeOne;
								next_state	=	S_displayOne_readMem;
							end
							displaySizeOne:  begin
								s_scale_w	=	displaySizeOne;
								next_state	=	S_displayOne_readMem;
							end

							default: begin
								s_scale_w	=	s_scale_r;
								next_state	=	S_displayFour_readMem;
							end
						endcase
					end
					`SCALE_UP: begin
						s_op_mode_w	=	`FROM_MEM;
						case (s_scale_r)
							displaySizeFour: begin
								s_scale_w	=	displaySizeFour;
								next_state	=	S_displayFour_readMem;
							end
							displaySizeTwo: begin
								if (origin_x == 13 || origin_y == 13) begin	//stock into right or bottom
									s_scale_w	=	displaySizeTwo;
									next_state	=	S_displayTwo_readMem;
								end
								else begin
									s_scale_w	=	displaySizeFour;
									next_state	=	S_displayFour_readMem;
								end
							end
							displaySizeOne: begin
								if (origin_x == 14 || origin_y == 14) begin	//stock into right or bottom
									s_scale_w	=	displaySizeOne;
									next_state	=	S_displayOne_readMem;
								end
								else begin
									s_scale_w	=	displaySizeTwo;
									next_state	=	S_displayTwo_readMem;
								end
							end
							default: begin
								s_scale_w	=	s_scale_r;
								next_state	=	S_displayFour_readMem;
							end
						endcase
					end

					`YCBCR: begin
						s_op_mode_w	=	`FROM_YCBCR;
						case (s_scale_r)
							displaySizeFour: 
								next_state	=	S_displayFour_readMem;
							displaySizeTwo:
								next_state	=	S_displayTwo_readMem; 
							displaySizeOne:
								next_state	=	S_displayOne_readMem;
							default:
								next_state	=	S_start; 
						endcase
					end

					`CENSUS: begin
						s_op_mode_w	=	`FROM_CENSUS;
						case (s_scale_r)
							displaySizeFour: 
								next_state	=	S_displayFour_readMem;
							displaySizeTwo:
								next_state	=	S_displayTwo_readMem; 
							displaySizeOne:
								next_state	=	S_displayOne_readMem;
							default:
								next_state	=	S_start; 
						endcase
					end
					`MEDIAN: begin
						s_op_mode_w	=	`FROM_MEDIAN;
						case (s_scale_r)
							displaySizeFour: 
								next_state	=	S_displayFour_readMem;
							displaySizeTwo:
								next_state	=	S_displayTwo_readMem; 
							displaySizeOne:
								next_state	=	S_displayOne_readMem;
							default:
								next_state	=	S_start; 
						endcase
					end

					default: 
						next_state 	= 	S_start;
					endcase
					
				end
			end
				
				
				
				
				
	
			S_loading: begin
				
				if (counter_w == 8'd255) begin
					next_state	=	S_start;
				end
				else begin
					counter_w	=	counter_r + 1;
					next_state	=	S_loading;
				end
			end

			//display 4x4
			S_displayFour_readMem: begin
				s_center_addr_w	=	s_origin_r + {counter_i_r[1:0], 2'b0 ,counter_j_r[1:0]};//addr = origin + 16*i + j
				counter_j_w		=	counter_j_r + 1;
				if (s_op_mode_r	==	`FROM_CENSUS || s_op_mode_r == `FROM_MEDIAN ) 
					next_state	=	S_filter_read1;
				else
					next_state	=	S_displayFour_wait;
			end
			S_displayFour_wait: begin
				if (counter_j_r != 4) begin	//not 3 cause previous cycle have add 1
					counter_i_w	=	counter_i_r;
					counter_j_w	=	counter_j_r;
				end
				else	begin
					counter_j_w	=	0;
					counter_i_w	=	counter_i_r	+	1;
				end

				if (counter_i_w	==	4) begin
					next_state	=	S_start;
				end
				else
					next_state	=	S_displayFour_readMem;
			end

			//display 2x2
			S_displayTwo_readMem: begin
				s_center_addr_w	=	s_origin_r + {counter_i_r[0], 3'b0, counter_j_r[0], 1'b0};//origin + 2*j + 16*2*i, i j in range  [0, 1]
				counter_j_w		=	counter_j_r + 1;
				if (s_op_mode_r	==	`FROM_CENSUS || s_op_mode_r == `FROM_MEDIAN ) 
					next_state	=	S_filter_read1;
				else
					next_state	=	S_displayTwo_wait;
			end
			S_displayTwo_wait: begin
				if (counter_j_r != 2) begin
					counter_i_w	=	counter_i_r;
					counter_j_r	=	counter_j_r;
				end
				else	begin
					counter_j_w	=	0;
					counter_i_w	=	counter_i_r	+	1;
				end

				if (counter_i_w	==	2) begin
					next_state	=	S_start;
				end
				else
					next_state	=	S_displayTwo_readMem;
			end
			//display 1x1
			S_displayOne_readMem: begin
				s_center_addr_w	=	s_origin_r;
				if (s_op_mode_r	==	`FROM_CENSUS || s_op_mode_r == `FROM_MEDIAN ) 
					next_state	=	S_filter_read1;
				else
					next_state	=	S_displayOne_wait;
			end
			S_displayOne_wait: begin
				next_state	=	S_start;
			end

			S_filter_read1: 
				next_state	=	S_filter_read2;
			S_filter_read2: 
				next_state	=	S_filter_read3;
			S_filter_read3: 
				next_state	=	S_filter_read4;
			S_filter_read4: 
				next_state	=	S_filter_read6;
			S_filter_read6: 
				next_state	=	S_filter_read7;
			S_filter_read7: 
				next_state	=	S_filter_read8;
			S_filter_read8: 
				next_state	=	S_filter_read9;
			S_filter_read9:
				next_state	=	S_filter_wait;
			S_filter_wait: begin
				if (s_scale_r == displaySizeFour )
					next_state	=	S_displayFour_wait;

				else if (s_scale_r == displaySizeTwo )
					next_state	=	S_displayTwo_wait;

				else if (s_scale_r == displaySizeOne )
					next_state	=	S_displayOne_wait;
				else
					next_state	=	S_start;
			end

		
		endcase
	end
	always @(*) begin		//OUTPUT LOGIC
		o_op_ready_w	=	0;
		o_out_valid_w	=	0;
		o_in_ready_w	=	1;
		
		//mem
		o_mem_CEN	=	1'b0;	//enable
		o_mem_WEN	=	1'b1;	//read
		o_mem_Addr		=	256'd0;

		//output mux
		o_out_data_src	=	0;
		//filter
		//o_filter_valid_w =	0;
		o_median_reset	=	0;
		o_padding_w		=	0;
		o_center_w		=	0; 

		//for padding calculate
		center_x		=	s_center_addr_r[3:0];	
		center_y		=	s_center_addr_r >> 4;
		//center SizeTwo origin
		center_sizeTwo_x =	center_x[3:1];		//center_x / 2;
		center_sizeTwo_y =	center_y[3:1];		//center_y / 2;
		//center SizeOne center
		center_sizeOne_x =	center_x[3:2];		//center_x / 4;
		center_sizeOne_y =	center_y[3:2];		//center_y / 4;

		case (current_state)
			S_reset: begin
				o_op_ready_r	=	0;
				o_out_valid_r	=	0;
				o_in_ready_r	=	1;
				o_padding_r		=	0;
				
				//mem
				o_mem_CEN		=	1'b0;	//enable
				o_mem_WEN		=	1'b1;	//read
				o_mem_Addr		=	256'd0;

				//output mux
				o_out_data_src	=	0;
				//for filter
				//o_filter_valid_r =	0; 
				o_center_r		=	0;
				o_median_reset	=	0;
			end 
			S_start: begin
				o_op_ready_w	= 	1;
				o_out_valid_w	=	0;
			end
			S_start_wait: begin
				o_op_ready_w = 0;
			end

			S_loading:	begin
				o_in_ready_w = 1;
				o_mem_WEN	=	1'b0;
				o_mem_CEN	=	1'b0;	//enable
				o_mem_Addr	=	counter_r;
			end

			// shift

			//display 4x4
			S_displayFour_readMem: begin
				o_out_valid_w	=	0;
				o_median_reset	=	1;
				//o_mem_Addr	=	s_origin_r + {counter_i_r[1:0], 2'b0 ,counter_j_r[1:0]};//addr = origin + 16*i + j
				o_mem_Addr		=	s_center_addr_w;	//w -> direct output, not delay one cycle

				o_center_w			=	1;
				/*
				if (s_op_mode_r == `FROM_MEDIAN ) 	//maybe don't need if statement
					o_filter_valid_w	=	1;
				else
					o_filter_valid_w	=	0;
				if (s_op_mode_r	==	`FROM_CENSUS) 
					o_center_w			=	1;
				else
					o_center_w			=	0;
				*/
				
			end
			S_displayFour_wait: begin
				o_out_valid_w	=	1;
				o_out_data_src	=	s_op_mode_r;
			end
			//display 2x2
			S_displayTwo_readMem: begin
				o_out_valid_w	=	0;
				o_median_reset	=	1;
				//move following line to next state block
				//o_mem_Addr	=	s_origin_r + {counter_i_r[0], 3'b0, counter_j_r[0], 1'b0};//origin + 2*j + 16*2*i, i j in range  [0, 1]
				o_mem_Addr		=	s_center_addr_w;	//w -> direct output, not delay one cycle

				o_center_w			=	1;
				/*
				if (s_op_mode_r == `FROM_MEDIAN ) 	//maybe don't need if statement
					o_filter_valid_w	=	1;
				else
					o_filter_valid_w	=	0;
				if (s_op_mode_r	==	`FROM_CENSUS) 
					o_center_w			=	1;
				else
					o_center_w			=	0;
				*/
			end
			S_displayTwo_wait: begin
				o_out_valid_w	=	1;
				o_out_data_src	=	s_op_mode_r;
			end
			//display 1x1
			S_displayOne_readMem: begin
				o_out_valid_w	=	0;
				o_median_reset	=	1;
				o_mem_Addr	=	s_origin_r;

				o_center_w			=	1;
				/*
				if (s_op_mode_r == `FROM_MEDIAN ) 	//maybe don't need if statement
					o_filter_valid_w	=	1;
				else
					o_filter_valid_w	=	0;
				if (s_op_mode_r	==	`FROM_CENSUS) 
					o_center_w			=	1;
				else
					o_center_w			=	0;
				*/
			end
			S_displayOne_wait: begin
				o_out_valid_w	=	1;
				o_out_data_src	=	s_op_mode_r;
			end

			S_filter_read1: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r - (1 << s_scale_r) - (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 0 || center_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 0 || center_sizeTwo_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 0 || center_sizeOne_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
					
				
			end
			S_filter_read2: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r - (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read3: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r + (1 << s_scale_r) - (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 15 || center_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 7 || center_sizeTwo_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 3 || center_sizeOne_y == 0)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read4: begin
				//_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r - (1 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 0 )
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 0 )
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 0 )
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read6: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r + (1 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 15)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 7)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 3)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read7: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r - (1 << s_scale_r) + (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 0 || center_y == 15)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 0 || center_sizeTwo_y == 7)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 0 || center_sizeOne_y == 3)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read8: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r + (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_y == 15)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_y == 7)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_y == 3)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			S_filter_read9: begin
				//o_filter_valid_w	=	1;
				o_mem_Addr			=	s_center_addr_r + (1 << s_scale_r) + (16 << s_scale_r);
				if (s_scale_r	==	displaySizeFour) begin
					if (center_x == 15 || center_y == 15)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end 
				else if (s_scale_r	==	displaySizeTwo) begin
					if (center_sizeTwo_x == 7 || center_sizeTwo_y == 7)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else if (s_scale_r	==	displaySizeOne) begin
					if (center_sizeOne_x == 3 || center_sizeOne_y == 3)
						o_padding_w	=	1;
					else
						o_padding_w = 	0;
				end
				else
					o_padding_w = 	0;
			end
			
				
			S_filter_wait: begin
				//o_filter_valid_w =	0;
			end
			
			default: begin
				o_op_ready_r	=	0;
				o_out_valid_r	=	0;
				o_in_ready_r	=	0;
				//display state

				//filter
				o_padding_r		=	0;
				//o_filter_valid_r =	0;
				//mem
				o_mem_CEN		=	1'b0;	//enable
				o_mem_WEN		=	1'b1;	//read
				o_mem_Addr		=	256'd0;
			end
		endcase
	end

	always@(posedge i_clk or negedge i_rst_n) begin //SEQUENTIAL PART 
		if(!i_rst_n) begin
			current_state <= S_reset;
			counter_r	<= 0;
			//for origin state
			s_scale_r		<=	displaySizeFour;
			s_origin_r		<=	0;
			s_center_addr_r		<=	0;
			//store inst state
			s_op_mode_r		<=	0;


		end

		else begin
			current_state 	<= 	next_state;
			//for origin state
			s_scale_r		<=	s_scale_w;
			s_origin_r		<=	s_origin_w;
			s_center_addr_r		<=	s_center_addr_w;
			//for load Imgae
			counter_r		<= 	counter_w;
			//for display 4x4
			counter_i_r		<=	counter_i_w;
			counter_j_r		<=	counter_j_w;
			//output register
			o_op_ready_r	<=	o_op_ready_w;
			o_out_valid_r	<=	o_out_valid_w;
			o_in_ready_r	<=	o_in_ready_w;	
			//display
			o_padding_r		<=	o_padding_w;
			//store inst state
			s_op_mode_r		<=	s_op_mode_w;
			//filter
			//o_filter_valid_r <=	o_filter_valid_w;
			o_center_r		<=	o_center_w;
			
		end
	end
	
endmodule

