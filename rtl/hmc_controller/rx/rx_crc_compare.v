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
 *  Module name: rx_crc_compare
 */

`default_nettype none

module rx_crc_compare #(
    parameter FPW               = 4,
    parameter LOG_FPW           = 2,
    parameter DWIDTH            = 512
) (

    //----------------------------------
    //----SYSTEM INTERFACE
    //----------------------------------
    input   wire             clk,
    input   wire             res_n,

    //----------------------------------
    //----Input data
    //----------------------------------
    input   wire [DWIDTH-1:0] d_in_data,
    input   wire [FPW-1:0]    d_in_hdr,
    input   wire [FPW-1:0]    d_in_tail,
    input   wire [FPW-1:0]    d_in_valid,
    input   wire [(FPW*4)-1:0]d_in_lng,

    //----------------------------------
    //----Outputs
    //----------------------------------
    output  wire [DWIDTH-1:0]d_out_data,
    output  reg  [FPW-1:0]   d_out_hdr,
    output  reg  [FPW-1:0]   d_out_tail,
    output  reg  [FPW-1:0]   d_out_valid,
    output  reg  [FPW-1:0]   d_out_error,
    output  reg  [FPW-1:0]   d_out_poisoned,
    output  reg  [FPW-1:0]   d_out_rtc,
    output  reg  [FPW-1:0]   d_out_flow

);

`include "hmc_field_functions.h"

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------WIRING AND SIGNAL STUFF---------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

//------------------------------------------------------------------------------------General Assignments
integer i_f;    //counts to FPW
integer i_f2;   //counts to FPW inside another i_f loop
integer i_c;    //depth of the crc data pipeline

genvar f, f2;

localparam CMD_TRET = 6'b000010;

//------------------------------------------------------------------------------------Local params for parameterization
localparam CRC_WIDTH            = 32;
localparam CRC_DATA_PIPE_DEPTH  = 20;
//Dwidth + valid/hdr/tail
localparam CRC_FIFO_DWIDTH      = DWIDTH + (3*FPW);

//------------------------------------------------------------------------------------Data Input
wire  [128-1:0]       d_in_flit   [FPW-1:0];
generate
    for(f = 0; f < (FPW); f = f + 1) begin : assign_input_data_to_flits
        assign d_in_flit[f] = d_in_data[(f*128)+128-1:f*128];
    end
endgenerate

wire [3:0] d_in_lng_per_flit [FPW-1:0];
generate
    for(f = 0; f < (FPW); f = f + 1) begin  : retrieve_packet_lengths_for_crc_assignment
        assign d_in_lng_per_flit[f] = d_in_lng[(f*4)+4-1:f*4] ;
    end
endgenerate

//------------------------------------------------------------------------------------CRC Assignment
//Combinational regs
reg  [LOG_FPW-1:0]          crc_var_multi_comb;
reg  [3:0]                  crc_pkt_length_comb[FPW-1:0];
reg  [LOG_FPW-1:0]          crc_offset_comb    [FPW-1:0];

//Sequential regs
reg  [LOG_FPW-1:0]          crc_var_single;
reg  [LOG_FPW-1:0]          crc_var_multi;
reg                         big_pkt;
reg  [3:0]                  crc_pkt_length     [FPW-1:0];
reg  [LOG_FPW-1:0]          crc_offset         [FPW-1:0];
reg  [LOG_FPW-1:0]          next_target_comb   [FPW-1:0];
reg  [LOG_FPW-1:0]          next_target_comb_t;
reg  [3:0]                  fill               [FPW-1:0];
reg  [3:0]                  fill_comb          [FPW-1:0];
reg  [3:0]                  fill_comb_t;

reg  [LOG_FPW-1:0]          next_target        [FPW-1:0];

reg  [LOG_FPW-1:0]          crc_fifo_d_in_target_crc_per_flit_comb  [FPW-1:0];
reg  [LOG_FPW-1:0]          crc_fifo_d_in_next_target_temp_comb;
reg  [LOG_FPW-1:0]          crc_fifo_d_in_next_target_temp;

//------------------------------------------------------------------------------------Temporary Fifo Input Regs
reg  [LOG_FPW-1:0]          crc_fifo_d_in_target_crc_per_flit       [FPW-1:0];
wire [(LOG_FPW*FPW)-1:0]    crc_fifo_d_in_target_crc;
reg  [DWIDTH-1:0]           crc_data2crc_fifo;
reg  [FPW-1:0]              crc_fifo_d_in_hdr;
reg  [FPW-1:0]              crc_fifo_d_in_tail;
reg  [FPW-1:0]              crc_fifo_d_in_valid;
reg  [DWIDTH-1:0]           crc_data2crc_fifo_buf;
reg  [FPW-1:0]              crc_fifo_d_in_hdr_buf;
reg  [FPW-1:0]              crc_fifo_d_in_tail_buf;
reg  [FPW-1:0]              crc_fifo_d_in_valid_buf;

generate
    for(f = 0; f < (FPW); f = f + 1) begin : concatenate_target_crcs_to_single_reg
        assign crc_fifo_d_in_target_crc[(f*LOG_FPW)+LOG_FPW-1:(f*LOG_FPW)]  = crc_fifo_d_in_target_crc_per_flit[f];
    end
endgenerate

//------------------------------------------------------------------------------------Fifo Input Stage
reg  [CRC_FIFO_DWIDTH-1:0]   crc_fifo_d_in_data              [FPW-1:0];
wire [FPW-1:0]               crc_fifo_empty;
reg  [FPW-1:0]               crc_fifo_shift_in;
wire [FPW-1:0]               crc_fifo_a_empty;
reg  [FPW-1:0]               crc_fifo_shift_out;
wire [CRC_FIFO_DWIDTH-1:0]   crc_fifo_d_out_data             [FPW-1:0];
wire [CRC_FIFO_DWIDTH-1:0]   crc_fifo_d_out_data_next        [FPW-1:0];

//------------------------------------------------------------------------------------Fifo Output Stage
wire [128-1:0]               crc_fifo_d_out_data_flit        [(FPW*FPW)-1:0];
wire [FPW-1:0]               crc_fifo_d_out_hdr              [FPW-1:0];
wire [FPW-1:0]               crc_fifo_d_out_tail             [FPW-1:0];
wire [FPW-1:0]               crc_fifo_d_out_valid            [FPW-1:0];

wire [128-1:0]               crc_fifo_d_out_data_flit_next   [(FPW*FPW)-1:0];
wire [FPW-1:0]               crc_fifo_d_out_hdr_next         [FPW-1:0];
wire [FPW-1:0]               crc_fifo_d_out_tail_next        [FPW-1:0];
wire [FPW-1:0]               crc_fifo_d_out_valid_next       [FPW-1:0];

generate
    for(f = 0; f < (FPW); f = f + 1) begin : retrieve_target_crcs

        //Get the last fifo entry
        assign crc_fifo_d_out_hdr[f]                  = crc_fifo_d_out_data[f][DWIDTH+FPW-1:DWIDTH];
        assign crc_fifo_d_out_tail[f]                 = crc_fifo_d_out_data[f][DWIDTH+(2*FPW)-1:DWIDTH+FPW];
        assign crc_fifo_d_out_valid[f]                = crc_fifo_d_out_data[f][DWIDTH+(3*FPW)-1:DWIDTH+(2*FPW)];
        for(f2 = 0; f2 < (FPW); f2 = f2 + 1) begin
            assign crc_fifo_d_out_data_flit[f*FPW+f2] = crc_fifo_d_out_data[f][(f2*128)+128-1:f2*128];
        end

        //Get the second last fifo entry (necessary when shifting out a fifo, which would otherwise cause one cycle delay)
        assign crc_fifo_d_out_hdr_next[f]                  = crc_fifo_d_out_data_next[f][DWIDTH+FPW-1:DWIDTH];
        assign crc_fifo_d_out_tail_next[f]                 = crc_fifo_d_out_data_next[f][DWIDTH+(2*FPW)-1:DWIDTH+FPW];
        assign crc_fifo_d_out_valid_next[f]                = crc_fifo_d_out_data_next[f][DWIDTH+(3*FPW)-1:DWIDTH+(2*FPW)];
        for(f2 = 0; f2 < (FPW); f2 = f2 + 1) begin
            assign crc_fifo_d_out_data_flit_next[f*FPW+f2] = crc_fifo_d_out_data_next[f][(f2*128)+128-1:f2*128];
        end

    end
endgenerate

//------------------------------------------------------------------------------------CRC Modules Input stage
reg  [128-1:0]               crc_d_in                    [FPW-1:0];
//Mask out FLITs that were already shifted into the CRC
reg  [FPW-1:0]               crc_d_in_mask               [FPW-1:0];
//Start a new crc calculation (a new packet hdr arrives)
reg  [FPW-1:0]               crc_d_in_startNew;
reg  [FPW-1:0]               crc_d_in_valid;
reg  [FPW-1:0]               crc_d_in_tail;


//------------------------------------------------------------------------------------CRC Modules Output stage to Output fifo signals
wire [CRC_WIDTH-1:0]         crc_crc                     [FPW-1:0];
wire [FPW-1:0]               crc_crc_valid;

//------------------------------------------------------------------------------------Output Fifo output signals
wire [CRC_WIDTH-1:0]         crc_o_fifo_d_out            [FPW-1:0];
reg  [FPW-1:0]               crc_o_fifo_shift_out;

//------------------------------------------------------------------------------------Data Pipeline signals
reg  [DWIDTH-1:0]            crc_data_pipe_in_data                               [CRC_DATA_PIPE_DEPTH-1:0];
wire [128-1:0]               crc_data_pipe_out_data_flit                         [FPW-1:0];
reg  [FPW-1:0]               crc_data_pipe_in_hdr                                [CRC_DATA_PIPE_DEPTH-1:0];
reg  [FPW-1:0]               crc_data_pipe_in_tail                               [CRC_DATA_PIPE_DEPTH-1:0];
reg  [FPW-1:0]               crc_data_pipe_in_valid                              [CRC_DATA_PIPE_DEPTH-1:0];
reg  [(FPW*LOG_FPW)-1:0]     crc_data_pipe_in_target_crc                         [CRC_DATA_PIPE_DEPTH-1:0];
wire [LOG_FPW-1:0]           crc_data_pipe_out_sec_last_stage_target_crc_per_flit[FPW-1:0];
wire [LOG_FPW-1:0]           crc_data_pipe_out_last_stage_target_crc_per_flit    [FPW-1:0];

generate
    for(f = 0; f < (FPW); f = f + 1) begin : assign_data_pipe_output
        assign crc_data_pipe_out_sec_last_stage_target_crc_per_flit[f] = crc_data_pipe_in_target_crc[CRC_DATA_PIPE_DEPTH-2][f*LOG_FPW+LOG_FPW-1:f*LOG_FPW] ;
        assign crc_data_pipe_out_last_stage_target_crc_per_flit[f]     = crc_data_pipe_in_target_crc[CRC_DATA_PIPE_DEPTH-1][f*LOG_FPW+LOG_FPW-1:f*LOG_FPW] ;
        assign crc_data_pipe_out_data_flit[f]                          = crc_data_pipe_in_data[CRC_DATA_PIPE_DEPTH-1][(f*128)+128-1:f*128];
    end
endgenerate

//------------------------------------------------------------------------------------The final Output stage with FLITS including their crc
reg  [128-1:0]              data_rdy_flit   [FPW-1:0];

generate
        for(f = 0; f < (FPW); f = f + 1) begin : reorder_flits_to_word
            assign d_out_data[(f*128)+128-1:(f*128)] = data_rdy_flit[f];
        end
endgenerate

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------LOGIC STARTS HERE---------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================
//====================================================================
//---------------------------------Generate Variables for fill regs
//====================================================================
always @(*)  begin

    //2 variables are used. crc_var_multi_comb counts multi-flit response packets so that they are assigned to a lower order crc target
    //crc_var_single counts single flit packets and assigns these FLITs to the higher order crc targets
    //This is done because in the next stage, crc targets are re-ordered so that the higher fill grades move to the upper positions

    //Reset all signals
    crc_var_multi_comb  = {LOG_FPW{1'b0}};
    crc_var_single      = FPW-1;    //TODO set only the upper bit

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_pkt_length_comb[i_f] = 4'h0;
    end

    //Logic starts here
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        if(d_in_hdr[i_f])begin
            if(d_in_tail[i_f]) begin
                //Single FLIT packet
                if(big_pkt && crc_var_single==FPW-1) begin
                    //if a packet crossed the cycle boundary, do not assign any other FLITs to this crc in this cycle!
                    //otherwise the CRCs wont be available in the same cycle after calculation
                    crc_var_single = crc_var_single - {{LOG_FPW-1{1'b0}},1'b1};
                end
                crc_offset_comb[i_f]                    = crc_var_single;
                crc_pkt_length_comb[crc_var_single]     = 4'h1;
                crc_var_single                          = crc_var_single - {{LOG_FPW-1{1'b0}},1'b1};
            end else begin
                //Multi FLIT packet
                crc_offset_comb[i_f]                    = crc_var_multi_comb;
                //use the length information that is already available to avoid misbehavior in case of dln/lng mismatch
                crc_pkt_length_comb[crc_var_multi_comb] = d_in_lng_per_flit[i_f];
                crc_var_multi_comb                      = crc_var_multi_comb + {{LOG_FPW-1{1'b0}},1'b1};
            end
        end else begin
            crc_offset_comb[i_f]     = {LOG_FPW{1'b0}};
        end
    end

    if(crc_var_multi_comb > 0) begin
        //subtract by one because this var will be used as index in the next stage
        crc_var_multi_comb = crc_var_multi_comb - {{LOG_FPW-1{1'b0}},1'b1};
    end
end

`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_pkt_length[i_f] <= 4'h0;
        crc_offset[i_f]     <= {LOG_FPW{1'b0}};
    end
    crc_var_multi   <= 0;
end else begin
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_pkt_length[i_f] <= crc_pkt_length_comb[i_f];
        crc_offset[i_f]     <= crc_offset_comb[i_f];
    end
    crc_var_multi   <= crc_var_multi_comb;
end
end

//====================================================================
//---------------------------------Detect packets that cross a cycle boundary, necessary to assign target CRCs
//====================================================================
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    big_pkt <= 1'b0;
end else begin
    //Reset the marker for a big packet when seen a tail in the current cycle
    if(|d_in_tail) begin
        big_pkt <= 1'b0;
    end
    //Set the big packet marker if there is a packet that spreads over multiple cycles
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        if(d_in_hdr[i_f])begin
            if ((i_f + d_in_lng_per_flit[i_f]) > FPW)begin
                big_pkt <= 1'b1;
            end
        end
    end
end
end

//====================================================================
//---------------------------------Check the fill grades, reorder
//====================================================================
always @(*)  begin

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        fill_comb[i_f]          = fill[i_f] + crc_pkt_length[i_f] - |fill[i_f];
        next_target_comb[i_f]   = next_target[i_f];
    end

    if(crc_fifo_d_in_hdr_buf || crc_fifo_d_in_tail_buf) begin

        if(big_pkt) begin
            //Always move the packet that spreads over mutiple cycle to the highest order target
            fill_comb_t              = fill_comb[crc_var_multi];
            fill_comb[crc_var_multi] = fill_comb[FPW-1];
            fill_comb[FPW-1]         = fill_comb_t;

            next_target_comb_t             = next_target_comb[crc_var_multi];
            next_target_comb[crc_var_multi]= next_target_comb[FPW-1];
            next_target_comb[FPW-1]        = next_target_comb_t;

            //Perform a reordering on the remaining targets
            for(i_f=0;i_f<FPW-2;i_f=i_f+1)begin
                if(fill_comb[i_f] > fill_comb[i_f+1]) begin
                    fill_comb_t      = fill_comb[i_f+1];
                    fill_comb[i_f+1] = fill_comb[i_f];
                    fill_comb[i_f]   = fill_comb_t;

                    next_target_comb_t       = next_target_comb[i_f+1];
                    next_target_comb[i_f+1]  = next_target_comb[i_f];
                    next_target_comb[i_f]    = next_target_comb_t;

                end
            end
        end else begin

            //Perform regular reordering over all FLITs and targets
            for(i_f=0;i_f<FPW-1;i_f=i_f+1)begin
                if(fill_comb[i_f] > fill_comb[i_f+1]) begin
                    fill_comb_t   = fill_comb[i_f+1];
                    fill_comb[i_f+1] = fill_comb[i_f];
                    fill_comb[i_f]   = fill_comb_t;

                    next_target_comb_t       = next_target_comb[i_f+1];
                    next_target_comb[i_f+1]  = next_target_comb[i_f];
                    next_target_comb[i_f]    = next_target_comb_t;
                end

            end
        end
    end
end

`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        fill[i_f]          <= 4'h0;
        next_target[i_f]   <= i_f;
    end
end else begin
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        fill[i_f]          <= fill_comb[i_f];
        next_target[i_f]   <= next_target_comb[i_f];
    end
end
end

//====================================================================
//---------------------------------Assign the target CRCs to FLITs
//====================================================================
always @(*)  begin
    crc_fifo_d_in_next_target_temp_comb = crc_fifo_d_in_next_target_temp;

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        if(crc_fifo_d_in_hdr_buf[i_f]) begin
            crc_fifo_d_in_target_crc_per_flit_comb[i_f]  =  next_target[crc_offset[i_f]];
            crc_fifo_d_in_next_target_temp_comb          =  next_target[crc_offset[i_f]];
        end else begin
             crc_fifo_d_in_target_crc_per_flit_comb[i_f] =  crc_fifo_d_in_next_target_temp_comb;
        end
    end
end

//Assign combinational values for next cycle
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    crc_fifo_d_in_next_target_temp         <= {LOG_FPW{1'b0}};

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_fifo_d_in_target_crc_per_flit[i_f] <= {LOG_FPW{1'b0}};
    end
end else begin

    crc_fifo_d_in_next_target_temp         <= crc_fifo_d_in_next_target_temp_comb;

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_fifo_d_in_target_crc_per_flit[i_f] <= crc_fifo_d_in_target_crc_per_flit_comb[i_f];
    end

end
end

//====================================================================
//---------------------------------Fill CRC input FIFOs
//====================================================================
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    //Reset the stages that are used while the crc assignment is taking place
    crc_data2crc_fifo_buf       <= {DWIDTH{1'b0}};
    crc_fifo_d_in_hdr_buf       <= {FPW{1'b0}};
    crc_fifo_d_in_tail_buf      <= {FPW{1'b0}};
    crc_fifo_d_in_valid_buf     <= {FPW{1'b0}};
    crc_data2crc_fifo           <= {DWIDTH{1'b0}};
    crc_fifo_d_in_hdr           <= {FPW{1'b0}};
    crc_fifo_d_in_tail          <= {FPW{1'b0}};
    crc_fifo_d_in_valid         <= {FPW{1'b0}};

    //And reset fifo inputs
    crc_fifo_shift_in           <= {FPW{1'b0}};
    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_fifo_d_in_data[i_f]     <= {128{1'b0}};
    end

end else begin

    //CRC fifos input data
    crc_data2crc_fifo_buf    <= d_in_data;
    crc_fifo_d_in_hdr_buf    <= d_in_hdr;
    crc_fifo_d_in_tail_buf   <= d_in_tail;
    crc_fifo_d_in_valid_buf  <= d_in_valid;

    crc_data2crc_fifo        <= crc_data2crc_fifo_buf;
    crc_fifo_d_in_hdr        <= crc_fifo_d_in_hdr_buf;
    crc_fifo_d_in_tail       <= crc_fifo_d_in_tail_buf;
    crc_fifo_d_in_valid      <= crc_fifo_d_in_valid_buf;

    crc_fifo_shift_in        <= {FPW{1'b0}};

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin

        //Reset Hdr/Tail/Valid information
        crc_fifo_d_in_data[i_f][DWIDTH+(3*FPW)-1:DWIDTH] <= 0;

        //Fill the CRC fifos, every input fifo gets the entire data-word
        crc_fifo_d_in_data[i_f][DWIDTH-1:0]                 <= crc_data2crc_fifo;

        //if at least one target_crc matches the currently selected crc stream -> shift data in
        for(i_f2=0;i_f2<FPW;i_f2=i_f2+1)begin
            if((crc_fifo_d_in_target_crc_per_flit[i_f2] == i_f) && crc_fifo_d_in_valid[i_f2])begin
                crc_fifo_shift_in[i_f]                          <= 1'b1;
                crc_fifo_d_in_data[i_f][DWIDTH+i_f2]            <= crc_fifo_d_in_hdr[i_f2];
                crc_fifo_d_in_data[i_f][DWIDTH+(FPW)+i_f2]      <= crc_fifo_d_in_tail[i_f2];
                crc_fifo_d_in_data[i_f][DWIDTH+(2*FPW)+i_f2]    <= crc_fifo_d_in_valid[i_f2];
            end
        end

    end
end
end

//====================================================================
//---------------------------------Constant propagation of the data pipeline
//====================================================================
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
    for(i_c=0;i_c<CRC_DATA_PIPE_DEPTH;i_c=i_c+1)begin
        crc_data_pipe_in_data[i_c]       <= {DWIDTH{1'b0}};
        crc_data_pipe_in_hdr[i_c]        <= {FPW{1'b0}};
        crc_data_pipe_in_tail[i_c]       <= {FPW{1'b0}};
        crc_data_pipe_in_valid[i_c]      <= {FPW{1'b0}};
        crc_data_pipe_in_target_crc[i_c] <= {FPW*LOG_FPW{1'b0}};
    end
end else begin

    //Set the first stage of the data pipeline
    crc_data_pipe_in_data[0]       <= crc_data2crc_fifo;
    crc_data_pipe_in_hdr[0]        <= crc_fifo_d_in_hdr;
    crc_data_pipe_in_tail[0]       <= crc_fifo_d_in_tail;
    crc_data_pipe_in_valid[0]      <= crc_fifo_d_in_valid;
    crc_data_pipe_in_target_crc[0] <= crc_fifo_d_in_target_crc;

    //Data Pipeline propagation
    for(i_c=0;i_c<(CRC_DATA_PIPE_DEPTH-1);i_c=i_c+1)begin
        crc_data_pipe_in_data[i_c+1]       <= crc_data_pipe_in_data[i_c];
        crc_data_pipe_in_hdr[i_c+1]        <= crc_data_pipe_in_hdr[i_c];
        crc_data_pipe_in_tail[i_c+1]       <= crc_data_pipe_in_tail[i_c];
        crc_data_pipe_in_valid[i_c+1]      <= crc_data_pipe_in_valid[i_c];
        crc_data_pipe_in_target_crc[i_c+1] <= crc_data_pipe_in_target_crc[i_c];
    end
end
end

//====================================================================
//---------------------------------Input FIFO to CRC
//====================================================================
//crc fifos output stage. select the proper sources for each crc
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin
        crc_d_in_startNew   <= {FPW{1'b0}};
        crc_fifo_shift_out  <= {FPW{1'b0}};
        crc_d_in_tail       <= {FPW{1'b0}};
        crc_d_in_valid      <= {FPW{1'b0}};

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_d_in[i_f]       <= {128{1'b0}};
        crc_d_in_mask[i_f]  <= {FPW{1'b1}};
    end

end else begin
    //Reset control signals
    crc_fifo_shift_out  <= {FPW{1'b0}};
    crc_d_in_startNew   <= {FPW{1'b0}};
    crc_d_in_valid      <= {FPW{1'b0}};
    crc_d_in_tail       <= {FPW{1'b0}};

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        crc_d_in_mask[i_f]   <= {FPW{1'b1}};
        crc_d_in[i_f]        <= {128{1'b0}};

        if(!crc_fifo_empty[i_f] && !(crc_fifo_shift_out[i_f] && crc_fifo_a_empty[i_f])) begin

            for(i_f2=FPW-1;i_f2>=0;i_f2=i_f2-1)begin
                //If there is a shift_out ongoing, look at the next fifo value so that we dont need to wait another cycle
                if(crc_fifo_shift_out[i_f]) begin
                    if(crc_d_in_mask[i_f][i_f2] && crc_fifo_d_out_valid_next[i_f][i_f2]) begin
                        crc_d_in_mask[i_f]      <= {FPW{1'b1}} << i_f2+1;
                        crc_d_in_startNew[i_f]  <= crc_fifo_d_out_hdr_next[i_f][i_f2];
                        crc_d_in_tail[i_f]      <= crc_fifo_d_out_tail_next[i_f][i_f2];
                        crc_d_in_valid[i_f]     <= 1'b1;
                        if(crc_fifo_d_out_tail_next[i_f][i_f2])begin
                            crc_d_in[i_f]           <= {{32{1'b0}},crc_fifo_d_out_data_flit_next[i_f*FPW+i_f2][95:0]};
                        end else begin
                            crc_d_in[i_f]           <= crc_fifo_d_out_data_flit_next[i_f*FPW+i_f2];
                        end
                    end

                    if((crc_fifo_d_out_valid_next[i_f] & crc_d_in_mask[i_f]) == {{FPW-1{1'b0}},1'b1} << i_f2)  begin
                        crc_fifo_shift_out[i_f] <= 1'b1;
                        crc_d_in_mask[i_f]      <= {FPW{1'b1}};
                    end

                end else begin
                    //No shift out, use FIFO output
                    if(crc_d_in_mask[i_f][i_f2] && crc_fifo_d_out_valid[i_f][i_f2]) begin
                        crc_d_in_mask[i_f]      <= {FPW{1'b1}} << i_f2+1;
                        crc_d_in_startNew[i_f]  <= crc_fifo_d_out_hdr[i_f][i_f2];
                        crc_d_in_tail[i_f]      <= crc_fifo_d_out_tail[i_f][i_f2];
                        crc_d_in_valid[i_f]     <= 1'b1;
                        if(crc_fifo_d_out_tail[i_f][i_f2])begin
                            crc_d_in[i_f]           <= {{32{1'b0}},crc_fifo_d_out_data_flit[i_f*FPW+i_f2][95:0]};
                        end else begin
                            crc_d_in[i_f]           <= crc_fifo_d_out_data_flit[i_f*FPW+i_f2];
                        end
                    end

                    if((crc_fifo_d_out_valid[i_f] & crc_d_in_mask[i_f]) == {{FPW-1{1'b0}},1'b1} << i_f2) begin
                        crc_fifo_shift_out[i_f] <= 1'b1;
                        crc_d_in_mask[i_f]      <= {FPW{1'b1}};
                    end
                end
            end

        end
    end

end
end

//====================================================================
//---------------------------------At the end of the data pipeline get and add CRCs
//====================================================================
`ifdef ASYNC_RES
always @(posedge clk or negedge res_n)  begin `else
always @(posedge clk)  begin `endif
if(!res_n) begin

    //Reset control signals
    crc_o_fifo_shift_out  <= {FPW{1'b0}};

    //Reset the outputs
    d_out_hdr             <= {FPW{1'b0}};
    d_out_tail            <= {FPW{1'b0}};
    d_out_valid           <= {FPW{1'b0}};
    d_out_error           <= {FPW{1'b0}};
    d_out_poisoned        <= {FPW{1'b0}};
    d_out_rtc             <= {FPW{1'b0}};
    d_out_flow            <= {FPW{1'b0}};

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin
        data_rdy_flit[i_f]  <= {128{1'b0}};
    end

end else begin

    crc_o_fifo_shift_out    <= {FPW{1'b0}};
    d_out_rtc               <= {FPW{1'b0}};
    d_out_error             <= {FPW{1'b0}};
    d_out_poisoned          <= {FPW{1'b0}};
    d_out_flow              <= {FPW{1'b0}};

    //Propagate
    d_out_hdr           <= crc_data_pipe_in_hdr[CRC_DATA_PIPE_DEPTH-1];
    d_out_tail          <= crc_data_pipe_in_tail[CRC_DATA_PIPE_DEPTH-1];
    d_out_valid         <= crc_data_pipe_in_valid[CRC_DATA_PIPE_DEPTH-1];

    for(i_f=0;i_f<FPW;i_f=i_f+1)begin

        //Propagate data
        data_rdy_flit[i_f]  <= crc_data_pipe_out_data_flit[i_f];

        if(crc_data_pipe_in_tail[CRC_DATA_PIPE_DEPTH-2][i_f])begin
        //Shift out the fifos with the desired CRCs, so they can be sampled in the next cycle
            crc_o_fifo_shift_out[crc_data_pipe_out_sec_last_stage_target_crc_per_flit[i_f]] <= 1'b1;
        end

        if(crc_data_pipe_in_tail[CRC_DATA_PIPE_DEPTH-1][i_f])begin
        //Finally compare the CRC and add flow/rtc information if there is a tail

            if(crc(crc_data_pipe_out_data_flit[i_f]) == ~crc_o_fifo_d_out[crc_data_pipe_out_last_stage_target_crc_per_flit[i_f]]) begin
                //Poisoned
                d_out_poisoned[i_f]    <= 1'b1;
            end else if(crc(crc_data_pipe_out_data_flit[i_f]) != crc_o_fifo_d_out[crc_data_pipe_out_last_stage_target_crc_per_flit[i_f]]) begin
                //Error
                d_out_error[i_f]    <= 1'b1;
            end

            //Add the return token count indicator when the packet has rtc
            if(!crc_data_pipe_in_hdr[CRC_DATA_PIPE_DEPTH-1][i_f]) begin
                //Multi-FLIT packets always have a valid RTC
                d_out_rtc[i_f] <= 1'b1;
            end else begin
                if((cmd(crc_data_pipe_out_data_flit[i_f]) == CMD_TRET) || !is_flow(crc_data_pipe_out_data_flit[i_f])) begin
                    //All non-flow packets have a valid RTC
                    d_out_rtc[i_f] <= 1'b1;
                end
                if(is_flow(crc_data_pipe_out_data_flit[i_f])) begin
                    //Set the flow packet indicator
                    d_out_flow[i_f] <= 1'b1;
                end
            end

        end
    end
end
end

//=====================================================================================================
//-----------------------------------------------------------------------------------------------------
//---------INSTANTIATIONS HERE-------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------
//=====================================================================================================

//CRC input fifos
generate
    for(f=0;f<FPW;f=f+1) begin : crc_input_fifo_gen
        sync_fifo #(
        .DATASIZE(CRC_FIFO_DWIDTH),
        .ADDRSIZE(4)
        )
        crc_input_fifo_I
        (
        .clk(clk),
        .res_n(res_n),
        .d_in(crc_fifo_d_in_data[f]),
        .shift_in(crc_fifo_shift_in[f]),
        .d_out(crc_fifo_d_out_data[f]),
        .d_out_nxt(crc_fifo_d_out_data_next[f]),
        .shift_out(crc_fifo_shift_out[f]),
        .empty(crc_fifo_empty[f]),
        .almost_empty(crc_fifo_a_empty[f])
        );
    end
endgenerate


//CRC Modules
generate
    for(f=0;f<FPW;f=f+1) begin : crc_gen_single_flit
        crc_128bit_pipe crc_I
        (
            .clk(clk),
            .res_n(res_n),
            .inStartNew(crc_d_in_startNew[f]),
            .inValid(crc_d_in_valid[f]),
            .inData(crc_d_in[f]),
            .inTail(crc_d_in_tail[f]),
            .crcValid(crc_crc_valid[f]),
            .crc(crc_crc[f])
        );
    end
endgenerate

//CRC output fifos
generate
    for(f=0;f<FPW;f=f+1) begin : crc_output_fifo_gen
        sync_fifo_simple #(
        .DATASIZE(CRC_WIDTH),
        .ADDRSIZE(4)
        )
        crc_output_fifo_I
        (
        .clk(clk),
        .res_n(res_n),
        .d_in(crc_crc[f]),
        .shift_in(crc_crc_valid[f]),
        .d_out(crc_o_fifo_d_out[f]),
        .shift_out(crc_o_fifo_shift_out[f]),
        .next_stage_full(1'b1),
        .empty()
        );
    end
endgenerate

endmodule
`default_nettype wire