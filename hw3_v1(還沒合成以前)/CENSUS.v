module CENSUS (
    input           i_clk,
    input           i_rst_n,
    input  [23:0]   i_data,
    input           i_center,
    input           i_padding,
    output [23:0]   o_data
);

reg [7:0]  data_R, data_G, data_B;
//center
reg  [7:0]  i_data_R_w, i_data_R_r; 
reg  [7:0]  i_data_G_w, i_data_G_r; 
reg  [7:0]  i_data_B_w, i_data_B_r;
//output (after compare)
reg  [7:0]  o_data_R_w, o_data_R_r; 
reg  [7:0]  o_data_G_w, o_data_G_r; 
reg  [7:0]  o_data_B_w, o_data_B_r;  
integer i;


assign  o_data  =   {o_data_R_r, o_data_G_r, o_data_B_r};



always @(*) begin       //if center == 1, load data to register for comparing
    if (i_center == 1) begin
        i_data_R_w  =   i_data[23:16]; 
        i_data_G_w  =   i_data[15: 8]; 
        i_data_B_w  =   i_data[ 7: 0]; 
    end
    else begin
        i_data_R_w  =   i_data_R_r; 
        i_data_G_w  =   i_data_G_r; 
        i_data_B_w  =   i_data_B_r;
    end
        
end
always @(*) begin       //if padding == 1, data coming from mem = 0
    if (i_padding == 1'b1) begin
        data_R  =   0;
        data_G  =   0;
        data_B  =   0;
    end
    else begin
        data_R  =   i_data[23:16];
        data_G  =   i_data[15: 8];
        data_B  =   i_data[ 7: 0];
    end
end
always @(*) begin   //use shift register to prevent decoder from large area
    for( i = 1; i <= 7 ; i = i + 1) begin
        o_data_R_w[i]    =   o_data_R_r[i-1];
        o_data_G_w[i]    =   o_data_G_r[i-1];
        o_data_B_w[i]    =   o_data_B_r[i-1];
    end
end
always @(*) begin
    if ( data_R <= i_data_R_r)
        o_data_R_w[0]  =   1'b0;
    else
        o_data_R_w[0]  =   1'b1;
end
always @(*) begin
    if ( data_G <= i_data_G_r)
        o_data_G_w[0]  =   1'b0;
    else
        o_data_G_w[0]  =   1'b1;
end
always @(*) begin
    if ( data_B <= i_data_B_r)
        o_data_B_w[0]  =   1'b0;
    else
        o_data_B_w[0]  =   1'b1;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        i_data_R_r    <=    0; 
        i_data_G_r    <=    0; 
        i_data_B_r    <=    0;
        //output (after compare)
        o_data_R_r    <=    0; 
        o_data_G_r    <=    0; 
        o_data_B_r    <=    0;  
    end
    else begin
        i_data_R_r    <=    i_data_R_w; 
        i_data_G_r    <=    i_data_G_w; 
        i_data_B_r    <=    i_data_B_w;
        //output (after compare)
        /*
        o_data_R_r    <=    o_data_R_w; 
        o_data_G_r    <=    o_data_R_w; 
        o_data_B_r    <=    o_data_R_w;
        */
        for( i = 7; i >= 0 ; i = i - 1) begin
            o_data_R_r[i]    <=   o_data_R_w[i];
            o_data_G_r[i]    <=   o_data_G_w[i];
            o_data_B_r[i]    <=   o_data_B_w[i];
        end  
    end
end
    
endmodule