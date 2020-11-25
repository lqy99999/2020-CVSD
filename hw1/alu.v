module alu #(
    parameter INT_W  = 3,
    parameter FRAC_W = 5,
    parameter INST_W = 3,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_valid,
    input signed [ DATA_W-1 : 0 ] i_data_a,
    input signed [ DATA_W-1 : 0 ] i_data_b,
    input  [ INST_W-1 : 0 ] i_inst,
    output                  o_valid,
    output [ DATA_W-1 : 0 ] o_data,
    output                  o_overflow
);
// --- Parameter definition ---//
parameter ADD = 3'b000;
parameter SUB = 3'b001;
parameter MUL = 3'b010;
parameter OR = 3'b011;
parameter XOR = 3'b100;
parameter ReLU = 3'b101;
parameter MEAN = 3'b110;
parameter MIN = 3'b111;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  [ DATA_W-1:0 ] o_data_w, o_data_r;
reg                 o_valid_w, o_valid_r;
reg                 o_overflow_w, o_overflow_r;
// ---- Add your own wires and registers here if needed ---- //

reg signed [ DATA_W : 0 ] i_data_a_r;
reg signed [ DATA_W : 0 ] i_data_b_r;
reg [ DATA_W : 0 ] result; 
reg signed [ DATA_W : 0 ] sub_b;
reg [ 2 * DATA_W - 1 : 0] mul_tmp;


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
	case(i_inst)
	    ADD:begin 
		        result = i_data_a_r + i_data_b_r;
				o_overflow_w =result[DATA_W]^result[DATA_W - 1];
			end
	    SUB:begin
				sub_b =  ~i_data_b_r + 1'b1;
				result = i_data_a_r + sub_b;
				o_overflow_w = result[DATA_W]^result[DATA_W - 1];
			end
	    MUL:begin
				mul_tmp = i_data_a_r * i_data_b_r;
				result = mul_tmp[ 2*DATA_W - 1 - INST_W : FRAC_W ];
				if(mul_tmp[ FRAC_W - 1 ])	result = result + 1'b1;
				o_overflow_w = mul_tmp[2*DATA_W - 1] ^ mul_tmp[2*DATA_W - 2] ^ mul_tmp[2*DATA_W - 3] ^ mul_tmp[2*DATA_W - 4];
			end
	    OR:begin
				result = i_data_a_r | i_data_b_r;
				o_overflow_w = 0;
			end
	    XOR:begin
				result = i_data_a_r ^ i_data_b_r;
				o_overflow_w = 0;
			end
	    ReLU:begin
			    if(~i_data_a_r[DATA_W]) result = i_data_a_r;	
				else result = 0;
				o_overflow_w = 0;
            end
	    MEAN:begin
				result = (i_data_a_r + i_data_b_r) >>> 1;
				o_overflow_w = 0;
			end
	    MIN:begin
			    if(i_data_a_r > i_data_b_r) result = i_data_b_r;
				else result = i_data_a_r;
				o_overflow_w = 0;
			end
	    default:begin 
					result = 0;
					o_overflow_w = 0;
				end
	endcase
	
    o_data_w = result[DATA_W - 1 : 0];
	
    if(i_valid)	o_valid_w = 1'b1;
	else o_valid_w = 1'b0;
end

always@(*) begin
	if(i_valid)begin
	    i_data_a_r = {i_data_a[DATA_W - 1], i_data_a};
	    i_data_b_r = {i_data_b[DATA_W - 1], i_data_b};
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
    end else begin
        o_data_r <= o_data_w;
        o_overflow_r <= o_overflow_w;
        o_valid_r <= o_valid_w;
    end
end


// --- Get inputs(signed extension) synchronized with the negative edge clock --- //
	




endmodule
