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
`timescale 100ps/100ps

module deserializer #(
	parameter LOG_DWIDTH=7,
	parameter DWIDTH=64
)
(
	input wire clk,
	input wire fast_clk,
	input wire bit_slip,
	input wire data_in,
	output reg [DWIDTH-1:0] data_out
);

reg [DWIDTH-1:0] tmp_buffer;
reg [DWIDTH-1:0] buffer;
reg [DWIDTH-1:0] buffer2;
reg [DWIDTH-1:0] buffer3;
reg [LOG_DWIDTH-1:0] curr_bit = 'h0;
reg bit_slip_done = 1'b0;
reg [8:0] bit_slip_cnt=9'h0;

// SEQUENTIAL PROCESS
always @ (posedge fast_clk)
begin
	if (!bit_slip || bit_slip_done) begin
		if(curr_bit == DWIDTH-1) begin
			curr_bit <= 0;
		end else begin
			curr_bit <= curr_bit + 1;
		end
	end

	if (bit_slip && !bit_slip_done)
		bit_slip_done = 1'b1;

	if (bit_slip_done && !bit_slip)
		bit_slip_done = 1'b0;

	tmp_buffer[curr_bit] <= data_in;
	if (|curr_bit == 1'b0)
		buffer <= tmp_buffer;
end

always @ (posedge clk)
begin
	buffer2 <= buffer;
	buffer3 <= buffer2;

	if (bit_slip)
		bit_slip_cnt = bit_slip_cnt + 1;
	if (bit_slip_cnt < 63)
		data_out <= buffer3;
	else if (bit_slip_cnt < 127)
		data_out <= buffer2;
	else if (bit_slip_cnt < 191)
		data_out <= buffer;
end

endmodule

