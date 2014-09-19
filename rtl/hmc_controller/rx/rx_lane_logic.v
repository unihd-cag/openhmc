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
 *  Module name: rx_lane_logic
 *
 */

`default_nettype none

module rx_lane_logic #(
    parameter DWIDTH            = 512,
    parameter NUM_LANES         = 8,
    parameter LANE_DWIDTH       = (DWIDTH/NUM_LANES)
) (

    //----------------------------------
    //----SYSTEM INTERFACE
    //----------------------------------
    input   wire clk,
    input   wire res_n,

    //----------------------------------
    //----CONNECT
    //----------------------------------
    input   wire [LANE_DWIDTH-1:0]      scrambled_data_in,
    input   wire                        bit_slip,   //bit slip per lane
    input   wire                        lane_polarity,
    output  wire [LANE_DWIDTH-1:0]      descrambled_data_out,
    output  wire                        descrambler_locked,
    input   wire                        descrambler_disable

);

reg     [LANE_DWIDTH-1:0]       scrambled_data_in_reg;

wire    [LANE_DWIDTH-1:0]       descrambled_data_out_tmp;
assign descrambled_data_out     = descrambler_disable ? scrambled_data_in_reg : descrambled_data_out_tmp;

wire                            descrambler_locked_tmp;
assign descrambler_locked       = descrambler_disable ? 1'b1 : descrambler_locked_tmp;

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------ACTUAL LOGIC STARTS HERE--------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif

if(!res_n) begin
    scrambled_data_in_reg   <=  {LANE_DWIDTH{1'b0}};
end
else begin
    scrambled_data_in_reg       <= scrambled_data_in^{LANE_DWIDTH{lane_polarity}};
end
end

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------INSTANTIATIONS HERE-------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

//Descrambler Init
    rx_descrambler #(
        .DWIDTH(LANE_DWIDTH)
    ) descrambler_I (
        .clk(clk),
        .res_n(res_n),
        .bit_slip(bit_slip),
        .locked(descrambler_locked_tmp),
        .data_in(scrambled_data_in_reg),
        .data_out(descrambled_data_out_tmp)
    );

endmodule
`default_nettype wire