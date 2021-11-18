module alu (
    input               i_clk,
    input               i_rst_n,
    input               i_valid,
    input signed [11:0] i_data_a,
    input signed [11:0] i_data_b,
    input        [2:0]  i_inst,
    output              o_valid,
    output       [11:0] o_data,
    output              o_overflow
);
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  [11:0] o_data_w, o_data_r;
reg         o_valid_w, o_valid_r;
reg         o_overflow_w, o_overflow_r;
// ---- Add your own wires and registers here if needed ---- //
//for add and subtraction
reg carry_add, o_overflow_add;
reg carry_sub, o_overflow_sub;
reg [11:0] o_data_add, o_data_sub;
//for Multiply
reg signed[23:0] mul_q14m10;
reg signed[19:0] mul_q15m5;  //add one bit to prevent overflowing
reg signed[11:0] mul_q7m5, o_data_mul;
reg mul_q14m10_carry, o_overflow_mul;
//for MAC
reg signed[11:0] mac_q7m5_w, mac_q7m5_r;
reg signed[23:0] mac_temp_q14m10;
reg signed[24:0] mac_temp_q15m10;
reg mac_temp_q15m10_carry;
reg signed[20:0] mac_temp_q16m5;
reg signed[11:0] mac_temp_q7m5; 
reg [2:0]  mac_inst_w, mac_inst_r;
reg mac_overflow_w, mac_overflow_r, mac_overflow, mac_temp_overflow;

//for xnor
reg signed[11:0] o_xnor;

//for ReLU
reg signed[11:0] o_relu;

//for Mean
reg signed[12:0] temp_mean;
reg signed[11:0] o_mean;

//for Abs
reg signed[11:0] o_abs, abs_a, abs_b;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
assign o_overflow = o_overflow_r;
// ---- Add your own wire data assignments here if needed ---- //




// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
    



    //add
    {carry_add, o_data_add} = i_data_a + i_data_b; 
    o_overflow_add = (carry_add == o_data_add[11]) ? 1'b0 : 1'b1;

    //subtraction
    {carry_sub, o_data_sub} = i_data_a - i_data_b; 
    o_overflow_sub = (carry_sub == o_data_sub[11]) ? 1'b0 : 1'b1;


    //multiply
    mul_q14m10 = i_data_a * i_data_b;
    mul_q14m10_carry = mul_q14m10[23]? ( mul_q14m10[4] & ( |mul_q14m10[3:0] ) ) : mul_q14m10[4] ;   //round carry bit
    mul_q15m5 = {mul_q14m10[23], mul_q14m10[23:5]} + mul_q14m10_carry ; //after rounding fraction part
    mul_q7m5 = mul_q15m5[11:0]; //after truncating integer part
    o_data_mul = mul_q7m5 ;

    if( mul_q15m5[19:12]=={8{mul_q15m5[11]}} )     
        o_overflow_mul = 1'b0;
    else
        o_overflow_mul = 1'b1;

    //MAC
    mac_temp_q14m10 = { {7{mac_q7m5_r[11]}}, mac_q7m5_r, {5{1'b0}} };
    mac_temp_q15m10 = mul_q14m10 + mac_temp_q14m10;
    mac_temp_q15m10_carry =  mac_temp_q15m10[24]? (mac_temp_q15m10[4] & (|mac_temp_q15m10[3:0])) : mac_temp_q15m10[4];//round carry bit
    mac_temp_q16m5 = {mac_temp_q15m10[24], mac_temp_q15m10[24:5] } + mac_temp_q15m10_carry;//after rounding fraction part
    mac_temp_q7m5 = mac_temp_q16m5[11:0];//after truncating integer part

    if (mac_temp_q16m5[20:12] == {9{mac_temp_q16m5[11]}} )
        mac_temp_overflow = 1'b0;
    else
        mac_temp_overflow = 1'b1;
    
    if (mac_overflow_r == 1'b1 && mac_inst_r == 3'b011) //previous cycle is mac and overflow
        mac_overflow = 1'b1;
    else
        mac_overflow = mac_temp_overflow;
    
    

    if (i_valid == 1'b1) begin
        if (i_inst != 3'b011) begin
            mac_q7m5_w = 12'b000000000000;
            mac_inst_w = 3'b000;
            mac_overflow_w = 1'b0;
        end
        else begin
            mac_q7m5_w = mac_temp_q7m5;
            mac_inst_w = 3'b011;
            mac_overflow_w = mac_overflow;

        end

    end

    else begin
        mac_q7m5_w = mac_q7m5_r;
        mac_inst_w = mac_inst_r;
        mac_overflow_w = mac_overflow_r;
    end
    

    //XNOR
    o_xnor = i_data_a ^~ i_data_b;

    //ReLU
    if (i_data_a >0) 
        o_relu = i_data_a;
    else
        o_relu = 0;

    //Mean
    
    temp_mean = i_data_a + i_data_b;
    o_mean = temp_mean >>>1;

    //Abs
    if (i_data_a < 0) 
        abs_a = ~i_data_a+1;
    else
        abs_a = i_data_a; 
    if (i_data_b < 0) 
        abs_b = ~i_data_b+1;
    else
        abs_b = i_data_b;
    if (abs_b > abs_a) 
        o_abs = abs_b;
    else
        o_abs = abs_a;
     



    //output
    o_data_w = 12'b0;
    o_overflow_w = 1'b0;
    o_valid_w = 1'b0;

    if(i_valid == 1'b1)begin
        o_valid_w = 1'b1;
        mac_inst_w = 3'b000;
        case (i_inst)
            3'b000:begin     //signed addition
                o_data_w = o_data_add;
                o_overflow_w = o_overflow_add;
            end
            3'b001:begin     //signed subtraction
                o_data_w = o_data_sub;
                o_overflow_w = o_overflow_sub;
            end
            3'b010:begin     //signed multiplication
                o_data_w = o_data_mul;
                o_overflow_w = o_overflow_mul;
            end
            3'b011:begin    //MAC
                o_data_w = mac_q7m5_w;
                o_overflow_w = mac_overflow_w;  
            end
            3'b100:begin    //XNOR
                o_data_w = o_xnor;
                o_overflow_w = 1'b0;
            end
            3'b101:begin    //Relu
                o_data_w = o_relu;
                o_overflow_w = 1'b0; 
            end
            3'b110:begin    //Mean
                o_data_w = o_mean;
                o_overflow_w = 1'b0;
            end
            3'b111:begin
                o_data_w = o_abs;
                o_overflow_w = 1'b0;
            end
             
            
            
            //default: 
        endcase
    end

    else begin
        mac_inst_w = mac_inst_r;
    end
    
    
end




// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_data_r <= 0;
        o_overflow_r <= 0;
        o_valid_r <= 0;
        //mac
        mac_q7m5_r <= 12'b000000000000;
        mac_inst_r <=  3'b000;
        mac_overflow_r <=1'b0;
    end else begin
        o_data_r <= o_data_w;
        o_overflow_r <= o_overflow_w;
        o_valid_r <= o_valid_w;
        //mac
        mac_q7m5_r <=mac_q7m5_w;
        mac_inst_r <=mac_inst_w;
        mac_overflow_r <= mac_overflow_w;

    end
end


endmodule
