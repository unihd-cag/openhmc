/*
 *                              .--------------. .----------------. .------------.
 *                             | .------------. | .--------------. | .----------. |
 *                             | | ____  ____ | | | ____    ____ | | |   ______ | |
 *                             | ||_   ||   _|| | ||_   \  /   _|| | | .' ___  || |
 *       ___  _ __   ___ _ __  | |  | |__| |  | | |  |   \/   |  | | |/ .'   \_|| |
 *      / _ \| '_ \ / _ \ '_ \ | |  |  __  |  | | |  | |\  /| |  | | || |       | |
 *       (_) | |_) |  __/ | | || | _| |  | |_ | | | _| |_\/_| |_ | | |\ `.___.'\| |
 *      \___/| .__/ \___|_| |_|| ||____||____|| | ||_____||_____|| | | `._____.'| |
 *           | |               | |            | | |              | | |          | |
 *           |_|               | '------------' | '--------------' | '----------' |
 *                              '--------------' '----------------' '------------'
 *
 *  openHMC - An Open Source Hybrid Memory Cube Controller
 *  (C) Copyright 2014 Computer Architecture Group - University of Heidelberg
 *  www.ziti.uni-heidelberg.de
 *  B6, 26
 *  68159 Mannheim
 *  Germany
 *
 *  Contact: openhmc@ziti.uni-heidelberg.de
 *  http://ra.ziti.uni-heidelberg.de/openhmc
 *
 *   This source file is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This source file is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public License
 *   along with this source file.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 */

//
//
// AXI4 Stream Interface
//
//

`ifndef AXI4_STREAM_IF_SV
`define AXI4_STREAM_IF_SV

interface axi4_stream_if #(parameter DATA_BYTES = 16, parameter TUSER_WIDTH = 16) (
	input logic ACLK,    //-- Clock (All signals sampled on the rising edge)
	input logic ARESET_N //-- Global Reset
	);
	
	//--
	//-- Interface signals
	//--

	logic TVALID;	// Master valid
	logic TREADY;	// Slave ready
	logic [8*DATA_BYTES-1:0] TDATA;	//-- Master data
	logic [TUSER_WIDTH-1:0] TUSER;	//-- Master sideband signals
	
	
	
	
	//--
	//-- Interface Assertions
	//--
	
	property data_hold_p;
		logic [8*DATA_BYTES-1:0] m_data;
		
		@(posedge ACLK) disable iff(!ARESET_N)
			(TVALID == 1 && TREADY == 0,m_data = TDATA) |=> (TDATA == m_data); 
	endproperty : data_hold_p
	
	chk_data_hold : assert property(data_hold_p);

endinterface : axi4_stream_if

`endif // AXI4_STREAM_IF_SV
