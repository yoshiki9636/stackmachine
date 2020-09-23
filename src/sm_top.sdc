//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2.02 Beta
//Created Time: 2020-09-13 18:09:39
create_clock -name clk -period 20 -waveform {0 10} [get_nets {clk}]
