module uart_logics(
	input clk,
	input rst_n,
	output [7:0] i_ram_radr,
	input [7:0] i_ram_rdata,
	output [7:0] i_ram_wadr,
	output [7:0] i_ram_wdata,
	output i_ram_wen,
	output [4:0] d_ram_radr,
	input [7:0] d_ram_rdata,
	output [4:0] d_ram_wadr,
	output [7:0] d_ram_wdata,
	output d_ram_wen,
	input s00_idle,
	input s04_wtbk,
	// from controller
	output run,
	input [7:0] uart_data,
	input cpu_start,
	input quit_cmd,
	input write_address_set,
	input write_data_en,
	input read_start_set,
	input read_end_set,
	input read_stop,
	output rdata_snd_start,
	output [31:0] rdata_snd,
	input flushing_wq,
	output dump_running,
	input start_trush,
	output trush_running,
	input start_step,
	output wire cpu_running,
	input dump_cpu,
	output cpust_start,
	input start_rdstack

	);


// CPU running state

reg cpu_run_state;
reg step_reserve;
reg cupst_snd_wait;
wire rdata_snd_wait;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cpu_run_state <= 1'b0;
	else if (quit_cmd)
		cpu_run_state <= 1'b0;	
	else if (cpu_start)
		cpu_run_state <= 1'b1;
end

assign cpu_running = cpu_run_state & ~(rdata_snd_wait | cupst_snd_wait);

wire step_idle_nodump = s00_idle & ~dump_cpu;
wire step_start_cond = step_idle_nodump & ~(rdata_snd_wait | cupst_snd_wait);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		step_reserve <= 1'b0;
	else if (step_start_cond)
		step_reserve <= 1'b0;	
	else if (~step_idle_nodump & start_step)
		step_reserve <= 1'b1;
end

wire step_run = step_start_cond & (step_reserve | start_step);

// sequencer start signal
assign run = cpu_running | step_run;

// iram write address 
reg [7:0] cmd_wadr_cntr;
wire [7:0] trush_adr;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_wadr_cntr <= 8'd0;
	else if (write_address_set)
		cmd_wadr_cntr <= uart_data;
	else if (write_data_en)
		cmd_wadr_cntr <= cmd_wadr_cntr + 8'd1;
end

assign i_ram_wadr = trush_running ? trush_adr : cmd_wadr_cntr;
assign i_ram_wdata = trush_running ? 8'd0 : uart_data;
assign i_ram_wen = write_data_en | trush_running;

// iram read address
reg [7:0] cmd_read_end;
reg [8:0] cmd_read_adr;
reg i_ram_sel;

wire dump_end;
wire radr_cntup;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_read_adr <= 9'd0;
	else if (read_start_set)
		cmd_read_adr <= uart_data;
	else if (start_rdstack)
		cmd_read_adr <= 9'd0;
	else if (radr_cntup)
		cmd_read_adr <= cmd_read_adr + 9'd1;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_read_end <= 8'd0;
	else if (read_end_set)
		cmd_read_end <= uart_data;
end

assign dump_end = i_ram_sel ? (cmd_read_adr >= { 1'b0, cmd_read_end }):
                              (cmd_read_adr >= 9'd31);

assign i_ram_radr = cmd_read_adr[7:0];
assign d_ram_radr = cmd_read_adr[4:0];

`define D_IDLE 2'd0
`define D_READ 2'd1
`define D_WAIT 2'd2
reg [2:0] status_dump;
wire [2:0] next_status_dump;

reg [1:0] i_ram_ofs;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		i_ram_ofs <= 2'd0;
	else if (status_dump == `D_READ)
		i_ram_ofs <= i_ram_ofs + 2'd1;
end

wire i_ram_ofs_end = (i_ram_ofs == 2'd3);

function [2:0] dump_status;
input [2:0] status_dump;
input read_end_set;
input start_rdstack;
input read_stop;
input i_ram_ofs_end;
input flushing_wq;
input dump_end;
begin
	case(status_dump)
		`D_IDLE :
			if (read_end_set | start_rdstack)
				dump_status = `D_READ;
			else
				dump_status = `D_IDLE;
		`D_READ :
			if (read_stop)
				dump_status = `D_IDLE;
			else if (i_ram_ofs_end)
				dump_status = `D_WAIT;
			else
				dump_status = `D_READ;			
		`D_WAIT :
			if (read_stop)
				dump_status = `D_IDLE;
			else if (flushing_wq & dump_end)
				dump_status = `D_IDLE;
			else if (flushing_wq & ~dump_end)
				dump_status = `D_READ;
			else
				dump_status = `D_WAIT;
		default : dump_status = `D_IDLE;
	endcase
end
endfunction

assign next_status_dump = dump_status(
							status_dump,
							read_end_set,
							start_rdstack,
							read_stop,
							i_ram_ofs_end,
							flushing_wq,
							dump_end);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		status_dump <= 3'd0;
	else
		status_dump <= next_status_dump;
end

assign radr_cntup = (status_dump == `D_READ);
assign dump_running = (status_dump != `D_IDLE);
assign rdata_snd_wait = (status_dump == `D_WAIT);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		i_ram_sel <= 1'b0;
	else if ( read_end_set )
		i_ram_sel <= 1'b1;
	else if ( start_rdstack )
		i_ram_sel <= 1'b0;
end

wire en0_data = radr_cntup & (i_ram_ofs == 3'd1);
wire en1_data = radr_cntup & (i_ram_ofs == 3'd2);
wire en2_data = radr_cntup & (i_ram_ofs == 3'd3);
reg en3_data;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		en3_data <= 1'b0;
	else
		en3_data <= en2_data;
end

reg [7:0] data_0;
reg [7:0] data_1;
reg [7:0] data_2;
reg [7:0] data_3;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_0 <= 8'd0;
	else if (en0_data)
		data_0 <= i_ram_sel ? i_ram_rdata : d_ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_1 <= 8'd0;
	else if (en1_data)
		data_1 <= i_ram_sel ? i_ram_rdata : d_ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_2 <= 8'd0;
	else if (en2_data)
		data_2 <= i_ram_sel ? i_ram_rdata : d_ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_3 <= 8'd0;
	else if (en3_data)
		data_3 <= i_ram_sel ? i_ram_rdata : d_ram_rdata;
end


assign rdata_snd = { data_0, data_1, data_2, data_3 };

// trashing memory data
reg [8:0] trash_cntr;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		trash_cntr <= 9'd0;
	else if (start_trush)
		trash_cntr <= 9'h100;
	else if (trash_cntr[8])
		trash_cntr <= trash_cntr + 9'd1;
end

assign trush_adr = trash_cntr[7:0];
assign trush_running = trash_cntr[8];

assign d_ram_wadr = trash_cntr[4:0];
assign d_ram_wdata = 8'd0;
assign d_ram_wen = trush_running;

// send CPU status to UART i/f

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cupst_snd_wait <= 1'b0;
	else if (flushing_wq)
		cupst_snd_wait <= 1'b0;
	else if (s04_wtbk)
		cupst_snd_wait <= 1'b1;
end

reg cpust_snd_wait_dly;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cpust_snd_wait_dly <= 1'b0;
	else
		cpust_snd_wait_dly <= cupst_snd_wait;
end

assign cpust_start = cupst_snd_wait & ~cpust_snd_wait_dly;

reg rdata_snd_wait_dly;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		rdata_snd_wait_dly <= 1'b0;
	else
		rdata_snd_wait_dly <= rdata_snd_wait;
end

assign rdata_snd_start = rdata_snd_wait & ~rdata_snd_wait_dly;


endmodule
