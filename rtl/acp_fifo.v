// acp_fifo.v --- 
// 
// Filename: acp_fifo.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Apr  1 12:59:20 2016 (-0700)
// Version: 
// Last-Updated: 
//           By: 
//     Update #: 0
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// 
// 
// 

// Change log:
// 
// 
// 

// -------------------------------------
// Naming Conventions:
// 	active low signals                 : "*_n"
// 	clock signals                      : "clk", "clk_div#", "clk_#x"
// 	reset signals                      : "rst", "rst_n"
// 	generics                           : "C_*"
// 	user defined types                 : "*_TYPE"
// 	state machine next state           : "*_ns"
// 	state machine current state        : "*_cs"
// 	combinatorial signals              : "*_com"
// 	pipelined or register delay signals: "*_d#"
// 	counter signals                    : "*cnt*"
// 	clock enable signals               : "*_ce"
// 	internal version of output port    : "*_i"
// 	device pins                        : "*_pin"
// 	ports                              : - Names begin with Uppercase
// Code:
module acp_fifo (/*AUTOARG*/
   // Outputs
   fifo_usedw, fifo_rdata, fifo_empty,
   // Inputs
   sys_clk, sys_rst, fifo_wdata, fifo_wren, fifo_rden
   );
   input sys_clk;
   input sys_rst;

   input [255:0] fifo_wdata;
   input 	 fifo_wren;
   output [3:0]  fifo_usedw;

   output [255:0] fifo_rdata;
   output 	  fifo_empty;
   input 	  fifo_rden;

   scfifo
     fifo (.rdreq (fifo_rden),
	   .clock (sys_clk),
	   .wrreq (fifo_wren),
	   .data  (fifo_wdata),
	   .usedw (fifo_usedw),
	   .empty (fifo_empty),
	   .q     (fifo_rdata),
	   .full  () ,
	   .aclr  (sys_rst),
	   .almost_empty (),
	   .almost_full (),
	   .sclr ());
   defparam
     fifo.add_ram_output_register = "ON",
     fifo.intended_device_family = "Stratix IV",
     fifo.lpm_numwords = 16,
     fifo.lpm_showahead = "ON",
     fifo.lpm_type = "scfifo",
     fifo.lpm_width = 256,
     fifo.lpm_widthu = 4,
     fifo.overflow_checking = "ON",
     fifo.underflow_checking = "ON",
     fifo.use_eab = "ON";

endmodule
// 
// acp_fifo.v ends here
