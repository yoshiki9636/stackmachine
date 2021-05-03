/*
 * Stack Machine CPU Sample
 *   Clock Generator Module for Tang Nano
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2020 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module clkgen (
    output reg clk
);

`define SIMULATION
`ifdef SIMULATION
initial clk = 0;

always #5 clk <= ~clk;

`else
wire oscclk;
// clock & PLL
Gowin_OSC osc1(
        .oscout(oscclk) //output oscout
);
Gowin_PLL pll1(
    .clkout(clk), //output clkout
    .clkin(oscclk) //input clkin
);
`endif

endmodule