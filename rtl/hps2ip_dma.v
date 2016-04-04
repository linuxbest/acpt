// hps2ip_dma.v --- 
// 
// Filename: hps2ip_dma.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Apr  1 10:15:25 2016 (-0700)
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
module hps2ip_dma (/*AUTOARG*/
   // Outputs
   hps2ip_ci, fifo_wdata, fifo_wren, m_araddr, m_arid, m_arvalid,
   m_arlen, m_arsize, m_arburst, m_arlock, m_arcache, m_arprot,
   m_aruser, m_rready,
   // Inputs
   c_arcache, c_arprot, c_aruser, hps2ip_base, hps2ip_ci_base,
   hps2ip_mindex, hps2ip_pi, sys_clk, sys_rst, fifo_usedw, dma_en,
   cycle, m_arready, m_rvalid, m_rlast, m_rresp, m_rdata, m_rid
   );
   parameter ADDRESS_WIDTH = 32;
   parameter ID_WIDTH      = 1;
   parameter AXUSER_WIDTH  = 5;
   parameter DATA_WIDTH    = 256;

   input sys_clk;
   input sys_rst;

   output [255:0] fifo_wdata;
   output 	  fifo_wren;
   input [3:0] 	  fifo_usedw;

   /*AUTOINOUTCOMP("acp_avs", "hps2ip")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [15:0]	hps2ip_ci;
   input [31:5]		hps2ip_base;
   input [31:5]		hps2ip_ci_base;
   input [16:0]		hps2ip_mindex;
   input [15:0]		hps2ip_pi;
   // End of automatics

   /*AUTOINOUTCOMP("acp_avs", "c_ar")*/
   // Beginning of automatic in/out/inouts (from specific module)
   input [3:0]		c_arcache;
   input [2:0]		c_arprot;
   input [4:0]		c_aruser;
   // End of automatics

   input 		dma_en;
   input [31:0] 	cycle;

   output [ADDRESS_WIDTH-1:0] m_araddr;
   output [ID_WIDTH-1:0]      m_arid;
   output 		      m_arvalid;
   output [3:0] 	      m_arlen;
   output [2:0] 	      m_arsize;
   output [1:0] 	      m_arburst;
   output [1:0] 	      m_arlock;
   output [3:0] 	      m_arcache;
   output [2:0] 	      m_arprot;
   input 		      m_arready;
   output [AXUSER_WIDTH-1:0]  m_aruser;

   input 		      m_rvalid;
   input 		      m_rlast;
   input [1:0] 		      m_rresp;
   output 		      m_rready;
   input [DATA_WIDTH-1:0]     m_rdata;
   input [ID_WIDTH-1:0]       m_rid;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [255:0]		fifo_wdata;
   reg			fifo_wren;
   reg [15:0]		hps2ip_ci;
   reg [ADDRESS_WIDTH-1:0] m_araddr;
   reg			m_arvalid;
   // End of automatics

   localparam [2:0] // synopsys enum state_info
     S_IDLE    = 3'h0,
     S_MSG_REQ = 3'h1,
     S_MSG_WAIT= 3'h2,
     S_CI_INCR = 3'h3;
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
   wire req_ready;
   reg [15:0] next_ci;
   assign req_ready = dma_en && hps2ip_pi != hps2ip_ci && ~fifo_usedw[3];
   wire       req_done;
   wire       req_accept;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (req_ready)
	    begin
	       state_ns = S_MSG_REQ;
	    end
	  S_MSG_REQ: if (m_arready)
	    begin
	       state_ns = S_MSG_WAIT;
	    end
	  S_MSG_WAIT: if (m_rvalid)
	    begin
	       state_ns = S_CI_INCR;
	    end
	  S_CI_INCR:
	    begin
	       state_ns = S_IDLE;
	    end
	endcase
     end // always @ (*)
   always @(posedge sys_clk)
     begin
	fifo_wren <= m_rvalid && m_rready;
	fifo_wdata<= {m_rdata[255:32], cycle[31:0]};
     end
   always @(*)
   begin
      next_ci = hps2ip_ci + 1;
      if (next_ci == hps2ip_mindex)
	next_ci = 0;
   end
   always @(posedge sys_clk)
     begin
	if (~dma_en)
	  begin
	     hps2ip_ci <= 0;
	  end
	else if (state == S_CI_INCR)
	  begin
	     hps2ip_ci <= next_ci;
	  end
     end // always @ (posedge sys_clk)

   assign m_arlen   = 4'h0;	// 1 burst
   assign m_arsize  = 4'h5;	// 32byte in transfer
   assign m_arburst = 2'h1;	// INCR
   assign m_arlock  = 1'b0;	// no lock
   assign m_arcache = c_arcache;
   assign m_arprot  = c_arprot;
   assign m_aruser  = c_aruser;
   assign m_arid    = 0;
   assign m_rready  = state == S_MSG_WAIT;

   always @(posedge sys_clk)
     begin
	m_araddr <= {hps2ip_base + hps2ip_ci, 5'h0};
	m_arvalid<= (state == S_IDLE && req_ready) |
		    (state == S_MSG_REQ && ~m_arready);
     end
   /************************************************************************/
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [63:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:     state_ascii = "idle    ";
	S_MSG_REQ:  state_ascii = "msg_req ";
	S_MSG_WAIT: state_ascii = "msg_wait";
	S_CI_INCR:  state_ascii = "ci_incr ";
	default:    state_ascii = "%Error  ";
      endcase
   end
   // End of automatics
endmodule
//
// hps2ip_dma.v ends here
