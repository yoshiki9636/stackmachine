module sm_logics(
	input clk,
	input rst_n,
	input s00_idle,  // idle status
	input s01_ife0,  // instruction fetch 0
	input s02_ife1,  // instruction fetch 1
	input s03_exec,  // execution
	input s04_wtbk,   // data writeback
	input run,
	output [7:0] iram_radr,
	input [7:0] iram_rdata,
	output [4:0] dram_radr,
	input [7:0] dram_rdata,
	output [5:0] dram_wadr,
	output [7:0] dram_wdata,
	output dram_wen,
	output [2:0] led_rgb,
	output [63:0] cpust_snd,
	input start_trush,
	input cpu_start,
	input [7:0] uart_data

	);

// resources
// PC

reg [7:0] pc;
wire inc_pc;
wire ld_pc;
wire [7:0] ld_value_pc;
reg [7:0] sample_pc;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		pc <= 8'd0;
	else if (start_trush)
		pc <= 8'd0;
	else if (cpu_start)
		pc <= uart_data;
	else if (ld_pc)
		pc <= ld_value_pc;
	else if (inc_pc)
		pc <= pc + 8'd1;
end

assign iram_radr = pc;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		sample_pc <= 8'd0;
	else if (s01_ife0)
		sample_pc <= pc;
end

// stack pointer

reg [4:0] rd_sp;
reg [4:0] wt_sp;
wire stack_underflow;
wire stack_overflow;
wire push_stack;
wire pop_stack;
wire rst_stack;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		rd_sp <= 5'h1f;
	else if (rst_stack)
		rd_sp <= 5'h1f;
	else if (push_stack)
		rd_sp <= rd_sp + 5'd1;
	else if (pop_stack)
		rd_sp <= rd_sp - 5'd1;
end

assign dram_radr = rd_sp;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		wt_sp <= 5'd0;
	else if (rst_stack)
		wt_sp <= 5'd0;
	else if (push_stack)
		wt_sp <= wt_sp + 5'd1;
	else if (pop_stack)
		wt_sp <= wt_sp - 5'd1;
end

assign dram_wadr = wt_sp[4:0];
assign dram_wen = push_stack;
assign stack_underflow = (wt_sp == 5'h00) & pop_stack;
assign stack_overflow = (wt_sp == 5'h1f) & push_stack;

// registers
reg [7:0] a_reg;
reg [7:0] b_reg;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		a_reg <= 8'd0;
	else if (rst_stack)
		a_reg <= 8'd0;
	else if (pop_stack)
		a_reg <= dram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		b_reg <= 8'd0;
	else if (rst_stack)
		b_reg <= 8'd0;
	else if (pop_stack)
		b_reg <= a_reg;
end

// flags
reg flag_st_udflw;
reg flag_st_ovflw;
reg flag_carry;
reg flag_zero;
wire carry_flg;
wire zero_flg;
wire set_carryzero;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		flag_st_udflw <= 1'b0;
	else if (rst_stack)
		flag_st_udflw <= 1'b0;
	else if (stack_underflow)
		flag_st_udflw <= 1'b1;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		flag_st_ovflw <= 1'b0;
	else if (rst_stack)
		flag_st_ovflw <= 1'b0;
	else if (stack_overflow)
		flag_st_ovflw <= 1'b1;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		flag_carry <= 1'b0;
	else if (rst_stack)
		flag_carry <= 1'b0;
	else if (set_carryzero)
		flag_carry <= carry_flg;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		flag_zero <= 1'b0;
	else if (rst_stack)
		flag_zero <= 1'b0;
	else if (set_carryzero)
		flag_zero <= zero_flg;
end

// stage assign
// stage ife0 :  decode instruction

wire [7:0] ir0 = iram_rdata;
//reg [7:0] inst_dbits;

function [7:0] instruction_decoder;
input [4:0] instruction_upperbits;
begin
	case(instruction_upperbits)
		4'd0  : instruction_decoder = 8'b0000_0001;
		4'd2  : instruction_decoder = 8'b0000_0010;
		4'd4  : instruction_decoder = 8'b0000_0100;
		4'd6  : instruction_decoder = 8'b0000_1000;
		4'd8  : instruction_decoder = 8'b0001_0000;
		4'd10 : instruction_decoder = 8'b0010_0000;
		4'd12 : instruction_decoder = 8'b0100_0000;
		4'd14 : instruction_decoder = 8'b1000_0000;
		default : instruction_decoder = 8'd0;
	endcase
end
endfunction

wire [7:0] inst_decode = instruction_decoder( ir0[7:4] );
wire [3:0] flag_decode = ir0[3:0];

wire inst_jmp_p = inst_decode[0];
wire inst_pop_p = inst_decode[1];
wire inst_psh_p = inst_decode[2];
wire inst_add_p = inst_decode[3];
wire inst_sub_p = inst_decode[4];
wire inst_cmp_p = inst_decode[5];
wire inst_out_p = inst_decode[6];
wire inst_clr_p = inst_decode[7];

wire [2:0] dsel_decode = { inst_psh_p&~(ir0[1]|ir0[0])|~inst_psh_p&~ir0[0], ir0[1], ir0[0] };
wire immediate_p = dsel_decode[2];

wire long_inst = (immediate_p & ( inst_psh_p | inst_add_p | inst_sub_p | inst_cmp_p )) | inst_jmp_p | inst_out_p;
wire if1_iread = s01_ife0 & long_inst;
assign inc_pc = (s00_idle & run) | if1_iread;

reg [7:0] sample_inst;
reg [3:0] jump_flags;
reg [2:0] data_select;

// to after stages
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		sample_inst <= 8'd0;
		jump_flags <= 4'd0;
		data_select <= 3'd0;
	end
	else if (s01_ife0) begin
		sample_inst <= ir0;
		jump_flags <= flag_decode;
		data_select <= dsel_decode;
	end
end

// ife1
wire [7:0] inst_dec = instruction_decoder( sample_inst[7:4] );

wire inst_jmp = inst_dec[0];
wire inst_pop = inst_dec[1];
wire inst_psh = inst_dec[2];
wire inst_add = inst_dec[3];
wire inst_sub = inst_dec[4];
wire inst_cmp = inst_dec[5];
wire inst_out = inst_dec[6];
wire inst_clr = inst_dec[7];

wire select_a = data_select[0];
wire select_b = data_select[1];
wire immediate = data_select[2];

reg if1_fetch;
reg [7:0] if1;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		if1_fetch <= 1'b0;
	else
		if1_fetch <= if1_iread;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		if1 <= 8'd0;
	else if (if1_fetch)
		if1 <= iram_rdata;
end

// execution
// JMP

wire [3:0] current_flags = { flag_st_udflw, flag_st_ovflw, flag_carry, flag_zero };
wire jump_condition = |(current_flags & jump_flags) | ~( |jump_flags );

assign ld_pc = jump_condition & s03_exec & inst_jmp;
assign ld_value_pc = if1;

// POP
assign pop_stack = (inst_pop | inst_out) & s03_exec;

// PSH
wire [8:0] result;
wire [7:0] dwbus_select;
wire [7:0] dwbus;

assign dwbus_select = inst_add | inst_sub ? result[7:0]:
                      select_a ? a_reg :
                      select_b ? b_reg : if1;

/*
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		dwbus <= 8'd0;
	else if (s03_exec)
		dwbus <= dwbus_select;
end
*/
// for logic compression
assign dwbus = dwbus_select;

// ADD
wire [7:0] add_value = immediate ? if1 : b_reg;
wire [7:0] comp_value = (~add_value) + 8'd1;
wire [7:0] addsub_value = inst_add ? add_value : comp_value;

assign result = { 1'b0, a_reg } + {  1'b0, addsub_value };
wire carry = result[8] ^ ~inst_add;
wire zero = ~(|result[7:0]);

// SUB & CMP
assign carry_flg = carry & (inst_add | inst_sub | inst_cmp);
assign zero_flg = zero & (inst_add | inst_sub | inst_cmp);

assign set_carryzero = (inst_add | inst_sub | inst_cmp) & s03_exec;

// OUT
reg [2:0] out_reg;

wire port0_wt = inst_out & (if1 == 8'd0) & s03_exec;

// should be placed outside cpu
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		out_reg <= 3'd0;
	else if (port0_wt)
		out_reg <= dram_rdata;
end

wire red = out_reg[2];
wire green = out_reg[1];
wire blue = out_reg[0];
assign led_rgb = { ~red, ~blue, ~green };

// CLR : clear data stack
assign rst_stack = (inst_clr & s03_exec) | start_trush;

// stack write back

assign push_stack = (inst_psh | inst_add | inst_sub) & s04_wtbk;
assign dram_wdata = dwbus;

// CPU status send to uart

wire [7:0] flags = { 4'd0, flag_st_udflw, flag_st_ovflw, flag_carry, flag_zero };

assign cpust_snd = { sample_pc, sample_inst, if1, 3'd0, rd_sp, a_reg, b_reg, dwbus, flags };

endmodule
