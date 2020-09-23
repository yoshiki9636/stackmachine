// Tang Nano clock generator by yoshiki9636

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