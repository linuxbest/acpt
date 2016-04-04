// avs_timing.v --- 
// 
// Filename: avs_timing.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 11 12:46:44 2016 (-0800)
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
module avs_timing (/*AUTOARG*/
   // Outputs
   avs_waitrequest,
   // Inputs
   sys_clk, sys_rst, avs_read, avs_write
   );
   input sys_clk;
   input sys_rst;

   input avs_read;
   input avs_write;
   output avs_waitrequest;

   reg 	  register_ready_reg;
   reg 	  register_access_sreg;
   always @(posedge sys_clk)
     begin
	if (sys_rst || register_ready_reg)
	  begin
	     register_access_sreg <= 1'b0;
	  end
	else if (avs_read | avs_write)
	  begin
	     register_access_sreg <= 1'b1;
	  end
     end // always @ (posedge unex_clk)
   wire register_access;
   assign register_access = register_access_sreg;

   reg 	register_access_reg;
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     register_access_reg <= 1'b0;
	  end
	else
	  begin
	     register_access_reg <= register_access;
	  end
     end // always @ (posedge unex_clk)

   wire register_access_rise;
   assign register_access_rise = ~register_access_reg & register_access;

   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     register_ready_reg <= 1'b0;
	  end
	else
	  begin
	     register_ready_reg <= register_access_rise;
	  end
     end
   assign avs_waitrequest = ~register_ready_reg;
endmodule
//
// avs_timing.v ends here
