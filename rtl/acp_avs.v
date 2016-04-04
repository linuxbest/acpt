// acp_avs.v --- 
// 
// Filename: acp_avs.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Apr  1 10:13:03 2016 (-0700)
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
module acp_avs (/*AUTOARG*/
   // Outputs
   avs_readdata, avs_readdatavalid, avs_waitrequest, hps2ip_base,
   hps2ip_ci_base, hps2ip_mindex, hps2ip_pi, ip2hps_base,
   ip2hps_pi_base, ip2hps_mindex, ip2hps_ci, dma_en, cycle, c_awcache,
   c_awprot, c_awuser, c_arcache, c_arprot, c_aruser,
   // Inputs
   sys_clk, sys_rst, avs_address, avs_read, avs_write, avs_writedata,
   hps2ip_ci, ip2hps_pi
   );
   input sys_clk;
   input sys_rst;

   input [11:0] avs_address;
   input 	avs_read;
   input 	avs_write;
   input [31:0] avs_writedata;
   output [31:0] avs_readdata;
   output 	 avs_readdatavalid;
   output 	 avs_waitrequest;

   // hps2ip
   output [31:5] hps2ip_base;
   output [31:5] hps2ip_ci_base;
   output [16:0] hps2ip_mindex;
   output [15:0] hps2ip_pi;
   input [15:0]  hps2ip_ci;

   // ip2hps
   output [31:5] ip2hps_base;
   output [31:5] ip2hps_pi_base;
   output [16:0] ip2hps_mindex;
   output [15:0] ip2hps_ci;
   input [15:0]  ip2hps_pi;

   output 	 dma_en;
   output [31:0] cycle;

   output [3:0]  c_awcache;
   output [2:0]  c_awprot;
   output [4:0]  c_awuser;
   
   output [3:0]  c_arcache;
   output [2:0]  c_arprot;
   output [4:0]  c_aruser;   
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		avs_readdata;
   reg			avs_readdatavalid;
   reg			dma_en;
   reg [31:5]		hps2ip_base;
   reg [31:5]		hps2ip_ci_base;
   reg [16:0]		hps2ip_mindex;
   reg [15:0]		hps2ip_pi;
   reg [31:5]		ip2hps_base;
   reg [15:0]		ip2hps_ci;
   reg [16:0]		ip2hps_mindex;
   reg [31:5]		ip2hps_pi_base;
   // End of automatics

   /*avs_timing AUTO_TEMPLATE (
    .sys_clk (sys_clk),
    .sys_rst (sys_rst),
    )*/
   avs_timing
     avs_timing (/*AUTOINST*/
		 // Outputs
		 .avs_waitrequest	(avs_waitrequest),
		 // Inputs
		 .sys_clk		(sys_clk),		 // Templated
		 .sys_rst		(sys_rst),		 // Templated
		 .avs_read		(avs_read),
		 .avs_write		(avs_write));

   reg [31:0] 		readdata;
   always @(posedge sys_clk)
     begin
	avs_readdata <= readdata;
	avs_readdatavalid <= avs_read;
     end

   reg [31:0] cycle;
   reg [11:0] w_attr;
   reg [11:0] r_attr;
   wire [3:0] addr;
   assign addr = avs_address[5:2];
   always @(*)
     begin
	readdata = 32'h0;
	case (addr)
	  4'h0: readdata = {hps2ip_base, 5'h0};
	  4'h2: readdata = hps2ip_mindex;
	  4'h3: readdata = hps2ip_pi;
	  4'h4: readdata = hps2ip_ci;

	  4'h7: readdata = cycle;

	  4'h8: readdata = {ip2hps_base, 5'h0};
	  4'h9: readdata = {ip2hps_pi_base, 5'h0};
	  4'ha: readdata = ip2hps_mindex;
	  4'hb: readdata = ip2hps_pi;
	  4'hc: readdata = ip2hps_ci;

	  4'he: readdata = {4'h0, r_attr, 4'h0, w_attr};
	  4'hf: readdata = {31'h0, dma_en};
	endcase
     end // always @ (*)
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     dma_en              <= 1'b0;
	     r_attr              <= 0;
	     w_attr              <= 0;
	  end
	else if (avs_write && ~avs_waitrequest)
	  case (addr)
	    4'h0: hps2ip_base    <= avs_writedata[31:5];
	    4'h2: hps2ip_mindex  <= avs_writedata[16:0];
	    4'h3: hps2ip_pi      <= avs_writedata[15:0];

	    4'h8: ip2hps_base    <= avs_writedata[31:5];
	    4'h9: ip2hps_pi_base <= avs_writedata[31:5];
	    4'ha: ip2hps_mindex  <= avs_writedata[16:0];
	    4'hc: ip2hps_ci      <= avs_writedata[15:0];

	    4'he: begin
	       r_attr            <= avs_writedata[27:16];
	       w_attr            <= avs_writedata[11:0];
	    end

	    4'hf: dma_en         <= avs_writedata[0];
	  endcase
     end // always @ (posedge sys_clk)
   assign {c_awuser, c_awcache, c_awprot} = w_attr;
   assign {c_aruser, c_arcache, c_arprot} = r_attr;

   always @(posedge sys_clk)
     begin
	if (~dma_en)
	  begin
	     cycle <= 0;
	  end
	else
	  begin
	     cycle <= cycle + 1;
	  end
     end // always @ (posedge sys_clk)
endmodule
//
// acp_avs.v ends here
