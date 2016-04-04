// ip2hps_dma.v --- 
// 
// Filename: ip2hps_dma.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Apr  1 10:18:02 2016 (-0700)
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
// 	clock signals                      : "clk"; "clk_div#"; "clk_#x"
// 	reset signals                      : "rst"; "rst_n"
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
module ip2hps_dma (/*AUTOARG*/
   // Outputs
   ip2hps_pi, fifo_rden, m_awvalid, m_awlen, m_awsize, m_awburst,
   m_awlock, m_awcache, m_awprot, m_awuser, m_awaddr, m_awid,
   m_wvalid, m_wlast, m_wdata, m_wstrb, m_wid, m_bready,
   // Inputs
   c_awcache, c_awprot, c_awuser, ip2hps_base, ip2hps_pi_base,
   ip2hps_mindex, ip2hps_ci, sys_clk, sys_rst, fifo_rdata, fifo_empty,
   dma_en, cycle, hps2ip_ci, m_awready, m_wready, m_bvalid, m_bresp,
   m_bid
   );
   parameter ADDRESS_WIDTH = 32;
   parameter ID_WIDTH      = 1;
   parameter AXUSER_WIDTH  = 5;
   parameter DATA_WIDTH    = 256;
   input sys_clk;
   input sys_rst;

   input [255:0] fifo_rdata;
   input 	 fifo_empty;
   output 	 fifo_rden;

   /*AUTOINOUTCOMP("acp_avs", "ip2hps")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [15:0]	ip2hps_pi;
   input [31:5]		ip2hps_base;
   input [31:5]		ip2hps_pi_base;
   input [16:0]		ip2hps_mindex;
   input [15:0]		ip2hps_ci;
   // End of automatics

   /*AUTOINOUTCOMP("acp_avs", "c_aw")*/
   // Beginning of automatic in/out/inouts (from specific module)
   input [3:0]		c_awcache;
   input [2:0]		c_awprot;
   input [4:0]		c_awuser;
   // End of automatics

   input 		dma_en;
   input [31:0] 	cycle;
   input [15:0] 	hps2ip_ci;

   output 		m_awvalid;
   output [3:0] 	m_awlen;
   output [2:0] 	m_awsize;
   output [1:0] 	m_awburst;
   output [1:0] 	m_awlock ;
   output [3:0] 	m_awcache;
   output [2:0] 	m_awprot ;
   input 		m_awready;
   output [AXUSER_WIDTH-1:0] m_awuser;
   output [ADDRESS_WIDTH-1:0] m_awaddr;
   output [ID_WIDTH-1:0]      m_awid;

   output 		      m_wvalid;
   output 		      m_wlast;
   input 		      m_wready;
   output [DATA_WIDTH-1:0]    m_wdata;
   output [DATA_WIDTH/8-1:0]  m_wstrb;
   output [ID_WIDTH-1:0]      m_wid;

   input 		      m_bvalid;
   input [1:0] 		      m_bresp;
   output 		      m_bready;
   input [ID_WIDTH-1:0]       m_bid;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [15:0]		ip2hps_pi;
   reg [ADDRESS_WIDTH-1:0] m_awaddr;
   reg			m_awvalid;
   reg [DATA_WIDTH-1:0]	m_wdata;
   reg			m_wvalid;
   // End of automatics

   localparam [2:0] // synopsys enum state_info
     S_IDLE    = 3'h0,
     S_MSG_REQ = 3'h1,
     S_PI_INCR = 3'h2,
     S_PI_REQ  = 3'h3,
     S_DONE    = 3'h4;
   reg [2:0] // synopsys enum state_info
	     state, state_ns;
   always @(posedge sys_clk)
     begin
	if (sys_rst)
	  begin
	     state <= S_IDLE;
	  end
	else
	  begin
	     state <= state_ns;
	  end
     end // always @ (posedge sys_clk)
   wire req_done;
   reg [15:0] next_pi;
   wire       req_accept;
   wire       req_ready;
   assign req_ready = ~fifo_empty && dma_en && next_pi != ip2hps_ci;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (req_ready)
	    begin
	       state_ns = S_MSG_REQ;
	    end
	  S_MSG_REQ: if (req_accept)
	    begin
	       state_ns = S_PI_INCR;
	    end
	  S_PI_INCR:
	    begin
	       state_ns = S_PI_REQ;
	    end
	  S_PI_REQ: if (req_accept)
	    begin
	       state_ns = S_DONE;
	    end
	  S_DONE: if (req_done)
	    begin
	       state_ns = S_IDLE;
	    end
	endcase
     end // always @ (*)
   assign fifo_rden = state == S_PI_INCR;

   always @(*)
   begin
      next_pi = ip2hps_pi + 1;
      if (next_pi == ip2hps_mindex)
	next_pi = 0;
   end
   always @(posedge sys_clk)
     begin
	if (~dma_en)
	  begin
	     ip2hps_pi <= 0;
	  end
	else if (state == S_PI_INCR)
	  begin
	     ip2hps_pi <= next_pi;
	  end
     end // always @ (posedge sys_clk)

   assign m_awlen   = 4'h0;	// 1 burst
   assign m_awsize  = 4'h5;	// 32byte in transfer
   assign m_awburst = 2'h1;	// INCR
   assign m_awlock  = 1'b0;	// no lock
   assign m_awcache = c_awcache;
   assign m_awprot  = c_awprot;
   assign m_awuser  = c_awuser;
   assign m_awid    = 0;
   assign m_wid     = 0;
   assign m_wstrb   = 32'hffff_ffff;
   assign m_wlast   = 1'b1;
   assign m_bready  = state != S_IDLE;

   always @(posedge sys_clk)
     begin
	if (state == S_IDLE)
	  begin
	     m_awaddr <= {ip2hps_base + ip2hps_pi, 5'h0};
	     m_wdata  <= {fifo_rdata[255:64], cycle, fifo_rdata[31:0]};
	  end
	else if (state == S_PI_INCR)
	  begin
	     m_awaddr <= {ip2hps_pi_base, 5'h0};
	     m_wdata  <= {cycle, hps2ip_ci, next_pi};
	  end
     end // always @ (posedge sys_clk)
   reg addr_done;
   reg data_done;
   wire m_addr_done;
   wire m_data_done;
   assign m_addr_done = m_awvalid && m_awready;
   assign m_data_done = m_wvalid && m_wready;
   assign req_accept  = (m_addr_done && m_data_done) |
			(addr_done && m_data_done) |
			(data_done && m_addr_done);
   always @(posedge sys_clk)
     begin
	if (state == S_IDLE || state == S_PI_INCR)
	  begin
	     addr_done <= 1'b0;
	  end
	else if (state == S_MSG_REQ && m_addr_done)
	  begin
	     addr_done <= 1'b1;
	  end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	if (state == S_IDLE || state == S_PI_INCR)
	  begin
	     data_done <= 1'b0;
	  end
	else if (state == S_MSG_REQ && m_data_done)
	  begin
	     data_done <= 1'b1;
	  end
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	m_awvalid <= (state == S_IDLE && req_ready) |
		     (state == S_MSG_REQ && ~addr_done && ~m_addr_done) |
		     (state == S_PI_INCR) |
		     (state == S_PI_REQ && ~addr_done && ~m_addr_done);
	m_wvalid  <= (state == S_IDLE && req_ready) |
		     (state == S_MSG_REQ && ~data_done && ~m_data_done) |
		     (state == S_PI_INCR) |
		     (state == S_PI_REQ && ~data_done && ~m_data_done);
     end // always @ (posedge sys_clk)

   reg [1:0] req_cnt;
   always @(posedge sys_clk)
     begin
	if (state == S_IDLE)
	  begin
	     req_cnt <= 2'h2;
	  end
	else if (m_bvalid && m_bready && m_bresp == 2'b00 && m_bid == 0)
	  begin
	     req_cnt <= req_cnt - 1;
	  end
     end // always @ (posedge sys_clk)
   assign req_done = req_cnt == 0;
   /************************************************************************/
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [55:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:    state_ascii = "idle   ";
	S_MSG_REQ: state_ascii = "msg_req";
	S_PI_INCR: state_ascii = "pi_incr";
	S_PI_REQ:  state_ascii = "pi_req ";
	S_DONE:    state_ascii = "done   ";
	default:   state_ascii = "%Error ";
      endcase
   end
   // End of automatics
endmodule
//
// ip2hps_dma.v ends here
