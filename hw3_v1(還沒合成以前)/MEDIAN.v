module MEDIAN   //insertion sort
#(
    parameter arrayLength   = 9
)
(
    input           i_clk,
    input           i_rst_n,
    input  [23:0]   i_data,
    //input           i_filter_valid,
    input           i_median_reset,
    input           i_padding,
    output [23:0]   o_data
);

localparam  bitLength   = arrayLength + 1;

reg [7:0]  insertArray_R_r [0  :   arrayLength - 1];
reg [7:0]  insertArray_R_w [0  :   arrayLength - 1];

reg [7:0]  insertArray_G_r [0  :   arrayLength - 1];
reg [7:0]  insertArray_G_w [0  :   arrayLength - 1];

reg [7:0]  insertArray_B_r [0  :   arrayLength - 1];
reg [7:0]  insertArray_B_w [0  :   arrayLength - 1];

reg [bitLength - 1 : 0] bitArray_R;//actually not array, instead it's wire
reg [bitLength - 1 : 0] bitArray_G;//actually not array, instead it's wire
reg [bitLength - 1 : 0] bitArray_B;//actually not array, instead it's wire

reg [7:0]   data_R, data_G, data_B;

integer i;

assign  o_data  =   {insertArray_R_r[4], insertArray_G_r[4], insertArray_B_r[4]};

always @(*) begin
    for ( i = 0 ; i < arrayLength ; i = i + 1) begin
        insertArray_R_w[i]   =   insertArray_R_r[i];
        insertArray_G_w[i]   =   insertArray_G_r[i];
        insertArray_B_w[i]   =   insertArray_B_r[i];
    end

    if (i_median_reset == 1'b1)begin
        for ( i = 0 ; i < arrayLength ; i = i + 1) begin
            insertArray_R_w[i]   <=   8'd255;
            insertArray_G_w[i]   <=   8'd255;
            insertArray_B_w[i]   <=   8'd255;
        end
    end
    /*
    else if ( i_filter_valid == 1'b0 )begin
        data_R  =   8'd255;
        data_G  =   8'd255;
        data_B  =   8'd255;
    end
    */
    else if (i_padding == 1'b1) begin
        data_R  =   0;
        data_G  =   0;
        data_B  =   0;
 
    end
    else begin
        data_R  =   i_data[23:16];
        data_G  =   i_data[15: 8];
        data_B  =   i_data[ 7: 0];
  
    end


    bitArray_R[bitLength - 1] = 1'b1;
    bitArray_G[bitLength - 1] = 1'b1;	
    bitArray_B[bitLength - 1] = 1'b1;	    
    
    for (i = 0; i < bitLength - 1; i = i + 1 ) begin
        bitArray_R[i] = (data_R > insertArray_R_r[i]) ? 1 : 0;	
        bitArray_G[i] = (data_G > insertArray_G_r[i]) ? 1 : 0;	
        bitArray_B[i] = (data_B > insertArray_B_r[i]) ? 1 : 0;	
    end
    

    for(i = bitLength - 1; i > 0; i = i - 1)begin
    insertArray_R_w[i-1] = (bitArray_R[i-:2] == 2'b10) ? data_R : 
								 (bitArray_R[i-:2]==2'b11) ? insertArray_R_r[i-1] : insertArray_R_r[i];
                                 
    insertArray_G_w[i-1] = (bitArray_G[i-:2] == 2'b10) ? data_G : 
								 (bitArray_G[i-:2]==2'b11) ? insertArray_G_r[i-1] : insertArray_G_r[i];

    insertArray_B_w[i-1] = (bitArray_B[i-:2] == 2'b10) ? data_B : 
								 (bitArray_B[i-:2]==2'b11) ? insertArray_B_r[i-1] : insertArray_B_r[i];

    end		
end


always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for ( i = 0 ; i < arrayLength ; i = i + 1) begin
            insertArray_R_r[i]   <=   8'd255;
            insertArray_G_r[i]   <=   8'd255;
            insertArray_B_r[i]   <=   8'd255;
        end
    end
    else begin
        for ( i = 0 ; i < arrayLength ; i = i + 1) begin
            insertArray_R_r[i]   <=   insertArray_R_w[i];
            insertArray_G_r[i]   <=   insertArray_G_w[i];
            insertArray_B_r[i]   <=   insertArray_B_w[i];
        end        
    end
end

endmodule