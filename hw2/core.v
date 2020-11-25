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
// --- Parameter definition ---//
parameter IDLE = 3'd0, INST = 3'd1, ALU = 3'd2, WAIT = 3'd3, LS = 3'd4;

// opcode parameter
parameter OP_LW = 6'd1;
parameter OP_SW = 6'd2;
parameter OP_ADD = 6'd3;
parameter OP_SUB = 6'd4;
parameter OP_ADDI = 6'd5;
parameter OP_OR = 6'd6;
parameter OP_XOR = 6'd7;
parameter OP_BEQ = 6'd8;
parameter OP_BNE = 6'd9;
parameter OP_EOF = 6'd10;

// MIPS status parameter
parameter R_TYPE_SUCCESS = 2'd0;
parameter I_TYPE_SUCCESS = 2'd1;
parameter MIPS_OVERFLOW = 2'd2;
parameter MIPS_END = 2'd3;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
reg [ ADDR_W-1 : 0 ] o_i_addr_r;
reg                  o_d_wen_r;
reg [ ADDR_W-1 : 0 ] o_d_addr_r;
reg [ DATA_W-1 : 0 ] o_d_wdata_r;
reg [        1 : 0 ] o_status_r;
reg                  o_status_valid_r;
reg [ ADDR_W-1 : 0 ] inst_tmp;


reg [2:0] state;
reg [2:0] state_n;
wire [    5 : 0 ] op;
wire [    4 : 0 ] s1;
wire [    4 : 0 ] s2;
wire [    4 : 0 ] s3;
wire [       14 : 0 ] im;
reg [   ADDR_W : 0 ] tmp;
reg [ DATA_W-1 : 0 ] reg_file [ DATA_W-1 : 0 ];

integer idx;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_i_addr = o_i_addr_r;
assign o_d_wen = o_d_wen_r;
assign o_d_addr = o_d_addr_r;
assign o_d_wdata = o_d_wdata_r;
assign o_status = o_status_r;
assign o_status_valid = o_status_valid_r;

assign op = inst_tmp[31:26];
assign s2 = inst_tmp[25:21];
assign s1 = inst_tmp[20:16];
assign s3 = inst_tmp[15:11];
assign im = inst_tmp[15:0];


// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
    
// state machine
always@(*)begin
    //$display("status = %b ",o_status_r);
    //$display("op = %b ",op);
    
    case(state)
        IDLE:begin
            state_n = INST;
           // $display("state = idle");
        end
        INST:begin
            state_n = ALU;
           // $display("state = inst");
        end
        ALU:begin
            if(op == OP_EOF) state_n = IDLE;
            else if(op == OP_LW) state_n = WAIT;
            else state_n = LS;
           // $display("state = alu");
        end
        WAIT:begin
            state_n = LS;
            //$display("state = wait");
        end
        LS:begin
            state_n = INST;
            //$display("state = ls");
        end
        default: state_n = IDLE;
    endcase 
end
    
// ---------------------------------------------------------------------------
// Sequential Block
// -------------------------------------------------- -------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_i_addr_r <= 32'd0;
        o_d_wen_r <= 1'b0;
        o_d_addr_r <= 32'd0;
        o_d_wdata_r <= 32'd0;
        o_status_r <= 2'd0;
        o_status_valid_r <= 1'b0;
        inst_tmp <= 32'd0;
        state <= IDLE;
        tmp <= 33'd0;
        for(idx = 0; idx < DATA_W; idx = idx + 1)begin
            reg_file[idx] <= 0;
        end
    end
    else begin
        state <= state_n;
        case(state)
            IDLE:begin
            end
            INST:begin
                o_status_r <= 0;
                o_status_valid_r <= 0;
                o_d_wen_r <= 0;
                inst_tmp <= i_i_inst;
            end
            ALU:begin
                //$display("inst = %b ",inst_tmp);
                
                case(op)
                    OP_LW:begin
                        o_d_addr_r <= reg_file[s2] + im;
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_SW:begin
                        o_d_addr_r <= reg_file[s2] + im;
                        o_d_wdata_r <= reg_file[s1];
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_ADD:begin
                        tmp <= reg_file[s2] + reg_file[s1];
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_SUB:begin
                        tmp <= reg_file[s2] - reg_file[s1];
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_ADDI:begin
                        tmp <= reg_file[s2] + im;
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_OR:begin
                        reg_file[s3] <= reg_file[s2] | reg_file[s1];
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_XOR:begin
                        reg_file[s3] <= reg_file[s2] ^ reg_file[s1];
                        o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_BEQ:begin
                        if(reg_file[s1] == reg_file[s2])begin
                            o_i_addr_r <= o_i_addr + 32'd4 + im;
                        end
                        else o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_BNE:begin
                        if(reg_file[s1] != reg_file[s2])begin
                            o_i_addr_r <= o_i_addr + 32'd4 + im;
                        end
                        else o_i_addr_r <= o_i_addr + 32'd4;
                    end
                    OP_EOF:begin
                        o_status_valid_r <= 1'b1;
                        o_status_r <= MIPS_END;
                    end
                    default:begin
                        
                    end
                endcase
            end
            WAIT:begin
            end
            LS:begin
                o_status_valid_r <= 1'b1;
                
                case(op)
                    OP_LW:begin
                        o_status_r <= I_TYPE_SUCCESS;
                        reg_file[s1] <= i_d_rdata;
                    end
                    OP_SW:begin
                        o_status_r <= I_TYPE_SUCCESS;
                        o_d_wen_r <= 1'd1;
                    end
                    OP_ADD:begin
                        reg_file[s3] = tmp[ADDR_W-1 : 0];

                        if(tmp[ADDR_W]) o_status_r <= MIPS_OVERFLOW;
                        else o_status_r <= R_TYPE_SUCCESS;
                    end
                    OP_SUB:begin
                        reg_file[s3] <= tmp[ADDR_W-1 : 0];

                        if(reg_file[s2] < reg_file[s1]) o_status_r = MIPS_OVERFLOW;
                        else o_status_r <= R_TYPE_SUCCESS;
                    end
                    OP_ADDI:begin
                        reg_file[s1] <= tmp[ADDR_W-1 : 0];

                        if(tmp[ADDR_W]) o_status_r <= MIPS_OVERFLOW;
                        else o_status_r <= I_TYPE_SUCCESS;
                    end
                    OP_OR:begin
                        o_status_r <= R_TYPE_SUCCESS;
                    end
                    OP_XOR:begin
                        o_status_r <= R_TYPE_SUCCESS;
                    end
                    OP_BEQ:begin
                        o_status_r <= I_TYPE_SUCCESS;
                    end
                    OP_BNE:begin
                        o_status_r <= I_TYPE_SUCCESS;
                    end
                    default:begin
            
                    end
                endcase 
            end
        endcase
    end
end

endmodule