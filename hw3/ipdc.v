
module ipdc (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 2:0] i_op_mode,
	input         i_in_valid,
	input  [23:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [23:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- /
parameter IDLE = 3'd0, OP = 3'd1, EXEC = 3'd2, OUT = 3'd3;
parameter OP_LW = 3'd0;
parameter OP_RS = 3'd1;
parameter OP_DS = 3'd2;
parameter OP_De = 3'd3;
parameter OP_ZI = 3'd4;
parameter OP_Me = 3'd5;
parameter OP_YCC = 3'd6;
parameter OP_RGB = 3'd7;

integer idx;

reg [7:0]  data [0:191]; // 192 (64R / 64B / 64G) 
reg [7:0]  med_data [0:191]; 
reg [2:0]  tmp_op;
reg [2:0]  state,   state_n;

reg        o_in_ready_r;
reg        o_out_valid_r;
reg [23:0] o_out_data_r;

reg       mode; // 0 for RGB, 1 for YCbCr
reg [6:0] cnt; // lw 64 data
reg [5:0] origin;
reg [1:0] i; // x in 4x4
reg [5:0] num; // index in 4x4
reg [6:0] cnt_data;// 0~63 pixel
wire [7:0] cnt_data_idx;// 192 RGB in data
wire [7:0] cnt_data_idx_last;
reg [7:0] ze;


// ======reg for median filter=======
reg [7:0] a11,a12,a13;
reg [7:0] a21,a22,a23;
reg [7:0] a31,a32,a33;

// wire
wire [7:0] min_x_1, min_x_2, min_x_3;
wire [7:0] med_x_1, med_x_2, med_x_3;
wire [7:0] max_x_1, max_x_2, max_x_3;
wire [7:0] max_y_1, med_y_2, min_y_3;
wire [7:0] med_i;

wire [6:0]  cnt_w;
wire [5:0]  origin_w;
wire [1:0]  i_w;
wire [5:0]  num_w;
wire        valid;
wire [6:0]  cnt_data_w;

wire [15:0] tmp_y;
wire [15:0] tmp_cb;
wire [15:0] tmp_cr;
wire [7:0] y;
wire [7:0] cb;
wire [7:0] cr;

integer t;


wire [7:0] data_o_sram;
wire wen;
wire [7:0] address;
wire [7:0] data_i_sram;

// sram
sram_256x8 sram_1(
    .Q(data_o_sram),
    .CLK(i_clk),
    .CEN(cen),
    .WEN(wen),
    .A(address),
    .D(data_i_sram)
);
sram_256x8 mySramR(.A(SramAddress),
					.D(R_data),
					.CLK(i_clk),
					.CEN(1'b0),
					.WEN(SramWen),
					.Q(R_data_out));

sram_256x8 mySramG(.A(SramAddress),
					.D(G_data),
					.CLK(i_clk),
					.CEN(1'b0),
					.WEN(SramWen),
					.Q(G_data_out));

sram_256x8 mySramB(.A(SramAddress),
					.D(B_data),
					.CLK(i_clk),
					.CEN(1'b0),
					.WEN(SramWen),
					.Q(B_data_out));

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_in_ready = o_in_ready_r;
assign o_out_valid = o_out_valid_r;
assign o_out_data = o_out_data_r;

assign cnt_w = cnt;
assign origin_w = origin;
assign i_w = i;
assign num_w = num;
assign cnt_data_w = cnt_data;
assign cnt_data_idx = (i==1)? (cnt_data+64):(i==2)? (cnt_data+128):(cnt_data);
assign cnt_data_idx_last = cnt_data_idx - 1;

assign min_x_1=(a11<a12)? ((a11<a13)? a11:a13) : ((a12<a13)?a12:a13);
assign min_x_2=(a21<a22)? ((a21<a23)? a21:a23) : ((a22<a23)?a22:a23);
assign min_x_3=(a31<a32)? ((a31<a33)? a31:a33) : ((a32<a33)?a32:a33);
assign max_x_1=(a11>a12)? ((a11>a13)? a11:a13) : ((a12>a13)?a12:a13);
assign max_x_2=(a21>a22)? ((a21>a23)? a21:a23) : ((a22>a23)?a22:a23);
assign max_x_3=(a31>a32)? ((a31>a33)? a31:a33) : ((a32>a33)?a32:a33);
assign med_x_1=(a11>a12)?((a12>a13)?(a12):((a11>a13)?a13:a11)):((a11>a13)?(a11):((a12>a13)?a13:a12));
assign med_x_2=(a21>a22)?((a22>a23)?(a22):((a21>a23)?a23:a21)):((a21>a23)?(a21):((a22>a23)?a23:a22));
assign med_x_3=(a31>a32)?((a32>a33)?(a32):((a31>a33)?a33:a31)):((a31>a33)?(a31):((a32>a33)?a33:a32));

assign max_y_1=(min_x_1>min_x_2)?((min_x_1>min_x_3)?min_x_1:min_x_3):((min_x_2>min_x_3)?min_x_2:min_x_3);
assign min_y_3=(max_x_1>max_x_2)?((max_x_2>max_x_3)?max_x_3:max_x_2):((max_x_1>max_x_3)?max_x_3:max_x_1);
assign med_y_2=(med_x_1>med_x_2)?((med_x_2>med_x_3)?(med_x_2):((med_x_1>med_x_3)?med_x_3:med_x_1)):((med_x_1>med_x_3)?(med_x_1):((med_x_2>med_x_3)?med_x_3:med_x_2));

assign med_i=(max_y_1>med_y_2)?((med_y_2>min_y_3)?(med_y_2):((max_y_1>min_y_3)?min_y_3:max_y_1)):((max_y_1>min_y_3)?(max_y_1):((med_y_2>min_y_3)?min_y_3:med_y_2));

assign tmp_y = (2*data[origin+num]+5*data[origin+num+64]);
assign tmp_cb = (-data[origin+num]-2*data[origin+num+64]+4*data[origin+num+128]);
assign tmp_cr = (4*data[origin+num]-3*data[origin+num+64]-data[origin+num+128]);
assign y = ((tmp_y[2])? (tmp_y[10:3]+1) : tmp_y[10:3]);
assign cb = ((tmp_cb[2])? (tmp_cb[10:3]+129) : (tmp_cb[10:3]+128));
assign cr = ((tmp_cr[2])? (tmp_cr[10:3]+129) : (tmp_cr[10:3]+128));

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
    
// state machine
always@(*) begin
    case(state)
        IDLE:begin
            if(i_op_valid==1 && tmp_op==0)begin
                state_n = EXEC;
            end
            else begin
                state_n = IDLE;
            end
        end
        OP:begin
            if(i_op_valid)  state_n = EXEC;
            else state_n = OP;
		end
        EXEC:begin
			if(tmp_op == OP_RS || tmp_op == OP_DS || 
               tmp_op == OP_De || tmp_op == OP_ZI)begin
                state_n = OUT;
               end
            // median
            else if(tmp_op == OP_Me)begin
                if(i == 2 && cnt_data == 64) state_n = OP;
		        else state_n = EXEC;
            end
            else if(tmp_op == OP_LW)begin
                state_n = (cnt_w == 64)? OP : EXEC;                  
            end
            else begin
                state_n = OP;
            end
        end
        OUT:begin
            if(cnt_w == 16) state_n = OP;
            else state_n = OUT;
        end
        default: state_n = IDLE;
    endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        for(idx = 0; idx < 192; idx = idx + 1) begin
            data[idx] <= 0;
            med_data[idx] <= 0;
        end
        tmp_op <= 0;
        state <= IDLE;
        o_in_ready_r <= 1;
        o_out_valid_r <= 0;
        o_out_data_r <= 0;
        mode <= 0;
        cnt <= 0;
        origin <= 0;
        i <= 0;
        num <= 0;
        cnt_data <= 0;
        // cnt_data_idx <= 0;
        ze <= 0;
        a11 <= 0;
        a12 <= 0;
        a13 <= 0;
        a21 <= 0;
        a22 <= 0;
        a23 <= 0;
        a31 <= 0;
        a32 <= 0;
        a33 <= 0;

        
    end
    else begin
		state <= state_n;
        case(state)
            IDLE:begin
            end
            OP:begin
                cnt <= 0;
                i <= 0;
                o_in_ready_r <= 0;
                o_out_valid_r <= 0;
                tmp_op <= i_op_mode;
                o_out_data_r <= 0;
                cnt_data <= 0;
                i <= 0;
                // for(t=0;t<192;t=t+1)begin
                //     med_data[t] <= 0;
                //     // $display("Me:[%d], %d",t,med_data[t]);
                // end

            end
            EXEC:begin
                case(tmp_op)
                    OP_LW:begin
                        if(cnt_w == 64)begin
                            cnt <= 0;
                            o_out_valid_r <= 1;
                        end
                        else begin
                            data[cnt_w] <= i_in_data[7:0];
                            data[cnt_w+64] <= i_in_data[15:8];
                            data[cnt_w+128] <= i_in_data[23:16];
                        
                            cnt <= cnt_w + 1;
                        end
                    end
                    OP_RS:begin
                        if(origin == 6'd4 || origin == 6'd12 
                           || origin == 6'd20 || origin == 6'd28
                           || origin == 6'd36)begin
                        end
                        else begin 
                            origin <= origin_w + 1;
                        end
                    end
                    OP_DS:begin
                        if(origin == 6'd32 || origin == 6'd33 
                           || origin == 6'd34 || origin == 6'd35
                           || origin == 6'd36)begin
                            // $display("origin=%d", origin);
                        end
                        else begin
                            origin <= origin_w + 8;
                        end
                    end
                    OP_De:begin
                        origin <= 0;
                    end
                    OP_ZI:begin
                        origin <= 18;
                    end
                    OP_Me:begin

                        ///////////////
                        if(cnt_data == 64)begin
                            cnt_data <= 0;

                            med_data[cnt_data_idx_last] <= 0;
                            
                            if(i == 2)begin
                                i <= 0;
                                o_out_valid_r <= 1;
                                cnt_data <= 0;

                                for(t=0;t<192;t=t+1)begin
                                    data[t] <= med_data[t];
                                    // $display("Me:[%d], %d",t,med_data[t]);
                                end
                                    
                                
                            end
                            else begin
                                i <= i + 1;
                            end
                        end
                        else begin
                            // corner
                            if(cnt_data == 0)begin
                                a11 <= 0;
                                a12 <= 0;
                                a13 <= 0;
                                a21 <= 0;
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= 0;
                                a32 <= data[cnt_data_idx+8];
                                a33 <= data[cnt_data_idx+9];
                            end
                            else if(cnt_data == 7)begin
                                a11 <= 0;
                                a12 <= 0;
                                a13 <= 0;
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= 0;
                                a31 <= data[cnt_data_idx+7];
                                a32 <= data[cnt_data_idx+8];
                                a33 <= 0;
                            end
                            else if(cnt_data == 56)begin
                                a11 <=0;
                                a12 <= data[cnt_data_idx-8];
                                a13 <= data[cnt_data_idx-7];
                                a21 <= 0;
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= 0;
                                a32 <= 0;
                                a33 <= 0;
                            end
                            else if(cnt_data == 63)begin
                                a11 <= data[cnt_data_idx-9];
                                a12 <= data[cnt_data_idx-8];
                                a13 <= 0;
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= 0;
                                a31 <= 0;
                                a32 <= 0;
                                a33 <= 0;
                            end
                                
                            // center
                            else if((8<cnt_data&&cnt_data<15) || (16<cnt_data&&cnt_data<23) ||
                                    (24<cnt_data&&cnt_data<31) || (32<cnt_data&&cnt_data<39) ||
                                    (40<cnt_data&&cnt_data<47) || (48<cnt_data&&cnt_data<55))begin
                                a11 <= data[cnt_data_idx-9];
                                a12 <= data[cnt_data_idx-8];
                                a13 <= data[cnt_data_idx-7];
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= data[cnt_data_idx+7];
                                a32 <= data[cnt_data_idx+8];
                                a33 <= data[cnt_data_idx+9];
                                
                            end
                            else if(0<cnt_data&&cnt_data<7)begin
                                a11 <= 0;
                                a12 <= 0;
                                a13 <= 0;
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= data[cnt_data_idx+7];
                                a32 <= data[cnt_data_idx+8];
                                a33 <= data[cnt_data_idx+9];
                            end
                            else if(56<cnt_data&&cnt_data<63)begin
                                a11 <= data[cnt_data_idx-9];
                                a12 <= data[cnt_data_idx-8];
                                a13 <= data[cnt_data_idx-7];
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= 0;
                                a32 <= 0;
                                a33 <= 0;
                            end
                            else if(cnt_data==8 || cnt_data==16 ||
                                    cnt_data==24 || cnt_data==32 ||
                                    cnt_data==40 || cnt_data== 48)begin
                                a11 <= 0;
                                a12 <= data[cnt_data_idx-8];
                                a13 <= data[cnt_data_idx-7];
                                a21 <= 0;
                                a22 <= data[cnt_data_idx];
                                a23 <= data[cnt_data_idx+1];
                                a31 <= 0;
                                a32 <= data[cnt_data_idx+8];
                                a33 <= data[cnt_data_idx+9];
                                    
                            end
                            else begin
                                a11 <= data[cnt_data_idx-9];
                                a12 <= data[cnt_data_idx-8];
                                a13 <= 0;
                                a21 <= data[cnt_data_idx-1];
                                a22 <= data[cnt_data_idx];
                                a23 <= 0;
                                a31 <= data[cnt_data_idx+7];
                                a32 <= data[cnt_data_idx+8];
                                a33 <= 0;
                                
                            end
                            // output
                            if(cnt_data_idx_last==0 || cnt_data_idx_last==7 ||
                                cnt_data_idx_last==56 || cnt_data_idx_last==63 ||
                                cnt_data_idx_last==64 || cnt_data_idx_last==71 ||
                                cnt_data_idx_last==120 || cnt_data_idx_last==127 ||
                                cnt_data_idx_last==128 || cnt_data_idx_last==135 ||
                                cnt_data_idx_last==184 || cnt_data_idx_last==191
                                )begin
                                med_data[cnt_data_idx_last] <= 0;
                            end
                            else begin
                                med_data[cnt_data_idx_last] <= med_i;
                            end

                            cnt_data <= cnt_data_w+1;
                        end
                        //////////////
                       
                    end
                    OP_YCC:begin
                        mode <= 1;
                        o_out_valid_r <= 1;
                    end
                    OP_RGB:begin
                        mode <= 0;
                        o_out_valid_r <= 1;
                    end
                endcase
            end
            OUT:begin
                o_out_valid_r <= 1;
                if(cnt == 16)begin
                    cnt <= 0;
                    i <= 0;
                    num <= 0;
                    o_out_valid_r <= 0;
                    o_out_data_r <= 0;
                end
                else begin
                    cnt <= cnt_w + 1;
                    if(i == 3)begin // 1,2,3,0
                        i <= 0;
                        num <= num_w + 5;
                        if(mode)begin
                            o_out_data_r[7:0] <= y;
                            o_out_data_r[15:8] <= cb;
                            o_out_data_r[23:16] <= cr;
                        end
                        else begin
                            o_out_data_r <= {data[origin+num+128],data[origin+num+64],data[origin+num]};
                        end
                    end
                    else begin
                        i <= i_w + 1;
                        num <= num_w + 1;
                        if(mode)begin
                            o_out_data_r[7:0] <= y;
                            o_out_data_r[15:8] <= cb;
                            o_out_data_r[23:16] <= cr;
                        end
                        else begin
                            o_out_data_r <= {data[origin+num+128],data[origin+num+64],data[origin+num]};
                        end
                    end
                end
            end
        endcase
    end
end

endmodule
