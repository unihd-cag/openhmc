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
 *  Module name: sync_fifo
 *
 */

`default_nettype none

module sync_fifo #(
        parameter DATASIZE          = 8,
        parameter ADDRSIZE          = 8
    ) (
        input wire                  clk,
        input wire                  res_n,
        input wire [DATASIZE-1:0]   d_in,
        input wire                  shift_in,
        output wire [DATASIZE-1:0]  d_out,
        output wire [DATASIZE-1:0]  d_out_nxt,
        input wire                  shift_out,
        output wire                 almost_empty,
        output wire                 empty
    );

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------WIRING AND SIGNAL STUFF---------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

wire reg_full;
wire shift_out_g;
wire fifo_empty;


wire [DATASIZE-1:0] reg_d_out, fifo_d_out;
assign almost_empty = fifo_empty;

assign d_out_nxt = fifo_d_out;
assign empty = !reg_full;
assign d_out = reg_d_out;

// It is sufficient to gate shift_in in the FIFO, and shift_out on the REG stage
assign shift_out_g = shift_out && !empty;

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------INSTANTIATIONS HERE-------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

sync_fifo_simple #(
    .DATASIZE(DATASIZE),
    .ADDRSIZE(ADDRSIZE),
    .GATE_SHIFT_IN(1'b1),
    .CHAIN_ENABLE(1)
    )
    fast_fifo_I (
        .clk(clk),
        .res_n(res_n),
        .d_in(d_in),
        .shift_in(shift_in),
        .shift_out(shift_out),
        .empty(fifo_empty),
        .d_out(fifo_d_out),
        .next_stage_full(reg_full)
    );

// Extra stage for D_next
sync_fifo_reg_stage #(.DWIDTH(DATASIZE))
    fifo_reg_stage_I (
        .clk(clk),
        .res_n(res_n),
        .d_in(d_in),
        .d_in_p(fifo_d_out),
        .p_full(!fifo_empty),
        .n_full(1'b1), // next stage is assumed to be full
        .si(shift_in),
        .so(shift_out_g),
        .full(reg_full),
        .d_out(reg_d_out)
    );


endmodule

`default_nettype wire

