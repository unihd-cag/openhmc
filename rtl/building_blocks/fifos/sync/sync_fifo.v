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
 *  Module name: sync_fifo_simple
 *
 */

`default_nettype none

module sync_fifo #(
`ifdef CAG_ASSERTIONS
        parameter DISABLE_EMPTY_ASSERT      = 0,
        parameter DISABLE_FULL_ASSERT       = 0,
        parameter DISABLE_SHIFT_OUT_ASSERT  = 0,
        parameter DISABLE_XCHECK_ASSERT     = 0,
`endif
        parameter DATASIZE                  = 8,
        parameter ADDRSIZE                  = 8,
        parameter GATE_SHIFT_IN             = 0,
        parameter CHAIN_ENABLE              = 0
    ) (
        //----------------------------------
        //----SYSTEM INTERFACE
        //----------------------------------
        input wire                  clk,
        input wire                  res_n,

        //----------------------------------
        //----Signals
        //----------------------------------
        input wire [DATASIZE-1:0]   d_in,
        input wire                  shift_in,
        input wire                  shift_out,
        input wire                  next_stage_full, // Set to 1 if not chained
        output wire [DATASIZE-1:0]  d_out,
        output wire                 empty
    );

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------WIRING AND SIGNAL STUFF---------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

wire si, so;    // internal gated shift signals
reg full, full_r1, full_r2;
wire full_1, full_2, full_3;
reg full_m2, full_m1;

reg [DATASIZE-1:0] d_out_r1, d_out_r2;
wire [DATASIZE-1:0] d_out_m2, d_out_2, d_out_3;
wire mux_rm_2;

reg [ADDRSIZE -1:0] ra_m, wa_m; //addr after register similar to signal internal to sram
reg [ADDRSIZE -1:0] ra, wa; // address calculated for the next read
wire wen, ren;

wire m_empty;

assign full_1 = full_r1 || full_m1 || (full_m2 && full_r2);
assign full_2 = full_r2 || full_m2;

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------LOGIC STARTS HERE---------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

always @ (posedge clk or negedge res_n) begin
    if (!res_n) begin
        d_out_r1 <= {DATASIZE {1'b0}};
        d_out_r2 <= {DATASIZE {1'b0}};
        full_r1 <= 1'b0;
        full_r2 <= 1'b0;
    end else begin

        // Register stage 1 (conditions shouldn't overlap)
        if ((full_2 && !full_1 && si && !so) ||         // fill stage
            (full_1 && m_empty && si && so)) begin      // shift through
            d_out_r1 <= d_in;
            full_r1 <= 1'b1;
        end
        if (full_r1 && so && (!si || !m_empty)) begin   // shift out
            full_r1 <= 1'b0;
        end

        // Register stage 2 (conditions shouldn't overlap)
        if (full_3 && ((!full_2 && si && !so) ||        // fill stage
                (full_2 && !full_1 && si && so))) begin // shift through
            d_out_r2 <= d_in;
            full_r2 <= 1'b1;
        end
        if (full_r1 && so) begin                        // shift through
            d_out_r2 <= d_out_r1;
            full_r2 <= 1'b1;
        end
        if (full_m2 && ((!full_r2 && !so) ||            // Rescue
                        (full_r2 && so))) begin
            d_out_r2 <= d_out_m2;
            full_r2 <= 1'b1;
        end
        if (full_r2 &&
                ((!full_r1 && !full_m2 && so && !si) || // shift out
                (full_m1 && si && so))) begin           // shift through with RAM
            full_r2 <= 1'b0;
        end
    end
end

// assign outputs and inputs to module interface
    assign d_out = d_out_3;

    assign empty = !full_3; // if the last stage is empty, the fifo is empty

    generate // gating of si and so, just for compatability!!!
        if (GATE_SHIFT_IN) begin : shift_in_gated
            assign si = shift_in && !full;
        end
        else begin : shift_in_raw
            assign si = shift_in;
        end

            assign so = shift_out;
    endgenerate

    wire [ADDRSIZE:0] fifo_ram_count = wa_m - ra_m;

    assign mux_rm_2 = full_r2;          // mux control of SRAM data bypass if only one value in stage r2
    assign d_out_2 = mux_rm_2 ? d_out_r2 : d_out_m2;    // additional data mux for SRAM bypass

    // write port control of SRAM
    assign wen = si && !so && full_1    // enter new value into SRAM, because regs are filled
                || si && !m_empty;  // if a value is in the SRAM, then we have to shift through or shift in

    // read port control of SRAM
    assign ren = so && !m_empty;

    assign m_empty = (wa_m == ra_m);

    always @ (posedge clk or negedge res_n) begin
        if (!res_n) begin
            full_m1 <= 1'b0;
            full_m2 <= 1'b0;
        end else begin
            full_m1 <= ren; // no control of m1
            full_m2 <= full_m1
                    || full_m2 && !so && full_r2;       // no rescue possible
        end
    end

// pointer management
    always @(*) begin
        wa = wa_m + 1'b1; // wa_m is the address stored in mem addr register
        ra = ra_m + 1'b1;
    end

    always @ (posedge clk or negedge res_n) begin
        if (!res_n) begin
            wa_m <= {ADDRSIZE {1'b0}};
            ra_m <= {ADDRSIZE {1'b0}};
        end else begin
            if (wen) begin
                wa_m <= wa; // next mem write addr to mem addr register
            end

            if (ren) begin
                ra_m <= ra;
            end
        end
    end

    // Calculate full as two spaces left in the RAM before si and !so
    wire [ADDRSIZE:0] const_f_next = -2; //After si the RAM will be full

    always @ (posedge clk or negedge res_n) begin
        if (!res_n) begin
            full <= 1'b0;
        end else begin
            if ((fifo_ram_count[ADDRSIZE-1:0] == const_f_next[ADDRSIZE-1:0]) && si && !so) begin
                full <= 1'b1;
            end
            if ((full == 1'b1) && !si && so) begin
                full <= 1'b0;
            end
        end
    end

wire stage4_full;
    generate
        if (CHAIN_ENABLE) begin : chaining_enabled
            assign stage4_full = next_stage_full;
        end
        else begin : chaining_disabled
            assign stage4_full = 1'b1; // this is the last stage
        end
    endgenerate


//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------INSTANTIATIONS HERE-------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================
sync_fifo_reg_stage #(.DWIDTH(DATASIZE))
    sync_fifo_reg_stage_3_I (
        .clk(clk),
        .res_n(res_n),
        .d_in(d_in),
        .d_in_p(d_out_2),
        .p_full(full_2),
        .n_full(stage4_full),
        .si(si),
        .so(so),
        .full(full_3),
        .d_out(d_out_3)
    );

ram #(
    .DATASIZE(DATASIZE),    // Memory data word width
    .ADDRSIZE(ADDRSIZE),    // Number of memory address bits
    .PIPELINED(1)
    )
    ram(
        .clk(clk),
        .wen(wen),
        .wdata(d_in),
        .waddr(wa),
        .ren(ren),
        .raddr(ra),
        .rdata(d_out_m2)
        );


`ifdef CAG_ASSERTIONS
    shift_in_and_full:          assert property (@(posedge clk) disable iff(!res_n) (shift_in |-> !full));

    if (DISABLE_SHIFT_OUT_ASSERT == 0 && CHAIN_ENABLE == 0)
        shift_out_and_empty:    assert property (@(posedge clk) disable iff(!res_n) (shift_out |-> !empty));

    if (DISABLE_XCHECK_ASSERT == 0)
    dout_known:                 assert property (@(posedge clk) disable iff(!res_n) (!empty |-> !$isunknown(d_out)));
    if (DISABLE_XCHECK_ASSERT == 0)

    final
    begin
        if (DISABLE_FULL_ASSERT == 0)
        begin
            full_set_assert:                assert (!full);
        end

        if (DISABLE_EMPTY_ASSERT == 0)
        begin
            empty_not_set_assert:           assert (empty);
        end
    end

`endif // CAG_ASSERTIONS

endmodule

`default_nettype wire

