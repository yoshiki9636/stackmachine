// Tang Nano UART monitor by yoshiki9636

module uart_controller (
    input clk,
    input rst_n,
	input [7:0] rout,
	input rout_en,
	// to ctrl logics
	output reg [7:0] uart_data,
	output reg cpu_start,
	output reg write_address_set,
	output reg write_data_en,
	output reg read_start_set,
	output reg read_end_set,
	output reg read_stop,
	input dump_running,
	output reg start_trush,
	input trush_running,
	output reg start_step,
	input cpu_running,
	output crlf_in,
	output reg quit_cmd,
	output reg start_rdstack

);

// read data decoder

reg [7:0] pdata;
reg data_en;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        pdata <= 8'd0;
    else if (rout_en)
        pdata <= rout;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
		data_en <= 1'b0;
	else
		data_en <= rout_en;
end

function [23:0] data_decoder;
input [7:0] pdata;
begin
	case(pdata)
		8'h30 : data_decoder = 24'b0000_0000_0000_0000_0000_0001; // 0
		8'h31 : data_decoder = 24'b0000_0000_0000_0000_0000_0010; // 1
		8'h32 : data_decoder = 24'b0000_0000_0000_0000_0000_0100; // 2
		8'h33 : data_decoder = 24'b0000_0000_0000_0000_0000_1000; // 3
		8'h34 : data_decoder = 24'b0000_0000_0000_0000_0001_0000; // 4
		8'h35 : data_decoder = 24'b0000_0000_0000_0000_0010_0000; // 5
		8'h36 : data_decoder = 24'b0000_0000_0000_0000_0100_0000; // 6
		8'h37 : data_decoder = 24'b0000_0000_0000_0000_1000_0000; // 7
		8'h38 : data_decoder = 24'b0000_0000_0000_0001_0000_0000; // 8
		8'h39 : data_decoder = 24'b0000_0000_0000_0010_0000_0000; // 9
		8'h61 : data_decoder = 24'b0000_0000_0000_0100_0000_0000; // a
		8'h62 : data_decoder = 24'b0000_0000_0000_1000_0000_0000; // b
		8'h63 : data_decoder = 24'b0000_0000_0001_0000_0000_0000; // c
		8'h64 : data_decoder = 24'b0000_0000_0010_0000_0000_0000; // d
		8'h65 : data_decoder = 24'b0000_0000_0100_0000_0000_0000; // e
		8'h66 : data_decoder = 24'b0000_0000_1000_0000_0000_0000; // f
		8'h67 : data_decoder = 24'b0000_0001_0000_0000_0000_0000; // g : go PC to address (run program)
		8'h71 : data_decoder = 24'b0000_0010_0000_0000_0000_0000; // q : quit,stop,finish
		8'h77 : data_decoder = 24'b0000_0100_0000_0000_0000_0000; // w : write data to memory
		8'h72 : data_decoder = 24'b0000_1000_0000_0000_0000_0000; // r : read data from memory and dump
		8'h74 : data_decoder = 24'b0001_0000_0000_0000_0000_0000; // t : trushed memory and 0 clear
		8'h73 : data_decoder = 24'b0010_0000_0000_0000_0000_0000; // s : step execution
		8'h70 : data_decoder = 24'b0100_0000_0000_0000_0000_0000; // p : 
		8'h0d : data_decoder = 24'b1000_0000_0000_0000_0000_0000; // CR : change to CRLF
		default : data_decoder = 24'd0;
	endcase
end
endfunction

wire [23:0] decode_bits = data_decoder( pdata );

function [3:0] bin_encoder;
input [15:0] hot_code;
begin
	case(hot_code)
		16'b0000_0000_0000_0001 : bin_encoder = 4'h0;
		16'b0000_0000_0000_0010 : bin_encoder = 4'h1;
		16'b0000_0000_0000_0100 : bin_encoder = 4'h2;
		16'b0000_0000_0000_1000 : bin_encoder = 4'h3;
		16'b0000_0000_0001_0000 : bin_encoder = 4'h4;
		16'b0000_0000_0010_0000 : bin_encoder = 4'h5;
		16'b0000_0000_0100_0000 : bin_encoder = 4'h6;
		16'b0000_0000_1000_0000 : bin_encoder = 4'h7;
		16'b0000_0001_0000_0000 : bin_encoder = 4'h8;
		16'b0000_0010_0000_0000 : bin_encoder = 4'h9;
		16'b0000_0100_0000_0000 : bin_encoder = 4'ha;
		16'b0000_1000_0000_0000 : bin_encoder = 4'hb;
		16'b0001_0000_0000_0000 : bin_encoder = 4'hc;
		16'b0010_0000_0000_0000 : bin_encoder = 4'hd;
		16'b0100_0000_0000_0000 : bin_encoder = 4'he;
		16'b1000_0000_0000_0000 : bin_encoder = 4'hf;
		default : bin_encoder = 4'h0;
	endcase
end
endfunction

wire [3:0] half_data = bin_encoder( decode_bits[15:0] ) ;
wire num_char = | decode_bits[15:0];

wire cmd_g = decode_bits[16] & data_en;
wire cmd_q = decode_bits[17] & data_en;
wire cmd_w = decode_bits[18] & data_en;
wire cmd_r = decode_bits[19] & data_en;
wire cmd_t = decode_bits[20] & data_en;
wire cmd_s = decode_bits[21] & data_en;
wire cmd_p = decode_bits[22] & data_en;
wire cmd_crlf = decode_bits[23] & data_en;

// command format
// g : goto PC address ( run program until quit ) : format:  g <start addess>
// q : quit from any command                      : format:  q
// w : write date to memory                       : format:  w <start adderss> <data> ....<data> q
// r : read data from memory                      : format:  r <start address> <end adderss>
// t : trashed memory data and 0 clear            : format:  t
// s : program step execution                     : format:  s
// p : stack dump                                 : format:  p
// state machine

reg bin_data_valid;

reg [3:0] cmd_status;
wire [3:0] next_cmd_status;

`define C_STAIDLE 4'd0
`define C_GSETNUM 4'd1
`define C_GOTONUM 4'd2
`define C_WADRNUM 4'd3
`define C_WDATNUM 4'd4
`define C_RSTARTN 4'd5
`define C_RENDNUM 4'd6
`define C_RDUMPDT 4'd7
`define C_TRUSHDT 4'd8
`define C_STEPRUN 4'd9
`define C_RDSTACK 4'd10


function [3:0] cmd_statemachine;
input [3:0] cmd_status;
input cmd_g;
input cmd_q;
input cmd_w;
input cmd_r;
input cmd_t;
input cmd_s;
input bin_data_valid;
input dump_running;
input trush_running;
input cpu_running;

begin
	case(cmd_status)
		`C_STAIDLE :
			casez({cmd_g,cmd_w,cmd_r,cmd_t,cmd_s,cmd_p})
				6'b1?_???? : cmd_statemachine = `C_GSETNUM;
				6'b01_???? : cmd_statemachine = `C_WADRNUM;
				6'b00_1??? : cmd_statemachine = `C_RSTARTN;
				6'b00_01?? : cmd_statemachine = `C_TRUSHDT;
				6'b00_001? : cmd_statemachine = `C_STEPRUN;
				6'b00_0001 : cmd_statemachine = `C_RDSTACK;
				default   : cmd_statemachine = `C_STAIDLE;
			endcase
		`C_GSETNUM :
			casez({cmd_q,bin_data_valid})
				2'b1? : cmd_statemachine = `C_STAIDLE;
				2'b01 : cmd_statemachine = `C_GOTONUM;
				default : cmd_statemachine = `C_GSETNUM;
			endcase
		`C_GOTONUM :
			if (cmd_q)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_GOTONUM;
		`C_WADRNUM :
			casez({cmd_q,bin_data_valid})
				2'b1? : cmd_statemachine = `C_STAIDLE;
				2'b01 : cmd_statemachine = `C_WDATNUM;
				default : cmd_statemachine = `C_WADRNUM;
			endcase
		`C_WDATNUM :
			if (cmd_q)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_WDATNUM;
		`C_RSTARTN :
			casez({cmd_q,bin_data_valid})
				2'b1? : cmd_statemachine = `C_STAIDLE;
				2'b01 : cmd_statemachine = `C_RENDNUM;
				default : cmd_statemachine = `C_RSTARTN;
			endcase
		`C_RENDNUM :
			casez({cmd_q,bin_data_valid})
				2'b1? : cmd_statemachine = `C_STAIDLE;
				2'b01 : cmd_statemachine = `C_RDUMPDT;
				default : cmd_statemachine = `C_RENDNUM;
			endcase
		`C_RDUMPDT :
			if (cmd_q | ~dump_running)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_RDUMPDT;
		`C_TRUSHDT :
			if (cmd_q | ~trush_running)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_TRUSHDT;
		`C_STEPRUN :
			if (cmd_q | ~cpu_running)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_STEPRUN;
		`C_RDSTACK :
			if (cmd_q | ~dump_running)
				cmd_statemachine = `C_STAIDLE;
			else
				cmd_statemachine = `C_RDSTACK;
		default : cmd_statemachine = `C_STAIDLE;
	endcase
end
endfunction

assign next_cmd_status = cmd_statemachine(
							cmd_status,
							cmd_g,
							cmd_q,
							cmd_w,
							cmd_r,
							cmd_t,
							cmd_s,
							bin_data_valid,
							dump_running,
							trush_running,
							cpu_running
							);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_status <= `C_STAIDLE;
	else
		cmd_status <= next_cmd_status;
end

// decode signals

wire idle_status = ( cmd_status == `C_STAIDLE );
wire gcmd_setnum = ( cmd_status == `C_GSETNUM );
wire wcmd_setnum = ( cmd_status == `C_WADRNUM );
wire wcmd_setdat = ( cmd_status == `C_WDATNUM );
wire rcmd_setsta = ( cmd_status == `C_RSTARTN );
wire rcmd_setend = ( cmd_status == `C_RENDNUM );
wire rcmd_dumpdt = ( cmd_status == `C_RDUMPDT );

wire g_crlf = ( cmd_status == `C_GSETNUM ) & ( next_cmd_status == `C_GOTONUM );
wire r_crlf = ( cmd_status == `C_RENDNUM ) & ( next_cmd_status == `C_RDUMPDT );
wire w_crlf = ( cmd_status == `C_WADRNUM ) & ( next_cmd_status == `C_WDATNUM );


assign crlf_in = g_crlf | cmd_q | r_crlf | w_crlf | cmd_t | cmd_s | cmd_crlf;

// data setter
reg [3:0] upper_data;
reg [3:0] lower_data;
reg lower_sel;

wire bin_data_set = data_en & num_char & (gcmd_setnum | wcmd_setnum | wcmd_setdat | rcmd_setsta | rcmd_setend);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		lower_sel <= 1'b0;
	else if (cmd_q)
		lower_sel <= 1'b0;
	else if (bin_data_set)
		lower_sel <= ~lower_sel;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		bin_data_valid <= 1'b0;
	else
		bin_data_valid <= lower_sel & bin_data_set;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		upper_data <= 3'd0;
	else if (bin_data_set & ~lower_sel)
		upper_data <= half_data ;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		lower_data <= 3'd0;
	else if (bin_data_set & lower_sel)
		lower_data <= half_data ;
end

wire [7:0] bin_data;
assign bin_data = { upper_data, lower_data };

// g command

wire ctrl_valid = gcmd_setnum | wcmd_setnum | wcmd_setdat | rcmd_setsta | rcmd_setend;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		uart_data <= 8'd0;
	else if (ctrl_valid & bin_data_valid)
		uart_data <= bin_data;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cpu_start <= 1'b0;
	else
		cpu_start <= gcmd_setnum & bin_data_valid;
end

// w command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		write_address_set <= 1'b0;
	else
		write_address_set <= wcmd_setnum & bin_data_valid;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		write_data_en <= 1'b0;
	else
		write_data_en <= wcmd_setdat & bin_data_valid;
end

// r command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		read_start_set <= 1'b0;
	else
		read_start_set <= rcmd_setsta & bin_data_valid;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		read_end_set <= 1'b0;
	else
		read_end_set <= rcmd_setend & bin_data_valid;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		read_stop <= 1'b0;
	else
		read_stop <= rcmd_dumpdt & cmd_q;
end

// t command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		start_trush <= 1'b0;
	else
		start_trush <= idle_status & cmd_t;
end

// s command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		start_step <= 1'b0;
	else
		start_step <= idle_status & cmd_s;
end

// q command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		quit_cmd <= 1'b0;
	else
		quit_cmd <= cmd_q;
end

// p command

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		start_rdstack <= 1'b0;
	else
		start_rdstack <= idle_status & cmd_p;
end

endmodule