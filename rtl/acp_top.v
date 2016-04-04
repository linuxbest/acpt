// acp_top.v --- 
// 
// Filename: acp_top.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Apr  1 09:53:57 2016 (-0700)
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
module acp_top (/*AUTOARG*/
   // Outputs
   m_wvalid, m_wstrb, m_wlast, m_wid, m_wdata, m_rready, m_bready,
   m_awvalid, m_awuser, m_awsize, m_awprot, m_awlock, m_awlen, m_awid,
   m_awcache, m_awburst, m_awaddr, m_arvalid, m_aruser, m_arsize,
   m_arprot, m_arlock, m_arlen, m_arid, m_arcache, m_arburst,
   m_araddr, avs_waitrequest, avs_readdatavalid, avs_readdata,
   // Inputs
   sys_rst, sys_clk, m_wready, m_rvalid, m_rresp, m_rlast, m_rid,
   m_rdata, m_bvalid, m_bresp, m_bid, m_awready, m_arready,
   avs_writedata, avs_write, avs_read, avs_address
   );
   parameter ADDRESS_WIDTH = 32;
   parameter ID_WIDTH      = 1;
   parameter AXUSER_WIDTH  = 5;
   parameter DATA_WIDTH    = 256;

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input [11:0]		avs_address;		// To acp_avs of acp_avs.v
   input		avs_read;		// To acp_avs of acp_avs.v
   input		avs_write;		// To acp_avs of acp_avs.v
   input [31:0]		avs_writedata;		// To acp_avs of acp_avs.v
   input		m_arready;		// To hps2ip_dma of hps2ip_dma.v
   input		m_awready;		// To ip2hps_dma of ip2hps_dma.v
   input [ID_WIDTH-1:0]	m_bid;			// To ip2hps_dma of ip2hps_dma.v
   input [1:0]		m_bresp;		// To ip2hps_dma of ip2hps_dma.v
   input		m_bvalid;		// To ip2hps_dma of ip2hps_dma.v
   input [DATA_WIDTH-1:0] m_rdata;		// To hps2ip_dma of hps2ip_dma.v
   input [ID_WIDTH-1:0]	m_rid;			// To hps2ip_dma of hps2ip_dma.v
   input		m_rlast;		// To hps2ip_dma of hps2ip_dma.v
   input [1:0]		m_rresp;		// To hps2ip_dma of hps2ip_dma.v
   input		m_rvalid;		// To hps2ip_dma of hps2ip_dma.v
   input		m_wready;		// To ip2hps_dma of ip2hps_dma.v
   input		sys_clk;		// To acp_avs of acp_avs.v, ...
   input		sys_rst;		// To acp_avs of acp_avs.v, ...
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	avs_readdata;		// From acp_avs of acp_avs.v
   output		avs_readdatavalid;	// From acp_avs of acp_avs.v
   output		avs_waitrequest;	// From acp_avs of acp_avs.v
   output [ADDRESS_WIDTH-1:0] m_araddr;		// From hps2ip_dma of hps2ip_dma.v
   output [1:0]		m_arburst;		// From hps2ip_dma of hps2ip_dma.v
   output [3:0]		m_arcache;		// From hps2ip_dma of hps2ip_dma.v
   output [ID_WIDTH-1:0] m_arid;		// From hps2ip_dma of hps2ip_dma.v
   output [3:0]		m_arlen;		// From hps2ip_dma of hps2ip_dma.v
   output [1:0]		m_arlock;		// From hps2ip_dma of hps2ip_dma.v
   output [2:0]		m_arprot;		// From hps2ip_dma of hps2ip_dma.v
   output [2:0]		m_arsize;		// From hps2ip_dma of hps2ip_dma.v
   output [AXUSER_WIDTH-1:0] m_aruser;		// From hps2ip_dma of hps2ip_dma.v
   output		m_arvalid;		// From hps2ip_dma of hps2ip_dma.v
   output [ADDRESS_WIDTH-1:0] m_awaddr;		// From ip2hps_dma of ip2hps_dma.v
   output [1:0]		m_awburst;		// From ip2hps_dma of ip2hps_dma.v
   output [3:0]		m_awcache;		// From ip2hps_dma of ip2hps_dma.v
   output [ID_WIDTH-1:0] m_awid;		// From ip2hps_dma of ip2hps_dma.v
   output [3:0]		m_awlen;		// From ip2hps_dma of ip2hps_dma.v
   output [1:0]		m_awlock;		// From ip2hps_dma of ip2hps_dma.v
   output [2:0]		m_awprot;		// From ip2hps_dma of ip2hps_dma.v
   output [2:0]		m_awsize;		// From ip2hps_dma of ip2hps_dma.v
   output [AXUSER_WIDTH-1:0] m_awuser;		// From ip2hps_dma of ip2hps_dma.v
   output		m_awvalid;		// From ip2hps_dma of ip2hps_dma.v
   output		m_bready;		// From ip2hps_dma of ip2hps_dma.v
   output		m_rready;		// From hps2ip_dma of hps2ip_dma.v
   output [DATA_WIDTH-1:0] m_wdata;		// From ip2hps_dma of ip2hps_dma.v
   output [ID_WIDTH-1:0] m_wid;			// From ip2hps_dma of ip2hps_dma.v
   output		m_wlast;		// From ip2hps_dma of ip2hps_dma.v
   output [DATA_WIDTH/8-1:0] m_wstrb;		// From ip2hps_dma of ip2hps_dma.v
   output		m_wvalid;		// From ip2hps_dma of ip2hps_dma.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [3:0]		c_arcache;		// From acp_avs of acp_avs.v
   wire [2:0]		c_arprot;		// From acp_avs of acp_avs.v
   wire [4:0]		c_aruser;		// From acp_avs of acp_avs.v
   wire [3:0]		c_awcache;		// From acp_avs of acp_avs.v
   wire [2:0]		c_awprot;		// From acp_avs of acp_avs.v
   wire [4:0]		c_awuser;		// From acp_avs of acp_avs.v
   wire [31:0]		cycle;			// From acp_avs of acp_avs.v
   wire			dma_en;			// From acp_avs of acp_avs.v
   wire			fifo_empty;		// From acp_fifo of acp_fifo.v
   wire [255:0]		fifo_rdata;		// From acp_fifo of acp_fifo.v
   wire			fifo_rden;		// From ip2hps_dma of ip2hps_dma.v
   wire [3:0]		fifo_usedw;		// From acp_fifo of acp_fifo.v
   wire [255:0]		fifo_wdata;		// From hps2ip_dma of hps2ip_dma.v
   wire			fifo_wren;		// From hps2ip_dma of hps2ip_dma.v
   wire [31:5]		hps2ip_base;		// From acp_avs of acp_avs.v
   wire [15:0]		hps2ip_ci;		// From hps2ip_dma of hps2ip_dma.v
   wire [31:5]		hps2ip_ci_base;		// From acp_avs of acp_avs.v
   wire [16:0]		hps2ip_mindex;		// From acp_avs of acp_avs.v
   wire [15:0]		hps2ip_pi;		// From acp_avs of acp_avs.v
   wire [31:5]		ip2hps_base;		// From acp_avs of acp_avs.v
   wire [15:0]		ip2hps_ci;		// From acp_avs of acp_avs.v
   wire [16:0]		ip2hps_mindex;		// From acp_avs of acp_avs.v
   wire [15:0]		ip2hps_pi;		// From ip2hps_dma of ip2hps_dma.v
   wire [31:5]		ip2hps_pi_base;		// From acp_avs of acp_avs.v
   // End of automatics

   acp_avs acp_avs (/*AUTOINST*/
		    // Outputs
		    .avs_readdata	(avs_readdata[31:0]),
		    .avs_readdatavalid	(avs_readdatavalid),
		    .avs_waitrequest	(avs_waitrequest),
		    .hps2ip_base	(hps2ip_base[31:5]),
		    .hps2ip_ci_base	(hps2ip_ci_base[31:5]),
		    .hps2ip_mindex	(hps2ip_mindex[16:0]),
		    .hps2ip_pi		(hps2ip_pi[15:0]),
		    .ip2hps_base	(ip2hps_base[31:5]),
		    .ip2hps_pi_base	(ip2hps_pi_base[31:5]),
		    .ip2hps_mindex	(ip2hps_mindex[16:0]),
		    .ip2hps_ci		(ip2hps_ci[15:0]),
		    .dma_en		(dma_en),
		    .cycle		(cycle[31:0]),
		    .c_awcache		(c_awcache[3:0]),
		    .c_awprot		(c_awprot[2:0]),
		    .c_awuser		(c_awuser[4:0]),
		    .c_arcache		(c_arcache[3:0]),
		    .c_arprot		(c_arprot[2:0]),
		    .c_aruser		(c_aruser[4:0]),
		    // Inputs
		    .sys_clk		(sys_clk),
		    .sys_rst		(sys_rst),
		    .avs_address	(avs_address[11:0]),
		    .avs_read		(avs_read),
		    .avs_write		(avs_write),
		    .avs_writedata	(avs_writedata[31:0]),
		    .hps2ip_ci		(hps2ip_ci[15:0]),
		    .ip2hps_pi		(ip2hps_pi[15:0]));

   hps2ip_dma #(/*AUTOINSTPARAM*/
		// Parameters
		.ADDRESS_WIDTH		(ADDRESS_WIDTH),
		.ID_WIDTH		(ID_WIDTH),
		.AXUSER_WIDTH		(AXUSER_WIDTH),
		.DATA_WIDTH		(DATA_WIDTH))
   hps2ip_dma (/*AUTOINST*/
	       // Outputs
	       .fifo_wdata		(fifo_wdata[255:0]),
	       .fifo_wren		(fifo_wren),
	       .hps2ip_ci		(hps2ip_ci[15:0]),
	       .m_araddr		(m_araddr[ADDRESS_WIDTH-1:0]),
	       .m_arid			(m_arid[ID_WIDTH-1:0]),
	       .m_arvalid		(m_arvalid),
	       .m_arlen			(m_arlen[3:0]),
	       .m_arsize		(m_arsize[2:0]),
	       .m_arburst		(m_arburst[1:0]),
	       .m_arlock		(m_arlock[1:0]),
	       .m_arcache		(m_arcache[3:0]),
	       .m_arprot		(m_arprot[2:0]),
	       .m_aruser		(m_aruser[AXUSER_WIDTH-1:0]),
	       .m_rready		(m_rready),
	       // Inputs
	       .sys_clk			(sys_clk),
	       .sys_rst			(sys_rst),
	       .fifo_usedw		(fifo_usedw[3:0]),
	       .hps2ip_base		(hps2ip_base[31:5]),
	       .hps2ip_ci_base		(hps2ip_ci_base[31:5]),
	       .hps2ip_mindex		(hps2ip_mindex[16:0]),
	       .hps2ip_pi		(hps2ip_pi[15:0]),
	       .c_arcache		(c_arcache[3:0]),
	       .c_arprot		(c_arprot[2:0]),
	       .c_aruser		(c_aruser[4:0]),
	       .dma_en			(dma_en),
	       .cycle			(cycle[31:0]),
	       .m_arready		(m_arready),
	       .m_rvalid		(m_rvalid),
	       .m_rlast			(m_rlast),
	       .m_rresp			(m_rresp[1:0]),
	       .m_rdata			(m_rdata[DATA_WIDTH-1:0]),
	       .m_rid			(m_rid[ID_WIDTH-1:0]));

   ip2hps_dma #(/*AUTOINSTPARAM*/
		// Parameters
		.ADDRESS_WIDTH		(ADDRESS_WIDTH),
		.ID_WIDTH		(ID_WIDTH),
		.AXUSER_WIDTH		(AXUSER_WIDTH),
		.DATA_WIDTH		(DATA_WIDTH))
   ip2hps_dma (/*AUTOINST*/
	       // Outputs
	       .fifo_rden		(fifo_rden),
	       .ip2hps_pi		(ip2hps_pi[15:0]),
	       .m_awvalid		(m_awvalid),
	       .m_awlen			(m_awlen[3:0]),
	       .m_awsize		(m_awsize[2:0]),
	       .m_awburst		(m_awburst[1:0]),
	       .m_awlock		(m_awlock[1:0]),
	       .m_awcache		(m_awcache[3:0]),
	       .m_awprot		(m_awprot[2:0]),
	       .m_awuser		(m_awuser[AXUSER_WIDTH-1:0]),
	       .m_awaddr		(m_awaddr[ADDRESS_WIDTH-1:0]),
	       .m_awid			(m_awid[ID_WIDTH-1:0]),
	       .m_wvalid		(m_wvalid),
	       .m_wlast			(m_wlast),
	       .m_wdata			(m_wdata[DATA_WIDTH-1:0]),
	       .m_wstrb			(m_wstrb[DATA_WIDTH/8-1:0]),
	       .m_wid			(m_wid[ID_WIDTH-1:0]),
	       .m_bready		(m_bready),
	       // Inputs
	       .sys_clk			(sys_clk),
	       .sys_rst			(sys_rst),
	       .fifo_rdata		(fifo_rdata[255:0]),
	       .fifo_empty		(fifo_empty),
	       .ip2hps_base		(ip2hps_base[31:5]),
	       .ip2hps_pi_base		(ip2hps_pi_base[31:5]),
	       .ip2hps_mindex		(ip2hps_mindex[16:0]),
	       .ip2hps_ci		(ip2hps_ci[15:0]),
	       .c_awcache		(c_awcache[3:0]),
	       .c_awprot		(c_awprot[2:0]),
	       .c_awuser		(c_awuser[4:0]),
	       .dma_en			(dma_en),
	       .cycle			(cycle[31:0]),
	       .hps2ip_ci		(hps2ip_ci[15:0]),
	       .m_awready		(m_awready),
	       .m_wready		(m_wready),
	       .m_bvalid		(m_bvalid),
	       .m_bresp			(m_bresp[1:0]),
	       .m_bid			(m_bid[ID_WIDTH-1:0]));

   acp_fifo acp_fifo (/*AUTOINST*/
		      // Outputs
		      .fifo_usedw	(fifo_usedw[3:0]),
		      .fifo_rdata	(fifo_rdata[255:0]),
		      .fifo_empty	(fifo_empty),
		      // Inputs
		      .sys_clk		(sys_clk),
		      .sys_rst		(sys_rst),
		      .fifo_wdata	(fifo_wdata[255:0]),
		      .fifo_wren	(fifo_wren),
		      .fifo_rden	(fifo_rden));

endmodule
//
// acp_top.v ends here
