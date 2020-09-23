
module sm_top(
	input rst_n,
	input fpga_rx,
	output fpga_tx,
	output [2:0] led_rgb
	);

wire [4:0] d_ram_radr;
wire [4:0] d_ram_wadr;
wire [4:0] dram_radr;
wire [4:0] dram_wadr;
wire [63:0] cpust_snd;
wire [31:0] rdata_snd;
wire [7:0] d_ram_rdata;
wire [7:0] d_ram_wdata;
wire [7:0] dram_rdata;
wire [7:0] dram_wdata;
wire [7:0] i_ram_radr;
wire [7:0] i_ram_rdata;
wire [7:0] i_ram_wadr;
wire [7:0] i_ram_wdata;
wire [7:0] iram_radr;
wire [7:0] iram_rdata;
wire [7:0] rout;
wire [7:0] uart_data;
wire cpu_running;
wire cpu_start;
wire cpust_start;
wire crlf_in;
wire d_ram_wen;
wire dram_wen;
wire dump_cpu;
wire dump_running;
wire flushing_wq;
wire i_ram_wen;
wire quit_cmd;
wire rdata_snd_start;
wire read_end_set;
wire read_start_set;
wire read_stop;
wire rout_en;
wire run;
wire s00_idle;
wire s01_ife0;
wire s02_ife1;
wire s03_exec;
wire s04_wtbk;
wire start_rdstack;
wire start_step;
wire start_trush;
wire trush_running;
wire write_address_set;
wire write_data_en;

clkgen clkgen (
	.clk(clk)
	);

ramblk ramblk (
	.clk(clk),
	.iram_radr(iram_radr),
	.iram_rdata(iram_rdata),
	.dram_radr(dram_radr),
	.dram_rdata(dram_rdata),
	.dram_wadr(dram_wadr),
	.dram_wdata(dram_wdata),
	.dram_wen(dram_wen),
	.i_ram_radr(i_ram_radr),
	.i_ram_rdata(i_ram_rdata),
	.i_ram_wadr(i_ram_wadr),
	.i_ram_wdata(i_ram_wdata),
	.i_ram_wen(i_ram_wen),
	.d_ram_radr(d_ram_radr),
	.d_ram_rdata(d_ram_rdata),
	.d_ram_wadr(d_ram_wadr),
	.d_ram_wdata(d_ram_wdata),
	.d_ram_wen(d_ram_wen),
	.dump_running(dump_running)
	);

sm_logics sm_logics (
	.clk(clk),
	.rst_n(rst_n),
	.s00_idle(s00_idle),
	.s01_ife0(s01_ife0),
	.s02_ife1(s02_ife1),
	.s03_exec(s03_exec),
	.s04_wtbk(s04_wtbk),
	.run(run),
	.iram_radr(iram_radr),
	.iram_rdata(iram_rdata),
	.dram_radr(dram_radr),
	.dram_rdata(dram_rdata),
	.dram_wadr(dram_wadr),
	.dram_wdata(dram_wdata),
	.dram_wen(dram_wen),
	.led_rgb(led_rgb),
	.cpust_snd(cpust_snd),
	.start_trush(start_trush),
	.cpu_start(cpu_start),
	.uart_data(uart_data)
	);

sm_status sm_status (
	.clk(clk),
	.rst_n(rst_n),
	.run(run),
	.s00_idle(s00_idle),
	.s01_ife0(s01_ife0),
	.s02_ife1(s02_ife1),
	.s03_exec(s03_exec),
	.s04_wtbk(s04_wtbk)
	);

uart_controller uart_controller (
	.clk(clk),
	.rst_n(rst_n),
	.rout(rout),
	.rout_en(rout_en),
	.uart_data(uart_data),
	.cpu_start(cpu_start),
	.write_address_set(write_address_set),
	.write_data_en(write_data_en),
	.read_start_set(read_start_set),
	.read_end_set(read_end_set),
	.read_stop(read_stop),
	.dump_running(dump_running),
	.start_trush(start_trush),
	.trush_running(trush_running),
	.start_step(start_step),
	.cpu_running(cpu_running),
	.crlf_in(crlf_in),
	.quit_cmd(quit_cmd),
	.start_rdstack(start_rdstack)
	);

uart_if uart_if (
	.clk(clk),
	.rst_n(rst_n),
	.fpga_rx(fpga_rx),
	.fpga_tx(fpga_tx),
	.rout(rout),
	.rout_en(rout_en),
	.rdata_snd_start(rdata_snd_start),
	.rdata_snd(rdata_snd),
	.flushing_wq(flushing_wq),
	.cpust_start(cpust_start),
	.cpust_snd(cpust_snd),
	.crlf_in(crlf_in),
	.dump_cpu(dump_cpu)
	);

uart_logics uart_logics (
	.clk(clk),
	.rst_n(rst_n),
	.i_ram_radr(i_ram_radr),
	.i_ram_rdata(i_ram_rdata),
	.i_ram_wadr(i_ram_wadr),
	.i_ram_wdata(i_ram_wdata),
	.i_ram_wen(i_ram_wen),
	.d_ram_radr(d_ram_radr),
	.d_ram_rdata(d_ram_rdata),
	.d_ram_wadr(d_ram_wadr),
	.d_ram_wdata(d_ram_wdata),
	.d_ram_wen(d_ram_wen),
	.s00_idle(s00_idle),
	.s04_wtbk(s04_wtbk),
	.run(run),
	.uart_data(uart_data),
	.cpu_start(cpu_start),
	.quit_cmd(quit_cmd),
	.write_address_set(write_address_set),
	.write_data_en(write_data_en),
	.read_start_set(read_start_set),
	.read_end_set(read_end_set),
	.read_stop(read_stop),
	.rdata_snd_start(rdata_snd_start),
	.rdata_snd(rdata_snd),
	.flushing_wq(flushing_wq),
	.dump_running(dump_running),
	.start_trush(start_trush),
	.trush_running(trush_running),
	.start_step(start_step),
	.cpu_running(cpu_running),
	.dump_cpu(dump_cpu),
	.cpust_start(cpust_start),
	.start_rdstack(start_rdstack)
	);

endmodule